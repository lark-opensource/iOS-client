//
//  TranslateButtonComponent.swift
//  LarkMessageCore
//
//  Created by Patrick on 11/8/2022.
//

import UIKit
import Foundation
import LarkModel
import AsyncComponent
import EEFlexiable
import LarkInteraction
import Homeric
import LKCommonsTracker

private struct TappedViewStyle {
    static var width: CSSValue { 16.auto() }
    static var height: CSSValue { 16.auto() }
}

public final class TranslateButtonComponent<C: AsyncComponent.Context>: ASComponent<TranslateButtonComponent.Props, EmptyState, TappedView, C> {

    public enum ButtonStatus {
        case normal, disable, loading
    }

    public final class Props: ASComponentProps {
        private var unfairLock = os_unfair_lock_s()
        public var trackInfo: [String: Any] {
            get {
                os_unfair_lock_lock(&unfairLock)
                defer {
                    os_unfair_lock_unlock(&unfairLock)
                }
                return _trackInfo
            }
            set {
                os_unfair_lock_lock(&unfairLock)
                _trackInfo = newValue
                os_unfair_lock_unlock(&unfairLock)
            }
        }
        private var _trackInfo: [String: Any] = [:]
        public var canShowTranslateIcon: Bool = false
        public var translateStatus: Message.TranslateState = .origin
        public var translateDisplayInfo: TranslateDisplayInfo = .display(backgroundColor: .clear)
        public var text: String? = BundleI18n.LarkMessageCore.Lark_ASLTranslation_IMOriginalText_TraslateIcon_Hover
        public var font: UIFont = .systemFont(ofSize: 14)
        public var iconAndLabelSpacing: CGFloat = 4
        public var tapHandler: (() -> Void)? {
            get {
                os_unfair_lock_lock(&unfairLock)
                defer {
                    os_unfair_lock_unlock(&unfairLock)
                }
                return _tapHandler
            }
            set {
                os_unfair_lock_lock(&unfairLock)
                _tapHandler = newValue
                os_unfair_lock_unlock(&unfairLock)
            }
        }
        private var _tapHandler: (() -> Void)?
        public var buttonStatus: ButtonStatus = .normal
    }

    private lazy var animationProps: TranslateAnimationTapComponent<C>.Props = {
        let props = TranslateAnimationTapComponent<C>.Props()
        props.play = false
        return props
    }()
    private lazy var animationStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        style.width = TappedViewStyle.width
        style.height = TappedViewStyle.height
        style.cornerRadius = CGFloat(TappedViewStyle.height.value / 2)
        return style
    }()
    private lazy var animationCompontent: TranslateAnimationTapComponent<C> = {
        return TranslateAnimationTapComponent<C>(props: animationProps, style: animationStyle)
    }()

    private lazy var labelProps: UILabelComponentProps = {
        let props = UILabelComponentProps()
        props.textAlignment = .right
        props.font = UIFont.systemFont(ofSize: 14)
        props.textColor = UIColor.ud.textLinkNormal
        return props
    }()

    private lazy var labelStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        return style
    }()

    private lazy var label: UILabelComponent<C> = {
        return UILabelComponent<C>(props: labelProps, style: labelStyle)
    }()

    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignItems = .center
        style.alignContent = .stretch
        style.justifyContent = .center
        setSubComponents([animationCompontent, label])
        setupProps(props)
    }

    private func setupProps(_ props: Props) {
        switch props.translateDisplayInfo {
        case .display(let backgroundColor):
            animationStyle.backgroundColor = backgroundColor
            animationStyle.display = .flex
        case .none:
            animationStyle.display = .none
        }
        switch props.buttonStatus {
        case .normal:
            labelProps.textColor = .ud.textLinkNormal
        case .disable:
            labelProps.textColor = .ud.textLinkNormal
        case .loading:
            labelProps.textColor = .ud.textLinkNormal
        }

        if props.canShowTranslateIcon && props.translateStatus == .origin {
            Tracker.post(TeaEvent(Homeric.ASL_CROSSLANG_TRANSLATION_IM_VIEW, params: props.trackInfo))
        }

        animationProps.play = props.translateStatus == .translating ? true : false

        labelProps.text = props.text
        labelProps.font = props.font
        labelStyle.marginLeft = CSSValue(cgfloat: props.iconAndLabelSpacing)
    }

    public override func create(_ rect: CGRect) -> TappedView {
        let view = TappedView(frame: rect)
        if #available(iOS 13.4, *) {
            let pointer = PointerInteraction(
                style: .init(effect: .hover(preferredTintMode: .overlay, prefersShadow: true, prefersScaledContent: true))
            )
            view.addLKInteraction(pointer)
        }
        return view
    }

    public override func update(view: TappedView) {
        super.update(view: view)

        if let tapped = self.props.tapHandler {
            view.initEvent(needLongPress: false)
            view.onTapped = { [weak self] _ in
                guard let `self` = self else { return }
                self.animationCompontent.play()
                var trackInfo = self.props.trackInfo
                trackInfo["click"] = "translate"
                Tracker.post(TeaEvent(Homeric.ASL_CROSSLANG_TRANSLATION_IM_CLICK, params: trackInfo))
                tapped()
            }
        } else {
            view.deinitEvent()
        }
    }

    public override func willReceiveProps(_ old: TranslateButtonComponent<C>.Props, _ new: TranslateButtonComponent<C>.Props) -> Bool {
        setupProps(new)
        return true
    }

}
