//
//  SMBGuideHandler.swift
//  LarkContact
//
//  Created by bytedance on 2022/4/11.
//

import Foundation
import EENavigator
import Swinject
import AppContainer
import LarkOpenPluginManager
import LarkWebViewContainer
import ECOProbe
import LarkNavigator

final class SMBGuideHandler: UserTypedRouterHandler {

    func handle(_ body: SMBGuideBody, req: EENavigator.Request, res: Response) throws {
        let guideViewController = SMBGuideViewController(url: body.url, isFullScreen: body.isFullScreen)
        res.end(resource: guideViewController)
    }
}
