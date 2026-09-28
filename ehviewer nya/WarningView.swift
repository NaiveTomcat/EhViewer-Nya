//
//  WarningView.swift
//  ehviewer nya
//
//  18+ 内容警告页面 (对应 Android WarningScene)
//

import SwiftUI

/// 18+ 内容警告视图
/// 首次启动时显示，用户必须接受才能继续使用
struct WarningView: View {
    let onAccept: () -> Void
    let onReject: () -> Void

    /// 正文最大行宽。不限的话宽窗口里长句会被拉成接近满宽的一整行；
    /// 顺带让内容在宽窗口里居中而不是贴边。
    private let contentMaxWidth: CGFloat = 460

    var body: some View {
        // 用 GeometryReader 拿真实可用尺寸，而不是 \.responsiveLayout 环境：
        // 那个环境值全项目没有注入点，读到的是默认的 375×667。
        GeometryReader { geo in
            ScrollView(.vertical) {
                VStack(spacing: 0) {
                    // ScrollView 里的 Spacer 不会伸展，纵向居中靠下面
                    // minHeight 撑满视口来实现
                    Spacer(minLength: 24)

                    // 警告图标
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: iconSize(for: geo.size)))
                        // 用红而非黄：这是一道需要用户如实回答的门槛，
                        // 黄色读起来像「注意一下」，红色才是「请确认」
                        .foregroundStyle(EhColor.danger)
                        .padding(.bottom, 20)

                    // 标题
                    Text("本应用包含成人内容")
                        .font(.system(size: titleSize(for: geo.size), weight: .bold))
                        .foregroundStyle(EhColor.label)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 14)

                    // 设计稿这版比原先的项目符号列表短得多，而且补上了「不托管内容」
                    // 这句免责——原文案通篇在描述内容形态，反而漏了这个更要紧的事实。
                    Text("继续使用表示你已满足所在地区的法定年龄要求，并自行承担浏览责任。本应用不托管任何内容，仅作为 E-Hentai / ExHentai 的第三方客户端。")
                        .font(EhFont.body)
                        .foregroundStyle(EhColor.secondaryLabel)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.bottom, 32)

                    Spacer(minLength: 24)

                    // 按钮区域
                    VStack(spacing: 12) {
                        Button("我已满 18 岁，继续", action: onAccept)
                            .buttonStyle(EhFilledButtonStyle(height: EhSize.actionButtonHeight))

                        Button("退出", action: onReject)
                            .buttonStyle(EhTintedButtonStyle(height: EhSize.actionButtonHeight))
                    }
                    .padding(.bottom, 24)
                }
                .padding(.horizontal, 24)
                .frame(maxWidth: contentMaxWidth)
                // 撑满视口：窗口够高时两个 Spacer 把内容居中；窗口不够高时
                // 内容自然变高、ScrollView 接管滚动，按钮不会被裁掉。
                .frame(maxWidth: .infinity, minHeight: geo.size.height)
            }
        }
        .background(EhColor.background)
    }

    private func iconSize(for size: CGSize) -> CGFloat {
        size.width >= 768 ? 56 : 48
    }

    private func titleSize(for size: CGSize) -> CGFloat {
        size.width < 500 ? 22 : 26
    }
}

#Preview {
    WarningView(
        onAccept: { print("Accepted") },
        onReject: { print("Rejected") }
    )
}
