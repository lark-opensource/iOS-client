//
//  SecurityPolicyCacheTest.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/8/10.
//

import XCTest
@testable import LarkSecurityCompliance
import LarkSecurityComplianceInterface
import LarkPolicyEngine
import LarkContainer

extension Action: Equatable {
    public static func == (lf: Action, ri: Action) -> Bool {
        return lf.name == ri.name
    }
}

extension ValidateResponse: Equatable {
    public static func == (lf: ValidateResponse, ri: ValidateResponse) -> Bool {
        return lf.resultMethod == ri.resultMethod && lf.effect == ri.effect && lf.actions == ri.actions && lf.uuid == ri.uuid && lf.errorMsg == ri.errorMsg && lf.type == ri.type
    }
}

 final class SecurityPolicyCacheTest: XCTestCase {
     var sceneCache: StrategyEngineSceneCache? = try? StrategyEngineSceneCache(resolver: Container.shared.getCurrentUserResolver())

    func testCacheReadAndWrite() throws {
        guard let sceneCache else { return }
        let operateTenantId: Int64 = 1
        let operateUserId: Int64 = 111
        let ccmCopyModel1 = PolicyModel(.ccmExportObject, CCMEntity(entityType: .doc,
                                                                    entityDomain: .ccm,
                                                                    entityOperate: .ccmCopy,
                                                                    operatorTenantId: operateTenantId,
                                                                    operatorUid: operateUserId,
                                                                    fileBizDomain: .ccm,
                                                                    token: "ghjkgfghjk",
                                                                    ownerTenantId: 2,
                                                                    ownerUserId: 222))
        let ccmCopyResult1 = ValidateResponse(effect: .deny, actions: [], uuid: "2023-8-4", type: .local, errorMsg: nil)
        sceneCache.merge([ccmCopyModel1.taskID: ccmCopyResult1])
        let result = sceneCache.read(policyModel: ccmCopyModel1)?.validateResponse
        XCTAssertEqual(result, ccmCopyResult1)
        
        let imReadModel = PolicyModel(.imFileRead, IMFileEntity(entityType: .imMsgFile,
                                                                entityDomain: .im,
                                                                entityOperate: .imFileRead,
                                                                operatorTenantId: operateTenantId,
                                                                operatorUid: operateUserId,
                                                                fileBizDomain: .im,
                                                                senderUserId: 222,
                                                                senderTenantId: 2,
                                                                msgId: "3334555"))
        let imReadResult = ValidateResponse(effect: .deny, actions: [], uuid: "2023-8-4", type: .local, errorMsg: nil)
        sceneCache.merge([imReadModel.taskID: imReadResult])
        let resultRead = sceneCache.read(policyModel: imReadModel)?.validateResponse
        XCTAssertEqual(resultRead, imReadResult)
    }
 }

 class LRUCacheTest: XCTestCase {
    func testLRUCache() {
        // 初始化
        let userId: Int64 = 111
        let cache = LRUCache(userID: "\(userId)", maxSize: 2, cacheKey: PointKey.ccmCopy.rawValue)
        cache.cleanAll()

        // LRU缓存写入1和读取1，结果应为1的结果
        let ccmCopyModel1 = PointCutOperate.ccmContentCopy(entityType: .doc,
                                                           operateTenantId: 111,
                                                           operateUserId: userId,
                                                           token: "dddddddd",
                                                           ownerTenantId: 1111,
                                                           ownerUserId: 11_111).asModel()
        let ccmCopyResult1 = SceneLocalCache(taskID: ccmCopyModel1.taskID, validateResponse: ValidateResponse(effect: .deny, actions: [], uuid: "2023-8-4", type: .local, errorMsg: nil))
        cache.write(value: ccmCopyResult1, forKey: ccmCopyModel1.taskID)
        let cacheResult: SceneLocalCache? = cache.read(forKey: ccmCopyModel1.taskID)
        XCTAssertEqual(cacheResult, ccmCopyResult1)

        // LRU缓存未写入时，读出来应该为空
        let ccmCopyModel2 = PointCutOperate.ccmContentCopy(entityType: .doc,
                                                           operateTenantId: 111,
                                                           operateUserId: userId,
                                                           token: "aaaaaaa",
                                                           ownerTenantId: 1111,
                                                           ownerUserId: 11_111).asModel()
        let cacheResult2: SceneLocalCache? = cache.read(forKey: ccmCopyModel2.taskID)
        XCTAssertNil(cacheResult2)
    }
 }

class FIFOCacheTest: XCTestCase {
    func testFIFOCache() {
        // 初始化
        let userId: Int64 = 111
        let cacheKey = PointKey.ccmCopy.rawValue
        let cache = FIFOCache(userID: "\(userId)", maxSize: 2, cacheKey: cacheKey)
        cache.cleanAll()

        // LRU缓存写入1和读取1，结果应为1的结果
        let ccmCopyModel1 = PointCutOperate.ccmContentCopy(entityType: .doc,
                                                           operateTenantId: 111,
                                                           operateUserId: userId,
                                                           token: "dddddddd",
                                                           ownerTenantId: 1111,
                                                           ownerUserId: 11_111).asModel()
        let ccmCopyResult1 = SceneLocalCache(taskID: ccmCopyModel1.taskID, validateResponse: ValidateResponse(effect: .deny, actions: [], uuid: "2023-8-4", type: .local, errorMsg: nil))
        cache.write(value: ccmCopyResult1, forKey: ccmCopyModel1.taskID)
        var cacheResult: SceneLocalCache? = cache.read(forKey: ccmCopyModel1.taskID)
        XCTAssertEqual(cacheResult, ccmCopyResult1)

        // LRU缓存未写入时，读出来应该为空
        let ccmCopyModel2 = PointCutOperate.ccmContentCopy(entityType: .doc,
                                                           operateTenantId: 111,
                                                           operateUserId: userId,
                                                           token: "aaaaaaa",
                                                           ownerTenantId: 1111,
                                                           ownerUserId: 11_111).asModel()
        let cacheResult2: SceneLocalCache? = cache.read(forKey: ccmCopyModel2.taskID)
        XCTAssertNil(cacheResult2)

        // 缓存阈值为2时，写入2和3，应该把第1个移除
        let ccmCopyResult2 = SceneLocalCache(taskID: ccmCopyModel2.taskID,
                                             validateResponse: ValidateResponse(effect: .permit, actions: [], uuid: "2023-8-4", type: .remote, errorMsg: nil))
        cache.write(value: ccmCopyResult2, forKey: ccmCopyModel2.taskID)
        let ccmCopyModel3 = PointCutOperate.ccmContentCopy(entityType: .bitable,
                                                           operateTenantId: 111,
                                                           operateUserId: userId,
                                                           token: "cccccccc",
                                                           ownerTenantId: 1111,
                                                           ownerUserId: 11_111).asModel()
        let ccmCopyResult3 = SceneLocalCache(taskID: ccmCopyModel3.taskID,
                                             validateResponse: ValidateResponse(effect: .indeterminate, actions: [], uuid: "2023-8-4", type: .fastPass, errorMsg: nil))
        cache.write(value: ccmCopyResult3, forKey: ccmCopyModel3.taskID)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(3) ) {
            cacheResult = cache.read(forKey: ccmCopyModel1.taskID)
            XCTAssertNil(cacheResult)
        }
        
        let miExpection = expectation(description: "test migrate")
        let migrateCache = FIFOCache(userID: "\(userId)", maxSize: 1, cacheKey: cacheKey)
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10) ) {
            cacheResult = migrateCache.read(forKey: ccmCopyModel2.taskID)
            miExpection.fulfill()
        }
        wait(for: [miExpection], timeout: 12)
        XCTAssertNil(cacheResult)
        XCTAssertEqual(migrateCache.count, 1)
        
        migrateCache.markInvalid()
        cacheResult = migrateCache.read(forKey: ccmCopyModel3.taskID)
        XCTAssertEqual(cacheResult?.isCredible, false)
        let allCaches: [SceneLocalCache] = migrateCache.getAllRealCache()
        XCTAssertEqual(allCaches.count, 1)
    }
}
