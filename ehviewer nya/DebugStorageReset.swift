//
//  DebugStorageReset.swift
//  ehviewer nya
//
//  DEBUG 专用的本地数据清空开关
//

#if DEBUG
import Foundation
import WebKit
import EhCookie

/// 只在显式要求时清空本 App 的全部本地数据，让这一次启动等价于全新安装。
///
/// Debug 与 Release 共用同一个 bundle id，UserDefaults / 钥匙串 / 缓存 / Cookie
/// 都会跨构建保留，想复现首次启动引导（18+ 警告页）得手动清数据。这个开关把
/// 那件事变成一条启动参数。
///
/// 触发方式（二选一）：
///   - 启动参数 `-EhResetStorage`（Xcode: Edit Scheme → Run → Arguments）
///   - 环境变量 `EH_RESET_STORAGE=1`
enum DebugStorageReset {
    static var isRequested: Bool {
        ProcessInfo.processInfo.arguments.contains("-EhResetStorage")
            || ProcessInfo.processInfo.environment["EH_RESET_STORAGE"] == "1"
    }

    static func runIfRequested() {
        guard isRequested else { return }

        let fm = FileManager.default
        let bid = Bundle.main.bundleIdentifier ?? "io.github.ShiroiTree.Ehviewer-Nya"

        // UserDefaults：AppSettings 的全部键，外加 reading_progress_* / resumeData_* 等散键
        UserDefaults.standard.removePersistentDomain(forName: bid)

        // Application Support / Caches 下属于本 App 的内容
        if let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            try? fm.removeItem(at: appSupport.appendingPathComponent(bid))
        }
        if let caches = fm.urls(for: .cachesDirectory, in: .userDomainMask).first {
            try? fm.removeItem(at: caches.appendingPathComponent(bid))
            // 这些缓存目录在未开沙盒的 macOS 上直接落在 ~/Library/Caches 根下，
            // 没有 bundle-id 子目录，只能逐个点名。
            for name in ["url_cache", "http_cache", "logs", "spider_image", "eh_tag_translation.json"] {
                try? fm.removeItem(at: caches.appendingPathComponent(name))
            }
        }

        // Documents：只删本 App 自建的路径（白名单），绝不整目录删
        if let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first {
            for name in ["eh.sqlite", "eh.sqlite-wal", "eh.sqlite-shm", "eh.sqlite.corrupted_backup",
                         "download", "archiver", "image"] {
                try? fm.removeItem(at: docs.appendingPathComponent(name))
            }
        }

        // 钥匙串（service com.ehviewer.credentials）
        EhCredentialStore.clear()

        // Cookie 罐 + WebView 站点数据（WebView 登录会留下 WKWebsiteDataStore）
        HTTPCookieStorage.shared.removeCookies(since: .distantPast)
        WKWebsiteDataStore.default().removeData(
            ofTypes: WKWebsiteDataStore.allWebsiteDataTypes(),
            modifiedSince: .distantPast
        ) {}

        NSLog("[DebugStorageReset] 本地数据已清空，本次启动为全新状态")
    }
}
#endif
