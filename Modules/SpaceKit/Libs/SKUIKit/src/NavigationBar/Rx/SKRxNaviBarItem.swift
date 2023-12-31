//
//  SKRxNaviBarItem.swift
//  SKUIKit
//
//  Created by Weston Wu on 2021/12/9.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa

public protocol SKRxNaviBarItem {
    var naviBarButtonID: SKNavigationBar.ButtonIdentifier { get }
    var itemIcon: BehaviorRelay<UIImage> { get }
    var itemVisable: BehaviorRelay<Bool> { get }
    var itemEnabled: BehaviorRelay<Bool> { get }
    func itemDidClicked(sourceView: UIView)
}

public extension SKRxNaviBarItem {
    var itemVisableChanged: Observable<Bool> {
        itemVisable.distinctUntilChanged().skip(1)
    }

    var itemEnabledChanged: Observable<Bool> {
        itemEnabled.distinctUntilChanged().skip(1)
    }
}

public struct SKCommonRxNaviBarItem: SKRxNaviBarItem {
    public let naviBarButtonID: SKNavigationBar.ButtonIdentifier
    public let itemIcon: BehaviorRelay<UIImage>
    public let itemVisable: BehaviorRelay<Bool>
    public let itemEnabled: BehaviorRelay<Bool>
    public let clickHandler: (UIView) -> Void

    public init(id: SKNavigationBar.ButtonIdentifier,
                icon: BehaviorRelay<UIImage>,
                visable: BehaviorRelay<Bool>,
                enabled: BehaviorRelay<Bool>,
                clickHandler: @escaping (UIView) -> Void) {
        naviBarButtonID = id
        itemIcon = icon
        itemVisable = visable
        itemEnabled = enabled
        self.clickHandler = clickHandler
    }

    public func itemDidClicked(sourceView: UIView) {
        clickHandler(sourceView)
    }
}

extension SKCommonRxNaviBarItem {
    // 普通的按钮
    public static func standard(id: SKNavigationBar.ButtonIdentifier, icon: UIImage, clickHandler: @escaping (UIView) -> Void) -> Self {
        return Self(id: id,
                    icon: BehaviorRelay(value: icon),
                    visable: BehaviorRelay(value: true),
                    enabled: BehaviorRelay(value: true),
                    clickHandler: clickHandler)
    }
}
