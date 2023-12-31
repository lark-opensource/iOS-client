//
//  MyAIQuickLaunchBar.swift
//  LarkAI
//
//  Created by ByteDance on 2023/5/11.
//

import Foundation
import LarkQuickLaunchBar
import UniverseDesignIcon
import LarkMessengerInterface
import LarkContainer
import UniverseDesignToast
import RxRelay
import RxSwift
import EENavigator
import LarkQuickLaunchInterface
import LKCommonsTracker
import Homeric

public class MyAIQuickLaunchBar: QuickLaunchBar, MyAIQuickLaunchBarInterface {

    @InjectedUnsafeLazy var aiService: MyAIService

    @InjectedUnsafeLazy var aiQuickLaunchBarService: MyAIQuickLaunchBarService

    @InjectedUnsafeLazy var quickLaunchService: QuickLaunchService

    private lazy var aiItem: QuickLaunchBarItem = {
        let info = self.aiQuickLaunchBarService.getQuickLaunchBarItemInfo(type: .ai(nil)).value
        return QuickLaunchBarItem(name: info.title,
                                  nomalImage: info.image,
                                  action: { [weak self] _ in
            Tracker.post(TeaEvent(Homeric.PUBLIC_TAB_CONTAINER_CLICK, params: ["click": "my_ai"]))
            self?.aiQuickLaunchBarService.launchByType(.ai(self?.aiBusinessInfoProvider))
            if let clickEvent = self?.extraItemClickEvent {
                clickEvent(.ai(self?.aiBusinessInfoProvider))
            }
        })
    }()

    private lazy var moreItem: QuickLaunchBarItem = {
        let info = self.aiQuickLaunchBarService.getQuickLaunchBarItemInfo(type: .more).value
        return QuickLaunchBarItem(name: info.title,
                                  nomalImage: info.image,
                                  action: { [weak self] _ in
            Tracker.post(TeaEvent(Homeric.PUBLIC_TAB_CONTAINER_CLICK, params: ["click": "more"]))
            self?.quickLaunchService.showQuickLaunchWindow(from: self)
            if let clickEvent = self?.extraItemClickEvent {
                clickEvent(.more)
            }
        })
    }()

    // 业务最大添加的Item数量（不含AI、More）
    static let maxBusinessItemCount = 4

    // LaunchBar自带的Item: AI、More
    private var extraItems: [QuickLaunchBarItem] = []

    // 业务注入的Item
    private var businessItems: [QuickLaunchBarItem] = []

    private var totalItems: [QuickLaunchBarItem] {
        return businessItems + extraItems
    }

    private var aiBusinessInfoProvider: MyAIChatModeConfigProvider?

    private var extraItemClickEvent: ((MyAIQuickLaunchBarExtraItemType) -> Void)?

    private var isAIItemEnable: Bool = true

    private var isAIServiceEnable: Bool = true

    private var disposeBag: DisposeBag = DisposeBag()

    public init(items: [QuickLaunchBarItem],
                enableTitle: Bool = false,
                enableAIItem: Bool = true,
                extraItemClickEvent: ((MyAIQuickLaunchBarExtraItemType) -> Void)? = nil,
                aiBusinessInfoProvider: MyAIChatModeConfigProvider? = nil) {
        super.init(enableTitle: enableTitle, items: [])
        // AIQuickLaunchBar 的曝光
        Tracker.post(TeaEvent(Homeric.PUBLIC_TAB_CONTAINER_VIEW))
        self.businessItems = Array(items.prefix(Self.maxBusinessItemCount))
        self.aiBusinessInfoProvider = aiBusinessInfoProvider
        self.isAIItemEnable = enableAIItem
        self.isAIServiceEnable = aiService.enable.value
        self.extraItemClickEvent = extraItemClickEvent
        if enableAIItem {
            self.extraItems.append(self.aiItem)
        }
        self.extraItems.append(self.moreItem)
        self.reloadAllItems()
        // 监听AI是否可用
        aiService.enable.asObservable()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] isEnable in
                guard let self = self, self.isAIServiceEnable != isEnable else {
                    return
                }
                self.isAIServiceEnable = isEnable
                if self.isAIServiceEnable && self.isAIItemEnable {
                    self.extraItems = [self.aiItem, self.moreItem]
                    self.reloadAllItems()
                } else {
                    self.extraItems = [self.moreItem]
                    self.reloadAllItems()
                }
        }).disposed(by: self.disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setAIItemEnable(_ isEnable: Bool) {
        guard self.isAIItemEnable != isEnable else {
            return
        }
        self.isAIItemEnable = isEnable
        if self.isAIItemEnable && self.isAIServiceEnable {
            extraItems = [aiItem, moreItem]
            self.reloadAllItems()
        } else {
            extraItems = [moreItem]
            self.reloadAllItems()
        }
    }

    private func reloadAllItems() {
        self.reloadByItems(businessItems)
    }

    public override func reloadByItems(_ items: [QuickLaunchBarItem]) {
        businessItems = Array(items.prefix(Self.maxBusinessItemCount))
        super.reloadByItems(totalItems)
    }
}
