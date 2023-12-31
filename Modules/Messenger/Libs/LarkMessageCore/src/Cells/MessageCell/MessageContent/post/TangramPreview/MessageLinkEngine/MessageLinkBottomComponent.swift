//
//  MessageLinkBottomComponent.swift
//  LarkMessageCore
//
//  Created by Ping on 2023/6/1.
//

import SnapKit
import TangramComponent
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignColor

// 底部查看详情 & 蒙层
final class MessageLinkBottomView: UIView {
    // 需要和卡片背景色保持一致，由外部传入
    var customBgColor: UIColor = UDMessageColorTheme.imMessageCardBGBodyEmbed {
        didSet {
            gradientLayer.ud.setColors([customBgColor.withAlphaComponent(0), customBgColor])
            wrapperView.backgroundColor = customBgColor
        }
    }

    var showMask: Bool = false {
        didSet {
            gradientLayer.removeFromSuperlayer()
            if showMask {
                // component里每次会移除多余的sublayer，所以每次update需要重新insert
                layer.insertSublayer(gradientLayer, at: 0)
                gradientLayer.isHidden = false
                // 高度25是加上了splitLine的高度，不然会有断层
                gradientLayer.frame = CGRect(x: 0, y: -24, width: frame.width, height: 25)
            }
        }
    }

    private lazy var gradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 0, y: 1)
        return gradient
    }()

    private lazy var splitLine: UIView = {
        let splitLine = UIView()
        splitLine.backgroundColor = UIColor.ud.lineDividerDefault
        return splitLine
    }()

    private lazy var wrapperView = UIView()

    private lazy var showMoreLabel: UILabel = {
        let showMoreLabel = UILabel()
        showMoreLabel.text = BundleI18n.LarkMessageCore.Lark_IM_MessageLink_ViewDetails_Button
        showMoreLabel.textColor = UIColor.ud.textCaption
        showMoreLabel.font = UDFont.body2
        showMoreLabel.numberOfLines = 1
        return showMoreLabel
    }()

    private lazy var showMoreIcon: UIImageView = {
        let showMoreIcon = UIImageView()
        showMoreIcon.image = BundleResources.rightSmallCcmOutlined
        showMoreIcon.contentMode = .center
        return showMoreIcon
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.insertSublayer(gradientLayer, at: 0)
        // 高度25是加上了splitLine的高度，不然会有断层
        gradientLayer.isHidden = true
        addSubview(splitLine)
        addSubview(wrapperView)
        wrapperView.addSubview(showMoreLabel)
        wrapperView.addSubview(showMoreIcon)
        layout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.ud.setColors([customBgColor.withAlphaComponent(0), customBgColor])
        layout()
    }

    private func layout() {
        gradientLayer.frame = CGRect(x: 0, y: -24, width: frame.width, height: 25)
        splitLine.frame = CGRect(x: 16, y: 0, width: frame.width - 16 * 2, height: 1)
        wrapperView.frame = CGRect(x: 0, y: 1, width: frame.width, height: frame.height - splitLine.frame.height)
        showMoreLabel.frame = CGRect(x: 16, y: 0, width: wrapperView.frame.width - 16 * 2 - 24, height: wrapperView.frame.height)
        showMoreIcon.frame = CGRect(x: wrapperView.frame.width - 16 - 24, y: (wrapperView.frame.height - 24) / 2, width: 24, height: 24)
    }

    static func sizeToFit(_ size: CGSize) -> CGSize {
        // 1: 分割线高；8: icon距顶部间距；24: icon size；16: icon距底部间距
        let height: CGFloat = 1 + 8 + 24 + 16
        return CGSize(width: size.width, height: height)
    }
}

final class MessageLinkBottomComponentProps: Props {
    // 是否展示渐变蒙层
    var showMask: Bool = false
    var backgroundColor: UIColor = UDMessageColorTheme.imMessageCardBGBodyEmbed

    init() {}

    func clone() -> MessageLinkBottomComponentProps {
        let clone = MessageLinkBottomComponentProps()
        clone.showMask = showMask
        clone.backgroundColor = backgroundColor.copy() as? UIColor ?? UDMessageColorTheme.imMessageCardBGBodyEmbed
        return clone
    }

    func equalTo(_ old: Props) -> Bool {
        guard let old = old as? MessageLinkBottomComponentProps else { return false }
        return showMask == old.showMask &&
        backgroundColor == old.backgroundColor
    }
}

final class MessageLinkBottomComponent<C: Context>: RenderComponent<MessageLinkBottomComponentProps, MessageLinkBottomView, C> {
    override var isSelfSizing: Bool {
        return true
    }

    public override func update(_ view: MessageLinkBottomView) {
        super.update(view)
        view.customBgColor = props.backgroundColor
        view.showMask = props.showMask
    }

    public override func sizeToFit(_ size: CGSize) -> CGSize {
        return MessageLinkBottomView.sizeToFit(size)
    }
}
