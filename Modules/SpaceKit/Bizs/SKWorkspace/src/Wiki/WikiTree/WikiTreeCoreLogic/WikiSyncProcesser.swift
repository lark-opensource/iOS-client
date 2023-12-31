//
//  WikiSyncProcesser.swift
//  SpaceKit
//
//  Created by 邱沛 on 2020/2/28.
//

import Foundation
import RxSwift
import RxCocoa
import SKFoundation
import SKCommon

public protocol WikiSyncProcessor {

    func observable<Value>() -> Observable<Value>

    func process(_ syncData: Data)
}

public class WikiSyncBaseProcessor<M: Codable, T>: WikiSyncProcessor {
    let sync = PublishSubject<T>()
    let bag = DisposeBag()
    let synergyUUID: String
    let networkAPI: WikiTreeNetworkAPI
    public init(synergyUUID: String, networkAPI: WikiTreeNetworkAPI) {
        self.synergyUUID = synergyUUID
        self.networkAPI = networkAPI
    }

    public func observable<Value>() -> Observable<Value> {
        if let observable = sync.asObservable().share() as? Observable<Value> {
            return observable
        } else {
            spaceAssertionFailure("必须强校验序列类型")
            return Observable<Value>.empty()
        }
    }

    public func process(_ syncData: Data) {
        do {
            let syncModel = try JSONDecoder().decode(M.self, from: syncData)
            process(syncModel)
        } catch {
            DocsLogger.warning("sync data parse failed\(error)")
            assertionFailure("sync data parse failed\(error)")
        }
    }

    public func process(_ syncModel: M) {
        DocsLogger.warning("WikiSyncProcessor process must be override")
        assertionFailure("WikiSyncProcessor process must be override")
    }
}

public struct WikiTreeAddSyncResult: Codable {
    var spaceId: String = ""
    var wikiToken: String = ""
    var tooManyCoordinator: Bool = false
    var delayTime: Int = 0
    var synergyUUID: String = ""


    private enum CodingKeys: String, CodingKey {
        case spaceId = "space_id"
        case wikiToken = "wiki_token"
        case tooManyCoordinator = "too_many_coordinator"
        case delayTime = "delay_time"
        case synergyUUID = "synergy_uuid"
    }
}

public class WikiAddSyncProcessorV2: WikiSyncBaseProcessor<WikiTreeAddSyncResult, WikiServerNode> {

    public override func process(_ syncModel: WikiTreeAddSyncResult) {
        guard !syncModel.tooManyCoordinator else {
            DocsLogger.info("🌲新增协同，协同人数过多，不处理")
            return
        }

        guard syncModel.synergyUUID != synergyUUID else {
            DocsLogger.info("🌲新增协同，协同触发为自己的请求，不处理")
            return
        }

        let delayTime = Int.random(in: 0...syncModel.delayTime)
        DocsLogger.info("🌲新增协同，开始反查，delay: \(delayTime)")
        networkAPI.getNodeMetaInfo(wikiToken: syncModel.wikiToken)
            .delaySubscription(.milliseconds(delayTime), scheduler: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] node in
                self?.sync.onNext(node)
            })
            .disposed(by: bag)
    }
}

public struct WikiTreeDeleteSpaceSyncResult: Codable {
    var spaceId: String = ""

    private enum CodingKeys: String, CodingKey {
        case spaceId = "space_id"
    }
}

public class WikiDeleteSpaceSyncProcessor: WikiSyncBaseProcessor<WikiTreeDeleteSpaceSyncResult, String> {

    public override func process(_ syncModel: WikiTreeDeleteSpaceSyncResult) {
        self.sync.onNext(syncModel.spaceId)
    }

}

public struct WikiTreeDeleteSyncResultV2: Codable {
    var spaceId: String = ""
    var wikiToken: String = ""

    var tooManyCoordinator: Bool = false
    var delayTime: Int = 0
    var opUid: String = ""
    var childrenSortId: [String: Double] = [:]
    var synergyUUID: String = ""
    private enum CodingKeys: String, CodingKey {
        case spaceId = "space_id"
        case wikiToken = "wiki_token"
        case tooManyCoordinator = "too_many_coordinator"
        case delayTime = "delay_time"
        case synergyUUID = "synergy_uuid"
    }
}

public class WikiDelSyncProcessorV2: WikiSyncBaseProcessor<WikiTreeDeleteSyncResultV2, String> {

    public override func process(_ syncModel: WikiTreeDeleteSyncResultV2) {

        guard !syncModel.tooManyCoordinator else {
            DocsLogger.info("🌲删除协同，协同人数过多，不处理")
            return
        }

        guard syncModel.synergyUUID != synergyUUID else {
            DocsLogger.info("🌲删除协同，协同触发为自己的请求，不处理")
            return
        }

        self.sync.onNext(syncModel.wikiToken)

    }
}

public struct WikiTreeMoveSyncResultV2: Codable {
    var oldSpaceId: String = ""
    var newSpaceId: String = ""
    var wikiToken: String = ""
    var from: String = ""
    var to: String = ""
    var tooManyCoordinator: Bool = false
    var delayTime: Int = 0
    var synergyUUID: String = ""

    private enum CodingKeys: String, CodingKey {
        case oldSpaceId = "old_space_id"
        case newSpaceId = "new_space_id"
        case wikiToken = "wiki_token"
        case from
        case to
        case tooManyCoordinator = "too_many_coordinator"
        case delayTime = "delay_time"
        case synergyUUID = "synergy_uuid"
    }
}

public struct MoveSyncResultV2 {
    public let oldParentToken: String
    public let newParentToken: String
    public let movedToken: String
    // nil 表示移动后失去了目标节点的权限
    public let movedNode: WikiServerNode?
    public init(oldParentToken: String, newParentToken: String, movedToken: String, movedNode: WikiServerNode? = nil) {
        self.oldParentToken = oldParentToken
        self.newParentToken = newParentToken
        self.movedToken = movedToken
        self.movedNode = movedNode
    }
}
public class WikiMovSyncProcessorV2: WikiSyncBaseProcessor<WikiTreeMoveSyncResultV2, MoveSyncResultV2> {

    public override func process(_ syncModel: WikiTreeMoveSyncResultV2) {

        guard !syncModel.tooManyCoordinator else {
            DocsLogger.info("🌲移动协同，协同人数过多，不处理")
            return
        }

        guard syncModel.synergyUUID != synergyUUID else {
            DocsLogger.info("🌲移动协同，协同触发为自己的请求，不处理")
            return
        }

        let delayTime = Int.random(in: 0...syncModel.delayTime)
        DocsLogger.info("🌲移动协同，开始反查，delay: \(delayTime)")
        networkAPI
            .getNodeMetaInfo(wikiToken: syncModel.wikiToken)
            .delaySubscription(.milliseconds(delayTime), scheduler: MainScheduler.instance)
            .subscribe { [weak self] node in
                guard let self = self else { return }
                self.sync.onNext(MoveSyncResultV2(oldParentToken: syncModel.from,
                                                  newParentToken: syncModel.to,
                                                  movedToken: syncModel.wikiToken,
                                                  movedNode: node))
            } onError: { error in
                DocsLogger.error("移动协同失败\(error)")
                let error = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
                switch error {
                case .nodePermFailCode, .permFail, .parentPermFail, .spacePermFail:
                    self.sync.onNext(MoveSyncResultV2(oldParentToken: syncModel.from,
                                                      newParentToken: syncModel.to,
                                                      movedToken: syncModel.wikiToken,
                                                      movedNode: nil))
                default: break
                }
            }.disposed(by: bag)
    }
}

// 区域权限变更协同
public struct WikiNodePermissionSyncResult: Codable {
    var spaceId: String = ""
    var wikiToken: String = ""
    var parent: String = ""
    var tooManyCoordinator: Bool = false
    var delayTime: Int = 0
    var affectedUsers: [String]?

    private enum CodingKeys: String, CodingKey {
        case spaceId = "space_id"
        case wikiToken = "wiki_token"
        case parent
        case tooManyCoordinator = "too_many_coordinator"
        case delayTime = "delay_time"
        case affectedUsers = "affected_user"
    }
}

public typealias NodePermSyncResult = (String, WikiServerNode?)
public class WikiNodePermissionSyncProcessor: WikiSyncBaseProcessor<WikiNodePermissionSyncResult, NodePermSyncResult> {

    public override func process(_ syncModel: WikiNodePermissionSyncResult) {

        guard !syncModel.tooManyCoordinator else {
            DocsLogger.info("🌲节点权限变更，协同人数过多，不处理")
            return
        }

        if let userId = User.current.info?.userID,
              let affectedUsers = syncModel.affectedUsers,
              !affectedUsers.isEmpty,
              !affectedUsers.contains(userId) {
            DocsLogger.info("🌲节点权限变更，affectedUsers不属于自己，不处理")
            return
        }

        // 反查节点权限
        let delayTime = Int.random(in: 0...syncModel.delayTime)
        DocsLogger.info("🌲节点权限变更，开始反查该节点信息，delay : \(delayTime)")
        networkAPI
            .getNodeMetaInfo(wikiToken: syncModel.wikiToken)
            .delaySubscription(.milliseconds(delayTime), scheduler: MainScheduler.instance)
            .subscribe { [weak self] node in
                DocsLogger.info("🌲节点权限变更，你有该节点权限，试图将该节点接入")
                self?.sync.onNext((syncModel.wikiToken, node))
            } onError: { [weak self] error in
                DocsLogger.info("🌲节点权限变更，你无该节点权限，试图将该节点删除\(error)")
                self?.sync.onNext((syncModel.wikiToken, nil))
            }.disposed(by: bag)
    }
}

public struct WikiTreeNodeTitleSyncResultV2: Codable {
    var spaceId: String = ""
    var wikiToken: String = ""
    var tooManyCoordinator: Bool = false
    var delayTime: Int = 0

    private enum CodingKeys: String, CodingKey {
        case spaceId = "space_id"
        case wikiToken = "wiki_token"
        case tooManyCoordinator = "too_many_coordinator"
        case delayTime = "delay_time"
    }
}

public class WikiTitleSyncProcessorV2: WikiSyncBaseProcessor<WikiTreeNodeTitleSyncResultV2, WikiTreeUpdateData> {

    public override func process(_ syncModel: WikiTreeNodeTitleSyncResultV2) {
        guard !syncModel.tooManyCoordinator else {
            DocsLogger.info("🌲标题协同，协同人数过多，不处理")
            return
        }
        let delayTime = Int.random(in: 0...syncModel.delayTime)
        DocsLogger.info("🌲标题协同，开始反查，delay: \(delayTime)")
        networkAPI.getNodeMetaInfo(wikiToken: syncModel.wikiToken)
            .delaySubscription(.milliseconds(delayTime), scheduler: MainScheduler.instance)
            .subscribe { [weak self] nodeInfo in
                guard let self = self else { return }
                
                self.sync.onNext(WikiTreeUpdateData(wikiToken: syncModel.wikiToken,
                                                    title: nodeInfo.meta.title,
                                                    iconInfo: nodeInfo.meta.iconInfo))
            } onError: { error in
                spaceAssertionFailure("移动协同失败\(error)")
            }.disposed(by: bag)
    }
}

// MARK: - Batch Add
public struct WikiTreeBatchAddSyncResult: Codable {
    var spaceId: String = ""
    var wikiTokens: [String] = []
    var tooManyCoordinator: Bool = false
    var delayTime: Int = 0
    var synergyUUID: String = ""
    var parentWikiToken: String = ""

    private enum CodingKeys: String, CodingKey {
        case spaceId = "space_id"
        case wikiTokens = "wiki_tokens"
        case tooManyCoordinator = "too_many_coordinator"
        case delayTime = "delay_time"
        case synergyUUID = "synergy_uuid"
        case parentWikiToken = "parent_wiki_token"
    }
}

public class WikiBatchAddSyncProcessorV2: WikiSyncBaseProcessor<WikiTreeBatchAddSyncResult, (String, [WikiServerNode])> {

    public override func process(_ syncModel: WikiTreeBatchAddSyncResult) {

        guard !syncModel.tooManyCoordinator else {
            DocsLogger.info("🌲新增批量协同，协同人数过多，不处理")
            return
        }

        guard syncModel.synergyUUID != synergyUUID else {
            DocsLogger.info("🌲新增批量协同，协同触发为自己的请求，不处理")
            return
        }

        let delayTime = Int.random(in: 0...syncModel.delayTime)
        DocsLogger.info("🌲新增批量协同，开始反查，delay: \(delayTime)")
        networkAPI.batchGetNodeMetaInfo(wikiTokens: syncModel.wikiTokens)
            .delaySubscription(.milliseconds(delayTime), scheduler: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] nodes in
                guard let self = self else { return }
                let validNodes = nodes.filter { node in
                    if node.parent != syncModel.parentWikiToken {
                        DocsLogger.error("🌲新增批量协同，发现子节点的父节点token与推送信息不符，不处理")
                        return false
                    }
                    return true
                }
                self.sync.onNext((syncModel.parentWikiToken, validNodes))
            }).disposed(by: bag)
    }
}

// MARK: - Batch Move
public struct WikiTreeBatchMoveSyncResultV2: Codable {
    var oldSpaceId: String = ""
    var newSpaceId: String = ""
    var wikiTokens: [String] = []
    var from: String = ""
    var to: String = ""
    var tooManyCoordinator: Bool = false
    var delayTime: Int = 0
    var synergyUUID: String = ""

    private enum CodingKeys: String, CodingKey {
        case oldSpaceId = "old_space_id"
        case newSpaceId = "new_space_id"
        case wikiTokens = "wiki_tokens"
        case from
        case to
        case tooManyCoordinator = "too_many_coordinator"
        case delayTime = "delay_time"
        case synergyUUID = "synergy_uuid"
    }
}

public struct BatchMoveSyncResultV2 {
    public let from: String
    public let to: String
    public let targetSpaceId: String
    public let movedTokens: [String]
    public let movingNodes: [String: WikiServerNode]
}

public class WikiBatchMovSyncProcessorV2: WikiSyncBaseProcessor<WikiTreeBatchMoveSyncResultV2, BatchMoveSyncResultV2> {

    public override func process(_ syncModel: WikiTreeBatchMoveSyncResultV2) {
        guard !syncModel.tooManyCoordinator else {
            DocsLogger.info("🌲批量移动协同，协同人数过多，不处理")
            return
        }

        guard syncModel.synergyUUID != synergyUUID else {
            DocsLogger.info("🌲批量移动协同，协同触发为自己的请求，不处理")
            return
        }

        let delayTime = Int.random(in: 0...syncModel.delayTime)
        DocsLogger.info("🌲批量移动协同，开始反查，delay: \(delayTime)")
        networkAPI.batchGetNodeMetaInfo(wikiTokens: syncModel.wikiTokens)
            .delaySubscription(.milliseconds(delayTime), scheduler: MainScheduler.instance)
            .subscribe { [weak self] nodes in
                guard let self = self else { return }
                var movedTokens: [String] = []
                var movedNodes: [String: WikiServerNode] = [:]
                nodes.forEach { node in
                    movedTokens.append(node.meta.wikiToken)
                    movedNodes[node.meta.wikiToken] = node
                }
                let result = BatchMoveSyncResultV2(from: syncModel.from,
                                                   to: syncModel.to,
                                                   targetSpaceId: syncModel.newSpaceId,
                                                   movedTokens: movedTokens,
                                                   movingNodes: movedNodes)
                self.sync.onNext(result)
            } onError: { [weak self] error in
                DocsLogger.error("🌲批量移动协同失败", error: error)
                guard let self = self else { return }
                let error = WikiErrorCode(rawValue: (error as NSError).code) ?? .networkError
                switch error {
                case .nodePermFailCode, .permFail, .parentPermFail, .spacePermFail:
                    let result = BatchMoveSyncResultV2(from: syncModel.from, to: syncModel.to, targetSpaceId: syncModel.newSpaceId, movedTokens: syncModel.wikiTokens, movingNodes: [:])
                    self.sync.onNext(result)
                default:
                    break
                }
            }.disposed(by: bag)
    }
}

// MARK: - Delete And Move Up
public struct WikiTreeDeleteAndMoveUpSyncResult: Codable {
    var spaceId: String = ""
    var wikiToken: String = ""
    var parentWikiToken: String = ""
    var tooManyCoordinator: Bool = false
    var delayTime: Int = 0
    var synergyUUID: String = ""

    private enum CodingKeys: String, CodingKey {
        case spaceId = "space_id"
        case wikiToken = "wiki_token"
        case parentWikiToken = "parent_wiki_token"
        case tooManyCoordinator = "too_many_coordinator"
        case delayTime = "delay_time"
        case synergyUUID = "synergy_uuid"
    }
}

public struct DeleteAndMoveUpSyncResult {
    public let wikiToken: String
    public let parentWikiToken: String
    public let spaceId: String
}

public class WikiDeleteAndMoveUpSyncProcessor: WikiSyncBaseProcessor<WikiTreeDeleteAndMoveUpSyncResult, DeleteAndMoveUpSyncResult> {

    public override func process(_ syncModel: WikiTreeDeleteAndMoveUpSyncResult) {
        guard !syncModel.tooManyCoordinator else {
            DocsLogger.info("🌲删除&上移协同，协同人数过多，不处理")
            return
        }

        guard syncModel.synergyUUID != synergyUUID else {
            DocsLogger.info("🌲删除&上移协同，协同触发为自己的请求，不处理")
            return
        }

        let delayTime = Int.random(in: 0...syncModel.delayTime)
        DocsLogger.info("🌲删除&上移协同，开始反查，delay: \(delayTime)")
        DispatchQueue.main.asyncAfter(deadline: .now() + .milliseconds(delayTime)) { [weak self] in
            self?.sync.onNext(DeleteAndMoveUpSyncResult(wikiToken: syncModel.wikiToken, parentWikiToken: syncModel.parentWikiToken, spaceId: syncModel.spaceId))
        }
    }
}

// MARK: Pin 置顶文档相关协同
public struct ClipDocumentSyncStatusResult: Codable {
    var objToken: String?
    var objType: Int?
    var synergyUUID: String?
    
    private enum CodingKeys: String, CodingKey {
        case objToken = "obj_token"
        case objType = "obj_type"
        case synergyUUID = "synergy_uuid"
    }
}


public class ClipDocumentSyncStatusProcessor: WikiSyncBaseProcessor<ClipDocumentSyncStatusResult, ()> {
    
    public override func process(_ syncModel: ClipDocumentSyncStatusResult) {
        guard UserScopeNoChangeFG.MJ.sidebarSyncEnable else {
            DocsLogger.info("🌲add or remove pin document sync fg closed")
            return
        }
        
        guard syncModel.synergyUUID != synergyUUID else {
            DocsLogger.info("🌲add or remove pin document ignore, because self triger")
            return
        }
        
        self.sync.onNext(())
    }
}

// MARK: Pin 置顶知识库相关协同
public struct ClipWikiSpaceSyncStatusResult: Codable {
    var spaceId: String?
    var synergyUUID: String?
    
    private enum CodingKeys: String, CodingKey {
        case spaceId = "space_id"
        case synergyUUID = "synergy_uuid"
    }
}

public class ClipWikiSpaceSyncStatusProcessor: WikiSyncBaseProcessor<ClipWikiSpaceSyncStatusResult, ()> {
    
    public override func process(_ syncModel: ClipWikiSpaceSyncStatusResult) {
        guard UserScopeNoChangeFG.MJ.sidebarSyncEnable else {
            DocsLogger.info("🌲add or remove pin wiki space sync fg closed")
            return
        }
        
        guard syncModel.synergyUUID != synergyUUID else {
            DocsLogger.info("🌲add or remove pin wiki space ignore, because self triger")
            return
        }
        
        self.sync.onNext(())
    }
}
