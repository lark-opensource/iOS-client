//
//  CategoryEditViewModel.swift
//  Moment
//
//  Created by liluobin on 2021/5/13.
//

import Foundation
import UIKit
import LarkContainer
import RxSwift
import LKCommonsLogging

final class CategoryEditViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(CategoryEditViewModel.self, category: "Module.Moments.CategoryEditViewModel")
    static let cannotMoveSection: Int = 1
    static let editSection: Int = 0

    @ScopedInjectedLazy var tabService: UserTabApiService?
    private let disposeBag = DisposeBag()
    private var usedTabs: [RawData.PostTab] = []
    let selectedTab: RawData.PostTab
    var datas: [[CategoryEditCellViewModel]] = []
    var headerItems: [CategoryEditHeaderItem] = []
    let selectBlock: ((RawData.PostTab) -> Void)?
    let finishBlock: (([RawData.PostTab]) -> Void)?
    init(userResolver: UserResolver,
         selectedTab: RawData.PostTab,
         usedTabs: [RawData.PostTab],
         selectBlock: ((RawData.PostTab) -> Void)?,
         finishBlock: (([RawData.PostTab]) -> Void)?) {
        self.userResolver = userResolver
        self.selectedTab = selectedTab
        self.usedTabs = usedTabs
        self.selectBlock = selectBlock
        self.finishBlock = finishBlock
        Self.logger.info("init tab count \(usedTabs.count)")
        self.datas = [self.mapTabsDataToCellVMs(tabs: usedTabs, selectedTabId: selectedTab.id), []]
    }

    func configTabsComplete(_ complete: ((Bool) -> Void)?) {
        let ids = datas[Self.editSection].map { $0.tab.id }
        tabService?.configTabsRequestWithTabIds(ids)
            .observeOn(MainScheduler.instance).subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                self.finishBlock?(self.datas[Self.editSection].map({ $0.tab }))
                complete?(true)
            }, onError: { (error) in
                complete?(false)
                Self.logger.error("configTabsRequestWithTabIds  fail \(error)")
            }).disposed(by: disposeBag)
    }

    func loadTabs(finish: ((Bool) -> Void)?) {
        tabService?.getListTabRequest()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (tabs) in
                guard let self = self else { return }
                let unUsedTabs = tabs.filter({ (tab) -> Bool in
                    return !self.usedTabs.contains { $0.id == tab.id }
                })
                self.datas = [self.mapTabsDataToCellVMs(tabs: self.usedTabs, selectedTabId: self.selectedTab.id),
                              self.mapTabsDataToCellVMs(tabs: unUsedTabs)]
                finish?(true)
            }, onError: { (error) in
                finish?(false)
                Self.logger.error("moment trace getListTabRequest fail", error: error)
            }).disposed(by: disposeBag)
    }

    func mapTabsDataToCellVMs(tabs: [RawData.PostTab], selectedTabId: String? = nil) -> [CategoryEditCellViewModel] {
        return tabs.map { (tab) -> CategoryEditCellViewModel in
            var isSelected = false
            if let selectedTabId = selectedTabId {
                isSelected = tab.id == selectedTabId
            }
            return CategoryEditCellViewModel(tab: tab, isSelected: isSelected)
        }
    }

}
