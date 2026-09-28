//
//  ProxySettingsView.swift
//  ehviewer nya
//
//  macOS 专用 — 引导流程中的代理配置页
//
//  登录页是 App 里第一个真正需要联网的地方。如果此时被墙（登录页打不开、
//  Cookie 贴进来也验证不通），用户根本走不到主界面里的「设置 → 网络」
//  去配代理——那扇门在登录之后。所以登录页右上角也放一个入口。
//
//  配置本身不存在这里：读写的是 `AppSettings.proxyMode/Host/Port`，
//  应用走 `EhAPI.applyProxySettings()`，与设置页「网络」一节共用同一份。
//

#if os(macOS)

import SwiftUI
import EhSettings
import EhAPI

/// 代理配置页（macOS）。
///
/// 交互约定：输入框默认带入当前**生效**的配置，用户改哪个字段就地改，
/// 按回车即应用——不再有单独的「应用」按钮。
struct ProxySettingsView: View {
    @Environment(\.dismiss) private var dismiss

    // 默认带入当前生效值，而不是从空白开始敲。
    @State private var mode: Int = AppSettings.shared.proxyMode
    @State private var host: String = AppSettings.shared.proxyHost
    // 端口用字符串承载：Int 未配置时是 0，TextField 会把它显示成「0」，
    // 只有空串才能让 prompt（7890）正常显示。
    @State private var port: String = AppSettings.shared.proxyPort > 0
        ? String(AppSettings.shared.proxyPort) : ""

    /// 输入防抖：边敲边重建会话毫无意义，停手后再落一次
    @State private var pendingApply: Task<Void, Never>?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("代理", selection: $mode) {
                        Text("跟随系统").tag(0)
                        Text("手动 HTTP").tag(1)
                    }
                    .pickerStyle(.segmented)
                    // 没有「应用」按钮，切换模式本身就得即时落下去，
                    // 否则切回「跟随系统」后没有任何途径把它生效。
                    .onChange(of: mode) { _, _ in apply() }

                    if mode == 1 {
                        // 标签交给 Form 渲染（左「地址」右输入框），提示走 prompt。
                        // 若把占位串当标题传给 TextField，macOS 会把它当成左侧标签
                        // 单独画出来，看起来就像「地址 127.0.0.1  [空的输入框]」。
                        TextField("地址", text: $host, prompt: Text("127.0.0.1"))
                            .multilineTextAlignment(.trailing)
                            .autocorrectionDisabled()
                            .onSubmit { apply() }

                        TextField("端口", text: $port, prompt: Text("7890"))
                            .multilineTextAlignment(.trailing)
                            .onSubmit { apply() }
                    }
                } footer: {
                    // 与设置页保持同一套说法：URLSession 不支持 SOCKS，
                    // 半配的代理会被当成没配，免得用户把网络配死还不知道为什么。
                    Text("只支持 HTTP/HTTPS 代理。地址或端口填不全时按「跟随系统」处理，"
                         + "不会把网络配死。改完自动生效，按回车立即应用。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            // 改完不用等回车：停手 0.5s 自动应用，回车则是立即应用。
            // 这样即便用户改了值又忘了回车，也不会「配了代理却要重启才生效」。
            .onChange(of: host) { _, _ in scheduleApply() }
            .onChange(of: port) { _, _ in scheduleApply() }
            .navigationTitle("配置代理服务")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .frame(minWidth: 420, minHeight: 300)
        // sheet 自带一层，根视图的提示层被它挡住 —— 在这里再挂一个，
        // 让「已应用代理」的提示浮在本页最上面。共用同一个 center，不会重复。
        .ehToastHost(bottomInset: 24)
    }

    /// 输入停手后再应用一次，避免每敲一个字符就重建一次会话
    private func scheduleApply() {
        pendingApply?.cancel()
        pendingApply = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            apply()
        }
    }

    /// 落盘 + 重建网络会话。
    ///
    /// `URLSessionConfiguration` 在会话创建时就被拷贝，改设置不会影响已建好的
    /// 会话，必须重建，否则新代理要重启 App 才生效。
    private func apply() {
        let settings = AppSettings.shared
        settings.proxyMode = mode
        settings.proxyHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.proxyPort = Int(port.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0

        Task { await EhAPI.shared.applyProxySettings() }

        EhToast.success(settings.manualProxyIsUsable
                        ? "已应用 \(settings.proxyHost):\(settings.proxyPort)"
                        : "已跟随系统代理")
    }
}

#Preview {
    ProxySettingsView()
}

#endif
