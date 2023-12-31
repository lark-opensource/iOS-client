//
//  MagicShareRuntimeImpl.swift
//  ByteView
//
//  Created by chentao on 2020/4/13.
//

import Foundation
import RxSwift
import RxCocoa
import ByteViewNetwork

final class MagicShareRuntimeImpl: MagicShareRuntime, InMeetMeetingProvider {

    static let logger = Logger.vcFollow
    /// p侧自动同步States的时间间隔
    lazy var autoSyncTimeInterval: Int = 5
    /// 超过此值，不再触发更新参会人数量，直到数量降至此数量之下
    private static let updateParticipantMaxCount: Int = 10
    /// UC计时器同步Context的时间间隔为5分钟
    private static let updateContextTimerInterval: TimeInterval = 300.0
    /// 投屏转妙享，应用位置数据的方法名
    private static let forceApplyStatesKey: String = "forceSetState"
    /// 常驻型 bag
    let disposeBag = DisposeBag()
    /// reload时会 dispose型 bag
    var refreshDisposeBag = DisposeBag()
    /// 日志额外信息
    lazy var metadataDes: String = {
        return "magic share runtime \(address(of: self)) "
    }()
    /// 发送人信息，格式为“-[userId]-[deviceId]”
    var sender: String = ""
    /// 文档内部跟随状态流转状态机
    lazy var logic: MagicShareRuntimeLogic = {
        return self.createAutomatonLogic()
    }()
    /// 文档内部跟随状态变化入口
    let logicInputSubject = PublishSubject<MagicShareRuntimeLogic.Input>()
    /// 文档API
    lazy var magicShareAPI: MagicShareAPI = {
        return self.createMagicShareAPI(
            magicShareDocument: self.magicShareDocument,
            followAPIFactory: self.followAPIFactory)
    }()
    /// 传递FollowStates的改变
    let vcFollowStatesSubject: PublishSubject<[FollowState]> = PublishSubject()
    /// 传递FollowPatches的改变
    let vcFollowPatchesSubject: PublishSubject<[FollowPatch]> = PublishSubject()
    /// 标记文档是否加载完成
    let followDidRenderFinishRelay: BehaviorRelay<Bool>
    /// 标记文档是否加载完成
    var followDidRenderFinishObservable: Observable<Bool> {
        return followDidRenderFinishRelay.asObservable()
    }
    /// 传递用户点击的改变，如点击链接
    let userOperationSubject: PublishSubject<MagicShareOperation> = PublishSubject()
    /// 从哪种场景中创建/更新Runtime
    var createSource: MagicShareRuntimeCreateSource
    /// 应用是否处于前台
    let isApplicationActiveSubject = PublishSubject<Bool>()
    /// 视频会议是否处于小窗
    let isVideoConferenceFloatingSubject = BehaviorSubject<Bool>(value: false)
    /// UC计时器，didReady开始每隔5分钟同步1次Context，shareID改变时刷新计时器
    private var updateContextTimer: Timer?
    /// 是否应在收到“首次位置变化”时进行上报
    var shouldUploadOnFirstPositionChange: Bool = true
    /// 记录上次主/被共享人位置的相对方向
    var lastDirection: MagicShareDirectionViewModel.Direction?
    /// Runtime代理，用于抛出用户操作等事件
    weak var magicShareDelegate: MagicShareRuntimeDelegate?
    /// 文档变动代理，用于小窗时抛出文档标题变化事件
    weak var documentChangeDelegate: MagicShareDocumentChangeDelegate?

    // MARK: - 初始化依赖

    /// 文档数据实体
    var magicShareDocument: MagicShareDocument
    /// 文档API工厂
    let followAPIFactory: FollowDocumentFactory

    // MARK: - Groot通道

    /// Groot的Session
    var grootSession: FollowGrootSession?
    /// 初始时打开groot需要的起始版本
    let downVersionSubject: PublishSubject<Int32?> = PublishSubject()
    /// groot通道推送的Follow数据下行数据
    let grootCellPayloadsSubject: PublishSubject<FollowGrootCell> = PublishSubject()
    /// 通道打开状态
    var grootChannelOpened = false

    // MARK: - 启动时间统计

    /// 启动时间
    var timeIntervalWhenOpened: TimeInterval = Date().timeIntervalSince1970
    /// Webview 触发 document ready 的时间
    var timeIntervalDocCreate: TimeInterval = Date().timeIntervalSince1970
    /// jssdk 注入完成的时间
    var timeIntervalJSSdkReady: TimeInterval = Date().timeIntervalSince1970
    /// strategies 准备完成的时间
    var timeIntervalInjectStrategies: TimeInterval = Date().timeIntervalSince1970
    /// 发起者第一次发出 Action 或被共享人第一次收到 Action
    var timeIntervalRuntimeInit: TimeInterval?
    /// 开始加载webView的时间
    var timeIntervalWebViewStartLoading: TimeInterval = Date().timeIntervalSince1970
    /// 开始开启Groot通道的时间
    var timeIntervalGrootChannelOpen: TimeInterval = Date().timeIntervalSince1970
    /// 发送/接收followStates的耗时记录
    var followStatesTimeCost: [Double] = []

    // MARK: - 回到上次位置

    /// 加载完成后回到上次记录的位置
    private var returnToLastLocationOnReady: Bool = false
    /// 加载完成后清理记录的位置
    private var clearLastLocationOnReady: Bool = false
    /// 加载完成后记录当前位置
    private var storeCurrentLocationOnReady: Bool = false

    // MARK: - 投屏转妙享

    /// 投屏转妙享中，是否应用过Action
    var isShareScreenToFollowActionApplied: Bool = false

    // MARK: - 当前会议/通话中参会人数量

    /// 当前会中的参会人数量，同步给CCM，做pad上的展示异化
    private var participantsCount: Int = 0 {
        didSet {
            if oldValue != participantsCount, Display.pad, participantsCount < Self.updateParticipantMaxCount {
                updateContext()
            }
        }
    }

    // MARK: - 过滤非当前sender数据

    /// 上报FollowState有效性专用线程
    private let filterInvalidFollowStateQueue = DispatchQueue(label: "byteview.magic.share.runtime.track.queue")
    /// 收到sender符合新格式的GrootCell的数量
    @RwAtomic var receivedTotalCount: Int = 0
    /// 收到sender符合新格式且被block的GrootCell数量
    @RwAtomic var receivedInvalidCount: Int = 0
    /// 上次上报的时间
    @RwAtomic var lastReportTime = NSDate().timeIntervalSince1970

    let meeting: InMeetMeeting

    // MARK: - 生命周期方法

    init(magicShareDocument: MagicShareDocument,
         meeting: InMeetMeeting,
         followAPIFactory: FollowDocumentFactory,
         delegate: MagicShareRuntimeDelegate,
         documentChangeDelegate: MagicShareDocumentChangeDelegate,
         createSource: MagicShareRuntimeCreateSource,
         participantsCount: Int) {
        self.magicShareDocument = magicShareDocument
        self.meeting = meeting
        self.followAPIFactory = followAPIFactory
        self.magicShareDelegate = delegate
        self.documentChangeDelegate = documentChangeDelegate
        self.createSource = createSource
        self.participantsCount = participantsCount
        self.followDidRenderFinishRelay = BehaviorRelay<Bool>(value: false)
        if UIApplication.shared.applicationState != .background {
            startDidReadyTimeout() // 如App位于后台，webview不会渲染，skip一次didReady的报警
        }
        magicShareAPI.setDelegate(self)
        self.router.addListener(self, fireImmediately: true)
        calculateSender()
        debugLog(message: "init with data:\(magicShareDocument)")
        bindLogic()
        bindGrootChannel()
        bindFollowStates()
        pullAllFollowStatesIfNeed()
        bindAutoSync()
        bindUserOperation()
        bindActive()
        followDidRenderFinishObservable
            .subscribe(onNext: { [weak self] (isFinish) in
                guard let self = self else { return }
                self.debugLog(message: "observable follow did render ready:\(isFinish)")
                self.didRenderFinish = isFinish
                if isFinish {
                    self.cancelDidReadyTimeout()
                    // 向CCM前端同步后端下发的strategies配置
                    for stg in self.magicShareDocument.strategies where !stg.settings.isEmpty {
                        self.magicShareAPI.updateOperations(stg.settings.addUsePatchParamIfNeeded())
                    }
                    // 向CCM同步MS相关数据
                    self.startUpdateContextTimer()
                    // 投屏转妙享，拉取最新数据并应用
                    self.pullAndApplyLatestFollowStatesIfNeeded()
                }
                if isFinish && self.clearLastLocationOnReady {
                    self.magicShareAPI.clearStoredLocation(nil)
                    self.clearLastLocationOnReady = false
                    return
                }
                if isFinish && self.returnToLastLocationOnReady {
                    self.magicShareAPI.returnToLastLocation()
                    self.returnToLastLocationOnReady = false
                }
                if isFinish && self.storeCurrentLocationOnReady {
                    self.magicShareAPI.storeCurrentLocation()
                    self.storeCurrentLocationOnReady = false
                }
            })
            .disposed(by: disposeBag)
    }

    deinit {
        reportInvalidApply()
        closeGrootChannelIfNeed()
        trackMagicShareStatus()
        stopUpdateContextTimerIfNeeded()
        // 未加载成功时，MS结束或更换了新文档的MS
        trackOnMagicShareInitFinished(dueTo: .stopBeforeInitialized)
        cancelAllMagicShareTimeouts()
        debugLog(message: "deinit")
    }

    // MARK: - 实现MagicShareRuntime

    var ownerID: ObjectIdentifier?

    var isFromRemote: Bool {
        guard let shareID = magicShareDocument.shareID,
            !shareID.isEmpty else {
            return false
        }
        return true
    }

    var documentUrl: String {
        return magicShareAPI.documentUrl
    }

    var documentTitle: String {
        return magicShareAPI.documentTitle
    }

    var documentVC: UIViewController {
        return magicShareAPI.documentVC
    }

    var contentScrollView: UIScrollView? {
        return magicShareAPI.contentScrollView
    }

    var canBackToLastPosition: Bool {
        switch documentInfo.shareSubType { // 4.8版本由VC记录，4.9及以上版本由CCM提供
        case .ccmDoc, .ccmWikiDoc:
            return true
        default:
            return false
        }
    }

    var documentInfo: MagicShareDocument {
        return magicShareDocument
    }

    /// 渲染已完成，“文档跟随状态”可以开始变化
    var didRenderFinish: Bool = false

    var isEditing: Bool {
        magicShareAPI.isEditing
    }

    var currentDocumentStatus: MagicShareDocumentStatus {
        return logic.state
    }

    /// 是否准备好做初始化埋点
    var isReadyForInitTrack: Bool = true

    func setLastDirection(_ direction: MagicShareDirectionViewModel.Direction?) {
        lastDirection = direction
    }

    func getLastDirection() -> MagicShareDirectionViewModel.Direction? {
        return lastDirection
    }

    func updateDocument(_ documentInfo: MagicShareDocument) {
        debugLog(message: "origin share id:\(magicShareDocument.shareID),begin update document:\(documentInfo)")
        // 更新数据不能完全一样，但是内容一样的
        guard documentInfo != magicShareDocument, documentInfo.hasEqualContentTo(magicShareDocument) else {
            debugLog(message: "can not update because they are same or has not same content")
            return
        }
        // 关闭上一个通道
        if documentInfo.shareID != magicShareDocument.shareID {
            debugLog(message: "share id is not same when update document and close current groot channel")
            closeGrootChannelIfNeed()
            cancelDidReadyTimeout()
        }
        // 重置文档的创建时间数据
        self.timeIntervalWhenOpened = Date().timeIntervalSince1970
        self.timeIntervalDocCreate = Date().timeIntervalSince1970
        self.timeIntervalRuntimeInit = nil
        self.isReadyForInitTrack = true
        // 覆盖文档数据
        magicShareDocument = documentInfo
        // 重新计算sender
        calculateSender()
        // 更新stg
        updateStrategy()
        pullAllFollowStatesIfNeed()
        // 重新向CCM同步MS相关数据
        refreshUpdateContextTimer()
        // 重置“首次收到位置变化”上报的标签
        shouldUploadOnFirstPositionChange = true
        // 收到followInfo时发现share_id有变化, 但是文档的doc_token等于当前正在浏览的文档, 所以不需要加载 (当前正在浏览的文档 = 自由浏览时当前正在浏览的文档或跟随中时分享的文档)
        trackOnMagicShareInitFinished(dueTo: .samePage)
    }

    func startRecord() {
        debugLog(message: "start record")
        logicInputSubject.onNext(.startRecord)
    }

    func stopRecord() {
        debugLog(message: "stop record")
        logicInputSubject.onNext(.stopRecord)
    }

    func startFollow() {
        debugLog(message: "start follow")
        logicInputSubject.onNext(.startFollow)
    }

    func stopFollow() {
        debugLog(message: "stop follow")
        logicInputSubject.onNext(.stopFollow)
    }

    func startSSToMS() {
        sstomsLog(message: "start sstoms follow")
        logicInputSubject.onNext(.startSSToMS)
    }

    func stopSSToMS() {
        sstomsLog(message: "stop sstoms follow")
        logicInputSubject.onNext(.stopSSToMS)
    }

    func reload() {
        debugLog(message: "reload")
        guard followDidRenderFinishRelay.value else {
            debugLog(message: "it is not ready when reload")
            return
        }
        pullAllFollowStatesIfNeed()
        runMethodInMainThread { [weak self] in
            self?.magicShareAPI.reload()
        }
    }

    func resetCreateSource(_ createSource: MagicShareRuntimeCreateSource) {
        self.createSource = createSource
        self.timeIntervalWhenOpened = Date().timeIntervalSince1970
        self.timeIntervalDocCreate = Date().timeIntervalSince1970
        self.timeIntervalRuntimeInit = nil
    }

    func setDelegate(_ delegate: MagicShareRuntimeDelegate) {
        self.magicShareDelegate = delegate
    }

    func setDocumentChangeDelegate(_ documentChangeDelegate: MagicShareDocumentChangeDelegate) {
        self.documentChangeDelegate = documentChangeDelegate
    }

    func setReturnToLastLocation() {
        if didRenderFinish {
            magicShareAPI.returnToLastLocation()
        } else {
            returnToLastLocationOnReady = true
        }
    }

    func setStoreCurrentLocation() {
        if didRenderFinish {
            magicShareAPI.storeCurrentLocation()
        } else {
            storeCurrentLocationOnReady = true
        }
    }

    func setClearStoredLocation() {
        if didRenderFinish {
            magicShareAPI.clearStoredLocation(nil)
        } else {
            clearLastLocationOnReady = true
        }
    }

    func willSetFloatingWindow() {
        magicShareAPI.willSetFloatingWindow()
    }

    func finishFullScreenWindow() {
        magicShareAPI.finishFullScreenWindow()
    }

    func updateParticipantCount(_ count: Int) {
        participantsCount = count
    }

    // MARK: - 发送Groot数据

    func sendGrootCell(_ cell: FollowGrootCell, action: GrootCell.Action) {
        guard let shareId = magicShareDocument.shareID else {
            return
        }
        let tag = cell.type == .states ? "states" : "patches"
        guard let session = grootSession else {
            Self.logger.error("send follow \(tag) for share id:\(shareId) and error: GrootSession is nil")
            return
        }
        session.sendCell(cell, action: action) { r in
            switch r {
            case .success:
                Self.logger.debug("send follow \(tag) for share id:\(shareId) and success")
            case .failure(let error):
                Self.logger.error("send follow \(tag) for share id:\(shareId) and error: \(error)")
            }
        }
    }

    // MARK: - 拉取最新状态
    func pullAllFollowStates(shareId: String, completion: @escaping (Result<PullAllFollowStatesResponse, Error>) -> Void) {
        let bag = self.refreshDisposeBag
        let request = PullAllFollowStatesRequest(meetingId: meetingId, breakoutRoomId: breakoutRoomId, shareId: shareId)
        httpClient.getResponse(request, options: .retry(3, owner: self.refreshDisposeBag)) { [weak self] result in
            guard let self = self, self.refreshDisposeBag === bag else { return }
            switch result {
            case .success(let resp):
                Self.logger.debug("pull all follow states for share id:\(shareId), meeting id:\(self.meetingId), and get downVersion:\(resp.downVersion) ")
            case .failure(let error):
                Self.logger.debug("pull all follow states for share id:\(shareId), meeting id:\(self.meetingId), and get error:\(error) ")
            }
            completion(result)
        }
    }

    /// 投屏转妙享，拉取最新数据并应用
    private func pullAndApplyLatestFollowStatesIfNeeded() {
        guard let shareID = self.documentInfo.shareID, documentInfo.isSSToMS else {
            return
        }
        pullAllFollowStates(shareId: shareID) { [weak self] result in
            guard let self = self, let resp = result.value else { return }
            let objArray = resp.states.map { $0.webData?.payload }
            var paramJson = ""
            objArray.forEach { (obj: String?) in
                if let validObj = obj {
                    paramJson.append(validObj)
                    paramJson.append(",")
                }
            }
            if !paramJson.isEmpty {
                paramJson.removeLast()
            }
            self.magicShareAPI.invoke(funcName: Self.forceApplyStatesKey,
                                      paramJson: paramJson,
                                      metaJson: "{\"source\":\"share_screen\"}")
        }
    }

    func replaceWithEmptyFollowAPI() {
        magicShareAPI.replaceWithEmptyFollowAPI()
    }
}

extension MagicShareRuntimeImpl {
    var isSharing: Bool {
        return currentDocumentStatus == .sharing
    }

    var isFollowing: Bool {
        return currentDocumentStatus == .following
    }

    var isFree: Bool {
        return currentDocumentStatus == .free
    }
}

extension MagicShareRuntimeImpl {
    func debugLog(message: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        MagicShareRuntimeImpl.logger.debug("\(metadataDes): \(message)", file: file, function: function, line: line)
    }

    func sstomsLog(message: String, file: String = #fileID, function: String = #function, line: Int = #line) {
        Logger.shareScreenToFollow.info("\(metadataDes): \(message)", file: file, function: function, line: line)
    }

    func runMethodInMainThread(_ block: @escaping () -> Void) {
        Util.runInMainThread {
            block()
        }
    }
}

extension MagicShareRuntimeImpl {
    private func createMagicShareAPI(magicShareDocument: MagicShareDocument,
                                     followAPIFactory: FollowDocumentFactory) -> MagicShareAPI {
            let document = magicShareDocument
            var magicShareAPI: MagicShareAPI?
            let injectJSCompletion: ((TimeInterval) -> Void) = { [weak self] JSTime in
                self?.timeIntervalJSSdkReady = JSTime
            }
            let injectStrategiesCompletion: ((TimeInterval) -> Void) = { [weak self] STGTime in
                self?.timeIntervalInjectStrategies = STGTime
            }
            if let followAPI = followAPIFactory.open(url: document.initUrl) {
                trackOnWebViewStartLoading()
                let stg = document.strategies.first ?? defaultStrategy()
                magicShareAPI = MagicShareAPICommonImpl(
                    service: service,
                    followAPI: followAPI,
                    strategy: stg,
                    sender: sender,
                    injectJSCompletion: injectJSCompletion,
                    injectStrategiesCompletion: injectStrategiesCompletion)
            }
            return magicShareAPI ?? MagicShareAPIDefaultImpl(magicShareDocument: document)
        }

    func defaultStrategy() -> FollowStrategy {
        return FollowStrategy(id: "default_ccm",
                              resourceVersions: [:],
                              settings: "",
                              keepOrder: false,
                              iosResourceIds: [])
    }

    func calculateSender() {
        let sender = "-\(account.id)-\(account.deviceId)"
        self.sender = sender
        self.magicShareAPI.sender = sender
    }
}

// MARK: - Sync MS Context
extension MagicShareRuntimeImpl {

    /// VC 将宿主环境的一些上下文同步给 CCM
    ///
    /// 同步时机包括：
    /// 1. 初始化结束时（didReady）
    /// 2. 首次上报后，每5分钟上报1次
    /// 3. FollowInfo变化后，上报1次，同时重置上一条的Timer
    /// 参考：https://bytedance.feishu.cn/docx/doxcnBumSYKjRdTsNDaOO1QeZdf
    private func updateContext() {
        httpClient.getResponse(GetNtpTimeRequest()) { [weak self] result in
            guard let self = self else {
                Logger.vcFollow.info("getNtpTime skipped, due to self is nil.")
                return
            }
            switch result {
            case .success(let rsp):
                Logger.vcFollow.debug("getNtpTime request succeeded, ntpOffset: \(rsp.ntpOffset)")
                let currentDoc = self.documentInfo
                var contextDic: [String: Any] = ["ntp_offset": rsp.ntpOffset,
                                                 "presenter_device_id": currentDoc.user.deviceId,
                                                 "presenter_user_id": currentDoc.user.id,
                                                 "presenter_user_type": currentDoc.user.type.rawValue,
                                                 "presenter_device_type": 1,
                                                 "user_id": self.account.id,
                                                 "device_id": self.account.deviceId,
                                                 "user_type": self.account.type.rawValue,
                                                 "doc_token": currentDoc.token ?? "",
                                                 "init_source": currentDoc.initSource.rawValue]
                if let shareID = currentDoc.shareID {
                    contextDic["share_id"] = shareID
                }
                if let actionUniqueID = currentDoc.actionUniqueID {
                    contextDic["action_unique_id"] = actionUniqueID
                }
                if self.participantsCount != 0 {
                    contextDic["participant_count"] = self.participantsCount
                }
                let jsonData = try? JSONSerialization.data(withJSONObject: contextDic, options: .prettyPrinted)
                if let unwrappedJSONDate = jsonData {
                    Logger.vcFollow.debug("context is valid, will call updateContext()")
                    let context = String(data: unwrappedJSONDate, encoding: .utf8) ?? ""
                    self.magicShareAPI.updateContext(context)
                } else {
                    Logger.vcFollow.info("updateContext skipped, due to context is invalid")
                }
            case .failure(let error):
                Logger.vcFollow.debug("getNtpTime request failed, error: \(error)")
            }
        }
    }

    /// 开始UC定时器，每隔5分钟同步1次
    private func startUpdateContextTimer() {
        let timer = Timer(timeInterval: Self.updateContextTimerInterval, repeats: true) { [weak self] (timer: Timer) in
            guard let self = self else {
                Logger.vcFollow.info("updateContextTimer trigger failed due to self is nil")
                timer.invalidate()
                return
            }
            self.updateContext()
        }
        RunLoop.main.add(timer, forMode: .common)
        timer.fire()
        self.updateContextTimer = timer
    }

    /// 重置UC定时器
    private func refreshUpdateContextTimer() {
        stopUpdateContextTimerIfNeeded()
        startUpdateContextTimer()
    }

    /// 停止UC定时器
    private func stopUpdateContextTimerIfNeeded() {
        self.updateContextTimer?.invalidate()
        self.updateContextTimer = nil
    }

}

extension MagicShareRuntimeImpl {

    func addTotalGrootCellsCount(_ addTotalCount: Bool, addInvalidCount: Bool) {
        filterInvalidFollowStateQueue.async { [weak self] in
            guard let self = self else {
                return
            }
            if addTotalCount {
                self.receivedTotalCount += 1
            }
            if addInvalidCount {
                self.receivedInvalidCount += 1
            }
            if NSDate().timeIntervalSince1970 - self.lastReportTime > 60 {
                self.reportInvalidApply()
            }
        }
    }

    func reportInvalidApply(with isPresenterChange: Bool = false) {
        filterInvalidFollowStateQueue.async { [weak self] in
            guard let self = self, self.receivedTotalCount > 0 else {
                return
            }
            let timeInterval = Int(NSDate().timeIntervalSince1970 - self.lastReportTime)
            let duration = (timeInterval > 60 ? 60 : timeInterval) * 1000
            MagicShareTracksV2.trackGrootCellValidStatistics(totalCount: self.receivedTotalCount,
                                                             invalidCount: self.receivedInvalidCount,
                                                             duration: duration,
                                                             isPresenterChange: isPresenterChange)
            self.lastReportTime = NSDate().timeIntervalSince1970
            self.receivedTotalCount = 0
            self.receivedInvalidCount = 0
        }
    }
}

private extension String {

    func addUsePatchParamIfNeeded() -> String {
        if let jsonData = self.data(using: .utf8),
           var jsonDic = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
            jsonDic["usePatch"] = true
            if let resultData = try? JSONSerialization.data(withJSONObject: jsonDic, options: .prettyPrinted),
               let resultString = String.init(data: resultData, encoding: .utf8) {
                return resultString
            }
        }
        Logger.vcFollow.info("add usePatch params failed")
        return self
    }

}

// MARK: - 创建MagicShareRuntime方法

extension FollowDocumentFactory {
    func createRuntime(document: MagicShareDocument,
                       meeting: InMeetMeeting,
                       delegate: MagicShareRuntimeDelegate,
                       documentChangeDelegate: MagicShareDocumentChangeDelegate,
                       createSource: MagicShareRuntimeCreateSource,
                       participantsCount: Int) -> MagicShareRuntime {
        assert(Thread.current.isMainThread)
        return MagicShareRuntimeImpl(magicShareDocument: document,
                                     meeting: meeting,
                                     followAPIFactory: self,
                                     delegate: delegate,
                                     documentChangeDelegate: documentChangeDelegate,
                                     createSource: createSource,
                                     participantsCount: participantsCount)
    }
}
