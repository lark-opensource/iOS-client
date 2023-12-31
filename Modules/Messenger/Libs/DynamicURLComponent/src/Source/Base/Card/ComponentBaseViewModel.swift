//
//  ComponentBaseViewModel.swift
//  DynamicURLComponent
//
//  Created by 袁平 on 2021/8/18.
//

import Foundation
import RustPB
import LarkModel
import LarkContainer
import TangramComponent

open class ComponentBaseViewModel: UserResolverWrapper {
    public var userResolver: UserResolver {
        return dependency.userResolver
    }
    private var _children: [ComponentBaseViewModel]
    public var children: [ComponentBaseViewModel] {
        get { safeRead { _children } }
        set { safeWrite { _children = newValue } }
    }
    // 卡片自身可提供的通用能力
    public let ability: ComponentAbility
    // 需要外部提供的依赖
    public let dependency: URLCardDependency
    public internal(set) var entity: URLPreviewEntity

    open var component: Component {
        assertionFailure("must be overrided")
        return Component()
    }

    public init(entity: URLPreviewEntity,
                children: [ComponentBaseViewModel],
                ability: ComponentAbility,
                dependency: URLCardDependency) {
        self.entity = entity
        self._children = children
        self.ability = ability
        self.dependency = dependency
    }

    public func safeRead<T>(_ read: () -> T) -> T {
        return read()
    }

    public func safeWrite(_ write: () -> Void) {
        write()
    }

    /// 中转一层，防止重写导致子元素willDisplay不调用
    public final func innerWillDisplay() {
        children.forEach({ $0.innerWillDisplay() })
        self.willDisplay()
    }

    public final func innerDidEndDisplay() {
        children.forEach({ $0.innerDidEndDisplay() })
        self.didEndDisplay()
    }

    public final func innerOnResize() {
        children.forEach({ $0.innerOnResize() })
        self.onResize()
    }

    /// Cell将要出现的时候
    open func willDisplay() {}

    /// Cell不再显示的时候
    open func didEndDisplay() {}

    /// Size发生变化
    open func onResize() {}
}
