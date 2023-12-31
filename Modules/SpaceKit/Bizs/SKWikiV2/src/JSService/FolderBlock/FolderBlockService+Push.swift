//
//  FolderBlockService+Push.swift
//  SKDoc
//
//  Created by Weston Wu on 2023/6/15.
//

import Foundation
import SKFoundation
import SKCommon
import RxSwift

class WikiTreePushManager: StablePushManagerDelegate {
    let spaceID: String
    let pushManager: StablePushManager

    var onReceivePush: ((String, [String: Any]) -> Void)?

    init(spaceID: String) {
        self.spaceID = spaceID
        let tag = StablePushPrefix.wikiTree.rawValue + spaceID
        let pushInfo = SKPushInfo(tag: tag,
                                  resourceType: StablePushPrefix.wikiTree.resourceType(),
                                  routeKey: spaceID,
                                  routeType: SKPushRouteType.id)
        self.pushManager = StablePushManager(pushInfo: pushInfo)
        self.pushManager.register(with: self)
    }

    func stablePushManager(_ manager: StablePushManagerProtocol,
                           didReceivedData data: [String : Any],
                           forServiceType type: String,
                           andTag tag: String) {
        onReceivePush?(spaceID, data)
    }

    deinit {
        pushManager.unRegister()
    }
}

struct WikiTreePushBlockInfo {
    let blockID: String
    let callback: String
}


extension FolderBlockService {

    typealias PushBlockInfo = WikiTreePushBlockInfo

    func handleWikiPush(params: [String: Any]) {
        guard let spaceID = params["spaceId"] as? String,
              let blockID = params["blockId"] as? String,
              let optIn = params["opt"] as? Int else {
            DocsLogger.error("failed to parse block info when receive register push event")
            return
        }
        if optIn == 1 {
            guard let callback = params["callback"] as? String else {
                DocsLogger.error("failed to parse callback when receive register push event")
                return
            }
            registerWikiPush(spaceID: spaceID, blockInfo: PushBlockInfo(blockID: blockID, callback: callback))
        } else if optIn == 0 {
            unregisterWikiPush(spaceID: spaceID, blockID: blockID)
        } else {
            DocsLogger.error("unknown opt in flag found: \(optIn)")
            return
        }
    }

    private func registerWikiPush(spaceID: String, blockInfo: PushBlockInfo) {
        DocsLogger.info("start register wiki push for block", extraInfo: ["spaceID": spaceID, "blockID": blockInfo.blockID])
        var blockInfos = pushBlockInfos[spaceID] ?? []
        if blockInfos.isEmpty {
            DocsLogger.info("register wiki push for first block", extraInfo: ["spaceID": spaceID, "blockID": blockInfo.blockID])
            let pushManager = WikiTreePushManager(spaceID: spaceID)
            pushManager.onReceivePush = { [weak self] spaceID, data in
                DispatchQueue.main.async {
                    self?.notifyDidReceivePush(spaceID: spaceID, data: ["data": data])
                }
            }
            pushManagers[spaceID] = pushManager
        }
        // 同一个 blockID 重复注册，后注册的要覆盖前一个
        if let previousIndex = blockInfos.firstIndex(where: { $0.blockID == blockInfo.blockID }) {
            DocsLogger.info("duplicate block found when register wiki push, override with new block callback", extraInfo: ["spaceID": spaceID, "blockID": blockInfo.blockID])
            blockInfos[previousIndex] = blockInfo
        } else {
            blockInfos.append(blockInfo)
        }
        pushBlockInfos[spaceID] = blockInfos
        DocsLogger.info("finish register wiki push for block", extraInfo: ["spaceID": spaceID, "blockID": blockInfo.blockID])
    }

    private func notifyDidReceivePush(spaceID: String, data: [String: Any]) {
        DocsLogger.info("did receive wiki push", extraInfo: ["spaceID": spaceID])
        guard let blockInfos = pushBlockInfos[spaceID], !blockInfos.isEmpty else {
            DocsLogger.error("receiving push when no blockInfos found")
            pushManagers[spaceID] = nil
            return
        }
        blockInfos.forEach { blockInfo in
            let payload: [String: Any] = [
                "blockId": blockInfo.blockID,
                "pushMsg": data.jsonString
            ]
            model?.jsEngine.callFunction(DocsJSCallBack(rawValue: blockInfo.callback), params: payload, completion: nil)
        }
    }

    private func unregisterWikiPush(spaceID: String, blockID: String) {
        DocsLogger.info("start unregister wiki push for block", extraInfo: ["spaceID": spaceID, "blockID": blockID])
        guard var blockInfos = pushBlockInfos[spaceID] else {
            DocsLogger.error("spaceID had not register when unregister", extraInfo: ["spaceID": spaceID, "blockID": blockID])
            return
        }
        blockInfos = blockInfos.filter { blockInfo in
            blockInfo.blockID != blockID
        }
        pushBlockInfos[spaceID] = blockInfos
        DocsLogger.info("finish unregister wiki push for block", extraInfo: ["spaceID": spaceID, "blockID": blockID])
        if blockInfos.isEmpty {
            DocsLogger.info("unregister wiki push after last block is unregister", extraInfo: ["spaceID": spaceID, "blockID": blockID])
            pushManagers[spaceID] = nil
        }
    }
    
    func setupLocalNotifyEvent() {
        NotificationCenter.default.rx.notification(Notification.Name.Docs.wikiExplorerStarNode)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notification in
                guard let spaceId = notification.userInfo?["spaceId"] as? String,
                      let addStar = notification.userInfo?["addStar"] as? Bool,
                      let wikiToken = notification.userInfo?["objToken"] as? String else {
                    return
                }
                self?.notifyDidReceivePush(spaceID: spaceId, data: ["operation": addStar ? "Star" : "Unstar", "data": ["wikiToken": wikiToken]])
            })
            .disposed(by: disposeBag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Docs.WikiExplorerPinNode)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notification in
                guard let spaceId = notification.userInfo?["spaceId"] as? String,
                      let addPin = notification.userInfo?["addPin"] as? Bool,
                      let wikiToken = notification.userInfo?["targetToken"] as? String else {
                    return
                }
                self?.notifyDidReceivePush(spaceID: spaceId, data: ["operation": addPin ? "Pin" : "Unpin", "data": ["wikiToken": wikiToken]])
            })
            .disposed(by: disposeBag)
    }
}
