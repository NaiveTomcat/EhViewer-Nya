//
//  SearchQuery.swift
//  EhCore
//
//  统一的搜索查询模型。
//
//  一条查询是一串**有序的 term**，渲染成 E-Hentai 的 `f_search` 语法。
//  之所以要显式的 term 而不是一个字符串：搜索框里的每个胶囊、命中高亮、
//  删除某一项、保存复用，本质上都是对「单个条件」的操作；把查询拆成
//  term 列表后这些操作才不会互相覆盖（此前 `searchTokens = [quoted]`
//  的覆盖式赋值就是多标签组合失效的根因）。
//
//  `.uploader("名字")` 渲染为 `uploader:"名字"` —— 已实测确认这是合法的
//  E-Hentai 命名空间，与 `/uploader/名字` 结果一致，且能与标签用空格做 AND。
//

import Foundation

/// 搜索语法的一个原子项。
public struct SearchTerm: Hashable, Codable, Sendable {
    public enum Kind: Hashable, Codable, Sendable {
        /// 结构化标签。`namespace == nil` 表示无命名空间（misc）。
        case tag(namespace: String?, value: String)
        /// 上传者。渲染为 `uploader:"名字"`。
        case uploader(String)
        /// 原样透传的自由文本（手输、历史条目、快速搜索关键字）。
        case keyword(String)
    }

    public var kind: Kind

    public init(kind: Kind) {
        self.kind = kind
    }

    // MARK: - 构造

    /// 把 `big breasts` / `female:big breasts` / `f:big breasts` 这类标签串
    /// 转成结构化 term。与 `EhTagDatabase.rebuildKeyword` 的输出一致。
    public static func makeTag(_ raw: String) -> SearchTerm {
        let trimmed = raw.trimmingCharacters(in: .whitespaces)
        if let colon = trimmed.firstIndex(of: ":") {
            let namespace = String(trimmed[trimmed.startIndex..<colon]).trimmingCharacters(in: .whitespaces)
            let value = String(trimmed[trimmed.index(after: colon)...]).trimmingCharacters(in: .whitespaces)
            if !namespace.isEmpty, !value.isEmpty {
                return SearchTerm(kind: .tag(namespace: namespace, value: value))
            }
        }
        // 无命名空间：清掉可能残留的引号与 `$`
        let bare = trimmed
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "$", with: "")
        return SearchTerm(kind: .tag(namespace: nil, value: bare))
    }

    public static func makeUploader(_ name: String) -> SearchTerm {
        SearchTerm(kind: .uploader(name))
    }

    public static func keyword(_ raw: String) -> SearchTerm {
        SearchTerm(kind: .keyword(raw))
    }

    // MARK: - 渲染

    /// 渲染成 `f_search` 语法（**未做百分号编码**）。
    public func render() -> String {
        switch kind {
        case .keyword(let raw):
            return raw
        case .uploader(let name):
            return "uploader:\"\(name)\""
        case .tag(let namespace, let value):
            let prefix = namespace.map { EhTagNamespace.prefix(forNamespace: $0) } ?? ""
            // 值里含空格或冒号必须加引号，否则会被 E-Hentai 按词/命名空间拆开
            if value.contains(" ") || value.contains(":") {
                return "\(prefix)\"\(value)$\""
            }
            return "\(prefix)\(value)$"
        }
    }

    /// 胶囊显示与翻译查询用的裸文本（不含 `"`、`$`）。
    /// 例：`.tag("female","big breasts")` → `f:big breasts`。
    public var bareText: String {
        switch kind {
        case .keyword(let raw), .uploader(let raw):
            return raw
                .replacingOccurrences(of: "\"", with: "")
                .replacingOccurrences(of: "$", with: "")
        case .tag(let namespace, let value):
            let prefix = namespace.map { EhTagNamespace.prefix(forNamespace: $0) } ?? ""
            return prefix + value
        }
    }
}

/// 一条完整查询：有序的 term 列表。
public struct SearchQuery: Hashable, Codable, Sendable {
    public var terms: [SearchTerm]

    public init(terms: [SearchTerm] = []) {
        self.terms = terms
    }

    public static var empty: SearchQuery { SearchQuery() }

    public var isEmpty: Bool {
        render().trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// 渲染成 `f_search` 的值：各 term 以空格连接。
    public func render() -> String {
        terms.map { $0.render() }.joined(separator: " ")
    }

    /// 按渲染形式去重后追加一个 term（已存在则不动）。
    public mutating func append(_ term: SearchTerm) {
        let rendered = term.render()
        guard !terms.contains(where: { $0.render() == rendered }) else { return }
        terms.append(term)
    }

    // MARK: - 解析

    /// 解析一段查询串：按空格分割（引号内的空格不拆），
    /// `uploader:"x"` 识别为上传者 term，其余原样透传为 keyword term。
    public static func parse(_ raw: String) -> SearchQuery {
        let pieces = splitRespectingQuotes(raw)
        var terms: [SearchTerm] = []
        for piece in pieces {
            if let name = uploaderName(from: piece) {
                terms.append(.makeUploader(name))
            } else {
                terms.append(.keyword(piece))
            }
        }
        return SearchQuery(terms: terms)
    }

    /// `uploader:"名字"` / `uploader:名字` → `名字`，否则 nil。
    private static func uploaderName(from piece: String) -> String? {
        let prefix = "uploader:"
        guard piece.lowercased().hasPrefix(prefix) else { return nil }
        var value = String(piece.dropFirst(prefix.count))
        value = value.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
        return value.isEmpty ? nil : value
    }

    /// 按空格拆查询，但引号内的空格不拆。
    /// `f:"big ass$" translated` → [`f:"big ass$"`, `translated`]
    public static func splitRespectingQuotes(_ query: String) -> [String] {
        var tokens: [String] = []
        var current = ""
        var inQuotes = false
        for ch in query {
            if ch == "\"" {
                inQuotes.toggle()
                current.append(ch)
            } else if ch == " " && !inQuotes {
                if !current.isEmpty { tokens.append(current); current = "" }
            } else {
                current.append(ch)
            }
        }
        if !current.isEmpty { tokens.append(current) }
        return tokens
    }

    // MARK: - 持久化

    public var jsonString: String {
        guard let data = try? JSONEncoder().encode(self) else { return "" }
        return String(data: data, encoding: .utf8) ?? ""
    }

    public static func from(jsonString: String) -> SearchQuery? {
        guard let data = jsonString.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(SearchQuery.self, from: data)
    }
}

/// 唯一的 GET query 值编码器。
///
/// 允许集 = 字母数字 + `-_.*`，其余（含 `&` `=` `+` `"` `:` `$` `~` `?`）
/// 一律百分号编码，空格编码为 `%20`。
///
/// 此前 `f_search` 用 `.urlQueryAllowed` 编码，该集合**放行** `&` `=` `+`：
/// `&`/`=` 会注入或破坏查询参数，`+` 会被服务端当空格解码。
/// 服务端会在解析 `f_search` 语法前先做百分号解码，所以 `:` `"` `$` 编码后
/// 语法依然成立；而 `*` 是通配符、保留字面量。与 `EhRequestBuilder.formURLEncode`
/// 的允许集保持一致。
public enum SearchQueryEncoder {
    public static let allowed: CharacterSet = {
        var set = CharacterSet.alphanumerics
        set.insert(charactersIn: "-_.*")
        return set
    }()

    public static func encodeValue(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
    }
}
