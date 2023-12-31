//
//  StatusComponent.swift
//  LarkMessageCore
//
//  Created by Meng on 2019/4/2.
//

import UIKit
import Foundation
import AsyncComponent
import EEFlexiable
import LarkMessageBase

public struct StatusComponentLayoutConstraints {
    public static let statusSize = CGSize(width: 18.0, height: 18.0)
    public static let margin: CGFloat = 6.0
}

public protocol StatusComponentContext: ComponentContext {

}

public struct StatusComponentConstant {
    public static let readStatusButtonKey = "readStatusButtonKey"
}

/// 消息状态Component
///
/// 隐藏了localstatus和readstatus的概念，只通过MessageStatus关心最终消息的状态
public final class StatusComponent<C: StatusComponentContext>: ASComponent<StatusComponent.Props, EmptyState, UIView, C> {

    public final class Props: ASComponentProps {

        public var messageStatus: MessageStatus = .none

        /// crash fix: http://t.wtturl.cn/e8aQm6E/
        private var _didTappedLocalStatus = Atomic<LocalStatusComponent<C>.Props.TapHandler>()
        public var didTappedLocalStatus: LocalStatusComponent<C>.Props.TapHandler? {
            get { return _didTappedLocalStatus.wrappedValue }
            set { _didTappedLocalStatus.wrappedValue = newValue }
        }

        /// crash fix: http://t.wtturl.cn/e8aQm6E/
        private var _didTappedReadStatus = Atomic<(_ sender: UIButton) -> Void>()
        public var didTappedReadStatus: ((_ sender: UIButton) -> Void)? {
            get { return _didTappedReadStatus.wrappedValue }
            set { _didTappedReadStatus.wrappedValue = newValue }
        }

        public var ignoreLocalStatus: Bool = false

        public var ignoreReadStatus: Bool = false

        public var marginLeft: CGFloat = StatusComponentLayoutConstraints.margin

        public var marginRight: CGFloat = 0.0

    }

    /// 消息状态显示样式
    ///
    /// - none: 全部隐藏
    /// - success: 成功样式：percent(已读进度)
    /// - failed: 显示失败
    /// - loading: 显示loading
    public enum MessageStatus {

        case none

        case success(percent: CGFloat)

        case failed

        case loading

    }

    private lazy var readStatusComponent: ReadStatusComponent<C> = {
        let style = ASComponentStyle()
        style.width = CSSValue(cgfloat: StatusComponentLayoutConstraints.statusSize.width)
        style.height = CSSValue(cgfloat: StatusComponentLayoutConstraints.statusSize.height)

        let readProps = ReadStatusComponent<C>.Props()
        readProps.tapHandler = { [weak self] in
            self?.props.didTappedReadStatus?($0)
        }
        readProps.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        readProps.key = StatusComponentConstant.readStatusButtonKey

        return ReadStatusComponent<C>(props: readProps, style: style)
    }()

    private lazy var localStatusComponent: LocalStatusComponent<C> = {
        let style = ASComponentStyle()
        style.width = CSSValue(cgfloat: StatusComponentLayoutConstraints.statusSize.width)
        style.height = CSSValue(cgfloat: StatusComponentLayoutConstraints.statusSize.height)

        let localProps = LocalStatusComponent<C>.Props()
        localProps.tapHandler = { [weak self] in
            self?.props.didTappedLocalStatus?($0, $1)
        }
        localProps.status = .normal

        return LocalStatusComponent<C>(props: localProps, style: style)
    }()

    public override init(props: Props, style: ASComponentStyle, context: C? = nil) {
        style.flexWrap = .wrap
        style.flexDirection = .columnReverse
        style.alignItems = .flexStart
        style.flexGrow = 0
        style.flexShrink = 0
        super.init(props: props, style: style, context: context)
        _updateUI(props: props)
        setSubComponents([localStatusComponent, readStatusComponent])
    }

    public override func willReceiveProps(_ old: StatusComponent<C>.Props, _ new: StatusComponent<C>.Props) -> Bool {
        _updateUI(props: new)
        return true
    }

    private func _updateUI(props: Props) {
        switch props.messageStatus {
        case .none:
            localStatusComponent.style.display = .none
            readStatusComponent.style.display = .none
        case .success(let percent):
            localStatusComponent.style.display = .none
            readStatusComponent.style.display = .flex
            localStatusComponent.props.status = .normal
            readStatusComponent.props.percent = percent
        case .failed:
            localStatusComponent.style.display = .flex
            readStatusComponent.style.display = .none
            localStatusComponent.props.status = .failed
        case .loading:
            localStatusComponent.style.display = .flex
            readStatusComponent.style.display = .none
            localStatusComponent.props.status = .loading
        }

        if props.ignoreLocalStatus {
            localStatusComponent.style.display = .none
        }

        if props.ignoreReadStatus {
            readStatusComponent.style.display = .none
        }

        localStatusComponent.props.tapHandler = { [weak self] in
            self?.props.didTappedLocalStatus?($0, $1)
        }
        readStatusComponent.props.tapHandler = { [weak self] in
            self?.props.didTappedReadStatus?($0)
        }
        localStatusComponent.style.marginLeft = CSSValue(cgfloat: props.marginLeft)
        localStatusComponent.style.marginRight = CSSValue(cgfloat: props.marginRight)
        readStatusComponent.style.marginLeft = CSSValue(cgfloat: props.marginLeft)
        readStatusComponent.style.marginRight = CSSValue(cgfloat: props.marginRight)
    }

}
