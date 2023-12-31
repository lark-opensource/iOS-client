//
//  ShareContainerDependency.swift
//  LarkShareContainer
//
//  Created by shizhengyu on 2020/12/21.
//

import UIKit
import Foundation
import LarkSegmentedView
import LarkSnsShare

public var dependency: ShareContainerDependency?

public protocol ShareContainerDependency {
    func getShareViaChooseChatResource(
        by material: ShareViaChooseChatMaterial
    ) -> JXSegmentedListContainerViewListDelegate?

    func inappShareContext(
        with name: String,
        image: UIImage,
        needFilterExternal: Bool
    ) -> CustomShareContext

    func inappShareContext(
        with name: String,
        image: UIImage,
        needFilterExternal: Bool,
        shareResultsCallBack: (([(String, Bool)]?) -> Void)?
    ) -> CustomShareContext

    func inappShareContext(with text: String) -> CustomShareContext

    func inappShareContext(
        with text: String,
        shareResultsCallBack: (([(String, Bool)]?) -> Void)?
    ) -> CustomShareContext
}

extension ShareContainerDependency {
    public func setInputNavigationItem(
        with subPage: JXSegmentedListContainerViewListDelegate,
        item: UINavigationItem?
    ) {
        if Thread.isMainThread {
            let vc = subPage as? ChooseChatViewControllerAbility
            vc?.inputNavigationItem = item
        } else {
            assertionFailure("assert when not in mainThread")
            DispatchQueue.main.async {
                let vc = subPage as? ChooseChatViewControllerAbility
                vc?.inputNavigationItem = item
            }
        }
    }

    public func setCloseHandler(
        with subPage: JXSegmentedListContainerViewListDelegate,
        closeHandler: (() -> Void)?
    ) {
        let vc = subPage as? ChooseChatViewControllerAbility
        vc?.closeHandler = closeHandler
    }

}
