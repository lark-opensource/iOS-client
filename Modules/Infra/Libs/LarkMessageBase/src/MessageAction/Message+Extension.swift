//
//  Message+Extension.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2022/10/24.
//

import Foundation
import LarkModel
import LarkFeatureGating

public extension Message {
    //不仅是displayInThreadMode模式下的消息要展示话题样式，普通模式下的话题也可能展示话题样式（受fg影响）
    public var showInThreadModeStyle: Bool {
        if self.displayInThreadMode
            || ((self.threadMessageType == .threadRootMessage && LarkFeatureGating.shared.getFeatureBoolValue(for: "message.chat.threadv2"))) { //Global 太底层了，实在改不动。。。
            return true
        }
        return false
    }
}
