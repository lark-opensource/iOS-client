//
//  RouteHandler.swift
//  LarkShareContainer
//
//  Created by shizhengyu on 2020/12/29.
//

import Foundation
import EENavigator
import Swinject
import LarkSegmentedView
import LarkNavigator

final class LarkShareContainterHandler: UserTypedRouterHandler {

    func handle(_ body: LarkShareContainterBody, req: EENavigator.Request, res: Response) throws {
        assert(
            !body.tabMaterials.isEmpty,
            "tabMaterials must be at least one element"
        )
        assert(
            body.tabMaterials.map { $0.type() }.contains(body.selectedShareTab),
            "tabMaterials must contains selectedShareTab, please check"
        )

        let material = ShareMaterial(
            title: body.title,
            selectedShareTab: body.selectedShareTab,
            contentProvider: body.contentProvider,
            tabMaterials: body.tabMaterials
        )
        let subContainerViews = material.tabMaterials.reduce([]) { (result, tabMaterial)
            -> [JXSegmentedListContainerViewListDelegate] in
            var result = result
            switch tabMaterial {
            case .viaChat(let material):
                if let resource = dependency!.getShareViaChooseChatResource(by: material.material) {
                    result.append(resource)
                }
            case .viaQRCode(let material):
                let resource = ShareQRCodeSubController(
                    userResolver: userResolver,
                    circleAvatar: body.circleAvatar,
                    needFilterExternal: !material.canShareToExternal,
                    contentProvider: body.contentProvider,
                    lifeCycleObserver: body.lifeCycleObserver
                )
                result.append(resource)
            case .viaLink:
                let resource = ShareLinkSubController(
                    userResolver: userResolver,
                    circleAvatar: body.circleAvatar,
                    contentProvider: body.contentProvider,
                    lifeCycleObserver: body.lifeCycleObserver
                )
                result.append(resource)
            }
            return result
        }

        let dest = LarkShareContainerController(
            material: material,
            subContainerViews: subContainerViews,
            lifeCycleObserver: body.lifeCycleObserver
        )
        res.end(resource: dest)
    }
}
