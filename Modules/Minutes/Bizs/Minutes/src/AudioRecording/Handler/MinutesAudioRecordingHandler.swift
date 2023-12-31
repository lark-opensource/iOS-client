//
//  MinutesAudioRecordingHandler.swift
//  Minutes
//
//  Created by 陈乐辉 on 2023/11/14.
//

import Foundation
import EENavigator
import LarkNavigator
import MinutesNetwork

public final class MinutesAudioRecordingHandler: UserTypedRouterHandler {
    public static func compatibleMode() -> Bool { MinutesUserCompatibleSetting.compatibleMode }

    public func handle(_ body: MinutesAudioRecordingBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let params = MinutesShowParams(minutes: body.minutes, userResolver: userResolver, recordingSource: body.source)
        let vc = MinutesManager.shared.startMinutes(with: .record, params: params)
        res.end(resource: vc)
    }
}
