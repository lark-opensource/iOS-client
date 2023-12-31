//
//  LarkInterface+TourDependency.swift
//  LarkTour
//
//  Created by Meng on 2019/12/9.
//

import Foundation
import LarkModel
import RxSwift
import EENavigator

public protocol TourDependency: AnyObject {

    /// 归因信息是否ready（AF SDK场景）
    var conversionDataReady: Bool { get }
    /// 归因信息处理block
    func setConversionDataHandler(_ handler: @escaping (String) -> Void)

    /// 是否需要跳过Onboarding引导
    var needSkipOnboarding: Bool { get }
}

public protocol TourChatGuideService {
    /// 是否需要显示chat引导
    func needShowChatUserGuide(for chatId: String) -> Bool
    /// 显示chatGuide
    func showChatUserGuideIfNeeded(
        with chatId: String,
        on targetRect: CGRect,
        completion: ((Bool) -> Void)?
    )
}
