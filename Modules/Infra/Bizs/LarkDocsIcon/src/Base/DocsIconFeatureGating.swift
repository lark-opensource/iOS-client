//
//  DocsIconFeatureGating.swift
//  LarkDocsIcon
//
//  Created by huangzhikai on 2023/7/5.
//

import Foundation
import LarkSetting
import LarkContainer

//FG key：ccm.icon.suite_custom_icon （与web端共用一个）
//FG为true：圆形图标替换为方形图标
//FG为false：圆形图标 不变、无自定义图标逻辑，对齐原CCM图标显示逻辑
//
//FG key：ccm.icon.circle_background_color（与web端共用一个）
//FG为true：有圆形图标底色
//FG为false：无圆形图标底色
//
//FG key：ccm.bitable.square_icon
//true: 新的方图标默认图标
//false: 旧的方图标默认图标

public final class DocsIconFeatureGating: UserResolverWrapper {
    public var userResolver: LarkContainer.UserResolver

    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    var featureGatingService: FeatureGatingService? {
        return self.userResolver.resolve(FeatureGatingService.self)
    }

    public var suiteCustomIcon: Bool {
        featureGatingService?.staticFeatureGatingValue(with: "ccm.icon.suite_custom_icon") ?? false
    }
    
    public var circleBackgroundColor: Bool {
        featureGatingService?.staticFeatureGatingValue(with: "ccm.icon.circle_background_color") ?? false
    }

    public var btSquareIcon: Bool { 
        featureGatingService?.staticFeatureGatingValue(with: "ccm.bitable.square_icon") ?? false
    }
    
    public var etAndWpsFileTypeEnable: Bool {
        featureGatingService?.staticFeatureGatingValue(with: "ccm.drive.wps_support_wps_and_et") ?? false
    }
    
    //是否优化使用LarkIcon
    public var larkIconDisable: Bool {
        featureGatingService?.staticFeatureGatingValue(with: "ccm.icon.lark_icon_disable") ?? false
    }
}


