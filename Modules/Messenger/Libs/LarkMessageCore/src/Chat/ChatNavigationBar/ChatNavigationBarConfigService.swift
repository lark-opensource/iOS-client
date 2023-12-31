//
//  ChatNavigationBarLayoutService.swift
//  LarkMessageCore
//
//  Created by liluobin on 2023/12/13.
//

import LarkUIKit
import LarkSetting

public protocol ChatNavigationBarConfigService: AnyObject {
    var showLeftStyle: Bool { get }
}

public class ChatNavigationBarConfigServiceIMP: ChatNavigationBarConfigService {
    /// 产品&UI要求 只有手机上展示居左样式
    public lazy var showLeftStyle: Bool = {
        let fg = self.fg.dynamicFeatureGatingValue(with: "im.chat.header_left_title")
        return fg && Display.phone
    }()

    let fg: FeatureGatingService

    public init(fg: FeatureGatingService) {
        self.fg = fg
    }
}
