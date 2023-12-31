//
//  MailHomeViewModel+Preload.swift
//  MailSDK
//
//  Created by tefeng liu on 2022/3/22.
//

import Foundation
import RxSwift
import RxRelay

// MARK: preload相关逻辑
extension MailHomeViewModel {
    static func createPreloadedViewModel(data: HomePreloadableData, userContext: MailUserContext) -> MailHomeViewModel {
        let viewModel = MailHomeViewModel(userContext: userContext)

        viewModel.handlePreloadData(data)

        return viewModel
    }

    /// 有预加载的话，应用数据有点不同
    func initDataOfPreloaded() {
        refreshAccountList(onCompleted: nil)
        $uiElementChange.accept(.title(currentLabelName))
        $uiElementChange.accept(.refreshHeaderBizInfo)
        MailLogger.info("[mail_home] initDataOfPreloaded -- refresh home list: \(listViewModel.mailThreads.all)")
        listViewModel.$dataState.accept(.refreshed(data: listViewModel.mailThreads.all, resetLoadMore: false)) // 让首页刷数据
        showPreviewCardIfNeeded(currentLabelId == Mail_LabelId_Important ? Mail_LabelId_Other : Mail_LabelId_Important)
    }

    private func handlePreloadData(_ data: HomePreloadableData) {
        filterViewModel.resetFilter() // 确保重置filter
        createNewThreadList(labelId: data.preloadedLabel.labelId) // 创建preload对应的新的listVM
        listViewModel.mailThreads.replaceAll(data.preloadedListCellViewModels) // 直接填充预加载的数据
        listViewModel.labelName = data.preloadedLabel.text

        labels = data.preloadedLabels ?? []
        MailTagDataManager.shared.updateTags(data.preloadedLabels.map({ $0.toPBModel() }))
    }
}
