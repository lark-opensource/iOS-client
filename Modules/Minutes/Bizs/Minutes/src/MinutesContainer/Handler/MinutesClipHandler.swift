//
//  MinutesClipHandler.swift
//  Minutes
//
//  Created by panzaofeng on 2022/5/14.
//

import Foundation
import EENavigator
import LarkNavigator
import MinutesNetwork

public final class MinutesClipHandler: UserTypedRouterHandler {
    public static func compatibleMode() -> Bool { MinutesUserCompatibleSetting.compatibleMode }

    public func handle(_ body: MinutesClipBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let params = MinutesShowParams(minutes: body.minutes, userResolver: userResolver, source: body.source, destination: body.destination)
        let vc = MinutesManager.shared.startMinutes(with: .clip, params: params)
        res.end(resource: vc)
    }
}
