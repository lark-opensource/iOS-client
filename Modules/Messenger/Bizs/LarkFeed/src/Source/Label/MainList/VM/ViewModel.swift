//
//  LabelMainListViewModel.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/20.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import LarkSDKInterface
import RustPB
import LarkModel
import LarkOpenFeed
import LarkContainer

/** LabelMainListViewModel的设计：面向VC，管理dataSource、LabelMainListViewDataStateModule
 1. 管理并协调其下面的各个角色
 2. 不做具体的工作，具体工作由它管理的各个角色来实现
 3. 缺点：有可能造成循环引用，引用关系有些乱
*/

final class LabelMainListViewModel: UserResolverWrapper {
    var userResolver: UserResolver { dependency.userResolver }
    private var settingStore: FeedSettingStore? {
        return try? userResolver.resolve(type: FeedSettingStore.self)
    }
    let context: FeedContextService?
    let labelContext: LabelMainListContext
    let dependency: LabelDependency
    private let disposeBag = DisposeBag()

    var isActive: Bool = false
    let dataModule: LabelMainListDataModule
    let viewDataStateModule: LabelMainListViewDataStateModule
    let expandedModule: ExpandedModule
    let selectedModule: SelectedModule
    let switchModeModule: SwitchModeModule
    let otherModule: OtherModule

    lazy var swipeSettingChanged: Driver<()> = {
        guard let setting = settingStore else { return .empty() }
        return setting.getFeedActionSetting().distinctUntilChanged().map({ _ -> Void in
            FeedContext.log.info("feedlog/actionSetting/getFeedActionSetting Label settingChanged")
            return ()
        }).asDriver { _ in
            return .empty()
        }
    }()
    init(dependency: LabelDependency,
         context: FeedContextService,
         labelContext: LabelMainListContext) {
        self.dependency = dependency
        self.context = context
        self.labelContext = labelContext
        let fetcher = LabelMainListFetcher(dependency: dependency)
        let dataModule = LabelMainListDataModule(fetcher: fetcher)
        self.dataModule = dataModule
        let expandedModule = ExpandedModule(userID: dependency.userResolver.userID)
        self.expandedModule = expandedModule
        let switchModeModule = SwitchModeModule(dataModule: dataModule, expandedModule: expandedModule)
        self.switchModeModule = switchModeModule
        let viewDataStateModule = LabelMainListViewDataStateModule(dataModule: dataModule, switchModeModule: switchModeModule)
        self.viewDataStateModule = viewDataStateModule
        self.selectedModule = SelectedModule(dependency: dependency, viewDataStateModule: viewDataStateModule)
        self.otherModule = OtherModule(dependency: dependency)
        setup()
    }

    private func setup() {
        dataModule.fetcher.refresh()
    }

    func willActive() {
        self.isActive = true
        // 切换后的vm强制resume queue，防止数据不上屏
        dataModule.dataQueue.resumeDataQueue(.willActive)
    }

    func willResignActive() {
        self.isActive = false
    }
}
