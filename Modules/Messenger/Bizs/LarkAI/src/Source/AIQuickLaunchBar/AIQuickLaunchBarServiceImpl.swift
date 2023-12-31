//
//  AIQuickLaunchBarServiceImpl.swift
//  LarkAI
//
//  Created by ByteDance on 2023/5/24.
//

import Foundation
import LarkQuickLaunchBar
import UniverseDesignIcon
import UniverseDesignColor
import LarkMessengerInterface
import LarkContainer
import UniverseDesignToast
import RxRelay
import RxSwift
import EENavigator
import LarkQuickLaunchInterface
import LarkSetting
import SuiteAppConfig

public class MyAIQuickLaunchBarServiceImpl: MyAIQuickLaunchBarService {

    @InjectedUnsafeLazy var aiService: MyAIService

    @InjectedUnsafeLazy var quickLaunchService: QuickLaunchService

    private let disposeBag = DisposeBag()

    public var isQuickLaunchBarEnable: Bool {
        return !AppConfigManager.shared.leanModeIsOn
    }

    public func createAIQuickLaunchBar(items: [QuickLaunchBarItem],
                                       enableTitle: Bool,
                                       enableAIItem: Bool,
                                       extraItemClickEvent: ((MyAIQuickLaunchBarExtraItemType) -> Void)? = nil,
                                       aiBusinessInfoProvider: MyAIChatModeConfigProvider?) -> MyAIQuickLaunchBarInterface {
        return MyAIQuickLaunchBar(items: items,
                                  enableTitle: enableTitle,
                                  enableAIItem: enableAIItem,
                                  extraItemClickEvent: extraItemClickEvent,
                                  aiBusinessInfoProvider: aiBusinessInfoProvider)
    }

    public func createQuickLaunchBarItemView(type: MyAIQuickLaunchBarExtraItemType, config: QuickLaunchBarItemViewConfig?) -> UIView {
        let info = self.getQuickLaunchBarItemInfo(type: type).value
        let item = QuickLaunchBarItem(name: info.title, nomalImage: info.image, action: { [weak self] _ in
            guard let self = self else { return }
            self.launchByType(type)
        })
        if let config = config {
            return QuickLaunchBarItemView(config: config, item: item)
        }
        return QuickLaunchBarItemView(item: item)
    }

    public func getQuickLaunchBarItemInfo(type: MyAIQuickLaunchBarExtraItemType) -> BehaviorRelay<QuickLaunchBarItemInfo> {
        if case .ai(_) = type {
            let aiResource = self.aiService.defaultResource
            return BehaviorRelay(value: QuickLaunchBarItemInfo(image: aiResource.iconSmall, title: aiResource.name))
        } else {
            return BehaviorRelay(value: QuickLaunchBarItemInfo(image: UDIcon.getIconByKey(.moreLauncherOutlined, iconColor: UIColor.ud.iconN2), title: "More"))
        }
    }

    public func launchByType(_ type: LarkMessengerInterface.MyAIQuickLaunchBarExtraItemType) {
        if case .ai(let provider) = type {
            guard let provider = provider,
                  let fromVC = Navigator.shared.mainSceneTopMost else {
                return
            }
            provider().observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] config in
                guard let self = self, let config = config else { return }
                self.aiService.openMyAIChatMode(config: config, from: fromVC)
            }).disposed(by: self.disposeBag)
        } else {
            quickLaunchService.showQuickLaunchWindow(from: nil)
        }
    }

    public var isAIServiceEnable: BehaviorRelay<Bool> {
        return self.aiService.enable
    }

    public var isAINeedOnboarding: BehaviorRelay<Bool> {
        return self.aiService.needOnboarding
    }

    public func openOnboarding(from: EENavigator.NavigatorFrom, onSuccess: ((Int64) -> Void)?, onError: ((Error?) -> Void)?, onCancel: (() -> Void)?) {
        return self.aiService.openOnboarding(from: from, onSuccess: onSuccess, onError: onError, onCancel: onCancel)
    }
}
