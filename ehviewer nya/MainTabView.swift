//
//  MainTabView.swift
//  ehviewer nya
//
//  主导航: TabView (iOS) / 三栏 NavigationSplitView (macOS)
//

import SwiftUI
import EhModels
import EhSettings

struct MainTabView: View {
    @Environment(AppState.self) private var appState
    @State private var selectedTab: Tab = Tab.fromLaunchPage(AppSettings.shared.launchPage)
    /// 剪贴板打开画廊 (iOS sheet 展示)
    @State private var clipboardGallery: GalleryInfo?
    #if os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    #endif
    #if os(macOS)
    @State private var selectedGallery: GalleryInfo?
    /// 标签导航路径 — 支持从 Detail 列点击标签推入新画廊列表到 Content 列
    @State private var contentPath = NavigationPath()
    #endif

    enum Tab: String, CaseIterable {
        case home = "首页"
        case subscription = "订阅"
        case popular = "热门"
        case toplist = "排行榜"
        case favorites = "收藏"
        case downloads = "下载"
        case history = "历史"
        case settings = "设置"
        case more = "更多"
        case profile = "我的"

        var icon: String {
            switch self {
            case .home: return "house"
            case .subscription: return "bell"
            case .popular: return "flame"
            case .toplist: return "chart.bar"
            case .favorites: return "heart"
            case .downloads: return "arrow.down.circle"
            case .history: return "clock"
            case .settings: return "gear"
            case .more: return "ellipsis.circle"
            case .profile: return "person.crop.circle"
            }
        }

        /// 固定的底部默认标签页。
        /// 「热门」「排行」已提到首页顶部的横向切页，不再占用底部位置；
        /// 「设置」并入「我的」，底部因此空出一格给「历史」。
        private static let defaultBottomTabs: [Tab] = [.home, .favorites, .downloads, .history, .profile]

        /// iPhone 底部标签固定为这五项。
        ///
        /// 此前会按「启动页面」设置把首页替换成热门/排行，但那两者现在是首页顶部的
        /// 横向切页而非独立标签页；继续替换会让底部栏在不同设置下项数与顺序都不同，
        /// 而底部栏是肌肉记忆最强的控件，不该随设置变形。
        /// 启动页指向热门/排行时改为落到首页并选中对应切页，见 initialBrowseSource。
        static var bottomTabs: [Tab] { defaultBottomTabs }

        /// "更多"菜单中的标签页 — 不在底部栏且非 .more 的标签
        static var moreTabs: [Tab] {
            let bottom = Set(bottomTabs)
            return allCases.filter { $0 != .more && $0 != .profile && !bottom.contains($0) }
        }

        /// 浮起导航条的图标（选中态用实心变体）
        var filledIcon: String {
            switch self {
            case .home: return "house.fill"
            case .favorites: return "heart.fill"
            case .downloads: return "arrow.down.circle.fill"
            case .history: return "clock.fill"
            case .profile: return "person.crop.circle.fill"
            default: return icon
            }
        }

        /// 启动页面设置映射
        /// 启动页面设置 → 底部标签。
        ///
        /// ⚠️ 返回值必须落在 `bottomTabs` 里。
        ///
        /// 这里原本给「热门」「排行」返回 .popular / .toplist，但那两者早就不是
        /// 独立标签页了，已经并进首页顶部的切页（见 initialBrowseSource，它才是
        /// 处理这两项的地方）。而底部内容是
        /// `ForEach(bottomTabs) { .opacity(selectedTab == tab ? 1 : 0) }`——
        /// selectedTab 落在 bottomTabs 之外时没有任何图层匹配，
        /// 全部 opacity 0：整屏黑，只剩浮起导航条。
        /// 把「启动页面」设成热门或排行的用户，每次冷启动都是这个画面。
        static func fromLaunchPage(_ page: Int) -> Tab {
            let tab: Tab
            switch page {
            // 热门 / 排行 → 首页，具体切页由 initialBrowseSource 决定
            case 1, 2: tab = .home
            case 3: tab = .favorites
            case 4: tab = .downloads
            case 5: tab = .history
            default: tab = .home
            }
            // 兜底：万一以后又有人往这里加一个不在底部栏的标签，
            // 也只是回到首页，而不是黑屏
            return bottomTabs.contains(tab) ? tab : .home
        }
    }

    var body: some View {
        let _ = NSLog("[RENDER] MainTabView body")
        #if DEBUG
        let _ = Self._printChanges()  // ★ 诊断: 精确显示哪个属性触发了 body 重新求值
        #endif
        #if os(macOS)
        NavigationSplitView {
            // 「我的」不占侧栏。它的内容（账号资料、图片配额）已并入设置页的
            // 「账号」分类——侧栏本来就是平铺全部入口，再单开一格只有一个
            // 二级页的入口，反而多一层。（iOS 的底部栏仍保留「我的」。）
            List(Tab.allCases.filter { $0 != .more && $0 != .profile },
                 id: \.self, selection: $selectedTab) { tab in
                Label(tab.rawValue, systemImage: tab.icon)
            }
            .navigationTitle("EhViewer")
            .navigationSplitViewColumnWidth(min: 160, ideal: 180)
        } detail: {
            // 列表与画廊详情并排放在 detail 这一栏里，而不是让 NavigationSplitView
            // 常驻第三个栏目。
            //
            // 三栏布局在没有任何选中时也会把第三栏画出来（内容是「选择画廊」占位），
            // 切到设置、下载这些与画廊无关的页面时那一栏同样还在。改成 HSplitView 后，
            // 详情栏只在真正选中一本画廊时才被加进来，其余时候列表独占整栏；
            // 设置页的二级 push 仍在左栏的导航栈里，不受影响。
            HSplitView {
                galleryListColumn
                if let gallery = selectedGallery {
                    galleryDetailColumn(gallery)
                }
            }
            // HSplitView 按子视图的 ideal 尺寸摆放，不会自动拉满整栏：
            // 设置页那类自带固定高度的内容会因此只覆盖上半截，下面露出窗口背景。
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onChange(of: selectedTab) { _, newTab in
            selectedGallery = nil
            contentPath = NavigationPath()
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToHome)) { _ in
            selectedTab = .home
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToPopular)) { _ in
            selectedTab = .popular
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToTopList)) { _ in
            selectedTab = .toplist
        }
        .onReceive(NotificationCenter.default.publisher(for: .navigateToFavorites)) { _ in
            selectedTab = .favorites
        }
        // 全局强调色：链接、开关、选中态一次性统一到琥珀，
        // 不必逐个视图替换散落的 .blue / .accentColor
        .tint(EhColor.accent)
        .onReceive(NotificationCenter.default.publisher(for: .openGalleryFromClipboard)) { notification in
            guard let userInfo = notification.userInfo,
                  let gid = userInfo["gid"] as? Int64,
                  let token = userInfo["token"] as? String else { return }
            let gallery = GalleryInfo(gid: gid, token: token)
            selectedGallery = gallery
        }
        #else
        // iOS: iPad regular → 侧边栏 NavigationSplitView, iPhone → 底部 TabView
        Group {
            if horizontalSizeClass == .regular {
                // iPad 横屏 / 外接键盘: 侧边栏导航
                NavigationSplitView {
                    List {
                        ForEach(Tab.allCases.filter { $0 != .more }, id: \.self) { tab in
                            Button {
                                selectedTab = tab
                            } label: {
                                HStack {
                                    Label(tab.rawValue, systemImage: tab.icon)
                                    Spacer()
                                }
                                .contentShape(Rectangle())
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(selectedTab == tab ? Color.accentColor.opacity(0.15) : nil)
                        }
                    }
                    .listStyle(.sidebar)
                    .navigationTitle("EhViewer")
                } detail: {
                    tabContent(selectedTab)
                        .id(selectedTab)
                }
            } else {
                // iPhone / iPad 竖屏: 浮起玻璃导航条
                //
                // 不再用系统 TabView：设计需要一条离开屏幕边缘、带圆角与模糊的浮条，
                // 而 TabBar 的外观定制到不了这个程度。代价是要自己补回系统行为，
                // 见 EhFloatingTabBar 的说明（安全区避让、重复点击回顶、无障碍）。
                ZStack {
                    ForEach(Tab.bottomTabs, id: \.self) { tab in
                        tabContent(tab)
                            // 保留全部页面的视图状态：切走的页面只是隐藏，
                            // 不销毁，回来时滚动位置与已加载数据都还在
                            .opacity(selectedTab == tab ? 1 : 0)
                            .allowsHitTesting(selectedTab == tab)
                            .accessibilityHidden(selectedTab != tab)
                    }
                }
                .ehFloatingTabBar(
                    items: Tab.bottomTabs.map {
                        .init(value: $0, title: $0.rawValue, symbol: $0.icon, selectedSymbol: $0.filledIcon)
                    },
                    selection: $selectedTab,
                    onReselect: { tab in
                        NotificationCenter.default.post(
                            name: .ehScrollToTop, object: nil, userInfo: ["tab": tab.rawValue]
                        )
                    }
                )
            }
        }
        // 全局强调色：链接、开关、选中态一次性统一到琥珀，
        // 不必逐个视图替换散落的 .blue / .accentColor
        .tint(EhColor.accent)
        .onReceive(NotificationCenter.default.publisher(for: .openGalleryFromClipboard)) { notification in
            guard let userInfo = notification.userInfo,
                  let gid = userInfo["gid"] as? Int64,
                  let token = userInfo["token"] as? String else { return }
            clipboardGallery = GalleryInfo(gid: gid, token: token)
        }
        .sheet(item: $clipboardGallery) { gallery in
            NavigationStack {
                GalleryDetailView(gallery: gallery)
                    .id(gallery.gid)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("关闭") { clipboardGallery = nil }
                        }
                    }
            }
        }
        .onChange(of: horizontalSizeClass) { _, newSizeClass in
            // iPad 旋转切换时确保选中标签有效
            if newSizeClass == .compact {
                if !Tab.bottomTabs.contains(selectedTab) {
                    selectedTab = .more
                }
            }
        }
        #endif
    }

    #if os(macOS)
    /// 列表栏：当前标签页的内容（画廊列表 / 设置 / 下载 …），并承载标签与查询的推入导航。
    ///
    /// `.id(selectedTab)` 让换标签时这一栏整体重建——
    /// 与改动前 content 栏的行为一致，列表不会残留上一个标签的滚动位置。
    private var galleryListColumn: some View {
        NavigationStack(path: $contentPath) {
            macOSContentView(for: selectedTab)
                // 历史页的列表用它推入画廊详情。画廊列表页走的是选中绑定，
                // 不产生这种取值式跳转，两者互不干扰。
                .navigationDestination(for: GalleryInfo.self) { gallery in
                    GalleryDetailView(gallery: gallery)
                        .id(gallery.gid)
                }
                .navigationDestination(for: TagSearchDestination.self) { dest in
                    // 标签点击推入的画廊列表 (对齐 Android: onTagClick → GalleryListScene)
                    GalleryListView(mode: .tag(keyword: dest.tag), selection: $selectedGallery)
                }
                .navigationDestination(for: GalleryQueryDestination.self) { dest in
                    // 上传者等查询推入的画廊列表
                    GalleryListView(mode: .search(dest.query), selection: $selectedGallery)
                }
        }
        .id(selectedTab)
        .frame(minWidth: 340, idealWidth: 480, maxWidth: .infinity)
    }

    /// 详情栏：只在有选中画廊时由 `HSplitView` 加入，所以不存在空占位状态。
    private func galleryDetailColumn(_ gallery: GalleryInfo) -> some View {
        NavigationStack {
            GalleryDetailView(gallery: gallery)
                .id(gallery.gid)
        }
        .frame(minWidth: 380, idealWidth: 520, maxWidth: .infinity)
        .environment(\.tagNavigationAction, TagNavigationAction { tag in
            contentPath.append(TagSearchDestination(tag: tag))
        })
        .environment(\.searchNavigationAction, SearchNavigationAction { query in
            contentPath.append(GalleryQueryDestination(query: query))
        })
    }

    @ViewBuilder
    private func macOSContentView(for tab: Tab) -> some View {
        switch tab {
        case .home:
            GalleryListView(mode: .home, selection: $selectedGallery)
        case .subscription:
            GalleryListView(mode: .subscription, selection: $selectedGallery)
        case .popular:
            GalleryListView(mode: .popular, selection: $selectedGallery)
        case .toplist:
            GalleryListView(mode: .toplist(period: 15), selection: $selectedGallery)
        case .favorites:
            FavoritesView(selection: $selectedGallery)
        case .downloads:
            // 与设置页同理：标题交给窗口顶部工具栏，页内不再自建导航栈。
            DownloadsView(isPushed: true)
        case .history:
            HistoryView(isPushed: true)
        case .settings:
            // 复用列表栏已有的 NavigationStack，不让设置页再套一层。
            //
            // SettingsView() 默认会自建 NavigationStack（那层是给 iOS 用的，
            // 手机上没有外层栈）。在 macOS 这里再套一层，就会多画一条只属于
            // 内层栈的标题条——它和下面的内容对不齐。二级页本来也只要推入
            // 外层栈即可，与 MoreTabView 里的 SettingsView(isPushed: true) 同理。
            SettingsView(isPushed: true)
        case .profile:
            // macOS 侧栏不再有「我的」这一格（见侧栏的过滤），落到这里只有
            // 兜底意义：账号资料与图片配额都在设置页的「账号」分类里。
            EmptyView()
        case .more:
            // macOS 不使用 "更多" 标签，不应出现
            EmptyView()
        }
    }
    #endif

    #if os(iOS)
    /// 保留全部页面的视图状态：切走的页面只是隐藏而不销毁，
    /// 回来时滚动位置与已加载数据都还在。
    @ViewBuilder
    private func tabLayer<Content: View>(
        _ tab: Tab, @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .opacity(selectedTab == tab ? 1 : 0)
            .allowsHitTesting(selectedTab == tab)
            .accessibilityHidden(selectedTab != tab)
    }

    /// 启动页面设置指向「热门 / 排行」时，落到首页并选中对应的顶部切页。
    /// 这两者已经不是独立标签页了，不能再去替换底部栏的第一项。
    private static var initialBrowseSource: BrowseSource {
        switch AppSettings.shared.launchPage {
        case 1: return .popular
        case 2: return .toplist
        default: return .home
        }
    }
    #endif

    @ViewBuilder
    private func tabContent(_ tab: Tab) -> some View {
        switch tab {
        case .home:
            // 浏览容器：顶部横向切页承载首页/订阅/热门/排行
            BrowseHomeView()
        case .subscription:
            GalleryListView(mode: .subscription)
        case .popular:
            GalleryListView(mode: .popular)
        case .toplist:
            GalleryListView(mode: .toplist(period: 15))
        case .favorites:
            FavoritesView()
        case .downloads:
            DownloadsView()
        case .history:
            HistoryView()
        case .settings:
            SettingsView()
        case .more:
            // 保留给 iPad/macOS 侧边栏的兼容路径；iPhone 底部栏已改用 .profile
            MoreTabView(onNavigate: { tab in selectedTab = tab })
        case .profile:
            ProfileHomeView()
        }
    }
}

#Preview {
    MainTabView()
        .environment(AppState())
}
