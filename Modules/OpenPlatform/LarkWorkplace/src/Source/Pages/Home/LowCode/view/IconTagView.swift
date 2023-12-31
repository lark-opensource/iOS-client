//
//  IconTagView.swift
//  LarkWorkplace
//
//  Created by Meng on 2022/4/21.
//

import UIKit
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignTheme

extension IconTagView.Config {
    /// 默认配置: 推荐标签
    static let `default` = recommendTag

    /// 推荐 标签配置
    static let recommendTag = IconTagView.Config(
        text: BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_RecTag,
        textColor: UDColor.opTokenAppTagText,
        backgroundColor: UDColor.opTokenAppTagBg
    )

    /// Bot 标签配置
    static let botTag = IconTagView.Config(
        text: BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_BotTag,
        textColor: UDColor.opTokenAppTagbotText,
        backgroundColor: UDColor.opTokenAppTagbotBg
    )

    /// 共享 标签配置
    static let sharedTag = IconTagView.Config(
        text: BundleI18n.LarkWorkplace.OpenPlatform_AppShare_AppTag,
        textColor: UDColor.udtokenTagTextSBlue.alwaysLight,
        backgroundColor: UDColor.B100.alwaysLight
    )
}

/// 我的常用 Icon 的标签组件，可用于「推荐」、「机器人」等。
///
/// 这是一个静态展示 UI，内部已经做好了 size 约束，外部只需设置好相对位置和 Config 即可使用
final class IconTagView: UIView {

    /// UI 配置项
    struct Config {
        /// 标签文本
        var text: String

        /// 文本颜色
        var textColor: UIColor

        /// 背景色
        var backgroundColor: UIColor

        init(text: String, textColor: UIColor, backgroundColor: UIColor) {
            self.text = text
            self.textColor = textColor
            self.backgroundColor = backgroundColor
        }
    }

    /// 布局样式
    enum Layout {
        static let cornerRadius: CGFloat = 8.0
        static let borderWidth: CGFloat = 1.0
        static let minWidth: CGFloat = 36.0
        static let maxWidth: CGFloat = 74.0
        static let height: CGFloat = 16.0
        static let horizontalPadding: CGFloat = 5.0
    }

    /// 配置项
    var config: Config = .default {
        didSet { reloadContent() }
    }

    /// 显示文字 label
    private let label: UILabel = UILabel(frame: .zero)

    init() {
        super.init(frame: .zero)
        setupView()
        setupLayout()
        reloadContent()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func reloadContent() {
        backgroundColor = config.backgroundColor
        label.text = config.text
        label.textColor = config.textColor
    }

    private func setupView() {
        addSubview(label)
        clipsToBounds = true
        layer.cornerRadius = Layout.cornerRadius
        layer.borderWidth = Layout.borderWidth
        layer.ud.setBorderColor(UIColor.ud.primaryOnPrimaryFill)

        label.font = UIFont.ud.caption2
        label.numberOfLines = 1
        label.textAlignment = .center
        label.lineBreakMode = .byTruncatingTail
    }

    private func setupLayout() {
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        label.setContentHuggingPriority(.defaultHigh, for: .vertical)
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        self.snp.makeConstraints { make in
            make.height.equalTo(Layout.height)
            make.width.greaterThanOrEqualTo(Layout.minWidth)
            make.width.lessThanOrEqualTo(Layout.maxWidth)
            make.leading.equalTo(label).offset(-Layout.horizontalPadding).priority(.low)
            make.trailing.equalTo(label).offset(Layout.horizontalPadding).priority(.low)
        }
    }
}
