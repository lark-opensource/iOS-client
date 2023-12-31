//
//  TabGuideService.swift
//  ByteViewTab
//
//  Created by kiri on 2021/8/22.
//

import Foundation
import ByteViewCommon

public struct TabGuideContent {
    public let text: String
    public let leftButton: String
    public let rightButton: String

    static var `default`: TabGuideContent { TabGuideContent(text: I18n.View_G_RecentMeetingsOnboarding,
                                                            leftButton: I18n.View_G_OkButton,
                                                            rightButton: I18n.View_G_ViewNow) }
}

public protocol TabGuideService: AnyObject {
    /// 通知VC_Tab已启用，可以在适当的时机弹出Guide
    func notifyTabEnabled()
}

public extension TabGuideService {
    var shouldShowGuide: Bool {
        // iPad上全屏或R视图下无法获取准确的TabItem位置，且分屏显示位置会超出边界，和PM沟通决定先在iPad上不显示此OnBoarding
        Display.phone
    }

    var guideContent: TabGuideContent {
        .default
    }
}
