//
//  MinutesAudioPreviewHandler.swift
//  Minutes
//
//  Created by 陈乐辉 on 2023/11/14.
//

import Foundation
import EENavigator
import LarkNavigator
import MinutesNetwork

public final class MinutesAudioPreviewHandler: UserTypedRouterHandler {
    public static func compatibleMode() -> Bool { MinutesUserCompatibleSetting.compatibleMode }

    public func handle(_ body: MinutesAudioPreviewBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let params = MinutesShowParams(minutes: body.minutes, userResolver: userResolver, topic: body.topic)
        let vc = MinutesManager.shared.startMinutes(with: .preview, params: params)
        res.end(resource: vc)
    }
}
