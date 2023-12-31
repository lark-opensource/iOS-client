//
//  KeyboardDisplayStyleManager.swift
//  LarkMessageCore
//
//  Created by ByteDance on 2022/7/6.
//

import Foundation
import LarkUIKit
import LarkFeatureGating

public final class KeyboardDisplayStyleManager {
    /// 因为这个FG 在lark上，只在手机上全量了，iPad上是关闭的，同国内。
    /// 因为FG手机全量了，所以第一次安装后本地默认值是打开，导致iPad上需要重启或者拉最新配置才能恢复
    /// 跟产品对齐 iPad上固定为飞书的样式，回车即发送
    /// FG开且不是Pad 才可以使用新样式
    public static func isNewKeyboadStyle() -> Bool {
        return LarkFeatureGating.shared.getFeatureBoolValue(for: .keyboardNewStyleEnable) && !Display.pad
    }
}
