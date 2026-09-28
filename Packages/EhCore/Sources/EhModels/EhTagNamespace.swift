//
//  EhTagNamespace.swift
//  EhCore
//
//  E-Hentai 标签命名空间 ↔ 搜索前缀映射。
//  原先放在 EhSettings/EhTagDatabase，下沉到 EhModels 以便搜索语法渲染器复用
//  （对应 Android NAMESPACE_TO_PREFIX / PREFIX_TO_NAMESPACE）。
//

import Foundation

public enum EhTagNamespace {
    public static let namespaceToPrefix: [String: String] = [
        "rows": "n:",
        "artist": "a:",
        "cosplayer": "cos:",
        "character": "c:",
        "female": "f:",
        "group": "g:",
        "language": "l:",
        "male": "m:",
        "misc": "",
        "mixed": "x:",
        "other": "o:",
        "parody": "p:",
        "reclass": "r:"
    ]

    public static let prefixToNamespace: [String: String] = [
        "n:": "rows",
        "a:": "artist",
        "cos:": "cosplayer",
        "c:": "character",
        "f:": "female",
        "g:": "group",
        "l:": "language",
        "m:": "male",
        "": "misc",
        "x:": "mixed",
        "o:": "other",
        "p:": "parody",
        "r:": "reclass"
    ]

    /// 全称命名空间 → 搜索前缀（含冒号）。未知命名空间回退为 `namespace:`。
    /// 与 `EhTagDatabase.rebuildKeyword` 的取值完全一致：
    /// `female` → `f:`，`misc` → ``（空），`f` → `f:`。
    public static func prefix(forNamespace namespace: String) -> String {
        if let prefix = namespaceToPrefix[namespace] {
            return prefix
        }
        return "\(namespace):"
    }
}
