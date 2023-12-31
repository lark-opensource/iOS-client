//  MinutesPodcastHandler.swift
//  ByteView
//
//  Created by panzaofen.cn on 2021/1/12.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import EENavigator
import LarkNavigator
import MinutesNetwork

public final class MinutesPodcastHandler: UserTypedRouterHandler {
    public static func compatibleMode() -> Bool { MinutesUserCompatibleSetting.compatibleMode }
    
    public func handle(_ body: MinutesPodcastBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let params = MinutesShowParams(minutes: body.minutes, userResolver: userResolver, player: body.player)
        let vc = MinutesManager.shared.enterDetailOrPodcast(with: params, forceToPodcast: true)
        res.end(resource: vc)
    }
}
