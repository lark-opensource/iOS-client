//
//  MailHomePreloader.swift
//  MailSDK
//
//  Created by tefeng liu on 2022/3/22.
//

import Foundation
import RxRelay
import RustPB
import LKCommonsLogging
import RxSwift
import LarkFeatureGating
import LarkContainer

/// MailHomeViewModel可以接受的预加载数据
struct HomePreloadableData {
    let preloadedLabel: MailFilterLabelCellModel
    let preloadedLabels: [MailFilterLabelCellModel]
    let preloadedListCellViewModels: [MailThreadListCellViewModel]
    let isLastPage: Bool
}

enum MailPreloadStatus {
    case none
    case preloading
    case preloaded
    case preloadFail
    case noNeed
}

class MailHomePreloader {
    let logger = Logger.log(MailHomePreloader.self, category: "Module.Mail")

    let disposeBag = DisposeBag()

    var listDisposeBag = DisposeBag()

    let resolver: UserResolver

    // MARK: Property
    var preloadStatus = BehaviorRelay<MailPreloadStatus>(value: .none) {
        didSet {
            preloadAPMReport(preloadStatus.value)
        }
    }
    private var threadListCellViewModels: [MailThreadListCellViewModel] = []
    private var preloadLabel: MailFilterLabelCellModel?
    private var preloadLabels: [MailFilterLabelCellModel]?
    private var isLastPage: Bool = false
    private var isFromDb: Bool = false

    private var preloadedHomeViewModel: MailHomeViewModel?

    // MARK: Temp
    var preloadEnable: Bool = false

    private func preloadAPMReport(_ status: MailPreloadStatus) {
        switch status {
        case .preloading:
            MailTracker.log(event: "mail_home_idle_preload_dev", params: ["event": "start"])
        case .preloaded:
            MailTracker.log(event: "mail_home_idle_preload_dev", params: ["event": "preloaded"])
        default:
            break
        }
    }

    private func needToPreload() -> Bool {
        let status = preloadStatus.value
        switch status {
        case .preloading, .preloaded, .noNeed, .preloadFail:
            return false
        case .none:
            return true
        }
    }

    // MARK: life circle
    init(resolver: UserResolver) {
        self.resolver = resolver
        preloadStatus.subscribe(onNext: { [weak self] status in
            guard let self = self else { return }
            switch status {
            case .preloaded:
                if let data = self.generatePreloadData(),
                   let userContext = try? self.resolver.resolve(type: MailUserContext.self)
                {
                    self.preloadedHomeViewModel = MailHomeViewModel
                        .createPreloadedViewModel(data: data, userContext: userContext)
                    self.preloadedHomeViewModel?.isPreloadedData = true
                }
            case .preloadFail:
                self.cleanPreloadData()
            default: break
            }
        }).disposed(by: disposeBag)
    }

    /// 去掉了side effect，纯计算方法
    private func startupInfo(_ setting: Email_Client_V1_Setting,
                             labels: [MailFilterLabelCellModel]) -> (String, Bool, MailFilterLabelCellModel?) {
        var initLabelId = Mail_LabelId_Inbox
        /// 判断是否开启了 smartInbox
        var smartInboxEnable = false
        let labelIds = labels.map({ $0.labelId })
        let labelListFgDataError = !(labelIds.contains(Mail_LabelId_Important) && labelIds.contains(Mail_LabelId_Other))
        if setting.smartInboxMode, !labelListFgDataError {
            smartInboxEnable = true
            MailLogger.info("[mail_init] [mail_preload] smartInboxModeEnable")
        }
        if smartInboxEnable, FeatureManager.open(.aiBlock) {
            MailLogger.info("[mail_init] [mail_preload] aiBlock smartInboxModeEnable set false")
            smartInboxEnable = false
        }

        if smartInboxEnable {
            initLabelId = Mail_LabelId_Important
        } else {
            let firstLabel = labels.first(where: { !smartInboxLabels.contains($0.labelId) && $0.tagType == .label && $0.labelId != Mail_LabelId_Outbox })
            initLabelId = firstLabel?.labelId ?? Mail_LabelId_Inbox
        }
        let label = labels.first(where: { $0.labelId == initLabelId })
        return (initLabelId, smartInboxEnable, label)
    }

    /// 这一步是为了拉取对应label下的allMail，只为预加载服务，所以去掉了很多奇怪的逻辑。
    private func preLoadListFromLocal(label: String) {
        // 从Rust层拉取数据 From DB/Serve
        var data: String = ""
        let listLength: Int64 = 20
        Store.fetcher?.getThreadListFromLocal(timeStamp: 0,
                                       labelId: label,
                                       filterType: .allMail,
                                       length: listLength).subscribe(onNext: { [weak self] (result) in
            guard let `self` = self else { return }
            data = result.threadItems.first?.thread.id ?? ""
            let isLastPage = result.isLastPage
            let newThreadsList = result.threadItems.map { (MailThreadListCellViewModel(with: $0, labelId: label, userID: self.resolver.userID)) }
            self.isFromDb = result.isFromDb
            ///  if should clear thread list, replace with new thread list
            self.logger.info("preLoadListFromLocal has renew label: \(label) timeStamp: \(0) items count: \(newThreadsList.count) isLastPage: \(isLastPage)")
            /// update new threads list
            self.threadListCellViewModels = newThreadsList
            self.logger.info("preLoadListFromLocal success label: \(label) timeStamp: \(0) items count: \(newThreadsList.count) isLastPage: \(isLastPage)")
            self.isLastPage = isLastPage
            self.preloadStatus.accept(.preloaded)
        }, onError: { [weak self] (error) in
            guard let self = self else { return }
            // 数据重置一下，别乱搞
            self.threadListCellViewModels = []
            self.isLastPage = false
            self.isFromDb = false
            self.logger.error("preLoadListFromLocal failed label: \(label) timeStamp: \(0) ", error: error)
            self.preloadStatus.accept(.preloadFail)
        }).disposed(by: listDisposeBag)
    }

    private func generatePreloadData() -> HomePreloadableData? {
        guard preloadStatus.value == .preloaded, let label = preloadLabel, let labels = preloadLabels else {
            return nil
        }
        return HomePreloadableData(preloadedLabel: label,
                                   preloadedLabels: labels,
                                   preloadedListCellViewModels: threadListCellViewModels,
                                   isLastPage: isLastPage)
    }

    private func cleanPreloadData() {
        self.preloadLabel = nil
        self.preloadLabels = nil
        self.isLastPage = false
        self.preloadedHomeViewModel = nil
        self.isFromDb = false
    }
}

// MARK: interface
extension MailHomePreloader {
    func consumeViewModelIfNeeded() -> MailHomeViewModel? {
        guard preloadStatus.value == .preloaded, let vm = preloadedHomeViewModel else {
            // 赶不上使用了，统统报废吧
            self.preloadStatus.accept(.none)
            self.listDisposeBag = DisposeBag()
            self.cleanPreloadData()
            return nil
        }

        cleanPreloadData()
        return vm
    }
}

// MARK: BootManager
extension MailHomePreloader: BootObserver {
    // 为了同步之前preload参数的逻辑
    func beforeInitMail() {
        preloadEnable = (try? resolver.resolve(assert: FeatureSwitchProxy.self))?.getFeatureBoolValue(for: "larkmail.cli.home.preload_with_unread_mail") == true && !MailSettingManagerInterface.mailClient
        self.logger.info("[mail_preload] - 预加载时机开始 ---------- \(preloadEnable)")
    }

    func didLoadSetting(_ setting: Email_Client_V1_Setting) {
        if preloadEnable && needToPreload() && !MailSettingManagerInterface.mailClient {
            // 预加载Thread List
            preloadStatus.accept(.preloading)
            MailDataSource.shared.getLabelsFromDB().subscribe(onNext: { [weak self] (labels) in
                guard let self = self else { return }
                self.preloadLabels = labels
                self.logger.debug("[mail_preload] getLabels labels count: \(labels.count)")
                let startupInfo = self.startupInfo(setting, labels: labels)
                self.preloadLabel = startupInfo.2
                self.logger.debug("[mail_preload] getLabels startupInfo initLabel: \(startupInfo.0)")
                self.preLoadListFromLocal(label: startupInfo.0)
            }, onError: { [weak self] (error) in
                self?.logger.debug("[mail_preload] getLabels error: \(error)")
                self?.preloadStatus.accept(.preloadFail)
            }).disposed(by: listDisposeBag)
        }
    }
}
