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

struct ProxySettingsView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var mode: Int = AppSettings.shared.proxyMode
    @State private var host: String = AppSettings.shared.proxyHost
    @State private var port: Int = AppSettings.shared.proxyPort

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("代理", selection: $mode) {
                        Text("跟随系统").tag(0)
                        Text("手动 HTTP").tag(1)
                    }
                    .pickerStyle(.segmented)

                    if mode == 1 {
                        HStack {
                            Text("地址")
                            TextField("127.0.0.1", text: $host)
                                .multilineTextAlignment(.trailing)
                                .autocorrectionDisabled()
                        }
                        HStack {
                            Text("端口")
                            TextField("7890", value: $port, format: .number.grouping(.never))
                                .multilineTextAlignment(.trailing)
                        }
                    }
                } footer: {
                    // 与设置页保持同一套说法：URLSession 不支持 SOCKS，
                    // 半配的代理会被当成没配，免得用户把网络配死还不知道为什么。
                    Text("只支持 HTTP/HTTPS 代理。地址或端口填不全时按「跟随系统」处理，"
                         + "不会把网络配死。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Section {
                    Button("应用代理设置") { apply() }
                } footer: {
                    Text("改完点一下才会重建网络会话；不点则要重启 App 才生效。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("配置代理服务")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { dismiss() }
                }
            }
        }
        .frame(minWidth: 420, minHeight: 360)
    }

    private func apply() {
        let settings = AppSettings.shared
        settings.proxyMode = mode
        settings.proxyHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        settings.proxyPort = port

        Task { await EhAPI.shared.applyProxySettings() }

        EhToast.success(settings.manualProxyIsUsable
                        ? "已切换到 \(settings.proxyHost):\(settings.proxyPort)"
                        : "已恢复跟随系统代理")
    }
}

#Preview {
    ProxySettingsView()
}

#endif
