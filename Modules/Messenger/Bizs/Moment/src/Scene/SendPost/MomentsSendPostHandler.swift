//
//  MomentsSendPostHandler.swift
//  Moment
//
//  Created by bytedance on 2021/1/6.
//

import Foundation
import LarkUIKit
import EENavigator
import Swinject
import LarkAttachmentUploader
import LarkNavigator

final class MomentsSendPostHandler: UserTypedRouterHandler {

    static func compatibleMode() -> Bool { Moment.userScopeCompatibleMode }

    func handle(_ body: MomentsSendPostBody, req: EENavigator.Request, res: Response) throws {
        let attachmentUploader = try userResolver.resolve(assert: AttachmentUploader.self, argument: MomentSendPostViewModel.momentsSendPostDraftKey())
        let vm = MomentSendPostViewModel(userResolver: userResolver,
                                         source: body.source,
                                         selectedCategoryID: body.categoryID,
                                         selectedHashTagContent: body.hashTagContent,
                                         attachmentUploader: attachmentUploader)
        let vc = MomentSendPostViewController(userResolver: userResolver, viewModel: vm, sendPostCallBack: body.sendPostCallBack)
        let nav = LkNavigationController(rootViewController: vc)
        nav.modalPresentationStyle = .overCurrentContext
        if Display.pad {
            let container = PadLargeModalViewController()
            container.delegate = vc
            container.childVC = nav
            vc.viewWillClosed = { [weak container] in
                container?.clearBackgroundColor()
            }
            res.end(resource: container)
        } else {
            res.end(resource: nav)
        }
    }
}
