//
//  DocRNPreloader.swift
//  SpaceKit
//
//  Created by lizechuang on 2020/1/13.
//

import Foundation
import SwiftyJSON
import SKFoundation
import LarkContainer

class DocRNPreloader {
    private var preloadingClientVarTasks = Set<PreloadClientVarTask>()
    private var preloadingPollTasks = Set<RNPreloadTask>()
    private var preloadingCommentTasks = Set<RNPreloadTask>()
    private var preloadQueue: DispatchQueue
    private let userResolver: UserResolver?
    
    init(preloadQueue: DispatchQueue, userResolver: UserResolver?) {
        self.userResolver = userResolver
        self.preloadQueue = DispatchQueue(label: "preloadQueue", target: preloadQueue)
        RNManager.manager.registerRnEvent(eventNames: [.bitablePreloadComplete,
                                                       .sheetPreloadComplete,
                                                       .docxPreloadComplete,
                                                       .preloadImages,
                                                       .rnPreloadComplete], handler: self)
    }
}

extension DocRNPreloader: RNMessageDelegate {
    
    func didReceivedRNData(data: [String: Any], eventName: RNManager.RNEventName) {
        preloadQueue.async {
            let json = JSON(data)
            guard let handlerName = json["handlerName"].string else {
                DocsLogger.info("DocRNPreloader didReceivedRNData handlerName wrong", component: LogComponents.preload)
                return
            }
            if handlerName == RNManager.RNEventName.sheetPreloadComplete.rawValue {
                self.handleSheetPreloadOK(json)
            } else if handlerName == RNManager.RNEventName.bitablePreloadComplete.rawValue {
                self.handleBitablePreloadOK(json)
            } else if handlerName == RNManager.RNEventName.docxPreloadComplete.rawValue {
                self.handleDocxPreloadOK(json)
            } else if handlerName == RNManager.RNEventName.preloadImages.rawValue {
                self.handleNeedPreloadImages(json)
            } else if handlerName == RNManager.RNEventName.rnPreloadComplete.rawValue {
                self.handleRNPreloadOK(json)
            }
        }
    }

    private func handleRNPreloadOK(_ json: JSON) {
        spaceAssert(!Thread.isMainThread)
        guard let objToken = json["data"]["objToken"].string,
            let typeName = json["data"]["type"].string else {
                DocsLogger.info("DocRNPreloader handleRNPreloadOK cannot get objToken", component: LogComponents.preload)
                return
        }
        if typeName == Preload.RNTaskType.poll.typeNameInRN {
            if let task = self.preloadingPollTasks.first(where: { $0.key.objToken == objToken }) {
                task.didFinishRNPreload(task.key)
                DocsLogger.info("DocRNPreloader \(task.key) pollData preload ok", component: LogComponents.preload)
                self.preloadingPollTasks.remove(task)
            }
        } else if typeName == Preload.RNTaskType.comment.typeNameInRN {
            if let task = self.preloadingCommentTasks.first(where: { $0.key.objToken == objToken }) {
                task.didFinishRNPreload(task.key)
                DocsLogger.info("DocRNPreloader \(task.key) commentData preload ok", component: LogComponents.preload)
                self.preloadingCommentTasks.remove(task)
            }
        } else {
            DocsLogger.info("DocRNPreloader handleRNPreloadOK , cannot get type \(typeName)", component: LogComponents.preload)
        }
    }

    private func handleDocxPreloadOK(_ json: JSON) {
        spaceAssert(!Thread.isMainThread)
        let code = json["data"]["code"].int ?? 0
        let docxToken = json["data"]["docxToken"].string
        let preloadType = json["data"]["type"].string
        guard let docxToken = docxToken, let preloadType = preloadType else {
            DocsLogger.info("DocRNPreloader handleDocxPreloadOK cannot get token", component: LogComponents.preload)
            return
        }

        DocsLogger.info("DocRNPreloader handleDocxPreloadOK preload docx \(DocsTracker.encrypt(id: docxToken)) code \(code), preloadType=\(preloadType)", component: LogComponents.preload)
        guard preloadType == "ALL_DATA_COMPLETE" else { return }
        preloadQueue.async {
            if let task = self.preloadingClientVarTasks.first(where: { $0.key.objToken == docxToken || $0.key.wikiRealPreloadKey?.objToken == docxToken}) {
                let succeed = code == 0
                task.didFinishClientVarPreload(task.key, success: succeed, code: code)
                DocsLogger.info("DocRNPreloader \(task.key.encryptedObjToken) docxClientVar preload ok", component: LogComponents.preload)
                self.preloadingClientVarTasks.remove(task)
            }
            else {
                DocsLogger.info("DocRNPreloader docxClientVar not contain objToken, \(self.preloadingClientVarTasks.count)", component: LogComponents.preload)
            }
        }
    }

    private func handleNeedPreloadImages(_ json: JSON) {
        let images = json["data"]["images"].arrayValue
        let token = json["data"]["token"].string
        guard let token = token else {
            spaceAssertionFailure()
            return
        }
        let decoder = JSONDecoder()
        let imagesInfos: [PreloadPicInfo] = images.compactMap { json in
            guard let data = try? json.rawData() else { return nil }
            return try? decoder.decode(PreloadPicInfo.self, from: data)
        }
        PreloadKey.preloadImagesDic.updateValue(imagesInfos, forKey: token)

    }

    private func handleSheetPreloadOK(_ json: JSON) {
        spaceAssert(!Thread.isMainThread)
        let code = json["data"]["code"].int ?? 0
        //所以如果只是ssr拉取失败，前端会通过这个字段置为false, 不需要重试
        //let canRetry = json["data"]["canRetry"].bool ?? true
        let canRetry = true
        guard let sheetToken = json["data"]["sheetToken"].string else {
            DocsLogger.info("DocRNPreloader handleSheetPreloadOK cannot get sheetToken", component: LogComponents.preload)
            return
        }

        DocsLogger.info("DocRNPreloader handleSheetPreloadOK preload sheet \(DocsTracker.encrypt(id: sheetToken)) code \(code), canRetry=\(canRetry)", component: LogComponents.preload)
        preloadQueue.async {
            if let task = self.preloadingClientVarTasks.first(where: { $0.key.objToken == sheetToken }) {
                let succeed = code == 0
                task.didFinishClientVarPreload(task.key, success: succeed, code: code, canRetry: canRetry)
                DocsLogger.info("DocRNPreloader \(task.key.encryptedObjToken) sheetClientVar preload ok", component: LogComponents.preload)
                self.preloadingClientVarTasks.remove(task)
            }
        }
    }

    private func handleBitablePreloadOK(_ json: JSON) {
        spaceAssert(!Thread.isMainThread)
        guard let bitableToken = json["data"]["bitableToken"].string,
              let code = json["data"]["code"].int else {
            DocsLogger.info("DocRNPreloader handleBitablePreloadOK cannot get bitableToken", component: LogComponents.preload)
            return
        }
        DocsLogger.info("DocRNPreloader handleBitablePreloadOK preload bitable \(DocsTracker.encrypt(id: bitableToken)) code \(code)", component: LogComponents.preload)
        preloadQueue.async {
            if let task = self.preloadingClientVarTasks.first(where: { $0.key.objToken == bitableToken }) {
                let succeed = code == 0
                task.didFinishClientVarPreload(task.key, success: succeed, code: code)
                DocsLogger.info("DocRNPreloader \(task.key.encryptedObjToken) bitableClientVar preload ok", component: LogComponents.preload)
                self.preloadingClientVarTasks.remove(task)
            }
        }
    }
}

extension DocRNPreloader: RNPreloadClientVarDelegate, RNPreloadTaskDelegate {

    // comment / poll
    func sendRNToPreload(_ task: RNPreloadTask) {
        spaceAssert(!Thread.isMainThread)
        preloadQueue.async {
            RNManager.manager.sendSpaceBusnessToRN(data: task.getDataToRN())
            switch task.type {
            case .comment: self.preloadingCommentTasks.insert(task)
            case .poll: self.preloadingPollTasks.insert(task)
            }
        }
    }

    // preload independent/embedded sheet/bitable
    func sendRNPreloadClientVarsIfNeed(_ task: PreloadClientVarTask, shouldContinue: Bool) {
        spaceAssert(!Thread.isMainThread)
        // 如果是wiki，使用wiki对应单品的preloadKey加载sheet
        let preloadKey = task.key.wikiRealPreloadKey ?? task.key

        switch preloadKey.type {
        case .doc: // 处理 block 预加载，从 task 的 innerFinish 逻辑走过来
            if preloadKey.shouldPreloadEmbeddedSheet {
                preloadQueue.async {
                    self.preloadEmbeddedSheet(preloadKey: preloadKey, task: task)
                }
            }
//            if preloadKey.shouldPreloadEmbeddedBitable {
//                preloadQueue.async {
//                    self.preloadEmbeddedBitable(preloadKey: preloadKey, task: task)
//                }
//            }
        case .docX:
            guard preloadKey.hasClientVar == false || shouldContinue else {
                DocsLogger.info("DocRNPreloader \(task.key) docX ClientVar already preload ok", component: LogComponents.preload)
                task.didFinishClientVarPreload(preloadKey, success: true, code: nil)
                return
            }
            preloadQueue.async {
                self.preloadIndependentDocX(preloadKey: preloadKey, task: task)
            }
        case .sheet: // 处理独立 sheet 预加载，从 task 的 _loadClientVars 逻辑走过来

            guard preloadKey.shouldPreloadIndependentSheet || shouldContinue else {
                DocsLogger.info("DocRNPreloader \(task.key) sheetClientVar already preload ok", component: LogComponents.preload)
                task.didFinishClientVarPreload(preloadKey, success: true, code: nil)
                return
            }
            preloadQueue.async {
                self.preloadIndependentSheet(preloadKey: preloadKey, task: task)
            }
        case .bitable: // 处理独立 bitable 预加载，从 task 的 _loadClientVars 逻辑走过来
            guard preloadKey.shouldPreloadIndependentBitable || shouldContinue else {
                DocsLogger.info("DocRNPreloader \(task.key) bitableClientVar already preload ok", component: LogComponents.preload)
                task.didFinishClientVarPreload(preloadKey, success: true, code: nil)
                return
            }
            preloadQueue.async {
                self.preloadIndependentBitable(preloadKey: preloadKey, task: task)
            }
        default: ()
        }
    }

    private func preloadIndependentDocX(preloadKey: PreloadKey, task: PreloadClientVarTask) {
        var body = [String: Any]()
        let docxToken = preloadKey.objToken
        let typeValue = preloadKey.type.rawValue
        body["docxToken"] = docxToken
        body["type"] = typeValue
        let data: [String: Any] = ["operation": "docx.fetchData",
                                   "body": body]
        DocsLogger.info("DocRNPreloader send rn to preload independent Docx \(preloadKey)", component: LogComponents.preload)
        RNManager.manager.sendSyncData(data: data)
        self.preloadingClientVarTasks.insert(task)
    }

    private func preloadIndependentSheet(preloadKey: PreloadKey, task: PreloadClientVarTask) {
        spaceAssert(preloadKey.independentSheetToken != nil)
        var body = [String: Any]()
        let sheetToken = preloadKey.independentSheetToken ?? ""
        body["sheetToken"] = sheetToken

        var fetchTypes: [String] = []
        if preloadKey.sheetSSRfg {
            //没有fetchType默认走clientvar
//            if !preloadKey.hasClientVar {
//                fetchTypes.append("clientVars")
//            }
            //如果不添加clientVar字段会导致拉ssr失败最终导致预加载内容失败
            //至于为什么可能出现hasClientVar为true并且hasCachedSheetSSR为false原因，猜测可能是请求ssr成功后写入缓存或者本地读ssr的缓存步骤有问题
            fetchTypes.append("clientVars")
            if !preloadKey.hasCachedSheetSSR(preloadKey.objToken) {
                fetchTypes.append("ssr")
            }
            body["fetchType"] = fetchTypes
        }

        let data: [String: Any] = ["operation": "sheet.fetchData",
                                   "body": body]
        DocsLogger.info("DocRNPreloader send rn to preload independent sheet \(preloadKey), fetchTypes=\(fetchTypes)", component: LogComponents.preload)
        RNManager.manager.sendSyncData(data: data)
        self.preloadingClientVarTasks.insert(task)
    }

    private func preloadEmbeddedSheet(preloadKey: PreloadKey, task: PreloadClientVarTask) {
        DocsLogger.info("DocRNPreloader send rn to preload embedded sheet \(preloadKey)", component: LogComponents.preload)
        spaceAssert(preloadKey.embeddedSheetToken != nil)
        var body = [String: String]()
        let sheetToken = preloadKey.embeddedSheetToken ?? ""
        body["sheetToken"] = sheetToken
        body["docToken"] = preloadKey.objToken // embedded 场景独有
        let data: [String: Any] = ["operation": "sheet.fetchData",
                                   "body": body]
        RNManager.manager.sendSyncData(data: data)
    }

    private func preloadIndependentBitable(preloadKey: PreloadKey, task: PreloadClientVarTask) {
        DocsLogger.info("DocRNPreloader send rn to preload independent bitable \(preloadKey)", component: LogComponents.preload)
        spaceAssert(preloadKey.independentBitableToken != nil)
        var body: [String: Any] = ["dataType": "PRELOAD_BITABLE_CLIENT_VARS"]
        let bitableToken = preloadKey.independentBitableToken ?? ""
        body["bitableToken"] = bitableToken
        let data: [String: Any] = ["operation": "preloadData",
                                   "body": body]
        let composedData: [String: Any] = ["business": "base", "data": data]
        RNManager.manager.sendSpaceBusnessToRN(data: composedData)
        self.preloadingClientVarTasks.insert(task)
    }

//    private func preloadEmbeddedBitable(preloadKey: PreloadKey, task: PreloadClientVarTask) {
//        DocsLogger.info("DocRNPreloader send rn to preload embedded bitable \(preloadKey)", component: LogComponents.preload)
//        spaceAssert(preloadKey.embeddedBitableToken != nil)
//        var body = ["dataType": "PRELOAD_BITABLE_CLIENT_VARS"]
//        let bitableToken = preloadKey.embeddedBitableToken ?? ""
//        body["bitableToken"] = bitableToken
//        body["docToken"] = preloadKey.objToken // embedded 场景独有
//        let data: [String: Any] = ["operation": "preloadData",
//                                   "body": body]
//        let composedData: [String: Any] = ["business": "base", "data": data]
//        RNManager.manager.sendSpaceBusnessToRN(data: composedData)
//    }
}
