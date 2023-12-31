//
//  WhiteBoardShareHandler.swift
//  ByteViewMod
//
//  Created by helijian on 2022/4/27.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import EENavigator
import LarkMessengerInterface
import RxSwift
import LarkUIKit
import LarkNavigator
import LarkModel

public struct WhiteBoardShareBody: PlainBody {
    public static let pattern = "//client/byteview/whiteboard/share"
    public let imagePaths: [String]
    public let nav: UINavigationController?
    public init(imagePaths: [String], nav: UINavigationController? = nil) {
        self.imagePaths = imagePaths
        self.nav = nav
    }
}

public final class WhiteBoardShareHandler: UserTypedRouterHandler {
    public func handle(_ body: WhiteBoardShareBody, req: EENavigator.Request, res: Response) {
        let mainFG = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_main_switch"))
        let subFG = userResolver.fg.staticFeatureGatingValue(with: .init(stringLiteral: "core.forward.component_refactor_first_stage"))
        if mainFG && subFG {
            openForwardComponent(body: body, req: req, res: res)
        } else {
            createForward(body: body, req: req, res: res)
        }
    }

    func openForwardComponent(body: WhiteBoardShareBody, req: EENavigator.Request, res: Response) {
        let chooseConfig = ForwardChooseConfig(enableSwitchSelectMode: false)
        let commonConfig = ForwardCommonConfig(enableCreateGroupChat: false,
                                               forwardTrackScene: .sendImage)
        let content = WhiteBoardShareContent(imagePaths: body.imagePaths, nav: body.nav)
        guard let forwardService = try? userResolver.resolve(assert: ForwardViewControllerService.self),
              let vc = forwardService.forwardComponentViewController(alertContent: content,
                                                                     commonConfig: commonConfig,
                                                                     targetConfig: ForwardTargetConfig(),
                                                                     additionNoteConfig: ForwardAdditionNoteConfig(),
                                                                     chooseConfig: chooseConfig) else {
            res.end(error: RouterError.invalidParameters("imagePaths"))
            return
        }
        let nvc = LkNavigationController(rootViewController: vc)
        nvc.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        res.end(resource: nvc)
    }

    func createForward(body: WhiteBoardShareBody, req: EENavigator.Request, res: Response) {
        let imagePaths = body.imagePaths
        let nav = body.nav
        let content = WhiteBoardShareContent(imagePaths: imagePaths, nav: nav)
        guard let forwardService = try? userResolver.resolve(assert: ForwardViewControllerService.self),
              let vc = forwardService.forwardViewController(with: content) else {
            res.end(error: RouterError.invalidParameters("imagePaths"))
            return
        }
        let nvc = LkNavigationController(rootViewController: vc)
        nvc.modalPresentationStyle = Display.pad ? .formSheet : .fullScreen
        res.end(resource: nvc)
    }
}
