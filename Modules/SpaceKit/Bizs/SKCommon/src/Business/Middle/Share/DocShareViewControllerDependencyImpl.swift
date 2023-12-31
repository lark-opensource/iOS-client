//
//  DocShareViewControllerDependencyImpl.swift
//  SKCommon
//
//  Created by CJ on 2021/6/25.
//

import Foundation
import SpaceInterface
import EENavigator
import LarkUIKit

public final class DocShareViewControllerDependencyImpl: DocShareViewControllerDependency {
    public init() {}
    public func openDocShareViewController(body: DocShareViewControllerBody, from: UIViewController?) {
        guard let from = from else { return }
        Navigator.shared.present(body: body, from: from, animated: false)
    }
}

public final class DocShareViewControllerHandler: TypedRouterHandler<DocShareViewControllerBody> {
    public override func handle(_ body: DocShareViewControllerBody, req: EENavigator.Request, res: Response) {
        let shareEntity = SKShareEntity(objToken: body.token,
                                        type: body.type,
                                        title: body.title,
                                        isOwner: body.isOwner,
                                        ownerID: body.ownerId,
                                        displayName: body.ownerName,
                                        tenantID: body.tenantID,
                                        isFromPhoenix: body.isFromPhoenix,
                                        shareUrl: body.url,
                                        enableShareWithPassWord: body.enableShareWithPassWord,
                                        enableTransferOwner: body.enableTransferOwner,
                                        scPasteImmunity: body.scPasteImmunity)
        let vc = SKShareViewController(shareEntity,
                                       source: .other,
                                       isInVideoConference: body.isInVideoConference)
        let nav = LkNavigationController(rootViewController: vc)
        if let needPopover = body.needPopover, needPopover == true {
            vc.modalPresentationStyle = .popover
            nav.modalPresentationStyle = .popover
            nav.popoverPresentationController?.sourceView = body.sourceView
            nav.popoverPresentationController?.sourceRect = body.popoverSourceFrame ?? .zero
            nav.popoverPresentationController?.permittedArrowDirections = body.padPopDirection ?? .any
        } else {
            nav.modalPresentationStyle = .overFullScreen
        }
        res.end(resource: nav)
    }
}
