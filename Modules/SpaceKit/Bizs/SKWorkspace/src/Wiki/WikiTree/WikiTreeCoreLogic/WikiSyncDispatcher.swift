//
//  WikiSyncDispatcher.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/10/28.
//

import SKCommon
import SKFoundation
import RxSwift
import SwiftyJSON

public class WikiSyncDispatcher {

    public struct Observers {

        public let addProcessorV2: WikiAddSyncProcessorV2
        public let delProcessorV2: WikiDelSyncProcessorV2
        public let movProcessorV2: WikiMovSyncProcessorV2
        public let udeTitleProcessorV2: WikiTitleSyncProcessorV2
        public let udeNodePermProcessor: WikiNodePermissionSyncProcessor
        public let deleteSpaceProcessor: WikiDeleteSpaceSyncProcessor
        public let batchAddProcessorV2: WikiBatchAddSyncProcessorV2
        public let batchMovProcessorV2: WikiBatchMovSyncProcessorV2
        public let delMoveUpProcessor: WikiDeleteAndMoveUpSyncProcessor
        public let pinDocumentProcessor: ClipDocumentSyncStatusProcessor
        public let pinWikiSpaceProcessor: ClipWikiSpaceSyncStatusProcessor

        public let map: [String: WikiSyncProcessor]

        public init(synergyUUID: String, networkAPI: WikiTreeNetworkAPI) {
            addProcessorV2 = WikiAddSyncProcessorV2(synergyUUID: synergyUUID, networkAPI: networkAPI)
            delProcessorV2 = WikiDelSyncProcessorV2(synergyUUID: synergyUUID, networkAPI: networkAPI)
            movProcessorV2 = WikiMovSyncProcessorV2(synergyUUID: synergyUUID, networkAPI: networkAPI)
            udeTitleProcessorV2 = WikiTitleSyncProcessorV2(synergyUUID: synergyUUID, networkAPI: networkAPI)
            udeNodePermProcessor = WikiNodePermissionSyncProcessor(synergyUUID: synergyUUID, networkAPI: networkAPI)
            deleteSpaceProcessor = WikiDeleteSpaceSyncProcessor(synergyUUID: synergyUUID, networkAPI: networkAPI)
            batchAddProcessorV2 = WikiBatchAddSyncProcessorV2(synergyUUID: synergyUUID, networkAPI: networkAPI)
            batchMovProcessorV2 = WikiBatchMovSyncProcessorV2(synergyUUID: synergyUUID, networkAPI: networkAPI)
            delMoveUpProcessor = WikiDeleteAndMoveUpSyncProcessor(synergyUUID: synergyUUID, networkAPI: networkAPI)
            pinDocumentProcessor = ClipDocumentSyncStatusProcessor(synergyUUID: synergyUUID, networkAPI: networkAPI)
            pinWikiSpaceProcessor = ClipWikiSpaceSyncStatusProcessor(synergyUUID: synergyUUID, networkAPI: networkAPI)

            map = [
                "add_v3": addProcessorV2,
                "rea_v3": addProcessorV2,
                "del_v3": delProcessorV2,
                "mov_v3": movProcessorV2,
                "ude_v3": udeTitleProcessorV2,
                "ude_node_perm_v3": udeNodePermProcessor,
                "des_v3": deleteSpaceProcessor,
                "m_add_v3": batchAddProcessorV2,
                "m_mov_v3": batchMovProcessorV2,
                "del_and_mov_up_v3": delMoveUpProcessor,
                // 置顶文档目录树相关协同事件
                "pin_add_v1": pinDocumentProcessor,
                "pin_del_v1": pinDocumentProcessor,
                "pin_mov_v1": pinDocumentProcessor,
                // 置顶知识库相关协同事件
                "space_pin_add_v1": pinWikiSpaceProcessor,
                "space_pin_del_v1": pinWikiSpaceProcessor,
                "space_pin_mov_v1": pinWikiSpaceProcessor
            ]
        }

        public func send(op: String, syncData: Data) {
            map[op]?.process(syncData)
        }
    }

    private let tagPrefix = StablePushPrefix.wikiTree.rawValue
    private var pushManager: StablePushManager

    public let observers: Observers
    public let synergyUUID: String

    public init(spaceID: String, synergyUUID: String, networkAPI: WikiTreeNetworkAPI) {
        self.synergyUUID = synergyUUID
        self.observers = Observers(synergyUUID: synergyUUID, networkAPI: networkAPI)
        let tag = tagPrefix + spaceID
        let pushInfo = SKPushInfo(tag: tag,
                                  resourceType: StablePushPrefix.wikiTree.resourceType(),
                                  routeKey: spaceID,
                                  routeType: SKPushRouteType.id)
        self.pushManager = StablePushManager(pushInfo: pushInfo)
        self.pushManager.register(with: self)
        DocsLogger.info("🌲wikitree 建立协同长链")
    }

    deinit {
        pushManager.unRegister()
        DocsLogger.debug("WikiTreePushHandler deinit")
        DocsLogger.info("🌲wikitree 释放协同长链")
    }

//    func reset() {
//        DocsLogger.info("🌲wikitree 协同长链重新注册")
//        pushManager.unRegister()
//        let tag = tagPrefix + (dataBuilder?.spaceId ?? "")
//        self.pushManager = StablePushManager(tag: tag)
//        self.pushManager.register(with: self)
//    }

    // 新增节点协同
    public lazy var handleAddSyncV2: Observable<WikiServerNode> = {
        return self.observers.addProcessorV2.observable()
    }()

    public lazy var handleBatchAddSyncV2: Observable<(String, [WikiServerNode])> = {
        observers.batchAddProcessorV2.observable()
    }()

    // 移除节点协同
    public lazy var handleDeleteSyncV2: Observable<String> = {
        return self.observers.delProcessorV2.observable()
    }()

    // 删除知识库协同
    public lazy var handleDeleteSpaceSync: Observable<String> = {
        return self.observers.deleteSpaceProcessor.observable()
    }()

    // 移动节点协同
    public lazy var handleMoveSyncV2: Observable<MoveSyncResultV2> = {
        return self.observers.movProcessorV2.observable()
    }()

    public lazy var handleBatchMoveSyncV2: Observable<BatchMoveSyncResultV2> = {
        observers.batchMovProcessorV2.observable()
    }()

    public lazy var handleDeleteAndMoveUpSync: Observable<DeleteAndMoveUpSyncResult> = {
        observers.delMoveUpProcessor.observable()
    }()

    // 更新节点标题协同
    public lazy var handleNodeTitleUpdateSyncV2: Observable<WikiTreeUpdateData> = {
        return self.observers.udeTitleProcessorV2.observable()
    }()

    // 更新节点权限协同
    public lazy var handleNodePermSync: Observable<(String, WikiServerNode?)> = {
        return self.observers.udeNodePermProcessor.observable()
    }()
    
    // 置顶目录树协同
    public lazy var handlePinDocumentSync: Observable<()> = {
        return self.observers.pinDocumentProcessor.observable()
    }()
    
    // 置顶知识库协同
    public lazy var handlePinWikiSpaceSync: Observable<()> = {
        return self.observers.pinWikiSpaceProcessor.observable()
    }()
}

extension WikiSyncDispatcher: StablePushManagerDelegate {
    public func stablePushManager(_ manager: StablePushManagerProtocol,
                           didReceivedData data: [String: Any],
                           forServiceType type: String,
                           andTag tag: String) {
        dispatchData(data)
    }

    public func dispatchData(_ data: [String: Any]) {
        if let dataString = JSON(data)["body"]["data"].string,
            let jsonData = dataString.data(using: .utf8),
            let dic = try? JSON(data: jsonData) {
            DocsLogger.info("🐟🌲wikitree 收到一个op：\(dic["op"].stringValue) 的协同")
            self.observers.send(op: dic["op"].stringValue, syncData: jsonData)
        } else {
            DocsLogger.warning("🐟🌲wikitree 协同格式解析不成功")
            assertionFailure("🐟🌲wikitree 协同格式解析不成功")
        }
    }
}
