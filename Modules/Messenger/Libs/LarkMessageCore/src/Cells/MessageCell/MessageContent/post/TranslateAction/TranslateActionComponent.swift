//
//  TranslateActionComponent.swift
//  LarkMessageCore
//
//  Created by Patrick on 2/8/2022.
//

import UIKit
import Foundation
import AsyncComponent
import LarkSearchCore
import EEFlexiable

public final class TranslateActionComponent<C: AsyncComponent.Context>: ASComponent<TranslateActionComponent.Props, EmptyState, UIView, C> {
    public final class Props: ASComponentProps {
        var needDisplayMoreButton: Bool = true
        private var unfairLock = os_unfair_lock_s()
        // 翻译反馈点击事件
        private var _translateFeedBackTapHandler: (() -> Void)?
        public var translateFeedBackTapHandler: (() -> Void)? {
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
        public var translateMoreActionTapHandler: ((UIView) -> Void)? {
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
    }
    /// 翻译反馈
    private lazy var translateFeedBackButton: RightButtonComponent<C> = {
        return ChatViewTemplate<C>.createTranslateFeedbackButton(action: { [weak self] in
            self?.props.translateFeedBackTapHandler?()
        }, style: feedBackStyle)
    }()
    /// 翻译反馈style
    private lazy var feedBackStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginTop = 6
        return style
    }()
    /// 中间的占位块
    private lazy var placeholderComponent: UIViewComponent<C> = {
        let style = ASComponentStyle()
        style.minWidth = 40
        return UIViewComponent<C>(props: .empty, style: style)
    }()
    /// 翻译更多
    private lazy var translateMoreActionButton: RightButtonComponent<C> = {
        return ChatViewTemplate<C>.createTranslateMoreActionButton(action: { [weak self] view in
            self?.props.translateMoreActionTapHandler?(view)
        }, style: moreActionStyle)
    }()
    /// 翻译更多 style
    private lazy var moreActionStyle: ASComponentStyle = {
        let style = ASComponentStyle()
        style.backgroundColor = .clear
        style.marginTop = 6
        return style
    }()
    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        super.init(props: props, style: style, context: context)
        setupProps(props)
    }

    private func setupProps(_ props: Props) {
        var subComponents: [ComponentWithSubContext<C, C>] = []
        if AIFeatureGating.translateFeedback.isEnabled {
            subComponents.append(translateFeedBackButton)
        }
        subComponents.append(placeholderComponent)
        if props.needDisplayMoreButton {
            subComponents.append(translateMoreActionButton)
        }
        setSubComponents(subComponents)
    }

    /// 此方法在该component的props属性被修改时调用，在这里我们可以根据最新的props
    /// 对界面进行调整
    public override func willReceiveProps(_ old: TranslateActionComponent<C>.Props, _ new: TranslateActionComponent<C>.Props) -> Bool {
        setupProps(new)
        return true
    }
}
