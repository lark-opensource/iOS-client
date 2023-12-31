//
//  UDNotice.swift
//  BannerTest
//
//  Created by 龙伟伟 on 2020/10/12.
//  Copyright © 2020 vvlong. All rights reserved.
//

import UIKit
import Foundation
import SnapKit
import UniverseDesignFont
import UniverseDesignColor


public protocol UDNoticeDelegate: AnyObject {
    /// 右侧文字按钮点击事件回调
    func handleLeadingButtonEvent(_ button: UIButton)

    /// 右侧图标按钮点击事件回调
    func handleTrailingButtonEvent(_ button: UIButton)
    
    /// 文字按钮/文字链按钮点击事件回调
    func handleTextButtonEvent(URL: URL, characterRange: NSRange)
}

private struct UDNoticeLayoutConfig {
    var iconLeftMargin: CGFloat = 16
    var iconTopMargin: CGFloat = 13
    var iconWidthHeight: CGFloat = 16
    var textLeftMargin: CGFloat = 8
    var textTopBottomMargin: CGFloat = 12
    var trailingButtonWidthHeight: CGFloat = 44
    var trailingButtonMargin: CGFloat = 14
    var trailingButtonInternalMargin: CGFloat = 16
    var leadingButtonHeight: CGFloat = 20
    var leadingButtonMargin: CGFloat = 16
    var leadingButtonAndTextMargin: CGFloat = 4
    var leadingButtonInternalMargin: CGFloat = 12
    var textAndLeadingButtonMinMargin: CGFloat = 16
    var noticeMinHeight: CGFloat = 44
}

// Notice文档，包含相关布局规则 https://bytedance.feishu.cn/docs/doccnVx0rsa30CxnLhmUJNHk3Yc
open class UDNotice: UIView {

    /// 控件配置
    public private(set) var config: UDNoticeUIConfig

    /// 左侧icon
    public var leadingIconImageView: UIImageView?

    /// Notice文本内容
    public var textView = UITextView()

    ///需要轮播时使用UILabel替换
    public var scrollLabel = MarqueeLabel.init(frame: .zero)

    /// 右侧文字按钮
    public var leadingButton: UIButton?

    /// 右侧图标按钮
    public var trailingButton: UIButton?


    ///居中View
    private var centerView = UIView()

    /// Notice文本内容字体大小
    public var font: UIFont = UDFont.body2(.fixed)

    /// 点击事件回调代理
    public weak var delegate: UDNoticeDelegate?

    private let layoutConfig = UDNoticeLayoutConfig()

    /// 决定leadingButton是否换行
    private var needWrap = false

    /// 内部宽度cache
    private var viewWidth: CGFloat = 0

    public init(config: UDNoticeUIConfig) {
        self.config = config
        super.init(frame: .zero)
        setupUI()
    }

    private func setupUI() {
        clipsToBounds = true
        setupUIWithConfig(config)
        if config.autoScrollable {
            scrollLabel.backgroundColor = .clear
            scrollLabel.font = font
            scrollLabel.textAlignment = .natural
            scrollLabel.textColor = UDNoticeColorTheme.noticeTextColor
            scrollLabel.speed = .rate(config.speed)
            switch config.direction {
            case .left:
                scrollLabel.type = .continuous
            case .right:
                scrollLabel.type = .continuousReverse
            }
            scrollLabel.fadeLength = config.fadeLength
            addSubview(scrollLabel)
        } else {
            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.backgroundColor = .clear
            textView.font = font
            textView.isScrollEnabled = false
            textView.isEditable = false
            textView.textContainer.lineFragmentPadding = 0
            textView.textAlignment = .natural
            textView.textContainerInset = .zero
            let linkTextColor = config.linkTextColor ?? UDNoticeColorTheme.noticeLinkTextColor
            textView.linkTextAttributes = [NSAttributedString.Key.foregroundColor: linkTextColor]
            textView.delegate = self
            textView.textColor = UDNoticeColorTheme.noticeTextColor
            addSubview(textView)
        }

    }

    private func setupUIWithConfig(_ config: UDNoticeUIConfig) {
        backgroundColor = config.backgroundColor
        if let leadingIcon = config.leadingIcon {
            leadingIconImageView = UIImageView(image: leadingIcon)
            leadingIconImageView?.clipsToBounds = true
            leadingIconImageView?.contentMode = .scaleAspectFill
            addSubview(leadingIconImageView ?? UIImageView())
        }
        if let leadingButtonText = config.leadingButtonText {
            leadingButton = UIButton(type: .custom)
            leadingButton?.setTitle(leadingButtonText, for: .normal)
            leadingButton?.titleLabel?.font = font
            leadingButton?.contentHorizontalAlignment = .left
            leadingButton?.setTitleColor(UDNoticeColorTheme.noticeButtonTextColor, for: .normal)
            leadingButton?.addTarget(self, action: #selector(handleLeadingButtonEvent), for: .touchUpInside)
            let inset = layoutConfig.trailingButtonMargin
            leadingButton?.titleEdgeInsets = UIEdgeInsets(top: inset, left: 0,
                                                          bottom: layoutConfig.trailingButtonMargin, right: 0)
            addSubview(leadingButton ?? UIButton())
        }
        if var trailingButtonIcon = config.trailingButtonIcon {
            trailingButton = UIButton(type: .custom)
            trailingButtonIcon = trailingButtonIcon.ud.withTintColor(UIColor.ud.iconN2)
            trailingButton?.setImage(trailingButtonIcon, for: .normal)
            trailingButton?.addTarget(self, action: #selector(handleTrailingButtonEvent), for: .touchUpInside)
            let inset = layoutConfig.trailingButtonMargin
            trailingButton?.imageEdgeInsets = UIEdgeInsets(top: inset, left: inset,
                                                           bottom: inset, right: inset)
            addSubview(trailingButton ?? UIButton())
        }
        setAttributeText()
    }

    private func setAttributeText() {
        let paragraphStyle = NSMutableParagraphStyle()
        let lineHeightMultiple: CGFloat = 1.055
        paragraphStyle.lineHeightMultiple = lineHeightMultiple
        paragraphStyle.lineSpacing = 0
        paragraphStyle.paragraphSpacing = 0
        paragraphStyle.alignment = .center
        if let lineBreakMode = config.lineBreakMode {
            paragraphStyle.lineBreakMode = lineBreakMode
        }

        let mutAttributedString = NSMutableAttributedString(attributedString: config.attributedText)
        mutAttributedString.addAttributes([NSAttributedString.Key.paragraphStyle: paragraphStyle],
                                          range: NSRange(location: 0, length: config.attributedText.length))
        if config.autoScrollable {
            scrollLabel.attributedText = mutAttributedString
        } else {
            textView.attributedText = mutAttributedString
        }
    }

    private func setupCenterLayout(){
        needWrap = getNeedWrapIfNeeded(bounds.width)
        if needWrap {
            setupLeftLayout()
            return
        }

        centerView.addSubview(textView)
        centerView.addSubview(leadingIconImageView ?? UIImageView())
        centerView.addSubview(leadingButton ?? UIButton())
        addSubview(centerView)
        centerView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(getCenterViewWidth())
            make.top.bottom.equalToSuperview()
        }
        leadingIconImageView?.snp.makeConstraints({ (make) in
            make.leading.equalToSuperview()
            make.top.equalTo(layoutConfig.iconTopMargin)
            make.width.height.equalTo(layoutConfig.iconWidthHeight)
        })
        textView.snp.makeConstraints({ (make) in
            make.top.equalTo(layoutConfig.textTopBottomMargin)
            // 左侧约束与左侧icon是否存在有关
            if let leadingIconImageView = leadingIconImageView {
                make.leading.equalTo(leadingIconImageView.snp.trailing).offset(layoutConfig.textLeftMargin)
            } else {
                make.leading.equalToSuperview()
            }
            // textview 底部约束与文字按钮是否换行相关
            make.bottom.equalToSuperview().offset(-layoutConfig.textTopBottomMargin)

        })
        leadingButton?.snp.makeConstraints({ (make) in
            make.top.equalToSuperview()
            make.leading.equalTo(textView.snp.trailing).offset(layoutConfig.leadingButtonMargin)
            make.height.equalTo(layoutConfig.trailingButtonWidthHeight)
        })
        trailingButton?.snp.makeConstraints({ (make) in
            make.top.equalToSuperview()
            //只需要offset(2)，因为trailingbutton视觉上自带右侧大小为14的inset
            make.trailing.equalTo(safeAreaLayoutGuide).offset(-2)
            make.width.height.equalTo(layoutConfig.trailingButtonWidthHeight)
        })
    }

    private func setupLeftLayout() {
        needWrap = getNeedWrapIfNeeded(bounds.width)
        leadingIconImageView?.snp.makeConstraints({ (make) in
            make.leading.equalTo(safeAreaLayoutGuide).offset(layoutConfig.iconLeftMargin)
            make.top.equalTo(layoutConfig.iconTopMargin)
            make.width.height.equalTo(layoutConfig.iconWidthHeight)
        })
        trailingButton?.snp.makeConstraints({ (make) in
            make.top.equalToSuperview()
            //只需要offset(2)，因为trailingbutton视觉上自带右侧大小为14的inset
            make.trailing.equalTo(safeAreaLayoutGuide).offset(-2)
            make.width.height.equalTo(layoutConfig.trailingButtonWidthHeight)
        })
        leadingButton?.snp.makeConstraints({ (make) in
            let buttonTextWidth = config.leadingButtonText?
                .getTextWidth(font: font, height: layoutConfig.leadingButtonHeight) ?? 0
            if buttonTextWidth > 0 {
                make.width.equalTo(buttonTextWidth)
            }
            if !needWrap {
                // 非换行情况下，右侧与图标按钮或者父级view做约束
                make.top.equalToSuperview()
                if let trailingButton = trailingButton {
                    make.trailing.equalTo(trailingButton.snp.leading)
                } else {
                    make.trailing.equalTo(safeAreaLayoutGuide).offset(-layoutConfig.trailingButtonInternalMargin)
                }
                make.height.equalTo(layoutConfig.trailingButtonWidthHeight)
            } else {
                // 换行情况下与图标按钮或者父级view做约束
                if let leadingIconImageView = leadingIconImageView {
                    make.leading.equalTo(leadingIconImageView.snp.trailing).offset(layoutConfig.textLeftMargin)
                } else {
                    make.leading.equalTo(layoutConfig.iconLeftMargin)
                }
                make.height.equalTo(layoutConfig.leadingButtonHeight)
                make.trailing.lessThanOrEqualToSuperview().offset(-layoutConfig.trailingButtonInternalMargin)
                make.top.equalTo(textView.snp.bottom).offset(layoutConfig.leadingButtonAndTextMargin)
            }
        })
        if config.autoScrollable {
            setupScrollLabelLayout()
        } else {
            setupTextViewLayout()
        }
    }

    private func setupScrollLabelLayout() {
        scrollLabel.snp.makeConstraints({ (make) in
            make.top.equalTo(layoutConfig.textTopBottomMargin)
            // 左侧约束与左侧icon是否存在有关
            if let leadingIconImageView = leadingIconImageView {
                make.leading.equalTo(leadingIconImageView.snp.trailing).offset(layoutConfig.textLeftMargin)
            } else {
                make.leading.equalTo(safeAreaLayoutGuide).offset(layoutConfig.iconLeftMargin)
            }
            let trailingRightMargin = trailingButton != nil ? layoutConfig.trailingButtonWidthHeight : 0
            let leadingRightMargin = leadingButton != nil ?
            layoutConfig.trailingButtonWidthHeight + layoutConfig.textAndLeadingButtonMinMargin : 0
            let rightMargin = max(trailingRightMargin + (needWrap ? 0 : leadingRightMargin),
                                  layoutConfig.trailingButtonInternalMargin)
            // scrollLabel右边距与右侧按钮以及按钮宽度有关
            if let trailingButton = trailingButton {
                if needWrap {
                    make.trailing.equalTo(trailingButton.snp.leading)
                } else {
                    let buttonTextWidth = config.leadingButtonText?
                        .getTextWidth(font: font, height: layoutConfig.leadingButtonHeight) ?? 0
                    make.trailing.equalTo(trailingButton.snp.leading)
                        .offset(-buttonTextWidth - layoutConfig.textAndLeadingButtonMinMargin)
                }
            } else {
                make.trailing.equalTo(safeAreaLayoutGuide).offset(-rightMargin)
            }
            // scrollLabel 底部约束与文字按钮是否换行相关
            if !needWrap || leadingButton == nil {
                make.bottom.equalToSuperview().offset(-layoutConfig.textTopBottomMargin)
            } else {
                make.bottom.equalToSuperview().offset(-layoutConfig.textTopBottomMargin -
                                                       layoutConfig.leadingButtonHeight -
                                                       layoutConfig.leadingButtonAndTextMargin)
            }
        })
    }

    private func setupTextViewLayout() {
        textView.snp.makeConstraints({ (make) in
            make.top.equalTo(layoutConfig.textTopBottomMargin)
            // 左侧约束与左侧icon是否存在有关
            if let leadingIconImageView = leadingIconImageView {
                make.leading.equalTo(leadingIconImageView.snp.trailing).offset(layoutConfig.textLeftMargin)
            } else {
                make.leading.equalTo(safeAreaLayoutGuide).offset(layoutConfig.iconLeftMargin)
            }
            let trailingRightMargin = trailingButton != nil ? layoutConfig.trailingButtonWidthHeight : 0
            let leadingRightMargin = leadingButton != nil ?
            layoutConfig.trailingButtonWidthHeight + layoutConfig.textAndLeadingButtonMinMargin : 0
            let rightMargin = max(trailingRightMargin + (needWrap ? 0 : leadingRightMargin),
                                  layoutConfig.trailingButtonInternalMargin)
            // textview右边距与右侧按钮以及按钮宽度有关
            if let trailingButton = trailingButton {
                if needWrap {
                    make.trailing.equalTo(trailingButton.snp.leading)
                } else {
                    let buttonTextWidth = config.leadingButtonText?
                        .getTextWidth(font: font, height: layoutConfig.leadingButtonHeight) ?? 0
                    make.trailing.equalTo(trailingButton.snp.leading)
                        .offset(-buttonTextWidth - layoutConfig.textAndLeadingButtonMinMargin)
                }
            } else {
                make.trailing.equalTo(safeAreaLayoutGuide).offset(-rightMargin)
            }
            // textview 底部约束与文字按钮是否换行相关
            if !needWrap || leadingButton == nil {
                make.bottom.equalToSuperview().offset(-layoutConfig.textTopBottomMargin)
            } else {
                make.bottom.equalToSuperview().offset(-layoutConfig.textTopBottomMargin -
                                                       layoutConfig.leadingButtonHeight -
                                                       layoutConfig.leadingButtonAndTextMargin)
            }
        })
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if bounds.width != viewWidth {
            viewWidth = bounds.width
            update()
        }
    }

    @objc
    func handleLeadingButtonEvent() {
        guard let leadingButton = leadingButton else { return }
        delegate?.handleLeadingButtonEvent(leadingButton)
    }

    @objc
    func handleTrailingButtonEvent() {
        guard let trailingButton = trailingButton else { return }
        delegate?.handleTrailingButtonEvent(trailingButton)
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func updateConfigAndRefreshUI(_ config: UDNoticeUIConfig) {
        self.config = config
        update()
    }

    public func update() {
        resetLayout()
        resetUI()
        setupUI()
        if config.alignment == .left {
            setupLeftLayout()
        } else {
            setupCenterLayout()
        }
    }

    private func resetLayout() {
        leadingIconImageView?.snp.removeConstraints()
        leadingButton?.snp.removeConstraints()
        trailingButton?.snp.removeConstraints()
        textView.snp.removeConstraints()
        scrollLabel.snp.removeConstraints()
    }

    private func resetUI() {
        leadingIconImageView?.removeFromSuperview()
        leadingButton?.removeFromSuperview()
        trailingButton?.removeFromSuperview()
        if config.autoScrollable {
            scrollLabel.removeFromSuperview()
        } else {
            textView.removeFromSuperview()
        }
        leadingIconImageView = nil
        leadingButton = nil
        trailingButton = nil
    }
    private func getCenterViewWidth() -> CGFloat{
        var buttonTextWidth: CGFloat = 0
        if let leadingButtonText = config.leadingButtonText {
            buttonTextWidth = leadingButtonText.getTextWidth(font: font, height: layoutConfig.leadingButtonHeight)
        }
        let textViewTextWidth = config.attributedText.string
            .getTextWidth(font: font, height: layoutConfig.leadingButtonHeight)
        let iconWidth = config.leadingIcon != nil ?
        layoutConfig.iconWidthHeight + layoutConfig.textLeftMargin
        : 0
        var leadingButtonWidth: CGFloat = 0
        if leadingButton != nil {
            leadingButtonWidth = layoutConfig.leadingButtonMargin + buttonTextWidth
        } else {
            leadingButtonWidth = 0
        }
        return textViewTextWidth + iconWidth + leadingButtonWidth
    }
    private func getWidth()->CGFloat{
        var buttonTextWidth: CGFloat = 0
        if let leadingButtonText = config.leadingButtonText {
            buttonTextWidth = leadingButtonText.getTextWidth(font: font, height: layoutConfig.leadingButtonHeight)
        }
        let textViewTextWidth = config.attributedText.string
            .getTextWidth(font: font, height: layoutConfig.leadingButtonHeight)
        let margin = config.leadingIcon != nil ?
        layoutConfig.iconLeftMargin + layoutConfig.iconWidthHeight + layoutConfig.textLeftMargin
        : layoutConfig.iconLeftMargin
        var buttonMargin: CGFloat = 0
        if trailingButton != nil && leadingButton != nil {
            buttonMargin = layoutConfig.iconLeftMargin * 3 + layoutConfig.trailingButtonWidthHeight + buttonTextWidth
        } else if trailingButton != nil {
            buttonMargin = layoutConfig.iconLeftMargin * 2 + layoutConfig.trailingButtonWidthHeight
        } else if leadingButton != nil {
            buttonMargin = layoutConfig.iconLeftMargin * 2 + buttonTextWidth
        } else {
            buttonMargin = layoutConfig.iconLeftMargin
        }
        return textViewTextWidth + margin + buttonMargin
    }
    /// 根据父View的宽度，计算 左侧按钮+文本+右侧文字按钮+右侧图标按钮的宽度是否在一行内显示，不能显示则返回需要换行的标记
    private func getNeedWrapIfNeeded(_ contentSizeWidth: CGFloat) -> Bool {
        if config.autoScrollable {
            return false
        }
        if textView.textContainer.maximumNumberOfLines == 1 {
            /// 如果设置了一行，不需要换行计算
            return false
        }
        let width = getWidth()
        let needWrap =  width > contentSizeWidth
        return needWrap
    }

    /// 计算整个组件的尺寸
    override public func sizeThatFits(_ contentSize: CGSize) -> CGSize {
        needWrap = getNeedWrapIfNeeded(contentSize.width)
        if !needWrap && (config.trailingButtonIcon != nil || config.leadingButtonText != nil) {
            return CGSize(width: contentSize.width, height: layoutConfig.noticeMinHeight)
        }
        var frameHeight = layoutConfig.textTopBottomMargin * 2
        var widthLimit = contentSize.width
        if config.trailingButtonIcon != nil {
            /// trailingButton 约束时，有偏移两个像素
            widthLimit -= 2
            widthLimit -= layoutConfig.trailingButtonWidthHeight
        }
        if config.leadingIcon != nil {
            widthLimit -= layoutConfig.iconWidthHeight
            widthLimit -= layoutConfig.iconLeftMargin
        }
        if let leadingButtonText = config.leadingButtonText, !needWrap {
            let buttonTextWidth = leadingButtonText.getTextWidth(font: font, height: layoutConfig.leadingButtonHeight)
            widthLimit -= (buttonTextWidth +
                           layoutConfig.leadingButtonMargin * 2 +
                           layoutConfig.textAndLeadingButtonMinMargin)
        }
        widthLimit -= layoutConfig.textLeftMargin
        let textViewSize = textView.sizeThatFits(CGSize(width: widthLimit, height: CGFloat.greatestFiniteMagnitude))
        var maximumHeight = textViewSize.height
        if config.trailingButtonIcon != nil {
            maximumHeight = CGFloat(max(layoutConfig.trailingButtonInternalMargin, maximumHeight))
        }
        if config.leadingButtonText != nil {
            if needWrap {
                frameHeight += layoutConfig.leadingButtonHeight + layoutConfig.leadingButtonAndTextMargin
            } else {
                maximumHeight = CGFloat(max(layoutConfig.trailingButtonInternalMargin, maximumHeight))
            }
        }
        if config.leadingIcon != nil {
            maximumHeight = CGFloat(max(layoutConfig.trailingButtonInternalMargin, maximumHeight))
        }
        frameHeight += maximumHeight
        return CGSize(width: contentSize.width, height: max(layoutConfig.noticeMinHeight, frameHeight))
    }
}

extension String {
    func getTextWidth(font: UIFont, height: CGFloat) -> CGFloat {
        let rect = NSString(string: self).boundingRect(with: CGSize(width: CGFloat(MAXFLOAT), height: height),
                                                       options: [.usesFontLeading, .usesLineFragmentOrigin],
                                                       attributes: [NSAttributedString.Key.font: font],
                                                       context: nil)
        return ceil(rect.width)
    }
}

extension UDNotice: UITextViewDelegate {
    public func textView(_ textView: UITextView,
                         shouldInteractWith URL: URL,
                         in characterRange: NSRange,
                         interaction: UITextItemInteraction) -> Bool {
        delegate?.handleTextButtonEvent(URL: URL, characterRange: characterRange)
        return false
    }

    public func textViewDidChangeSelection(_ textView: UITextView) {
        if !NSEqualRanges(textView.selectedRange, NSRange(location: 0, length: 0)) {
            textView.selectedRange = NSRange(location: 0, length: 0)
        }
    }
}
