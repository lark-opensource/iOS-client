//
//  ShareMeetingHandler.swift
//  ByteViewMessenger
//
//  Created by kiri on 2021/9/12.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import EENavigator
import LarkMessengerInterface
import RxSwift
import LarkUIKit
import UniverseDesignToast
import LarkContainer
import LarkNavigator

final class ShareMeetingHandler: UserTypedRouterHandler {
    let disposeBag = DisposeBag()
    private static let token = "LARK-PSDA-room_share_copy_meeting_content"

    func handle(_ body: ShareMeetingBody, req: EENavigator.Request, res: Response) {
        shareMeetContent(body: body, req: req, res: res)
    }

    func shareMeetContent(body: ShareMeetingBody, req: EENavigator.Request, res: Response) {
        if body.skipCopyLink {
            _ = self.createForward(body: body, req: req, res: res)
        } else {
            let service = ShareLinkService(userResolver: userResolver)
            service.getMeetingContent(meetingId: body.meetingId).observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] content in
                    guard let self = self else {
                        res.end(error: RouterError.invalidParameters("conference_id"))
                        return
                    }
                    let vc = self.createForward(body: body, content: content, req: req, res: res)
                    if ClipboardSncWrapper.set(text: content, with: Self.token), let hudOn = vc?.view {
                        // room 扫码分享时会同时操作剪切板
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25, execute: {
                            UDToast.showTips(with: I18n.View_M_LinkCopied, on: hudOn)
                        })
                    }
                }, onError: { _ in
                    res.end(error: RouterError.invalidParameters("conference_id"))
                }).disposed(by: disposeBag)
            res.wait()
        }
    }

    func createForward(body: ShareMeetingBody, content: String = "", req: EENavigator.Request, res: Response) -> UIViewController? {
        let content = ShareMeetingAlertContent(meetingId: body.meetingId, content: content, style: body.style, source: body.source, canShare: body.canShare)
        guard let forwardService = try? userResolver.resolve(assert: ForwardViewControllerService.self),
              let vc = forwardService.forwardViewController(with: content) else {
            res.end(error: RouterError.invalidParameters("conference_id"))
            return nil
        }
        let nvc = LkNavigationController(rootViewController: vc)
        if body.style == .link {
            nvc.modalPresentationStyle = .pageSheet
        } else {
            nvc.modalPresentationStyle = Display.pad ? .formSheet : .pageSheet
        }
        res.end(resource: nvc)
        return nvc
    }
}
