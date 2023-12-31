//
//  AudioViewWrapperComponent.swift
//  LarkMessageCore
//
//  Created by KT on 2019/6/10.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageBase
import LarkModel
import LarkAudio
import RichLabel
import LarkMessengerInterface
import LarkSetting
import LarkUIKit
import UniverseDesignIcon
import RustPB
import LarkSearchCore

/// component 最小依赖
public protocol AudioViewWrapperComponentContext: ComponentContext, ColorConfigContext {}

/// Component Key
struct AudioViewWrapperComponentConstant {
    static let audioViewKey = "AudioViewWrapperComponent_AudioViewKey"
}

/// Action
public protocol AudioViewActionDelegate: AnyObject {
    func audioViewPanAction(_ audioView: AudioView, _ state: AudioView.PanState, _ progress: TimeInterval)
    func audioViewTapAction()
}

/// Props
final public class AudioViewWrapperComponentProps: ASComponentProps {
    public weak var delegate: AudioViewActionDelegate?
    public var message: Message?
    public var minLineWidth: CGFloat = 0
    public var duration: TimeInterval = 0
    public var showUnReadDot: Bool = false
    public var isDotInside: Bool = false
    public var audioWaves: [AudioProcessWave]?
    public var playingState: AudioPlayMediatorStatus?
    public var hideVoice2Text: Bool = true
    public var originText: String = ""
    public var text: String = ""
    public var isMe: Bool = false
    public var isAudioWithText: Bool = false
    public var audioToTextEnable: Bool = false
    public var isLoadingFinished: Bool = false
    public var style: AudioView.Style = .light
    public var audioViewInset: UIEdgeInsets = AudioView.defaultInset
    public var disableMarginWhenAudioToText: Bool = false
    public var hasBoder: Bool = false
    public var boderWidth: CGFloat?
    public var hasCorner: Bool = false
    public var dotSize = CGSize(width: 6, height: 6)
    public var dotMargin: CGFloat = 3
    public var contentPreferMaxWidth: CGFloat = 0
    public var isFileDeleted: Bool = false

    public var colorConfig: AudioView.ColorConfig?
    public var backgroundColor: UIColor?
    public var convertStateButtonBackground: UIColor = UIColor.ud.N900.withAlphaComponent(0.4)
    public var convertStateColor: UIColor = UIColor.ud.textCaption
    public var audioWithTextTextColor: UIColor = UIColor.ud.N900
    public var audioTextColor: UIColor = UIColor.ud.textTitle

    /// 翻译相关
    public var displayRule: RustPB.Basic_V1_DisplayRule = .noTranslation
    public var translateText: String = ""
    // 翻译反馈点击事件
    private var unfairLock = os_unfair_lock_s()
    private var _translateFeedBackTapHandler: (() -> Void)?
    var translateFeedBackTapHandler: (() -> Void)? {
        get {
            os_unfair_lock_lock(&unfairLock)
            defer {
                os_unfair_lock_unlock(&unfairLock)
            }
            return _translateFeedBackTapHandler
        }
        set {
            os_unfair_lock_lock(&unfairLock)
            _translateFeedBackTapHandler = newValue
            os_unfair_lock_unlock(&unfairLock)
        }
    }
    private var _translateMoreActionTapHandler: ((UIView) -> Void)?
    var translateMoreActionTapHandler: ((UIView) -> Void)? {
        get {
            os_unfair_lock_lock(&unfairLock)
            defer {
                os_unfair_lock_unlock(&unfairLock)
            }
            return _translateMoreActionTapHandler
        }
        set {
            os_unfair_lock_lock(&unfairLock)
            _translateMoreActionTapHandler = newValue
            os_unfair_lock_unlock(&unfairLock)
        }
    }
    public var lineColor: UIColor = .clear
}

public final class AudioViewWrapperComponent<C: AudioViewWrapperComponentContext>: ASComponent<AudioViewWrapperComponentProps, EmptyState, UIView, C> {

    enum Constants {
        static var hMargin: CGFloat { 12 }
        static var autoAudioFont: UIFont { UIFont.ud.body0 }
        static var manualAudioFont: UIFont { UIFont.ud.title4 }
        static var transFont: UIFont { UIFont.ud.caption1 }
        static var transIconSize: CGSize { .square(transFont.pointSize) }
    }

    public override init(props: AudioViewWrapperComponentProps, style: ASComponentStyle, context: C? = nil) {
        // 翻译 action props
        let translateActionProps = TranslateActionComponent<C>.Props()
        // 翻译 action style
        let translateActionStyle = ASComponentStyle()
        // 让译文默认隐藏，避免跳动
        translateActionStyle.display = .none
        translateActionStyle.marginLeft = 12
        translateActionStyle.marginRight = 12
        translateActionStyle.marginTop = 4
        translateActionStyle.justifyContent = .spaceBetween
        self.translateActionComponent = TranslateActionComponent<C>(props: translateActionProps, style: translateActionStyle)
        super.init(props: props, style: style, context: context)
        style.flexDirection = .row
        style.alignItems = .flexStart
        style.backgroundColor = .clear
        updateProps(props: props)
        footer.setSubComponents([recognitionIconView, recognitionLabel])
        container.setSubComponents([originPostText, audioView])
        setSubComponents([container, dot])
    }

    private lazy var container: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .column
        style.cornerRadius = 10
        return UIViewComponent<C>(props: ASComponentProps(), style: style)
    }()

    private lazy var originPostProps: RichLabelProps = {
        let props = RichLabelProps()
        props.numberOfLines = 0
        props.font = Constants.autoAudioFont
        props.backgroundColor = UIColor.clear
        return props
    }()

    private lazy var originPostStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginLeft = 12
        style.marginRight = 12
        return style
    }()

    private lazy var originPostText: RichLabelComponent<C> = {
        return RichLabelComponent<C>(props: originPostProps, style: originPostStyle)
    }()

    private lazy var translatePostProps: RichLabelProps = {
        let props = RichLabelProps()
        props.numberOfLines = 0
        props.font = Constants.autoAudioFont
        props.backgroundColor = UIColor.clear
        return props
    }()

    private lazy var translatePostStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginLeft = 12
        style.marginRight = 12
        style.marginTop = 8
        return style
    }()

    private lazy var translatePostText: RichLabelComponent<C> = {
        return RichLabelComponent<C>(props: translatePostProps, style: translatePostStyle)
    }()

    /// 分割Component：line
    private lazy var centerLineComponent: UIViewComponent<C> = {
        return UIViewComponent<C>(props: .empty, style: centerStyle)
    }()

    /// 分割style
    private lazy var centerStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        style.flexGrow = 1
        style.height = CSSValue(cgfloat: 1)
        style.marginLeft = 12
        style.marginRight = 12
        style.marginTop = 12
        return style
    }()

    /// 翻译 action component
    private let translateActionComponent: TranslateActionComponent<C>

    private lazy var audioView: AudioViewComponent<C> = {
        let props = AudioViewWrapperComponentProps()
        props.key = AudioViewWrapperComponentConstant.audioViewKey
        let style = ASComponentStyle()
        style.flexGrow = 0
        style.flexShrink = 0
        return AudioViewComponent<C>(props: props, style: style)
    }()

    private lazy var dot: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.backgroundColor = UIColor.ud.colorfulRed
        style.width = CSSValue(cgfloat: props.dotSize.width)
        style.height = CSSValue(cgfloat: props.dotSize.height)
        style.cornerRadius = props.dotSize.height / 2
        style.position = .absolute
        style.top = 0
        return UIViewComponent<C>(props: ASComponentProps(), style: style)
    }()

    private lazy var footer: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.flexDirection = .row
        style.justifyContent = .flexStart
        style.alignItems = .center
        style.marginTop = 14
        style.marginBottom = 12
        style.marginLeft = 12
        style.marginRight = 12
        return UIViewComponent<C>(props: ASComponentProps(), style: style)
    }()

    private lazy var recognitionIconView: UIViewComponent<C> = {
        let style = ASComponentStyle()
        let size = 12.auto()
        style.width = CSSValue(cgfloat: size)
        style.height = CSSValue(cgfloat: size)
        style.cornerRadius = size / 2
        style.backgroundColor = self.props.convertStateButtonBackground
        style.alignItems = .center
        style.justifyContent = .center

        let imageProps = UIImageViewComponentProps()
        let iconSize: CGFloat = 10.auto()
        imageProps.setImage = { $0.set(image: UDIcon.getIconByKey(.checkOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: iconSize, height: iconSize))) }
        let imageStyle = ASComponentStyle()
        imageStyle.width = CSSValue(cgfloat: iconSize)
        imageStyle.height = CSSValue(cgfloat: iconSize)
        let imageComponent = UIImageViewComponent<C>(props: imageProps, style: imageStyle)
        let viewComponent = UIViewComponent<C>(props: .empty, style: style)
        viewComponent.setSubComponents([imageComponent])
        return viewComponent
    }()

    private lazy var recognitionLabel: UILabelComponent<C> = {
        let props = UILabelComponentProps()
        props.numberOfLines = 1
        props.font = Constants.transFont
        props.text = BundleI18n.LarkMessageCore.Lark_Chat_AudioConvertToTextSuccess
        props.textColor = self.props.convertStateColor
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginLeft = 4
        return UILabelComponent<C>(props: props, style: style)
    }()

    public override func willReceiveProps(_ old: AudioViewWrapperComponentProps,
                                          _ new: AudioViewWrapperComponentProps) -> Bool {
        updateProps(props: new)
        return true
    }

    private func updateProps(props: AudioViewWrapperComponentProps) {
        dot.style.display = props.showUnReadDot ? .flex : .none
        // 红点绝对布局，在气泡右侧
        dot.style.right = (props.showUnReadDot && props.isDotInside)
            ? 0
            : CSSValue(cgfloat: -props.dotMargin - props.dotSize.width)

        recognitionLabel.props.textColor = props.convertStateColor
        recognitionIconView.style.backgroundColor = props.convertStateButtonBackground
        // UI要求在详情页中他人气泡不加边框，所以讲两个属性分开
        // https://bytedance.feishu.cn/space/bitable/bascn4SxXm9NkYXAA1lgEDaKnyc?amp=&table=tblxj6alpv&view=vewgWRjztC
        if props.hasBoder {
            container.style.border = Border(BorderEdge(width: props.boderWidth ?? 1, color: UIColor.ud.N300, style: .solid))
        } else {
            container.style.border = nil
        }
        if props.hasCorner {
            container.style.cornerRadius = 10
        } else {
            container.style.cornerRadius = 0
        }

        // 红点在气泡内侧，通过marginRight撑开
        container.style.marginRight = (props.showUnReadDot && props.isDotInside)
            ? CSSValue(cgfloat: props.dotMargin + props.dotSize.width)
            : 0

        // 自动转文字，转化完成且有文字, 才会出现
        footer.style.display = (
            props.audioToTextEnable &&
            !props.isAudioWithText &&
            props.isLoadingFinished &&
            !props.text.isEmpty
        ) ? .flex : .none

        if props.isAudioWithText {
            if AIFeatureGating.audioMessageTranslation.isEnabled {
                container.setSubComponents([originPostText, centerLineComponent, translatePostText, translateActionComponent, audioView, footer])
            } else {
                container.setSubComponents([originPostText, audioView, footer])
            }
            originPostText.style.marginTop = 12
            originPostText.style.marginBottom = 0
        } else {
            if AIFeatureGating.audioMessageTranslation.isEnabled {
                container.setSubComponents([audioView, originPostText, centerLineComponent, translatePostText, translateActionComponent, footer])
            } else {
                container.setSubComponents([audioView, originPostText, footer])
            }
            originPostText.style.marginTop = 0
            if footer.style.display == .flex {
                originPostText.style.marginBottom = 0
            } else {
                originPostText.style.marginBottom = 12
            }
        }

        var showOrigin: Bool = false
        var showTranslate: Bool = false
        var originIsEmpty: Bool = true

        // fg 开 且 显示文字 且发送成功
        if props.audioToTextEnable &&
            !props.hideVoice2Text {
            // raw text
            let richText = NSMutableAttributedString(string: props.originText)
            let textColor = props.isAudioWithText ? props.audioWithTextTextColor : props.audioTextColor
            let textFont = props.isAudioWithText ? Constants.autoAudioFont : Constants.manualAudioFont
            richText.addAttributes(
                [
                    .font: textFont,
                    .foregroundColor: textColor
                ],
                range: NSRange(location: 0, length: richText.length)
            )

            // 发送成功 且处于loading 状态时 显示loading icon
            if !props.isLoadingFinished,
                let message = props.message,
                message.localStatus == .success {
                let attachment = LKAsyncAttachment(
                    viewProvider: {
                        let loadingView = AudioRecognizeLoadingView(text: "")
                        loadingView.bounds = loadingView.attachmentBounds
                        loadingView.startAnimationIfNeeded()
                        return loadingView
                    },
                    size: CGSize(width: 20, height: 20)
                )
                attachment.fontDescent = originPostProps.font.descender
                attachment.fontAscent = originPostProps.font.ascender
                richText.append(NSAttributedString(string: LKLabelAttachmentPlaceHolderStr,
                                                   attributes: [LKAttachmentAttributeName: attachment]))
            }
            originPostProps.attributedText = richText

            // 最终显示文案长度不为0 则显示 label
            originIsEmpty = props.text.isEmpty
        }

        if AIFeatureGating.audioMessageTranslation.isEnabled {
            switch props.displayRule {
            case .onlyTranslation, .withOriginal:
                showOrigin = !originIsEmpty
                showTranslate = !props.text.isEmpty
            case .unknownRule, .noTranslation:
                showOrigin = !props.hideVoice2Text && !originIsEmpty
                showTranslate = false
            @unknown default:
                assertionFailure("unknown display rule")
                break
            }
            translateActionComponent.props.translateFeedBackTapHandler = props.translateFeedBackTapHandler
            translateActionComponent.props.translateMoreActionTapHandler = props.translateMoreActionTapHandler
            centerStyle.backgroundColor = props.lineColor
            let richText = NSMutableAttributedString(string: props.translateText)
            let textColor = props.isAudioWithText ? props.audioWithTextTextColor : props.audioTextColor
            let textFont = props.isAudioWithText ? Constants.autoAudioFont : Constants.manualAudioFont
            richText.addAttributes(
                [
                    .font: textFont,
                    .foregroundColor: textColor
                ],
                range: NSRange(location: 0, length: richText.length)
            )
            translatePostProps.attributedText = richText
        } else {
            showOrigin = !originIsEmpty
        }

        // origin 展示判断
        originPostStyle.display = showOrigin ? .flex : .none

        if showTranslate {
            translatePostStyle.display = .flex
            translateActionComponent.style.display = .flex
            centerStyle.display = .flex
        } else {
            translatePostStyle.display = .none
            translateActionComponent.style.display = .none
            centerStyle.display = .none
        }

        audioView.props = props
        // container
        if let color = props.backgroundColor {
            container.style.backgroundColor = color
        } else {
            switch props.style {
            case .light:
                container.style.backgroundColor = UIColor.ud.primaryOnPrimaryFill
            case .dark:
                container.style.backgroundColor = UIColor.ud.N200
            case .blue:
                container.style.backgroundColor = UIColor.ud.colorfulBlue.withAlphaComponent(0.1)
            case .clearLight:
                container.style.backgroundColor = UIColor.clear
            case .clearDark:
                container.style.backgroundColor = UIColor.clear
            case .clearBlue:
                container.style.backgroundColor = UIColor.clear
            @unknown default:
                assert(false, "new value")
                container.style.backgroundColor = UIColor.clear
            }
        }
    }
}
