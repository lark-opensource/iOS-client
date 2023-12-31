//
//  RNWatcherSpec.swift
//  DocsTests
//
//  Created by guotenghu on 2019/8/22.
//  Copyright © 2019 Bytedance. All rights reserved.
// 测试 ManuOfflineRNWatcher

import Foundation

import XCTest
@testable import SpaceKit
import Quick
import SwiftyJSON
import Nimble
import SwiftyBeaver
import Swinject

class ManuOfflineRNWatcherSpec: DocsSpec {

    override func spec() {
        testRetry()
        testWatchSuccess()
    }

    func testRetry() {
        it("不要一直重试") {
            let resolver = getResolver(.failRN)
            let manuOfflineRnWatcher = ManuOfflineRNWatcher(resolver)
            let fileManuOfflineManager = resolver.resolve(FileManualOfflineManagerAPI.self)
            let preloadAPI = resolver.resolve(DocPreloaderManagerAPI.self)! as? TestDocPreloaderManagerAPI
            let rnAPI = resolver.resolve(RNMangerAPI.self)! as? TestRNMangerAPI
            self.wait(1)
            let manualOfflineFile = ManualOfflineFile(objToken: "token1", type: .doc)
            fileManuOfflineManager?.addToOffline(manualOfflineFile)
            self.wait(2)
            expect(preloadAPI?.addedPreloadKeys.count).to(equal(1))
            expect(rnAPI?.receiveWatchCount).to(equal(3))
        }
    }

    func testWatchSuccess() {
        it("watch 成功的例子") {
            let resolver = getResolver(.succ)
            let manuOfflineRnWatcher = ManuOfflineRNWatcher(resolver)
            let fileManuOfflineManager = resolver.resolve(FileManualOfflineManagerAPI.self)
            let preloadAPI = resolver.resolve(DocPreloaderManagerAPI.self)! as? TestDocPreloaderManagerAPI
            let rnAPI = resolver.resolve(RNMangerAPI.self)! as? TestRNMangerAPI
            self.wait(1)
            let manualOfflineFile1 = ManualOfflineFile(objToken: "token1", type: .doc)
            let manualOfflineFile2 = ManualOfflineFile(objToken: "token2", type: .doc)
            let manualOfflineFile3 = ManualOfflineFile(objToken: "token3", type: .doc)
            fileManuOfflineManager?.addToOffline(manualOfflineFile1)
            fileManuOfflineManager?.addToOffline(manualOfflineFile2)
            fileManuOfflineManager?.addToOffline(manualOfflineFile3)
            self.wait(3)
            expect(preloadAPI?.addedPreloadKeys.count).to(equal(3))
            expect(rnAPI?.receiveWatchCount).to(equal(3))
        }
    }
}

private enum ResolverType {
    case failRN
    case succ
}

private func getResolver(_ type: ResolverType) -> DocsResolver {
    let container = Container()
    container.register(FileManualOfflineManagerAPI.self, factory: { _ in return TestFileManualOfflineManager() }).inObjectScope(.container)

    container.register(RNMangerAPI.self, factory: { _ in
        let rnAPI = TestRNMangerAPI()
        if type == .failRN {
            rnAPI.shouldFail = true
        }
        return rnAPI
    }).inObjectScope(.container)
    container.register(DocPreloaderManagerAPI.self) { (_) in
        return TestDocPreloaderManagerAPI()
    }.inObjectScope(.container)
    return DocsContainer(container: container)
}

private class TestFileManualOfflineManager: FileManualOfflineManagerAPI {
    func removeFromOffline(by file: ManualOfflineFile, extra: [ManualOfflineCallBack.ExtraKey: Any]?) {

    }

    func updateOffline(_ files: [ManualOfflineFile]) {

    }

    func startOpen(_ file: ManualOfflineFile) {

    }

    func endOpen(_ file: ManualOfflineFile) {

    }

    func download(_ file: ManualOfflineFile, use strategy: ManualOfflineAction.DownloadStrategy) {

    }

    var target: ManualOfflineFileStatusObserver?
    func addObserver(_ target: ManualOfflineFileStatusObserver) {
        self.target = target
    }

    func removeObserver(_ target: ManualOfflineFileStatusObserver) {

    }

    func excuteCallBack(_ callBack: ManualOfflineCallBack) {
        testLog.info("TestFileManualOfflineManager receive \(callBack)")
    }

    func addToOffline(_ file: ManualOfflineFile) {
        let action = ManualOfflineAction(event: .add, files: [file], extra: nil)
        target?.didReceivedFileOfflineStatusAction(action)
    }

    func refreshOfflineData(of file: ManualOfflineFile) {

    }

    func removeFromOffline(by file: ManualOfflineFile) {

    }

    func clear() {

    }
}

private class TestRNMangerAPI: RNMangerAPI {
    var handler: RNMessageDelegate?
    var shouldFail: Bool = false
    var receiveWatchCount = 0

    private func getKeysFrom(_ json: JSON) -> [PreloadKey] {
        let tokens = json["data"]["body"]
        return tokens.arrayValue.compactMap({ (data) -> PreloadKey in
            let token = data["token"].stringValue
            let type = DocsType(rawValue: data["type"].intValue)!
            return PreloadKey(objToken: token, type: type)
        })
    }

    private func getResult(success: Bool, for keys: [PreloadKey]) -> [[String: Any]] {
        var results = [[String: Any]]()
        keys.forEach { (key) in
            var keyResult = [String: Any]()
            keyResult["type"] = key.type.rawValue
            keyResult["token"] = key.objToken
            keyResult["succ"] = success ? 1 : 0
            results.append(keyResult)
        }
        return results
    }

    func sendSpaceBusnessToRN(data: [String: Any]) {
        let json = JSON(data)
        let operation = json["data"]["operation"].stringValue
        let keys = getKeysFrom(json)
        let results = getResult(success: !shouldFail, for: keys)
        var backDict = [String: Any]()
        if operation == "offWatch" {
            backDict["action"] = "offWatchResult"
            receiveWatchCount += keys.count
            testLog.info("get offWatch request for \(keys.map({ $0.objToken }))")
        } else if operation == "offUnwatch" {
            backDict["action"] = "offUnwatchResult"
        }
        let backData = ["tokens": results]
        backDict["data"] = backData
        backDict["data"] = backDict

        DispatchQueue.main.async {
            self.handler!.didReceivedRNData(data: backDict, eventName: RNManager.RNEventName.getDataFromRN)
        }
    }

    func sendSyncData(data: [String: Any], responseId: String?) {

    }

    func registerRnEvent(eventNames: [RNManager.RNEventName], handler: RNMessageDelegate) {
        self.handler = handler
    }

}

private class TestDocPreloaderManagerAPI: DocPreloaderManagerAPI {
    var addedPreloadKeys = [PreloadKey]()
    func addManuOfflinePreloadKey(_ preloadKeys: [PreloadKey]) {
        testLog.info("get addManuOfflinePreloadKey request for \(preloadKeys.map({ $0.objToken }))")
        addedPreloadKeys.append(contentsOf: preloadKeys)
    }

    func loadContent(_ url: String) {

    }
}
