//
//  TangramHeaderView.swift
//  TangramHeaderView
//
//  Created by Saafo on 2021/4/20.
//

import Foundation
import LarkInteraction
import LarkTag
import RichLabel
import UIKit
import UniverseDesignColor
import UniverseDesignFont

extension TangramHeaderView {
    /// 图标大小
    public static var iconSize: CGFloat { return 16.auto() }
    public static let elementMargin: CGFloat = 8
    public static var lineSpacing: CGFloat { 6.auto() }
    public static let titleFont: UIFont = UDFont.headline
}

public final class TangramHeaderView: UIView {
    private var config: TangramHeaderConfig = .default

    private var rightWidth: CGFloat {
        var width: CGFloat = 0
        if config.showMenu {
            width += Self.iconSize + Self.elementMargin
        }
        if customView != nil {
            // width += self.customViewSize.width + Self.elementMargin
            // customView取消margin，因为customView需要定宽
            width += self.config.customViewSize.width
        }
        return width
    }

    // Components
    private lazy var iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 2
        return imageView
    }()
    private lazy var labelView: LKLabel = {
        let labelView = LKLabel()
        labelView.backgroundColor = UIColor.clear
        labelView.lineSpacing = Self.lineSpacing
        return labelView
    }()
    private let textParser = LKTextParserImpl()
    // LKLabel的size需要使用layoutEngine计算，componentTextSize算出来的不准
    private let layoutEngine = LKTextLayoutEngineImpl()
    private var customView: UIView?
    private lazy var menuButton: UIButton = {
        let btn = UIButton()
        btn.setImage(BundleResources.more.withRenderingMode(.alwaysTemplate), for: .normal)
        btn.addTarget(self, action: #selector(menuButtonDidTap), for: .touchUpInside)
        btn.tintColor = config.theme.iconColor
        btn.addTangramPointerIfNeeded()
        return btn
    }()

    // MARK: - Public Interface

    /// 根据配置和Container Size，计算 TangramHeaderView 所需要的大小
    public static func sizeThatFit(config: TangramHeaderConfig, size: CGSize) -> CGSize {
        var titleH: CGFloat = 0
        if config.title.isEmpty {
            titleH = Self.iconSize
        } else {
            let preferMaxWidth = getPreferMaxWidth(width: size.width, config: config)
            let (titleAttr, outOfRangeAttr) = getAttributeString(config: config, size: CGSize(width: preferMaxWidth, height: .greatestFiniteMagnitude))
            let textParser = LKTextParserImpl()
            textParser.defaultFont = Self.titleFont
            textParser.originAttrString = titleAttr
            textParser.parse()
            let layoutEngine = LKTextLayoutEngineImpl()
            layoutEngine.attributedText = textParser.renderAttrString
            layoutEngine.outOfRangeText = outOfRangeAttr
            layoutEngine.preferMaxWidth = preferMaxWidth
            layoutEngine.numberOfLines = config.titleNumberOfLines
            layoutEngine.lineSpacing = lineSpacing
            titleH = layoutEngine.layout(size: size).height
        }
        // 没有title时，header的大小是iconSize
        return CGSize(width: size.width, height: titleH)
    }

    private static func getPreferMaxWidth(width: CGFloat, config: TangramHeaderConfig) -> CGFloat {
        var preferMaxWidth: CGFloat = width - config.customViewSize.width
        if config.iconProvider != nil {
            preferMaxWidth -= (Self.iconSize + Self.elementMargin)
        }
        if config.showMenu {
            preferMaxWidth -= (Self.iconSize + Self.elementMargin)
        }
        return preferMaxWidth
    }

    private static func getAttributeString(config: TangramHeaderConfig, size: CGSize) -> (titleAttr: NSAttributedString, outOfRangeAttr: NSAttributedString) {
        let paragraphStyle = NSMutableParagraphStyle()
        // 根据 https://bytedance.feishu.cn/docx/VpZTdl1IioCrENxfWakcPcrwnFo 替换为 byWordWrapping
        paragraphStyle.lineBreakMode = .byWordWrapping
        let titleAttr = NSMutableAttributedString(
            string: config.title,
            attributes: [
                .font: Self.titleFont,
                .paragraphStyle: paragraphStyle,
                .foregroundColor: config.textColor
            ]
        )
        let outOfRangeAttr = NSMutableAttributedString(string: "...", attributes: [.font: Self.titleFont, .foregroundColor: config.textColor])
        if let headerTag = config.headerTag {
            let tagSize = HeaderTagWrapper.sizeToFit(headerTag: headerTag, size: size)
            let tagAttachment = LKAsyncAttachment(
                viewProvider: { HeaderTagWrapper(headerTag: headerTag, frame: .init(origin: .zero, size: tagSize)) },
                size: tagSize
            )
            tagAttachment.verticalAlignment = .middle
            tagAttachment.fontAscent = Self.titleFont.ascender
            tagAttachment.fontDescent = Self.titleFont.descender
            tagAttachment.margin = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 0)
            let tagAttr = NSAttributedString(string: LKLabelAttachmentPlaceHolderStr,
                                             attributes: [LKAttachmentAttributeName: tagAttachment])
            titleAttr.append(tagAttr)
            outOfRangeAttr.append(tagAttr)
        }
        return (titleAttr, outOfRangeAttr)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(iconView)
        // labelView会一直显示
        addSubview(labelView)
        addSubview(menuButton)
        menuButton.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 配置 TangramHeaderView 的实例，并进行布局，需要在主线程调用
    /// - Parameters:
    ///   - config:     TangramHeaderView 配置
    ///   - width:      TangramHeaderView 所占宽度
    public func configure(with config: TangramHeaderConfig, width: CGFloat) {
        self.config = config
        reset()
        if let iconProvider = config.iconProvider {
            iconView.isHidden = false
            iconProvider(iconView)
        }
        self.customView = config.customView?()
        if let customView = customView {
            addSubview(customView)
        }
        menuButton.isHidden = !config.showMenu
        menuButton.tintColor = config.theme.iconColor
        layout(width: width, config: config)
    }

    public func layout(width: CGFloat, config: TangramHeaderConfig) {
        var layoutPointer: CGFloat = 0
        let fontH = config.title.isEmpty ? Self.iconSize : Self.titleFont.figmaHeight
        if config.iconProvider != nil {
            iconView.frame = .init(x: 0, y: (fontH - Self.iconSize) / 2, width: Self.iconSize, height: Self.iconSize)
            layoutPointer = Self.iconSize + Self.elementMargin
        }

        let preferMaxWidth = Self.getPreferMaxWidth(width: width, config: config)
        let (titleAttr, outOfRangeAttr) = Self.getAttributeString(config: config, size: CGSize(width: preferMaxWidth, height: .greatestFiniteMagnitude))
        textParser.defaultFont = Self.titleFont
        textParser.originAttrString = titleAttr
        textParser.parse()
        layoutEngine.outOfRangeText = outOfRangeAttr
        layoutEngine.attributedText = textParser.renderAttrString
        layoutEngine.preferMaxWidth = preferMaxWidth
        layoutEngine.numberOfLines = config.titleNumberOfLines
        layoutEngine.lineSpacing = Self.lineSpacing
        let titleSize = layoutEngine.layout(size: UIScreen.main.bounds.size)
        labelView.outOfRangeText = outOfRangeAttr
        labelView.preferredMaxLayoutWidth = preferMaxWidth
        labelView.numberOfLines = config.titleNumberOfLines
        labelView.attributedText = titleAttr
        labelView.frame = CGRect(origin: .init(x: layoutPointer, y: 0), size: titleSize)
        layoutPointer += titleSize.width

        if let customView = self.customView {
            var customViewX = width - config.customViewSize.width
            if config.showMenu {
                customViewX -= (Self.iconSize + Self.elementMargin)
            }
            customView.frame = CGRect(origin: .init(x: customViewX, y: (fontH - config.customViewSize.height) / 2), size: config.customViewSize)
            layoutPointer += config.customViewSize.width
        }

        if config.showMenu {
            menuButton.frame = CGRect(x: width - Self.iconSize, y: (fontH - Self.iconSize) / 2, width: Self.iconSize, height: Self.iconSize)
        }
    }

    private func reset() {
        self.customView?.removeFromSuperview()
        iconView.isHidden = true
        menuButton.isHidden = true
    }

    @objc
    private func menuButtonDidTap() {
        config.menuTapHandler?(menuButton)
    }
}

private extension UIButton {
    /// 加上 padding 为 8 pt，radius 为 8 pt 的 Highlight 效果
    func addTangramPointerIfNeeded() {
        if #available(iOS 13.4, *) {
            let action = PointerInteraction(
                style: PointerStyle(
                    effect: .highlight,
                    shape: .roundedSize({ (interaction, _) -> (CGSize, CGFloat) in
                        guard let view = interaction.view else {
                            return (.zero, 0)
                        }
                        return (CGSize(width: view.bounds.width + 16, height: view.bounds.height + 16), 8)
                    })
                )
            )
            self.addLKInteraction(action)
        }
    }
}
