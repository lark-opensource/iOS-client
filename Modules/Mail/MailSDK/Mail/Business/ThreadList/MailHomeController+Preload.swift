//
//  MailHomeController+Preload.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2021/8/9.
//

import Foundation
import RxSwift

extension MailHomeController {
    /*
    func handlePreloadCirculation() {
        let status = viewModel.preloadStatus.value
        switch status {
        case .noNeed, .none, .preloadFail:
            break
        case .preloading:
            // 如果preloading 或者 已经不必要加载都要兼容
            viewModel.preloadStatus
                .subscribeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] preloadStatus in
                guard let `self` = self else { return }
                if preloadStatus == .preloaded {
                    self.preloadThreadList()
                } else if preloadStatus == .preloadFail {
                    // 预加载发生错误，直接重试
                    self.showMailLoading()
                    self.viewModel.refreshAllListData()
                }
            }).disposed(by: self.disposeBag)
        case .preloaded:
            preloadThreadList()
        }
    }

    func preloadThreadList() {
        guard let preloadLabel = viewModel.preloadLabel else {
            return
        }
        MailLogger.debug("[mail_preload] listdatasource ready for thread list vc")
        let event = MailAPMEvent.LabelListLoaded()
        event.commonParams.append(MailAPMEvent.LabelListLoaded.CommonParam.sence_cold_start)
        event.markPostStart()
        loadLabelListCostTimeStart()

        updateTitle(preloadLabel.text)
        hiddenLoading()
        viewModel.switchLabelId(preloadLabel.labelId)

        viewModel.labels = viewModel.preloadLabels ?? []
        MailTagDataManager.shared.updateTags(viewModel.labels.map({ $0.toPBModel() }))
        viewModel.preloadLabels = nil
        let labelCount = MailAPMEvent.LabelListLoaded.EndParam.list_length(self.viewModel.labels.count)
        event.endParams.append(labelCount)
        event.endParams.append(MailAPMEventConstant.CommonParam.status_success)
        event.postEnd()
        loadLabelListCostTimeEnd()
        loadThreadListCostTimeStart()
        viewModel.syncDataSource()
        tableView.reloadData()
        threadListDevTrack()
        firstScreenAPMReport(true)
        viewModel.refreshAccountList(onCompleted: nil)
        viewModel.showPreviewCardIfNeeded(preloadLabel.labelId == Mail_LabelId_Important ? Mail_LabelId_Other : Mail_LabelId_Important)
        let labelIds = viewModel.labels.map({ $0.labelId })
        labelListFgDataError = !(labelIds.contains(Mail_LabelId_Important) && labelIds.contains(Mail_LabelId_Other))
        labelsMenuController.fgDataError = labelListFgDataError
        labelsMenuController.updateLabels(viewModel.labels)
        labelsMenuController.smartInboxModeEnable = Store.settingData.getCachedCurrentSetting()?.smartInboxMode ?? false
    }
     */
}
