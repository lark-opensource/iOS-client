//
//  DKNaviBarItem.swift
//  SpaceKit
//
//  Created by Weston Wu on 2020/6/16.
//

import SKUIKit
import RxSwift
import RxRelay
import EENavigator
import UniverseDesignBadge

enum DKNaviBarItemAction {
    case none
    case push(body: DKNaviBarBody)
    case present(body: DKNaviBarBody)
    case toast(content: String)
    case presentShareVC
    case presentSpaceMoreVC
    case presentFeedVC
    case presentSercetSetting
    case presentMyAIVC
}

protocol DKNaviBarItem {
    typealias Action = DKNaviBarItemAction
    var naviBarButtonID: SKNavigationBar.ButtonIdentifier { get }
    var badgeStyle: UDBadgeConfig? { get set }
    var itemIcon: UIImage { get }
    var isHighLighted: Bool { get }
    var itemVisable: BehaviorRelay<Bool> { get }
    var itemEnabled: BehaviorRelay<Bool> { get }
    var useOriginRenderedImage: Bool { get }
    func itemDidClicked() -> Action
}

extension DKNaviBarItem {
    
    var itemVisable: BehaviorRelay<Bool> { BehaviorRelay<Bool>(value: true) }
    var itemVisableChanged: Observable<Bool> { itemVisable.distinctUntilChanged() }

    var itemEnabled: BehaviorRelay<Bool> { BehaviorRelay<Bool>(value: true) }
    var itemEnabledChanged: Observable<Bool> { itemEnabled.distinctUntilChanged() }

    func itemDidClicked() -> Action { .none }
    var useOriginRenderedImage: Bool { return false }
}

struct DKStandardNaviBarItem: DKNaviBarItem {
    var naviBarButtonID: SKNavigationBar.ButtonIdentifier
    var itemIcon: UIImage
    var handler: () -> Action
    var badgeStyle: UDBadgeConfig?
    var isHighLighted: Bool
    
    func itemDidClicked() -> Action {
        return handler()
    }
    
    init(naviBarButtonID: SKNavigationBar.ButtonIdentifier, itemIcon: UIImage, isHighLighted: Bool = false, handler: @escaping () -> Action) {
        self.naviBarButtonID = naviBarButtonID
        self.itemIcon = itemIcon
        self.handler = handler
        self.isHighLighted = isHighLighted
    }
    
    init(naviBarButtonID: SKNavigationBar.ButtonIdentifier, itemIcon: UIImage, badgeStyle: UDBadgeConfig?, isHighLighted: Bool = false, handler: @escaping () -> Action) {
        self.naviBarButtonID = naviBarButtonID
        self.itemIcon = itemIcon
        self.handler = handler
        self.badgeStyle = badgeStyle
        self.isHighLighted = isHighLighted
    }
}
