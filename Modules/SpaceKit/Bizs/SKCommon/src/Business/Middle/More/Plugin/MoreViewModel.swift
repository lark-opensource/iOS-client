//
//  MoreViewModel.swift
//  SKCommon
//
//  Created by lizechuang on 2021/2/25.
//

import SKFoundation
import RxSwift
import RxCocoa
import SwiftyJSON

import SKResource
import SpaceInterface
import SKInfra

public typealias DismissCompletion = (() -> Void)
public final class MoreViewModel {
    // input
    public let clickAction = PublishRelay<(item: ItemsProtocol, isSwitchOn: Bool, style: MoreViewV2RightButtonCell.Style?)>() // 点击事件
    // BTW: 为什么reading有两个数据源，旧逻辑同时使用前端回调数据以及前端回调数据作为数据源
    public let readingDataReceived = PublishRelay<[ReadingPanelInfo]>()
    public lazy var showOnboardingEnd: Driver<(action: String, success: Bool)> = {
        showOnboardingEndCall.asDriver(onErrorJustReturn: (action: "", success: false))
    }()

    // output
    // 更新More面板的标题栏
    lazy var docsInfosUpdated: Observable<DocsInfo?> = {
        if docsInfo.isShortCut {
            // 通过 meta 接口拿到的是本体名字，不是 shortcut 名字，这里跳过更新
            // 后续此接口有其他用处时，需要考虑对 shortcut 名字的影响
            return .never()
        }
        let params: [String: Any] = ["type": docsInfo.type.rawValue,
                                     "token": docsInfo.objToken]
        return DocsRequest<JSON>(path: OpenAPI.APIPath.findMeta, params: params)
            .set(method: .GET)
            .rxStart()
            .map({ [weak self] (result) -> DocsInfo? in
                guard let self = self else {
                    DocsLogger.info("Request DocsInfo error: self is dealloc")
                    return nil
                }
                if let title = result?["data"]["title"].string {
                    self.docsInfo.title = title
                }
                // wiki目录树下无法传入ownerName，在请求时更新获取一次
                if let ownerName = result?["data"]["owner_user_name"].string {
                    self.docsInfo.ownerName = ownerName
                }
                if let data = result {
                    let aliasInfo = UserAliasInfo(json: data["data"]["owner_user_display_name"])
                    self.docsInfo.ownerAliasInfo = aliasInfo
                }
                return self.docsInfo
            })
            .asObservable()
    }()

    var readingDataRequest: ReadingDataRequest?

    // 更新reading数据
    lazy var readingDataUpdated: Observable<MoreReadingDataInfo> = {
        _readingDataUpdate.asObservable()
    }()
    lazy var dataSourceUpdated: Driver<[MoreSection]> = {
        _dataUpdate.asObservable().asDriver(onErrorJustReturn: [])
    }()

    lazy var dismissAction: Driver<DismissCompletion> = {
        _dismissAction.asObservable().asDriver(onErrorJustReturn: {})
    }()

    private let _dataUpdate = PublishSubject<[MoreSection]>()

    private let _readingDataUpdate = PublishSubject<MoreReadingDataInfo>()

    private let _dismissAction = PublishSubject<DismissCompletion>()

    let showOnboardingEndCall = PublishSubject<(action: String, success: Bool)>()

    private(set) var dataProvider: MoreDataProvider

    private(set) var dataSource: [MoreSection]

    private(set) var readingDataInfo: MoreReadingDataInfo = MoreReadingDataInfo(readingCount: nil, wordCount: nil)

    let bag = DisposeBag()

    // 暂时还是使用docsInfo作为MoreInfo来源，部分逻辑无法完全抽离
    // todo: 后续完全去除
    var docsInfo: DocsInfo

    var onboardingConfig: MoreOnboardingConfig?
    // 用于列表点击more面板的埋点上报
    var moreItemClickTracker: ListMoreItemClickTracker?
    // 用于透传给业务方按需展示 UI 用
    weak var hostController: UIViewController?

    public init(dataProvider: MoreDataProvider,
                docsInfo: DocsInfo,
                onboardingConfig: MoreOnboardingConfig? = nil,
                moreItemClickTracker: ListMoreItemClickTracker? = nil) {
        self.dataProvider = dataProvider
        self.dataSource = dataProvider.builder.build()
        self.docsInfo = docsInfo
        self.onboardingConfig = onboardingConfig
        self.moreItemClickTracker = moreItemClickTracker
        self.dataProvider.updater = { [weak self] builder in
            self?._dataUpdate.onNext(builder.build())
        }
    }

    public func setup() {
        self.setupInput()
        self.setupDataForStatistics()
        self.loadReadingData()
    }

    private func setupInput() {
        // 上报
        clickAction.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (item: ItemsProtocol, isSwitchOn: Bool, style: MoreViewV2RightButtonCell.Style?) in
                guard let self = self else { return }
                let hostController = self.hostController
                // enable, disable, isSwitchOn 都在外部闭包中自行处理
                if !item.style.isSwitch && item.state.isEnable && !item.shouldPreventDismissal { // 正常场景需要dismiss
                    self._dismissAction.onNext { [weak hostController] in
                        item.handler(item, isSwitchOn, hostController, style)
                    }
                } else { // 默认mSwitch无需dismiss，disable也无需dismiss
                    item.handler(item, isSwitchOn, hostController, style)
                }
                // 集中处理红点
                if item.needNewTag {
                    item.removeNewTagMarkWith(self.docsInfo.type)
                }
                self.reportActionWith(type: item.type)
            }).disposed(by: bag)

        readingDataReceived.observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (data) in
                guard let self = self else {
                    return
                }
                if self.docsInfo.isShortCut {
                    // 如果是 shortcut，不关心阅读数据，直接忽略掉
                    return
                }
                var readingCount: String?
                var wordCount: String?
                // 为了不写死顺序
                for panelInfo in data {
                    for info in panelInfo.info {
                        if info.type == .readingTimer, info.detail != ReadingDataRequest.loadingToken {
                            readingCount = info.detail
                        }

                        if info.type == .wordNumber, info.detail != ReadingDataRequest.loadingToken {
                            wordCount = info.detail
                        }
                    }
                }
                if let readingCount = readingCount {
                    self.readingDataInfo.readingCount = readingCount
                }
                if let wordCount = wordCount {
                    self.readingDataInfo.wordCount = wordCount
                }
                self._readingDataUpdate.onNext(self.readingDataInfo)
            }).disposed(by: bag)
    }

    private func loadReadingData() {
        readingDataRequest = ReadingDataRequest(docsInfo)
        readingDataRequest?.dataSource = self
        readingDataRequest?.request()
    }
}
/// 请求阅读量回来之后的回调方法
extension MoreViewModel: ReadingDataFrontDataSource {
    public func requestData(request: ReadingDataRequest, docs: DocsInfo, finish: @escaping (ReadingInfo) -> Void) {
        // do nothing
    }

    // 请求阅读数据的回调
    public func requestRefresh(info: DocsReadingData?, data: [ReadingPanelInfo], avatarUrl: String?, error: Bool) {
        guard !data.isEmpty, !error else {
            self._readingDataUpdate.onError(ReadingDataError.reuestError)
            return
        }
        var readingCount: String?
        var wordCount: String?
        // 为了不写死顺序
        for panelInfo in data {
            for info in panelInfo.info {
                if info.type == .readingTimer, info.detail != ReadingDataRequest.loadingToken {
                    readingCount = info.detail
                }

                if info.type == .wordNumber, info.detail != ReadingDataRequest.loadingToken {
                    wordCount = info.detail
                }
            }
        }
        if let readingCount = readingCount {
            self.readingDataInfo.readingCount = readingCount
        }
        if let wordCount = wordCount {
            self.readingDataInfo.wordCount = wordCount
        }
        self._readingDataUpdate.onNext(self.readingDataInfo)
    }
}

// Action
extension MoreViewModel {
    private func setupDataForStatistics() {
        FileListStatistics.source = .innerpageMore
        FileListStatistics.curFileObjToken = self.docsInfo.objToken
        FileListStatistics.curFileType = self.docsInfo.type
    }

    // report
    private func reportActionWith(type: MoreItemType) {
        FileListStatistics.curFileObjToken = self.docsInfo.objToken
        FileListStatistics.curFileType = self.docsInfo.type
        self.addReportForClickItem(actionType: type)
        if let tracker = moreItemClickTracker {
            /// 外部的more面板的点击事件埋点通过该方法上报
            self.listReportForClickItem(actionType: type, clickTracker: tracker)
        } else {
            self.newReportForClickItem(actionType: type)
        }
    }
    
}

public struct ListMoreItemClickTracker {
    var isShareFolder: Bool
    var type: DocsType
    var originInWiki: Bool
    var isBitableHome: Bool = false
    var subModule: HomePageSubModule?

    public init(isShareFolder: Bool, type: DocsType, originInWiki: Bool) {
        self.isShareFolder = isShareFolder
        self.type = type
        self.originInWiki = originInWiki
    }

    public mutating func setIsBitableHome(_ value: Bool) {
        isBitableHome = value
    }
    
    public mutating func setSubModule(_ subModule: HomePageSubModule) {
        self.subModule = subModule
    }
}
