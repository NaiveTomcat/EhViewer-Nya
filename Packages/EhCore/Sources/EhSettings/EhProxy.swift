//
//  EhProxy.swift
//  EhSettings
//
//  手动 HTTP 代理的统一出口。
//
//  此前只有 EhAPI 的两个 URLSession 会读代理设置，缩略图、阅读器、下载
//  各自建的 session 压根没带代理，于是「配了代理但图片仍走直连」。
//  把字典构造和「代理变了」的通知收敛到这里，各模块共用。
//

import Foundation

public enum EhProxy {

    /// 手动代理配置发生变化时发出。
    ///
    /// 已经建好 session 的模块收到后应重建会话——`URLSessionConfiguration`
    /// 在创建会话的那一刻就被拷贝，不重建就要等下次启动才生效。
    public static let didChangeNotification = Notification.Name("EhProxyDidChange")

    /// 当前手动代理的 `connectionProxyDictionary`。
    ///
    /// 没配全返回 nil —— URLSession 会退回系统代理 / VPN，这正是
    /// 「跟随系统」该有的行为，绝不半配着把网络搞挂。
    /// 只给 HTTP/HTTPS 两组键：URLSession 支持的只有这些，SOCKS 无效。
    public static func connectionProxyDictionary() -> [AnyHashable: Any]? {
        let settings = AppSettings.shared
        guard settings.manualProxyIsUsable else { return nil }
        let host = settings.proxyHost
        let port = settings.proxyPort
        return [
            "HTTPEnable": 1,
            "HTTPProxy": host,
            "HTTPPort": port,
            "HTTPSEnable": 1,
            "HTTPSProxy": host,
            "HTTPSPort": port,
        ]
    }

    /// 给 configuration 套上当前代理设置。
    public static func apply(to config: URLSessionConfiguration) {
        config.connectionProxyDictionary = connectionProxyDictionary()
    }
}
