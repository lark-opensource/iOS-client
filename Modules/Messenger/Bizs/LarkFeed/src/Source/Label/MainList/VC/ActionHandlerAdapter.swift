//
//  LabelMainListActionHandlerAdapter.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2022/4/20.
//

import Foundation
import RxSwift
import RxCocoa
import LarkUIKit
import SnapKit
import UniverseDesignActionPanel
import LarkNavigator
import EENavigator
import LarkOpenFeed
import RustPB
import UniverseDesignDialog
import LarkAccountInterface
import UIKit
import UniverseDesignToast
import LarkSDKInterface
import LarkContainer

/** LabelMainListActionHandlerAdapter的设计：分担VC的事件处理工作
 1. 从事件转发到vc，转向到LabelMainListActionHandlerAdapter
 2. 缺点：应该由各个subModule来处理，这个类不应该存在
*/

final class LabelMainListActionHandlerAdapter: AdapterInterface, UserResolverWrapper {
    var userResolver: UserResolver { vm.userResolver }

    private weak var page: LabelMainListViewController?
    private let vm: LabelMainListViewModel
    private let disposeBag = DisposeBag()
    let muteActionSetting: FeedSetting.FeedGroupActionSetting
    let atAllSetting: FeedAtAllSetting
    let clearBadgeActionSetting: FeedSetting.FeedGroupActionSetting
    let displayRuleSetting: FeedSetting.FeedGroupActionSetting
    lazy var feedActionService: FeedActionService? = {
        return try? userResolver.resolve(assert: FeedActionService.self)
    }()
    init(vm: LabelMainListViewModel) {
        let userResolver = vm.userResolver
        self.vm = vm
        self.muteActionSetting = FeedSetting(userResolver).getFeedMuteActionSetting()
        self.atAllSetting = FeedAtAllSetting.get(userResolver: userResolver)
        self.clearBadgeActionSetting = FeedSetting(userResolver).gettGroupClearBadgeSetting()
        self.displayRuleSetting = FeedSetting(userResolver).getGroupDisplayRuleSetting()
        let filterGroupAction = try? userResolver.resolve(assert: FilterActionHandler.self)
        filterGroupAction?.groupActionSubject
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] action in
                self?.handleAction(action)
            }).disposed(by: disposeBag)

    }

    func handleAction(_ action: FilterGroupAction) {
        switch action {
        case .firstLevel(_): break
        case .secondLevel(let subFilter):
            guard subFilter.type == .tag else { return }
            switch self.vm.switchModeModule.mode {
            case .standardMode: break
            case .threeBarMode(let labelId):
                guard let LabelViewModel = self.vm.viewDataStateModule.uiStore.labelEntityMap[labelId],
                      let header = self.page?.tableView.headerView(forSection: 0) as? LableSectionHeader else { return }
                tryShowSheet(label: LabelViewModel, header: header)
            }
        }
    }

    func setup(page: LabelMainListViewController) {
        self.page = page
    }

    func expand(label: LabelViewModel, section: Int) {
        vm.expandedModule.toggleExpandState(id: label.item.id)
        let info = LabelMainListDataState.ExtraInfo(render: .reloadSection(section), dataFrom: .none)
        vm.dataModule.trigger(info: info)
    }
    func tryShowSheet(label: LabelViewModel, header: LableSectionHeader) {
        let queryMute = muteActionSetting.secondryLabel
        let queryAtAll = atAllSetting.secondryLabel
        if queryMute || queryAtAll {
            vm.dependency.getBatchFeedsActionState(label: label, queryMuteAtAll: queryAtAll)
                .timeout(.milliseconds(atAllSetting.timeout), scheduler: MainScheduler.instance)
                .observeOn(MainScheduler.instance)
                .subscribe(onNext: { [weak self] response in
                    guard let self = self else { return }
                    let showMute = response.feedCount > 0
                    let isMute = response.hasUnmuteFeeds_p
                    var showAtAll = false
                    var muteAtAll = false
                    switch response.muteAtAllType {
                    case .unknown, .shouldNotDisplay: break
                    case .displayMuteAtAll:
                        showAtAll = true
                        muteAtAll = true
                    case .displayRemindAtAll:
                        showAtAll = true
                        muteAtAll = false
                    @unknown default: break
                    }
                    self.showSheet(label: label, header: header, showMute: showMute, isMute: isMute, showAtAll: showAtAll, muteAtAll: muteAtAll)
                }, onError: { [weak self] _ in
                    guard let self = self else { return }
                    self.showSheet(label: label, header: header, showMute: false, isMute: false, showAtAll: false, muteAtAll: false)
                }).disposed(by: disposeBag)
        } else {
            self.showSheet(label: label, header: header, showMute: false, isMute: false, showAtAll: false, muteAtAll: false)
        }
    }

    func showSheet(label: LabelViewModel,
                          header: LableSectionHeader,
                          showMute: Bool,
                          isMute: Bool,
                          showAtAll: Bool,
                          muteAtAll: Bool) {
        guard let page = self.page else { return }
        let popSource = UDActionSheetSource(sourceView: header.moreButton.imageView ?? header.moreButton,
                                            sourceRect: header.moreButton.imageView?.bounds ?? header.moreButton.bounds,
                                            arrowDirection: [.up, .down])
        let config = UDActionSheetUIConfig(isShowTitle: !Display.pad, popSource: popSource)
        let actionSheet = UDActionSheet(config: config)
        if Display.pad {
            self.vm.dataModule.dataQueue.frozenDataQueue(.showSettingSheet)
        }
        actionSheet.dismissCallback = { [weak self] in
            if Display.pad {
                self?.vm.dataModule.dataQueue.resumeDataQueue(.showSettingSheet)
            }
        }
        actionSheet.setTitle(label.meta.feedGroup.name)
        var disabledSelectedIds: Set<String> = []
        page.vm.viewDataStateModule.uiStore.getFeeds(labelId: Int(label.meta.feedGroup.id)).forEach({
            disabledSelectedIds.insert($0.feedViewModel.bizData.entityId)
        })

        FeedDebug.executeTask {
            actionSheet.addDefaultItem(text: "copy label", action: { [weak self, weak page] in
                guard let self = self,
                      let page = page else { return }
                self.vm.otherModule.handleDebugEvent(label: label, view: page.view.window ?? page.view)
            })
        }
        if clearBadgeActionSetting.secondryLabel {
            for item in vm.viewDataStateModule.uiStore.getFeeds(labelId: Int(label.meta.feedGroup.id)) where item.feedPreview.basicMeta.unreadCount > 0 {
                actionSheet.addDefaultItem(text: BundleI18n.LarkFeed.Lark_Core_IgnoreUnreadMessages_Button, action: { [weak self, weak header] in
                    guard let self = self, let header = header else { return }
                    let unreadCount = Int(label.meta.extraData.remindUnreadCount)
                    let muteUnreadCount = Int(label.meta.extraData.muteUnreadCount)
                    let labelId = String(label.meta.feedGroup.id)
                    FeedTracker.Label.Click.BatchClearLabelBadge(labelId: labelId, unreadCount: unreadCount, muteUnreadCount: muteUnreadCount)
                    self.showClearBadgeSheet(label: label, header: header)
                })
                break
            }
        }
        if showMute {
            let text: String
            if isMute {
                text = BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_Mute_Button
            } else {
                text = BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_Unmute_Button
            }
            actionSheet.addDefaultItem(text: text, action: { [weak self, weak header] in
                guard let self = self, let header = header else { return }
                FeedTracker.Label.Click.BatchMuteLabelFeeds(labelId: String(label.meta.feedGroup.id), mute: isMute)
                self.showMuteSheet(label: label, header: header, isMute: isMute)
            })
        }

        if showAtAll {
            let text: String
            if muteAtAll {
                text = BundleI18n.LarkFeed.Lark_IM_MuteTagAllMentions_Button
            } else {
                text = BundleI18n.LarkFeed.Lark_IM_UnmuteTagAllMentions_Button
            }
            actionSheet.addDefaultItem(text: text, action: { [weak self, weak header] in
                guard let self = self, let header = header else { return }
                self.showAtAllSheet(label: label, header: header, muteAtAll: muteAtAll)
                FeedTracker.Label.Click.FirstOpenAtAll(labelId: String(label.meta.feedGroup.id), openAtAll: muteAtAll)
            })
        }

        if Feed.Feature(userResolver).groupSettingEnable && Feed.Feature(userResolver).groupSettingOptEnable && displayRuleSetting.secondryLabel {
            actionSheet.addDefaultItem(text: BundleI18n.LarkFeed.Lark_IM_MessageDisplaySettings_Button, action: { [weak self, weak page] in
                guard let self = self, let page = page else { return }
                let labelId = label.meta.feedGroup.id
                FeedTracker.Label.Click.ShowMsgDisplayRule(labelId: String(labelId))
                self.presentDisplayRulePage(tabId: labelId, from: page)
            })
        }

        actionSheet.addDefaultItem(text: BundleI18n.LarkFeed.Lark_Core_AddChatToLabel_Button, action: { [weak page] in
            guard let page = page else { return }
            let body = AddItemInToLabelPickerBody(labelId: label.meta.feedGroup.id,
                                                  disabledSelectedIds: disabledSelectedIds)
            page.navigator.present(body: body,
                                   wrap: LkNavigationController.self,
                                   from: page)
        })

        actionSheet.addDefaultItem(text: BundleI18n.LarkFeed.Lark_Core_EditLabel_Button, action: { [weak page] in
            guard let page = page else { return }
            let body = SettingLabelBody(mode: .edit,
                                        entityId: nil,
                                        labelId: label.meta.feedGroup.id,
                                        labelName: label.meta.feedGroup.name,
                                        successCallback: nil)
            page.navigator.present(body: body,
                                   wrap: LkNavigationController.self,
                                   from: page)
        })

        actionSheet.addDestructiveItem(text: BundleI18n.LarkFeed.Lark_Core_DeleteLabel_AlertTitle, action: { [weak self, weak header] in
            guard let self = self, let header = header else { return }
            self.showDeleteLabelSheet(label: label, header: header)
        })
        actionSheet.setCancelItem(text: BundleI18n.LarkFeed.Project_T_CancelButton)
        navigator.present(actionSheet, from: page)
    }
}

// 创建标签
extension LabelMainListActionHandlerAdapter {
    func creatLabel() {
        guard let page = self.page else { return }
        let body = SettingLabelBody(mode: .create, entityId: nil, labelId: nil, labelName: nil, successCallback: nil)
        navigator.present(body: body,
                          wrap: LkNavigationController.self,
                          from: page)
    }
}

// 添加会话到标签
extension LabelMainListActionHandlerAdapter {
    func createLabelFeed(labelId: Int) {
        guard let page = page else { return }
        var disabledSelectedIds: Set<String> = []
        page.vm.viewDataStateModule.uiStore.getFeeds(labelId: labelId).forEach({
            disabledSelectedIds.insert($0.feedViewModel.bizData.entityId)
        })
        let body = AddItemInToLabelPickerBody(labelId: Int64(labelId), disabledSelectedIds: disabledSelectedIds)
        userResolver.navigator.present(body: body,
                                 wrap: LkNavigationController.self,
                                 from: page)
    }
}

// 删除标签
extension LabelMainListActionHandlerAdapter {
    private func showDeleteLabelSheet(label: LabelViewModel, header: LableSectionHeader) {
        guard let page = self.page else { return }
        let popSource = UDActionSheetSource(sourceView: header.moreButton.imageView ?? header.moreButton,
                                            sourceRect: header.moreButton.imageView?.bounds ?? header.moreButton.bounds,
                                            arrowDirection: [.up, .down])
        let config = UDActionSheetUIConfig(isShowTitle: !Display.pad, popSource: popSource)
        let actionSheet = UDActionSheet(config: config)
        if Display.pad {
            self.vm.dataModule.dataQueue.frozenDataQueue(.showSettingSheet)
        }
        actionSheet.dismissCallback = { [weak self] in
            if Display.pad {
                self?.vm.dataModule.dataQueue.resumeDataQueue(.showSettingSheet)
            }
        }
        actionSheet.setTitle(BundleI18n.LarkFeed.Lark_Core_DeleteLabel_AlertDesc(label.meta.feedGroup.name))
        actionSheet.addDestructiveItem(text: BundleI18n.LarkFeed.Lark_Core_DeleteLabel_AlertTitle, action: { [weak self] in
            self?.deleteLabelRequest(label: label)
        })
        actionSheet.setCancelItem(text: BundleI18n.LarkFeed.Project_T_CancelButton)
        navigator.present(actionSheet, from: page)
    }

    private func deleteLabelRequest(label: LabelViewModel) {
        guard let page = self.page else { return }
        vm.dependency.deleteLabel(id: label.meta.feedGroup.id)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak page] _ in
                guard let page = page, let window = page.view.window else { return }
                UDToast.showSuccess(with: BundleI18n.LarkFeed.Lark_Feed_Label_SuccessfullyDeleted_Toast(label.meta.feedGroup.name), on: window)
            }, onError: { [weak page] error in
                guard let page = page, let window = page.view.window else { return }
                UDToast.showFailure(with: BundleI18n.LarkFeed.Lark_Feed_Label_FailedToDelete_Toast, on: window, error: error)
            }).disposed(by: disposeBag)
    }
}

// 批量清理badge
extension LabelMainListActionHandlerAdapter {
    private func showClearBadgeSheet(label: LabelViewModel, header: LableSectionHeader) {
        guard let page = self.page else { return }
        let popSource = UDActionSheetSource(sourceView: header.moreButton.imageView ?? header.moreButton,
                                            sourceRect: header.moreButton.imageView?.bounds ?? header.moreButton.bounds,
                                            arrowDirection: [.up, .down])
        let config = UDActionSheetUIConfig(isShowTitle: !Display.pad, popSource: popSource)
        let actionSheet = UDActionSheet(config: config)
        if Display.pad {
            self.vm.dataModule.dataQueue.frozenDataQueue(.showSettingSheet)
            actionSheet.dismissCallback = { [weak self] in
                self?.vm.dataModule.dataQueue.resumeDataQueue(.showSettingSheet)
            }
        }
        actionSheet.setTitle(BundleI18n.LarkFeed.Lark_Core_DismissAllMultipleChats_Title)
        actionSheet.addDestructiveItem(text: BundleI18n.LarkFeed.Lark_Core_IgnoreUnreadMessages_Ignore_Button, action: { [weak self] in
            self?.clearBadgeRequest(label: label)
            FeedTracker.Label.Click.BatchClearLabelBadgeConfirm()
        })
        actionSheet.setCancelItem(text: BundleI18n.LarkFeed.Lark_Core_IgnoreUnreadMessages_Cancel_Button)
        navigator.present(actionSheet, from: page)
    }

    private func clearBadgeRequest(label: LabelViewModel) {
        let taskID = UUID().uuidString
        vm.dependency.feedGuideDependency.didShowGuide(key: GuideKey.feedClearBadgeGuide.rawValue)
        vm.dependency.batchClearBadgeService.addTaskID(taskID: taskID)
        vm.dependency.clearLabelBadage(label: label, taskID: taskID)
    }
}

// MARK: 批量打开/关闭 at all
extension LabelMainListActionHandlerAdapter {
    private func showMuteSheet(label: LabelViewModel, header: LableSectionHeader, isMute: Bool) {
        let title: String
        let confirmText: String
        if isMute {
            title = BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_ConfirmMute_Title
            confirmText = BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_ConfirmMute_Mute_Button
        } else {
            title = BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_ConfirmUnmute_Title
            confirmText = BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_ConfirmUnmute_Unmute_Button
        }

        guard let page = self.page else { return }
        let popSource = UDActionSheetSource(sourceView: header.moreButton.imageView ?? header.moreButton,
                                            sourceRect: header.moreButton.imageView?.bounds ?? header.moreButton.bounds,
                                            arrowDirection: [.up, .down])
        let config = UDActionSheetUIConfig(isShowTitle: !Display.pad, popSource: popSource)
        let actionSheet = UDActionSheet(config: config)
        if Display.pad {
            self.vm.dataModule.dataQueue.frozenDataQueue(.showSettingSheet)
            actionSheet.dismissCallback = { [weak self] in
                self?.vm.dataModule.dataQueue.resumeDataQueue(.showSettingSheet)
            }
        }
        actionSheet.setTitle(title)
        actionSheet.addDestructiveItem(text: confirmText, action: { [weak self] in
            guard let self = self else { return }
            FeedTracker.Label.Click.BatchMuteLabelFeedsConfirm(mute: isMute)
            self.muteRequest(label: label, mute: isMute)
        })
        actionSheet.setCancelItem(text: BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_ConfirmMute_Cancel_Button)
        navigator.present(actionSheet, from: page)
    }

    private func muteRequest(label: LabelViewModel, mute: Bool) {
        let taskID = UUID().uuidString
        vm.dependency.batchMuteFeedCardsService.addTaskID(taskID: taskID, mute: mute)
        vm.dependency.setBatchFeedsState(label: label, taskID: taskID, action: mute ? .mute : .remind)
    }
}

// MARK: 批量打开/关闭 at all
extension LabelMainListActionHandlerAdapter {
    private func showAtAllSheet(label: LabelViewModel, header: LableSectionHeader, muteAtAll: Bool) {
        let title: String
        let confirmText: String
        if muteAtAll {
            title = BundleI18n.LarkFeed.Lark_IM_MuteAllMentionsInAllChats_Title
            confirmText = BundleI18n.LarkFeed.Lark_IM_MuteAllMentionsInAllChats_Mute_Button
        } else {
            title = BundleI18n.LarkFeed.Lark_IM_UnmuteAllMentionsInAllChats_Title
            confirmText = BundleI18n.LarkFeed.Lark_IM_UnmuteAllMentionsInAllChats_Unmute_Button
        }

        guard let page = self.page else { return }
        let popSource = UDActionSheetSource(sourceView: header.moreButton.imageView ?? header.moreButton,
                                            sourceRect: header.moreButton.imageView?.bounds ?? header.moreButton.bounds,
                                            arrowDirection: [.up, .down])
        let config = UDActionSheetUIConfig(isShowTitle: !Display.pad, popSource: popSource)
        let actionSheet = UDActionSheet(config: config)
        if Display.pad {
            self.vm.dataModule.dataQueue.frozenDataQueue(.showSettingSheet)
            actionSheet.dismissCallback = { [weak self] in
                self?.vm.dataModule.dataQueue.resumeDataQueue(.showSettingSheet)
            }
        }
        actionSheet.setTitle(title)
        actionSheet.addDestructiveItem(text: confirmText, action: { [weak self] in
            guard let self = self else { return }
            self.atAllRequest(label: label, muteAtAll: muteAtAll)
        })
        actionSheet.setCancelItem(text: BundleI18n.LarkFeed.Lark_Core_BatchMuteChats_ConfirmMute_Cancel_Button)
        navigator.present(actionSheet, from: page)
        FeedTracker.GroupAction.ConfirmView(openAtAll: muteAtAll, type: FilterGroupAction.secondLevel(.init(type: .tag, tabId: String(label.meta.feedGroup.id))))
    }

    private func atAllRequest(label: LabelViewModel, muteAtAll: Bool) {
        let taskID = UUID().uuidString
        vm.dependency.setBatchFeedsState(label: label, taskID: taskID, action: muteAtAll ? .muteAtAll : .remindAtAll)
        FeedTracker.GroupAction.Click.ConfirmOpenAtAll(openAtAll: muteAtAll, type: FilterGroupAction.secondLevel(.init(type: .tag, tabId: String(label.meta.feedGroup.id))))
    }
}

// MARK: 消息分组展示设置
extension LabelMainListActionHandlerAdapter {
    // 展示某个二级标签在消息分组的展示规则，选中保存对应规则
    private func presentDisplayRulePage(tabId: Int64, from: UIViewController) {
        guard let labelItem = vm.dataModule.store.getLabels().first(where: { $0.item.id == tabId }) else { return }
        let selectedTypes = FiltersModel.transformToSelectedTypes(userResolver: userResolver, labelItem.meta.extraData.displayRule)
        let itemTitle = labelItem.meta.feedGroup.name
        let selectedItem = FeedMsgDisplayFilterModel(userResolver: userResolver, selectedTypes: selectedTypes, filterType: .tag, itemId: tabId, itemTitle: itemTitle)
        let body = FeedMsgDisplaySettingBody(filterName: itemTitle, currentItem: selectedItem)
        body.selectObservable.subscribe(onNext: { [weak self, weak from] item in
            guard let self = self, let from = from else { return }
            FeedTracker.Label.Click.SaveMsgDisplayRule(labelId: String(tabId), ruleChanged: selectedTypes != item.selectedTypes)
            self.updateDisplayRuleRequest(item, from)
        }).disposed(by: disposeBag)
        self.userResolver.navigator.present(body: body,
                                            wrap: LkNavigationController.self,
                                            from: from,
                                            prepare: { $0.modalPresentationStyle = .formSheet },
                                            animated: true)
    }

    private func updateDisplayRuleRequest(_ item: FeedMsgDisplayFilterItem, _ from: UIViewController) {
        guard let tabId = item.itemId, let rule = FiltersModel.transformToFeedRule(userResolver: userResolver, item) else { return }
        let ruleMap: [Int64: Feed_V1_DisplayFeedRule] = [tabId: rule]
        vm.dependency.updateMsgDisplayRuleMap(ruleMap)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak from] _ in
                guard let from = from, let window = from.currentWindow() else { return }
                UDToast.showSuccess(with: BundleI18n.LarkFeed.Lark_IM_MessageDisplaySettingsSaved_Toast, on: window)
            }, onError: { [weak from] _ in
                guard let from = from, let window = from.currentWindow() else { return }
                UDToast.showFailure(with: BundleI18n.LarkFeed.Lark_IM_MessageDisplaySettingsSaveFailed_Toast, on: window)
            }).disposed(by: disposeBag)
    }
}
