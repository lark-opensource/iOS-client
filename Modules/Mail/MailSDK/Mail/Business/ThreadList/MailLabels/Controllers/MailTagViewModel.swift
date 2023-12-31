//
//  MailTagViewModel.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2020/12/6.
//

import Foundation
import RxSwift
import RxCocoa
import RxDataSources
import UniverseDesignIcon

protocol MailTagDelegate: AnyObject {
    func didSelectedTag(_ selectedLabel: MailLabelModel)
    func retryReload(_ labelId: String)
}

class MailTagViewModel {
    // TagModel
    var tagCellVMs: Driver<[MailTagSection]> {
        return tagModels.asDriver(onErrorJustReturn: [])
    }
    private let tagModels = BehaviorSubject<[MailTagSection]>(value: [])

    var showLoading: Driver<Bool> {
        return showLoadingVariable.asDriver(onErrorJustReturn: false)
    }
    private let showLoadingVariable = BehaviorSubject<Bool>(value: true)

    var showError: Driver<Bool> {
        return showErrorVariable.asDriver(onErrorJustReturn: false)
    }
    private let showErrorVariable = BehaviorSubject<Bool>(value: false)

    var showUnreadDot: Driver<(Bool, Bool)> {
        return showUnreadDotVariable.asDriver(onErrorJustReturn: (true, false))
    }
    private let showUnreadDotVariable = BehaviorSubject<(Bool, Bool)>(value: (true, false))

    private let disposeBag = DisposeBag()

    var selectedID: String = Mail_LabelId_Inbox {
        didSet {
            updateSelectedStatus()
        }
    }

    var didAppear = false
    var shouldForceReload = false
    var failedOutboxCount: Int = 0
    weak var delegate: MailTagDelegate?

    private(set) var labels: [MailFilterLabelCellModel] = []
    private var delayOutboxTask: (() -> Void)?

    init() {
        addObserver()
    }

    func addObserver() {
        EventBus.threadListEvent
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (event) in
                switch event {
                case .didFailedOutboxCountRefreshed(let count):
                    self?.updateOutboxCount(count)
                default: break
                }
            }).disposed(by: disposeBag)

        PushDispatcher
            .shared
            .mailChange
            .throttle(.milliseconds(timeIntvl.normalMili), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                switch push {
                case .cacheInvalidChange(let change):
                    MailLogger.info("[mail_client_folder] [mail_folder] labelListNeedRefresh")
                    self?.handleListNeedRefresh()
                default:
                    break
                }
        }).disposed(by: disposeBag)

        PushDispatcher
            .shared
            .mailChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                switch push {
                case .updateLabelsChange(let change):
                    self?.didReceiveLabelChange(change.labels)
                default:
                    break
                }
        }).disposed(by: disposeBag)

        NotificationCenter.default.addObserver(self,
                                               selector: #selector(mailSettingChange(_:)),
                                               name: Notification.Name.Mail.MAIL_CACHED_CURRENT_SETTING_CHANGED,
                                               object: nil)

        EventBus.accountChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                self?.shouldForceReload = true
            }).disposed(by: disposeBag)
    }

    @objc
    private func mailSettingChange(_ notification: Notification) {
        updateUnreadDotIfNeeded()
        if let setting = Store.settingData.getCachedCurrentSetting() {
            smartInboxModeEnable = setting.smartInboxMode
            strangerModeEnable = setting.enableStranger
        }
    }

    func updateUnreadDotIfNeeded() {
        if let setting = Store.settingData.getCachedCurrentSetting() {
            let canNotificate = setting.allNewMailNotificationSwitch && setting.newMailNotification
            showUnreadDotVariable.onNext((getUnreadCount() <= 0, canNotificate))
        }
    }

    func getUnreadCount() -> Int {
        let labelID = Store.settingData.mailClient ? Mail_LabelId_Inbox : (smartInboxModeEnable ? Mail_LabelId_Important : Mail_LabelId_Inbox)
        return self.labels.filter({ ($0.labelId == labelID || ($0.tagType == .folder && $0.labelId != Mail_LabelId_Stranger)) && $0.labelId != selectedID })
            .map({ $0.badge ?? 0 }).reduce(0, +)
    }
    
    func enableNotification() -> Bool {
        if let enableNotification = try? showUnreadDotVariable.value().1 {
            return enableNotification
        } else {
            return false
        }
    }

    @objc
    private func mailOutboxCountRefresh(_ notification: Notification) {
        if let count = notification.object as? Int {
            updateOutboxCount(count)
        }
    }

    func updateOutboxCount(_ count: Int) {
        guard count != self.failedOutboxCount,
              self.labels.count > 0 else { return }

        self.failedOutboxCount = count
        self.refresh()
        self.checkDelayOutboxTask()
    }

    @objc
    func handleListNeedRefresh() {
        fetchData()
    }

    func didReceiveLabelChange(_ labels: [MailClientLabel]) {
        guard self.labels.count > 0 else {
            // labels没有被正确初始化, 理论上不会走进这里, just in case
            // mailAssertionFailure("labels没有被正确初始化，但是收到了LabelChange")
            MailLogger.error("mail labels menu init error")
            return
        }

        MailLogger.info("[mail_client_folder] label order from rust \(labels.map({ $0.id }).joined(separator: ", "))")
        var labels = labels.map { MailFilterLabelCellModel(pbModel: $0) }
        labels = MailLabelArrangeManager.sortLabels(labels)
        labels = decidedOutboxLabel(labels)
        if Store.settingData.folderOpen() {
            labels = FolderTree.getSortedListWithNodePath(FolderTree.build(labels).rootNode)
        }
        let labelIds = labels.map({ $0.labelId })
        self.fgDataError = !(labelIds.contains(Mail_LabelId_Important) && labelIds.contains(Mail_LabelId_Other))
        self.updateDatasource(labels)
        self.updateView(labels: labels)
        self.updateUnreadDotIfNeeded()
    }

    func updateView(labels: [MailFilterLabelCellModel]) {
        delegate?.retryReload(selectedID)
    }

    func retryFetchData() {
        apmMarkRefresh()
        showErrorVariable.onNext(false)
        showLoadingVariable.onNext(true)
        fetchData()
    }

    // FG、排序逻辑收敛在这里，控制数据源的输出，视图层只关心展示数据
    func fetchData(apmEvent: MailAPMEvent.LabelListLoaded? = nil) {
        guard labels.isEmpty else {
            MailLogger.info("[mail_client_folder] load exist labels: \(labels.count)")
            self.handleLabelsLoaded(labels: labels, apmEvent: apmEvent)
            return
        }
        MailDataSource.shared.getLabelsFromDB().subscribe(onNext: { [weak self] (labels) in
            guard let `self` = self else { return }
            MailLogger.info("[mail_client_folder] fetchData labels: \(labels.count)")
            self.handleLabelsLoaded(labels: labels, apmEvent: apmEvent)
        }, onError: { [weak self] (error) in
            MailLogger.info("[mail_client_folder] fetchData labels error: \(error)")
            self?.showErrorVariable.onNext(true)
            if let event = apmEvent {
                event.endParams.appendError(errorCode: error.mailErrorCode, errorMessage: error.getMessage())
                MailTagViewModel.endApmEvent(event: event, status: .status_rust_fail)
            } else {
                self?.apmMarkLoadEnd(status: .status_rust_fail, error: error)
            }
        }).disposed(by: disposeBag)
    }

    func handleLabelsLoaded(labels: [MailFilterLabelCellModel], apmEvent: MailAPMEvent.LabelListLoaded? = nil) {
        self.updateLabels(labels)
        self.updateUnreadDotIfNeeded()
        if let event = apmEvent {
            let labelCount = MailAPMEvent.LabelListLoaded.EndParam.list_length(labels.count)
            event.endParams.append(labelCount)
            if labels.isEmpty {
                MailTagViewModel.endApmEvent(event: event, status: .status_rust_fail)
            } else {
                MailTagViewModel.endApmEvent(event: event, status: .status_success)
            }
        }
    }

    var fgDataError = false
    var smartInboxModeEnable = false
    func smartInboxEnable() -> Bool {
        return smartInboxModeEnable && !fgDataError
    }
    var strangerModeEnable = false
    func strangerEnable() -> Bool {
        return FeatureManager.open(FeatureKey(fgKey: .stranger, openInMailClient: false)) && strangerModeEnable
    }

    func updateLabels(_ labels: [MailFilterLabelCellModel]) {
        if labels.isEmpty {
            MailLogger.info("[mail_client_folder] update labels empty, no need to update")
            return
        }
        let labelIds = labels.map({ $0.labelId })
        MailLogger.info("[mail_client_folder] [loadLabels] label order from rust \(labelIds.map({ $0 }).joined(separator: ", "))")
        self.fgDataError = !(labelIds.contains(Mail_LabelId_Important) && labelIds.contains(Mail_LabelId_Other))

        showLoadingVariable.onNext(false)

        self.updateDatasource(labels)

        if !labels.isEmpty {
            self.apmMarkLoadEnd(status: .status_success)
        }
    }

    func updateDatasource(_ labels: [MailFilterLabelCellModel]) {
        // 要做一次颜色值的映射逻辑替换
        var newLabels = labels.map({ label -> MailFilterLabelCellModel in
            var newLabel = label
            let config = MailLabelTransformer.transformLabelColor(backgroundColor: label.bgColorHex ?? "")
            newLabel.fontColor = config.fontColor
            newLabel.bgColor = config.backgroundColor
            newLabel.colorType = config.colorType
            return newLabel
        })

        self.labels = newLabels
        var sections = [MailTagSection]()

        var toProcess: [MailFilterLabelCellModel] = newLabels

        if FeatureManager.enableSystemFolder() { // eas支持奇怪的分类，systemlabel下能建文件夹
            let (system, other) = newLabels.genSortedSystemAndOther()
            sections.append(MailTagSection(header: "", items: processSystemLabel(system, needSort: false)))
            toProcess = other
        } else {
            sections.append(MailTagSection(header: "", items: processSystemLabel(newLabels)))
        }
        let folderItems = processFolder(toProcess)
        if !folderItems.isEmpty {
            sections.append(MailTagSection(header: BundleI18n.MailSDK.Mail_Folder_FolderTab, items: folderItems))
        }
        let labelItems = processCustomLabel(toProcess)
        if !labelItems.isEmpty {
            sections.append(MailTagSection(header: BundleI18n.MailSDK.Mail_Manage_ManageLabelMobile, items: labelItems))
        }

        tagModels.onNext(sections)
    }

    func processStrangerLabel(_ labels: [MailFilterLabelCellModel]) -> [MailTagSectionItem] {
        if var strangerLabel = labels.first(where: { $0.labelId ==  Mail_LabelId_Stranger }) {
            return [.folder(strangerLabel)]
        } else {
            return []
        }
    }

    func processSystemLabel(_ labels: [MailFilterLabelCellModel], needSort: Bool = true) -> [MailTagSectionItem] {
        var sortLabels = labels
        if needSort {
            sortLabels = sortLabels.sorted(by: { $0.userOrderedIndex < $1.userOrderedIndex })
            sortLabels = sortLabels.filter({ (systemLabel($0) && $0.tagType == .label)}) // 如果stranger放在系统标签列表下需要放开tagType
        }
        return sortLabels.map({ .label($0) })
    }

    func processFolder(_ labels: [MailFilterLabelCellModel]) -> [MailTagSectionItem] {
        if !Store.settingData.folderOpen() && !Store.settingData.mailClient { // 三方客户端不管userType
            return []
        }

        let filterLabels = {
            if FeatureManager.open(FeatureKey(fgKey: .stranger, openInMailClient: false)) {
                return labels.filter({ !$0.isSystem && $0.tagType == .folder && $0.labelId != Mail_LabelId_Stranger })
            } else {
                return labels.filter({ !$0.isSystem && $0.tagType == .folder })
            }
        }()
        MailLogger.info("[mail_client_folder] labels: \(labels.count) folders: \(filterLabels.count)")
        return filterLabels.map({ .folder($0) })
    }

    func processCustomLabel(_ labels: [MailFilterLabelCellModel]) -> [MailTagSectionItem] {
        let filterLabels = labels.filter({ !$0.isSystem })
        return filterLabels
            .sorted(by: { $0.userOrderedIndex < $1.userOrderedIndex })
            .filter({ !$0.isSystem && $0.tagType == .label })
            .map({ .label($0) })
    }

    /// 延迟显示 Outbox label
    func decidedOutboxLabel(_ labels: [MailFilterLabelCellModel]) -> [MailFilterLabelCellModel] {
        guard let outbox = labels.first(where: { $0.labelId == Mail_LabelId_Outbox }),
              self.labels.first(where: { $0.labelId == Mail_LabelId_Outbox }) == nil,
              failedOutboxCount == 0
        else {
            delayOutboxTask = nil
            return labels
        }

        var filteredLabels = labels
        filteredLabels.removeAll(where: { $0.labelId == Mail_LabelId_Outbox })

        if delayOutboxTask == nil {
            delayOutboxTask = { [weak self] in
                guard let self = self else { return }
                let labels = MailLabelArrangeManager.sortLabels((self.labels + [outbox]).unique)
                self.updateDatasource(labels)
                self.delayOutboxTask = nil
            }
            DispatchQueue.main.asyncAfter(wallDeadline: .now() + 3.0) { [weak self] in
                self?.delayOutboxTask?()
            }
        }

        return filteredLabels
    }

    func checkDelayOutboxTask() {
        guard let task = delayOutboxTask, failedOutboxCount > 0 else { return }
        task()
    }

    func systemLabel(_ label: MailLabelModel) -> Bool {
        if label.labelId == Mail_LabelId_SHARED {
            return true
        }
        if label.labelId == Mail_LabelId_Outbox {
            return FeatureManager.open(.newOutbox) ? true : failedOutboxCount > 0
        }
//        if strangerEnable(), label.labelId == Mail_LabelId_Stranger {
//            return true
//        }
        if smartInboxEnable() {
            if selectedID == Mail_LabelId_Inbox {
                selectedID = Mail_LabelId_Important
            }
            return label.isSystem && label.labelId != Mail_LabelId_Inbox
        } else {
            if smartInboxLabels.contains(selectedID) {
                selectedID = Mail_LabelId_Inbox
            }
            return label.isSystem && !smartInboxLabels.contains(label.labelId)
        }
    }

    func updateSelectedStatus() {
        guard let currentVMs = try? self.tagModels.value() else { return }
        tagModels.onNext(currentVMs)
    }

    func refresh() {
        guard didAppear else {
            return
        }
        updateDatasource(self.labels)
//        guard var currentVMs = try? self.tagModels.value(), currentVMs.first != nil else { return }
//        let systemSection = MailTagSection(header: smartInboxEnable() ? "System Label" : "", items: processSystemLabel(labels))
//        currentVMs[0] = systemSection
//        tagModels.onNext(currentVMs)
    }
}

extension MailTagViewModel: MailApmHolderAble {
    static func createStartedApmRefresh() -> MailAPMEvent.LabelListLoaded {
        let event = MailAPMEvent.LabelListLoaded()
        event.commonParams.append(MailAPMEvent.LabelListLoaded.CommonParam.sence_reload)
        event.markPostStart()
        return event
    }

    static func endApmEvent(event: MailAPMEvent.LabelListLoaded,
                            status: MailAPMEventConstant.CommonParam) {
        event.endParams.append(status)
        event.postEnd()
    }

    func apmMarkColdStart() {
        let event = MailAPMEvent.LabelListLoaded()
        event.commonParams.append(MailAPMEvent.LabelListLoaded.CommonParam.sence_cold_start)
        event.markPostStart()
        apmHolder[MailAPMEvent.LabelListLoaded.self] = event
    }

    func apmMarkRefresh() {
        let event = MailAPMEvent.LabelListLoaded()
        event.commonParams.append(MailAPMEvent.LabelListLoaded.CommonParam.sence_reload)
        event.markPostStart()
        apmHolder[MailAPMEvent.LabelListLoaded.self] = event
    }

    func apmMarkLoadEnd(status: MailAPMEventConstant.CommonParam, error: Error? = nil) {
        guard let event = apmHolder[MailAPMEvent.LabelListLoaded.self] else {
            // assert(false, "no event started before end called. review you code")
            MailAPMMonitorService.offTrack(event: MailAPMEventConstant.EndKey.labelListLoaded,
                                           type: .type_launch_without_start, message: nil)
            return
        }
        event.endParams.append(status)
        event.endParams.appendError(errorCode: error?.mailErrorCode, errorMessage: error?.getMessage())
        event.postEnd()
    }

}
