//
//  ProxyAwareSession.swift
//  ehviewer nya
//
//  跟随「手动代理」设置自动重建的 URLSession 持有者。
//
//  URLSessionConfiguration 在创建会话那一刻就被拷贝，之后再改 AppSettings
//  对已建好的会话毫无影响。缩略图、阅读器用的都是长生命周期单例 session，
//  不监听通知就会「配了代理要重启 App 才生效」。
//

import Foundation
import EhSettings

final class ProxyAwareSession: @unchecked Sendable {
    private let lock = NSLock()
    private var _session: URLSession
    private let build: () -> URLSession
    /// 持有观察者令牌，否则注册可能被回收
    private var observer: NSObjectProtocol?

    init(_ build: @escaping () -> URLSession) {
        self.build = build
        self._session = build()
        self.observer = NotificationCenter.default.addObserver(
            forName: EhProxy.didChangeNotification, object: nil, queue: nil
        ) { [weak self] _ in
            self?.rebuild()
        }
    }

    var session: URLSession {
        lock.lock(); defer { lock.unlock() }
        return _session
    }

    private func rebuild() {
        let old = session
        let next = build()
        lock.lock(); _session = next; lock.unlock()
        // 等在途请求跑完再释放，别把用户正在看的那一页打断
        old.finishTasksAndInvalidate()
    }
}
