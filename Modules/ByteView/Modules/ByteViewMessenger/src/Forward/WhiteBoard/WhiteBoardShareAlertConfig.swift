//
//  WhiteBoardShareAlertConfig.swift
//  ByteViewMod
//
//  Created by ByteDance on 2023/5/25.
//

import LarkMessengerInterface
import LarkSDKInterface

public final class WhiteBoardShareAlertConfig: ForwardAlertConfig {
    public override class func canHandle(content: ForwardAlertContent) -> Bool {
        if content as? WhiteBoardShareContent != nil {
            return true
        }
        return false
    }
}
