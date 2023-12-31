//  MinutesDetailHandler.swift
//  ByteView
//
//  Created by panzaofen.cn on 2021/1/12.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import EENavigator
import LarkNavigator
import MinutesNetwork

public enum MinutesUserCompatibleSetting {
    public static var compatibleMode: Bool { false }
}

public final class MinutesDetailHandler: UserTypedRouterHandler {
    public static func compatibleMode() -> Bool { MinutesUserCompatibleSetting.compatibleMode }

    public func handle(_ body: MinutesDetailBody, req: EENavigator.Request, res: EENavigator.Response) throws {
        let params = MinutesShowParams(minutes: body.minutes, userResolver: userResolver, source: body.source, destination: body.destination)
        let vc = MinutesManager.shared.enterDetailOrPodcast(with: params)
        res.end(resource: vc)
    }
}
