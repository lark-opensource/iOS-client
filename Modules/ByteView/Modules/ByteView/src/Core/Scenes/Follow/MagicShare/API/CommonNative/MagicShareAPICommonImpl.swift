//
//  MagicShareAPICommonImpl.swift
//  ByteView
//
//  Created by chentao on 2020/4/20.
//

import Foundation
import RxSwift
import ByteViewNetwork

class MagicShareAPICommonImpl: MagicShareAPI {

    static let logger = Logger.vcFollow
    private static let stateKey: String = "stateKey"
    private static let idKey: String = "id"
    let disposeBag = DisposeBag()
    /// 日志额外信息
    lazy var metadataDes: String = {
        return "magic share api \(address(of: self)) "
    }()
    /// CCM文档API实例
    var followAPI: FollowDocument
    /// 前端展示的策略
    var strategy: FollowStrategy
    /// 文档API状态变化代理
    weak var delegate: MagicShareAPIDelegate?
    /// 需要注入的resources
    let resources: PublishSubject<[FollowResource]> = PublishSubject()
    /// 已经注入过的js资源id列表
    var injectedResources: [String] = []
    // 注入JS成功的回调
    let injectJSCompletion: ((TimeInterval) -> Void)
    // 注入STG成功的回调
    let injectStrategiesCompletion: ((TimeInterval) -> Void)
    /// 有效FollowEvent，其余事件不注册
    let validFollowEvent: [FollowEvent] = [.newAction, .newPatches, .presenterFollowerLocation, .relativePositionChange, .track, .firstPositionChangeAfterFollow, .magicShareInfo]
    var httpClient: HttpClient { service.httpClient }
    let service: MeetingBasicService
    // MARK: - 生命周期方法

    init(service: MeetingBasicService,
         followAPI: FollowDocument,
         strategy: FollowStrategy,
         sender: String,
         injectJSCompletion: @escaping ((TimeInterval) -> Void),
         injectStrategiesCompletion: @escaping ((TimeInterval) -> Void)) {
        self.service = service
        self.followAPI = followAPI
        self.strategy = strategy
        self.sender = sender
        self.injectJSCompletion = injectJSCompletion
        self.injectStrategiesCompletion = injectStrategiesCompletion
        // ccm google native api delegate
        followAPI.setDelegate(self)
        debugLog(message: "init with strategy:\(strategyID), and sender:\(sender)")
        bindResources()
        // 初始化拉去resources
        updateStrategyResources()
    }

    deinit {
        debugLog(message: "deinit strategy:\(strategyID)")
        let api = self.followAPI
        Util.runInMainThread {
            // followAPI里有UIViewController相关的内容，这里是保护followAPI对象在主线程释放
            _ = api
        }
    }

    // MARK: - 实现MagicShareAPI

    var documentUrl: String {
        return followAPI.followUrl
    }

    var documentTitle: String {
        return followAPI.followTitle
    }

    var documentVC: UIViewController {
        return followAPI.followVC
    }

    var contentScrollView: UIScrollView? {
        return followAPI.scrollView
    }

    var canBackToLastPosition: Bool {
        return followAPI.canBackToLastPosition
    }

    var isEditing: Bool {
        return followAPI.isEditing
    }

    var sender: String

    func updateSettings(_ settings: String) {
    }

    func updateStrategies(_ strategies: [FollowStrategy]) {
        guard let stg = strategies.first else {
            return
        }
        debugLog(message: "update to strategy:\(strategyID)")
        self.strategy = stg
        // 更新resources
        updateStrategyResources()
    }

    func startRecord() {
        followAPI.startRecord()
    }

    func stopRecord() {
        followAPI.stopRecord()
    }

    func startFollow() {
        followAPI.startFollow()
    }

    func stopFollow() {
        followAPI.stopFollow()
    }

    func reload() {
        followAPI.reload()
    }

    func setStates(_ states: [FollowState], uuid: String?) {
        applyStatesForStrategies(states: states, uuid: uuid)
    }

    func applyPatches(_ patches: [FollowPatch]) {
        applyPatchesForStrategies(patches: patches)
    }

    func getState(callBack: @escaping MagicShareStatesCallBack) {
        debugLog(message: "begin get states")
        followAPI.getState { [weak self] (followStates, metaJson) in
            guard let `self` = self else {
                callBack([], nil)
                return
            }
            self.debugLog(message: "end get states, count:\(followStates.count)")
            if let vcFollowStates = self.generateFollowSyncDatas(from: followStates,
                                                                 metaJson: metaJson,
                                                                 syncFollowDataType: .state) as? [FollowState],
               !vcFollowStates.isEmpty {
                callBack(vcFollowStates, metaJson)
            } else {
                Logger.vcFollow.warn("getState failed, generateFollowSyncDatas got invalid result")
                callBack([], nil)
            }
        }
    }

    func setDelegate(_ delegate: MagicShareAPIDelegate) {
        self.delegate = delegate
    }

    func returnToLastLocation() {
        if service.setting.isMSBackToLastLocationEnabled {
            debugLog(message: "callFollowAPI: .backToLastPosition")
            followAPI.backToLastPosition()
        }
    }

    func clearStoredLocation(_ token: String?) {
        if service.setting.isMSBackToLastLocationEnabled {
            debugLog(message: "callFollowAPI: .clearLastPosition, withToken: \(token != nil ? true : false)")
            followAPI.clearLastPosition(token)
        }
    }

    func storeCurrentLocation() {
        if service.setting.isMSBackToLastLocationEnabled {
            debugLog(message: "callFollowAPI: .keepCurrentPosition")
            followAPI.keepCurrentPosition()
        }
    }

    func updateOperations(_ operations: String) {
        debugLog(message: "updateOperations, operations.hash: \(operations.hash)")
        followAPI.updateOptions(operations)
    }

    func willSetFloatingWindow() {
        followAPI.willSetFloatingWindow()
    }

    func finishFullScreenWindow() {
        followAPI.finishFullScreenWindow()
    }

    func updateContext(_ context: String) {
        debugLog(message: "updateContext, context.hash: \(context.hash)")
        followAPI.updateContext(context)
    }

    func invoke(funcName: String,
                paramJson: String?,
                metaJson: String?) {
        followAPI.invoke(funcName: funcName,
                         paramJson: paramJson,
                         metaJson: metaJson)
    }

    func replaceWithEmptyFollowAPI() {
        followAPI = PlaceHolderFollowAPIImpl()
    }
}

// MARK: - 应用或同步FollowState/FollowPatch

extension MagicShareAPICommonImpl {

    var strategyID: String {
        return strategy.id
    }

    // MARK: - FollowState

    /// 应用远端发送的FollowState
    /// - Parameters:
    ///   - states: 妙享全量同步数据
    ///   - uuid: 本地依靠时间戳生成的uuid数据，在应用成功率的监控中使用
    private func applyStatesForStrategies(states: [FollowState], uuid: String?) {
        // 只应用相同策略产生的数据
        let validWebDatas = states.validWebDatas()
            .filter({ $0.strategyID == strategyID })
        debugLog(message: "apply valid states count: \(validWebDatas.count) uuid: \(uuid)")
        guard !validWebDatas.isEmpty else {
            return
        }
        let meta = "{\"uuid\":\"\(uuid)\"}"
        followAPI.setState(states: validWebDatas.map({ $0.payload }), meta: meta)
    }

    /// 上传本地的FollowState到远端
    /// - Parameters:
    ///   - states: 妙享全量同步数据
    ///   - metaJson: 本地前端模块生成的补充数据，含ID与StateKey
    func syncFollowStates(_ states: [String], metaJson: String?) {
        let action = getStrategyGrootAction()
        let followStatesCreateTime = Date().timeIntervalSince1970
        debugLog(message: "sync states count:\(states.count) with groot action:\(action)")
        if let vcFollowStates = generateFollowSyncDatas(from: states, metaJson: metaJson, syncFollowDataType: .state) as? [FollowState] {
            delegate?.magicShareAPI(self, onStates: vcFollowStates, grootAction: action, createTime: followStatesCreateTime)
        }
    }

    // MARK: - FollowPatch

    /// 应用远端发送的FollowPatch
    /// - Parameter patches: 妙享增量同步数据
    private func applyPatchesForStrategies(patches: [FollowPatch]) {
        let validWebDatas = patches.validWebDatas()
            .filter { $0.strategyID == strategyID }
        debugLog(message: "apply valid patches count:\(patches.count)")
        guard !validWebDatas.isEmpty else {
            return
        }
        let now = Date().timeIntervalSince1970 * 1000
        let uuid = "\(now)"
        let meta = "{\"uuid\":\"\(uuid)\"}"
        followAPI.setState(states: validWebDatas.map { $0.payload }, meta: meta)
    }

    /// 上传本地的FollowPatch到远端
    /// - Parameters:
    ///   - patches: 妙享增量同步数据
    ///   - metaJson: 本地前端模块生成的补充数据，含ID与StateKey
    func syncFollowPatches(_ patches: [String], metaJson: String?) {
        let action = getStrategyGrootAction()
        debugLog(message: "sync patches count: \(patches.count) with groot action: \(action)")
        if let vcFollowPatches = generateFollowSyncDatas(from: patches, metaJson: metaJson, syncFollowDataType: .patch) as? [FollowPatch] {
            delegate?.magicShareAPI(self, onPatches: vcFollowPatches, grootAction: action)
        }
    }

    private func getStrategyGrootAction() -> GrootCell.Action {
        let stg = strategy
        return stg.keepOrder ? .clientReq : .trigger
    }

    /// 生成[FollowState]或[FollowPatch]
    /// - Parameters:
    ///   - datas: 妙享同步信息的原始数据
    ///   - metaJson: 本地前端模块生成的补充数据，含ID与StateKey
    ///   - syncFollowDataType: FollowState或FollowPatch
    /// - Returns: [FollowState]或[FollowPatch]
    private func generateFollowSyncDatas(from rawDatas: [String],
                                         metaJson: String?,
                                         syncFollowDataType: MagicShareFollowSyncDataType) -> [FollowSyncDataGenerable] {
        let sender = self.sender
        let stgID = self.strategyID

        guard let metaJsonData = metaJson?.data(using: .utf8),
              let metaJsonObjectArray = try? JSONDecoder().decode([MagicShareMetaJsonObject].self, from: metaJsonData),
              metaJsonObjectArray.count == rawDatas.count else {
            Logger.vcFollow.warn("invalid metaJson, patch is ignored")
            return []
        }
        return zip(metaJsonObjectArray, rawDatas).map { (metaJsonObject: MagicShareMetaJsonObject, rawData: String) -> FollowSyncDataGenerable in
            switch syncFollowDataType {
            case .state:
                return FollowState(sender: sender,
                                   dataType: .followWebData,
                                   stateKey: metaJsonObject.stateKey,
                                   webData: FollowWebData(id: metaJsonObject.id,
                                                          strategyID: stgID,
                                                          payload: rawData))
            case .patch:
                return FollowPatch(sender: sender,
                                   opType: .appendType,
                                   dataType: .followWebData,
                                   stateKey: metaJsonObject.stateKey,
                                   webData: FollowWebData(id: metaJsonObject.id,
                                                          strategyID: stgID,
                                                          payload: rawData))
            }
        }
    }

}

extension MagicShareAPICommonImpl {

    func debugLog(message: String) {
        MagicShareAPICommonImpl.logger.debug("\(metadataDes): \(message)")
    }

}
