//
//  MyAIQuickLaunchBarService.swift
//  LarkMessengerInterface
//
//  Created by ByteDance on 2023/5/12.
//

import Foundation
//import LarkQuickLaunchBar
import RxSwift
import RxCocoa
import RxRelay
import EENavigator
import LarkQuickLaunchInterface
import LarkAIInfra

public typealias MyAIChatModeConfigProvider = () -> Observable<MyAIChatModeConfig?>

/// Item类型
public enum MyAIQuickLaunchBarExtraItemType {
    case ai(MyAIChatModeConfigProvider?)
    case more
}

/// Item信息
public struct QuickLaunchBarItemInfo {
    // 图标
    public var image: UIImage
    // 名称
    public var title: String

    public init(image: UIImage, title: String) {
        self.image = image
        self.title = title
    }
}

/// MyAIQuickLaunchBar提供的对外服务
public protocol MyAIQuickLaunchBarService {

    /// 功能FG,控制QuickLaunchBar是否展示
    /// lark.navigation.superapp
    var isQuickLaunchBarEnable: Bool { get }

    /// 创建QuickLaunchBar
    func createAIQuickLaunchBar(items: [QuickLaunchBarItem],
                                enableTitle: Bool,
                                enableAIItem: Bool,
                                extraItemClickEvent: ((MyAIQuickLaunchBarExtraItemType) -> Void)?,
                                aiBusinessInfoProvider: MyAIChatModeConfigProvider?) -> MyAIQuickLaunchBarInterface

    /// 创建完整的ItemView
    func createQuickLaunchBarItemView(type: MyAIQuickLaunchBarExtraItemType, config: QuickLaunchBarItemViewConfig?) -> UIView

    /// 获取ItemInfo
    func getQuickLaunchBarItemInfo(type: MyAIQuickLaunchBarExtraItemType) -> BehaviorRelay<QuickLaunchBarItemInfo>

    /// 跳转到AI/Launch
    func launchByType(_ type: MyAIQuickLaunchBarExtraItemType)

    /// AIService是否可用
    /// 用户创建ItemView和获取ItemInfo前需要手动
    var isAIServiceEnable: BehaviorRelay<Bool> { get }

    /// AI是否需要进入Onboarding流程
    var isAINeedOnboarding: BehaviorRelay<Bool> { get }

    /// 透穿自myaiService
    /// 打开onboarding。（在打开单聊/打开profile时不需要额外判断是否跳onboarding，打开单聊/打开profile的接口内部已经检查了是否需要跳onboarding）
    func openOnboarding(from: NavigatorFrom,
                        onSuccess: ((_ chatID: Int64) -> Void)?,
                        onError: ((_ error: Error?) -> Void)?,
                        onCancel: (() -> Void)?)
}
