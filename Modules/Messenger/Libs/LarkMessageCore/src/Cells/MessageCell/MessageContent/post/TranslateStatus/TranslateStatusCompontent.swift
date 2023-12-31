//
//  TranslateStatusCompentent.swift
//  LarkMessageCore
//
//  Created by 李勇 on 2019/6/23.
//

import UIKit
import Foundation
import LarkModel
import AsyncComponent
import EEFlexiable
import Homeric
import LKCommonsTracker

/// LOTAnimationTapComponent统一样式
private struct TappedViewStyle {
    static var width: CSSValue { 16.auto() }
    static var height: CSSValue { 16.auto() }
}

public enum TranslateDisplayInfo {
    case display(backgroundColor: UIColor)
    case none
}

/// 翻译状态 因为LOTAnimationView不能动态的设置path，所以创建了两个LOTAnimationTapComponent
public final class TranslateStatusCompentent<C: AsyncComponent.Context>: ASComponent<TranslateStatusCompentent.Props, EmptyState, TappedView, C> {

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
    }

    private lazy var animationProps: TranslateAnimationTapComponent<C>.Props = {
        let props = TranslateAnimationTapComponent<C>.Props()
        props.play = false
        props.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        return props
    }()
    private lazy var animationStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        style.width = TappedViewStyle.width
        style.height = TappedViewStyle.height
        style.cornerRadius = CGFloat(TappedViewStyle.height.value / 2)
        return style
    }()
    private lazy var animationCompentent: TranslateAnimationTapComponent<C> = {
        return TranslateAnimationTapComponent<C>(props: animationProps, style: animationStyle)
    }()

    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        style.alignItems = .center
        style.alignContent = .stretch
        style.justifyContent = .center
        switch props.translateDisplayInfo {
        case .display(let backgroundColor):
            animationStyle.display = .flex
            animationStyle.backgroundColor = backgroundColor
        case .none:
            animationStyle.display = .none
        }

        animationProps.play = props.translateStatus == .translating ? true : false
        setSubComponents([self.animationCompentent])
    }

    public override func create(_ rect: CGRect) -> TappedView {
        let view = TappedView(frame: rect)
        view.initEvent()
        // newChat和Thread都在使用这个component，这里做个范围判断，增加热区。
        if rect.width < 20 || rect.height < 20 {
            view.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        }
        return view
    }

    public override func update(view: TappedView) {
        super.update(view: view)
        view.onTapped = { [weak self] _ in
            guard let `self` = self else { return }
            self.props.tapHandler?()
        }
    }

    public override func willReceiveProps(_ old: TranslateStatusCompentent<C>.Props, _ new: TranslateStatusCompentent<C>.Props) -> Bool {
        switch new.translateDisplayInfo {
        case .display(let backgroundColor):
            animationStyle.display = .flex
            animationStyle.backgroundColor = backgroundColor
        case .none:
            animationStyle.display = .none
        }
        if new.canShowTranslateIcon && new.translateStatus == .origin {
            Tracker.post(TeaEvent(Homeric.ASL_CROSSLANG_TRANSLATION_IM_VIEW, params: new.trackInfo))
        }
        animationProps.play = new.translateStatus == .translating ? true : false
        animationProps.tapHandler = new.tapHandler
        return true
    }
}
