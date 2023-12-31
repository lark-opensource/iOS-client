//
//  UnReadMessagesTipContentView.swift
//  LarkMessageCore
//
//  Created by 袁平 on 2021/2/4.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import LarkZoomable
import ByteWebImage
import UniverseDesignShadow
import UniverseDesignTheme
import LarkBizAvatar
import UniverseDesignColor

enum UnReadMessagesTipContentType: Equatable {
    case forToLastMsg
    case forUnreadAt(entityId: String?, avatarKey: String?, text: String, placeholder: String)
    case forUnreadMsg(unreadCount: Int32, text: String, showMyAI: Bool)
    case none
}

enum TipDirect {
    case up
    case down
}

enum ArrowViewStyle {
    case black
    case white
    case blue
}

private final class ArrowView: UIView {
    lazy var whilteDownUnreadTipArrow: UIImage = {
        let whiteImage = Resources.blueDownUnreadTipArrow.lu.colorize(color: UIColor.ud.primaryOnPrimaryFill, resizingMode: .stretch)
        return whiteImage
    }()

    lazy var blackDownUnreadTipArrow: UIImage = {
        let blackImage = Resources.blueDownUnreadTipArrow.lu.colorize(color: UIColor.ud.iconN1, resizingMode: .stretch)
        return blackImage
    }()

    lazy var whiteUpUnreadTipArrow: UIImage = {
        let whiteImage = Resources.blueUpUnreadTipArrow.lu.colorize(color: UIColor.ud.primaryOnPrimaryFill, resizingMode: .stretch)
        return whiteImage
    }()

    lazy var blueUnReadTipLoading: UIImage = {
        let whiteImage = BundleResources.whiteUnReadTipLoading.lu.colorize(color: UIColor.ud.primaryContentDefault, resizingMode: .stretch)
        return whiteImage
    }()

    var style: ArrowViewStyle = .white {
        didSet {
            /// resolve correct dynamic UIImage
            if #available(iOS 13.0, *) {
                let correctStyle = UDThemeManager.getRealUserInterfaceStyle()
                let correctTraitCollection = UITraitCollection(userInterfaceStyle: correctStyle)
                UITraitCollection.current = correctTraitCollection
            }
            switch (direct, style) {
            case (.up, .white):
                arrowImg.image = self.whiteUpUnreadTipArrow
                loadingImg.image = BundleResources.whiteUnReadTipLoading
            case (.up, .blue):
                arrowImg.image = Resources.blueUpUnreadTipArrow
                loadingImg.image = self.blueUnReadTipLoading
            case (.down, .white):
                arrowImg.image = self.whilteDownUnreadTipArrow
                loadingImg.image = BundleResources.whiteUnReadTipLoading
            case (.down, .blue):
                arrowImg.image = Resources.blueDownUnreadTipArrow
                loadingImg.image = self.blueUnReadTipLoading
            case (.up, .black):
                //ui上暂时没有这种场景
                arrowImg.image = nil
                loadingImg.image = nil
            case (.down, .black):
                arrowImg.image = blackDownUnreadTipArrow
                // 这种场景下无loading
                loadingImg.image = nil
            }
        }
    }

    var direct: TipDirect = .down
    var isLoading: Bool = false {
        didSet {
            // loadingImg未设置image时表示不需要loading，需要提前处理，否则isLoading状态变更时有机率看到空白背景(arrowImg被隐藏)
            guard oldValue != isLoading, loadingImg.image != nil else {
                return
            }
            if isLoading {
                self.loadingImg.isHidden = false
                self.arrowImg.isHidden = true
                self.loadingImgStartRolling()
            } else {
                self.loadingImg.isHidden = true
                self.arrowImg.isHidden = false
                self.loadingImgStopRolling()
            }
        }
    }

    lazy var loadingImg: UIImageView = {
        let img = UIImageView(image: nil)
        img.isHidden = true
        return img
    }()

    lazy var arrowImg: UIImageView = {
        let img = UIImageView(image: nil)
        return img
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(arrowImg)
        self.addSubview(loadingImg)
        arrowImg.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        loadingImg.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func loadingImgStartRolling() {
        let animation = CABasicAnimation()
        animation.keyPath = "transform.rotation.z"
        animation.toValue = Double.pi * 2.0
        animation.duration = 1.5
        animation.repeatCount = Float.infinity
        animation.isRemovedOnCompletion = false
        loadingImg.layer.add(animation, forKey: "Rolling")
    }

    func loadingImgStopRolling() {
        loadingImg.layer.removeAllAnimations()
    }
}

final class UnReadMessagesTipContentView: UIControl {
    var content: UnReadMessagesTipContentType = .none

    var myAIViewClickCallBack: (() -> Void)?

    var loading: Bool = false {
        didSet {
            guard oldValue != loading else { return }
            self.arrowView.isLoading = loading
        }
    }

    var direct: TipDirect = .down {
        didSet {
            arrowView.direct = direct
        }
    }

    private lazy var arrowView: ArrowView = {
        let arrowView = ArrowView(frame: .zero)
        arrowView.direct = direct
        arrowView.isUserInteractionEnabled = false
        return arrowView
    }()

    private lazy var head: BizAvatar = {
        let head = BizAvatar()
        head.layer.cornerRadius = Const.avatarSize / 2
        head.clipsToBounds = true
        head.isHidden = true
        return head
    }()

    private lazy var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        textLabel.font = Const.textFont
        return textLabel
    }()

    private lazy var myAIView: UnReadMessagesMyAIView = {
        let view = UnReadMessagesMyAIView()
        view.addTarget(self, action: #selector(myAIClick), for: .touchUpInside)
        return view
    }()

    override var isHighlighted: Bool {
        didSet {
            switch content {
            case .forUnreadAt: colorForUnreadAt(isHighlighted)
            case .forUnreadMsg: colorForUnreadMsg(isHighlighted)
            case .forToLastMsg: colorForToLastMsg(isHighlighted)
            case .none: break
            }
        }
    }

    override var intrinsicContentSize: CGSize {
        switch content {
        case .forUnreadAt: return contentSizeForUnreadAt()
        case .forUnreadMsg(_, _, let showMyAI): return contentSizeForUnreadMsg(showMyAI: showMyAI)
        case .forToLastMsg: return contentSizeForToLastMsg()
        case .none: return .zero
        }
    }

    init() {
        super.init(frame: .zero)
        self.addSubview(arrowView)
        self.addSubview(head)
        self.addSubview(textLabel)
        self.addSubview(myAIView)
        // 公共样式设置
        backgroundColor = UIColor.ud.bgFloat
        layer.ud.setShadow(type: UDShadowType.s3Down)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(content: UnReadMessagesTipContentType) {
        let needAnimation = (self.content == .forToLastMsg)
        self.content = content
        switch content {
        case .forUnreadAt(entityId: let entityId, avatarKey: let avatarKey, text: let text, placeholder: let placeholder):
            setUnreadAtStyle(entityId: entityId, avatarKey: avatarKey, text: text, placeholder: placeholder, animate: needAnimation)
        case .forUnreadMsg(unreadCount: let unreadCount, text: let text, showMyAI: let showMyAI):
            setUnreadMsgStyle(unreadCount: unreadCount, text: text, animate: needAnimation, showMyAI: showMyAI)
        case .forToLastMsg:
            setToLastMsgStyle()
        case .none:
            break
        }
    }

    func setMyAIViewIcon(_ image: UIImage) {
        myAIView.iconView.image = image
    }

    private func animateSelf() {
        self.alpha = 0
        self.arrowView.alpha = 0
        self.textLabel.alpha = 0
        self.head.alpha = 0
        self.transform = CGAffineTransform(scaleX: 0.2, y: 1)
        UIView.animateKeyframes(withDuration: 0.56, delay: 0, options: [], animations: {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.18, animations: {
                self.alpha = 1
            })
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.35, animations: {
                self.transform = CGAffineTransform(scaleX: 1, y: 1)
            })
            UIView.addKeyframe(withRelativeStartTime: 0.18, relativeDuration: 0.82, animations: {
                self.head.alpha = 1
                self.arrowView.alpha = 1
                self.textLabel.alpha = 1
            })
        })
    }

    @objc
    func myAIClick() {
        self.myAIViewClickCallBack?()
    }
}

// MARK: - forUnreadAt：显示箭头 + 头像 + 文字
extension UnReadMessagesTipContentView {
    private func setUnreadAtStyle(entityId: String?, avatarKey: String?, text: String, placeholder: String, animate: Bool) {
        arrowView.isHidden = false
        head.isHidden = false
        textLabel.isHidden = false
        self.myAIView.isHidden = true
        self.arrowView.style = .white
        self.textLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        arrowView.snp.remakeConstraints { (make) in
            make.leading.equalToSuperview().offset(Const.smallArrowLeading)
            make.centerY.equalToSuperview()
            make.size.equalTo(Const.smallArrowSize)
        }
        head.snp.remakeConstraints { (make) in
            make.leading.equalTo(arrowView.snp.trailing).offset(Const.smallArrowTrailing)
            make.centerY.equalToSuperview()
            make.size.equalTo(Const.avatarSize)
        }
        head.setAvatarByIdentifier(entityId ?? "", avatarKey: avatarKey ?? "", scene: .Chat, avatarViewParams: .init(sizeType: .size(Const.avatarSize)))
        textLabel.text = text + placeholder
        // 一行展示且不缩略时需要的宽度
        Const.textW = 0
        let textW = self.textLabel.sizeThatFits(CGSize(width: CGFloat(MAXFLOAT), height: Const.smallArrowBgHeight)).width
        let maxTextW = Const.maxContentWidth - Const.smallArrowWithTextWidth - Const.smallArrowTrailing - Const.avatarSize
        Const.textW = min(textW, maxTextW)
        textLabel.snp.remakeConstraints { (make) in
            make.leading.equalTo(head.snp.trailing).offset(Const.smallArrowTrailing)
            make.centerY.equalToSuperview()
            make.width.equalTo(Const.textW)
        }
        layoutIfNeeded()
        backgroundColor = UIColor.ud.primaryContentDefault
        layer.borderWidth = 0
        layer.cornerRadius = Const.smallArrowBgHeight / 2
        invalidateIntrinsicContentSize()

        if animate {
            animateSelf()
        }
    }

    private func contentSizeForUnreadAt() -> CGSize {
        return CGSize(width: Const.smallArrowWithTextWidth + Const.avatarSize + Const.smallArrowTrailing, height: Const.smallArrowBgHeight)
    }

    private func colorForUnreadAt(_ isHighlighted: Bool) {
        if isHighlighted {
            backgroundColor = UIColor.ud.primaryContentPressed
        } else {
            backgroundColor = UIColor.ud.primaryContentDefault
        }
    }
}

// MARK: - forUnreadMsg：显示箭头 + 文字
extension UnReadMessagesTipContentView {
    private func setUnreadMsgStyle(unreadCount: Int32, text: String, animate: Bool, showMyAI: Bool) {
        arrowView.isHidden = false
        head.isHidden = true
        textLabel.isHidden = false
        self.myAIView.isHidden = !showMyAI
        self.arrowView.style = .blue
        self.textLabel.textColor = UIColor.ud.colorfulBlue
        arrowView.snp.remakeConstraints { (make) in
            make.leading.equalToSuperview().offset(Const.smallArrowLeading)
            make.centerY.equalToSuperview()
            make.size.equalTo(Const.smallArrowSize)
        }
        textLabel.text = "\(unreadCount) \(text)"
        Const.textW = textLabel.sizeThatFits(CGSize(width: CGFloat(MAXFLOAT), height: Const.smallArrowBgHeight)).width
        textLabel.snp.remakeConstraints { (make) in
            make.leading.equalTo(arrowView.snp.trailing).offset(Const.smallArrowTrailing)
            make.centerY.equalToSuperview()
        }
        myAIView.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalTo(Const.myAIViewHeight)
            make.left.equalTo(textLabel.snp.right).offset(Const.textLabelTrailing)
        }
        layoutIfNeeded()
        backgroundColor = UIColor.ud.bgFloat
        layer.borderWidth = 0.5
        layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        layer.cornerRadius = Const.smallArrowBgHeight / 2
        invalidateIntrinsicContentSize()

        if animate {
            self.animateSelf()
        }
    }

    private func contentSizeForUnreadMsg(showMyAI: Bool) -> CGSize {
        let width: CGFloat = showMyAI ? Const.smallArrowWithTextAndMyAIWidth(myAIWidth: myAIView.intrinsicContentSize.width)
        : Const.smallArrowWithTextWidth
        return CGSize(width: width, height: Const.smallArrowBgHeight)
    }

    private func colorForUnreadMsg(_ isHighlighted: Bool) {
        if isHighlighted {
            backgroundColor = UIColor.ud.bgFiller
        } else {
            backgroundColor = UIColor.ud.bgFloat
        }
    }
}

// MARK: - forToLastMsg：只显示箭头
extension UnReadMessagesTipContentView {
    private func setToLastMsgStyle() {
        arrowView.isHidden = false
        head.isHidden = true
        textLabel.isHidden = true
        myAIView.isHidden = true
        arrowView.style = .black
        arrowView.snp.remakeConstraints { (make) in
            make.center.equalToSuperview()
            make.size.equalTo(Const.bigArrowSize)
        }
        backgroundColor = UIColor.ud.bgFloat
        layer.borderWidth = 0.5
        layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        layer.cornerRadius = Const.bigArrowBgHeight / 2
        invalidateIntrinsicContentSize()
    }

    private func contentSizeForToLastMsg() -> CGSize {
        return CGSize(width: Const.bigArrowBgHeight, height: Const.bigArrowBgHeight)
    }

    private func colorForToLastMsg(_ isHighlighted: Bool) {
        if isHighlighted {
            backgroundColor = UIColor.ud.bgFiller
        } else {
            backgroundColor = UIColor.ud.bgFloat
        }
    }
}

extension UnReadMessagesTipContentView {
    enum Const {
        static var avatarSize: CGFloat { 20.auto() }
        static var textFont: UIFont { UIFont.ud.body1 }
        static var bigArrowSize: CGFloat { 20.auto() }
        static var bigArrowBgHeight: CGFloat { 48.auto() }
        static var smallArrowSize: CGFloat { 16.auto() }
        static var smallArrowBgHeight: CGFloat { 40.auto() }
        static var smallArrowLeading: CGFloat { 12.auto() }
        static var smallArrowTrailing: CGFloat { 4.auto() }
        static var textLabelTrailing: CGFloat { 4.auto() }
        static var myAIViewHeight: CGFloat { 26.auto() }
        static var myAIViewTrailing: CGFloat { (Self.smallArrowBgHeight - myAIViewHeight) / 2 }
        static var smallArrowWithTextWidth: CGFloat {
            return smallArrowLeading * 2 + smallArrowSize + smallArrowTrailing + textW
        }
        static func smallArrowWithTextAndMyAIWidth(myAIWidth: CGFloat) -> CGFloat {
            return smallArrowLeading + smallArrowSize + smallArrowTrailing + textW + textLabelTrailing + myAIWidth + myAIViewTrailing
        }
        // @人时，限制气泡最大宽度为 268
        static var maxContentWidth: CGFloat {
            min(268.auto(), UIScreen.main.bounds.width * 0.8)
        }
        static var textW: CGFloat = 0
    }
}

private class UnReadMessagesMyAIView: UIControl {
    override var intrinsicContentSize: CGSize {
        return .init(width: 33.auto() + (titleView.text ?? "").lu.width(font: titleView.font), height: UnReadMessagesTipContentView.Const.myAIViewHeight)
    }

    override var bounds: CGRect {
        didSet {
            updateCornerRadiusAndBackgroundColor()
        }
    }
    fileprivate lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.isUserInteractionEnabled = false
        return view
    }()

    fileprivate lazy var titleView: UILabel = {
        let view = UILabel()
        view.isUserInteractionEnabled = false
        view.font = UnReadMessagesTipContentView.Const.textFont
        view.text = BundleI18n.LarkMessageCore.MyAI_IM_SummarizeUnread_Button
        view.textColor = UDColor.AISendicon.toColor(withSize: CGSize(
            width: BundleI18n.LarkMessageCore.MyAI_IM_SummarizeUnread_Button.lu.width(font: view.font),
            height: view.font.lineHeight))
        return view
    }()

    init() {
        super.init(frame: .zero)
        addSubview(iconView)
        addSubview(titleView)
        iconView.snp.makeConstraints({ make in
            make.left.equalToSuperview().offset(7.auto())
            make.centerY.equalToSuperview()
            make.width.height.equalTo(14.auto())
        })
        titleView.snp.makeConstraints({ make in
            make.left.equalTo(iconView.snp.right).offset(4.auto())
            make.centerY.equalToSuperview()
            make.right.equalTo(-8.auto())
        })
        updateCornerRadiusAndBackgroundColor()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func updateCornerRadiusAndBackgroundColor() {
        self.layer.cornerRadius = self.bounds.height / 2
        self.backgroundColor = UDColor.AIPrimaryFillSolid01.toColor(withSize: self.bounds.size)
    }
}
