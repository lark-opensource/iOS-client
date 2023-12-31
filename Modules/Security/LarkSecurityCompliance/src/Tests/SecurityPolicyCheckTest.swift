//
//  SecurityPolicyCheckTest.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2023/8/10.
//

import XCTest
@testable import LarkSecurityCompliance
import LarkSecurityComplianceInterface
import LarkContainer
import LarkPolicyEngine
import LarkAccountInterface

extension ValidateExtraInfo: Equatable {
    public static func == (lhs: ValidateExtraInfo, rhs: ValidateExtraInfo) -> Bool {
        return lhs.resultSource == rhs.resultSource && lhs.resultMethod == rhs.resultMethod && lhs.errorReason == rhs.errorReason && lhs.isCredible == rhs.isCredible
    }
}
extension ValidateResult: Equatable {
    public static func == (lhs: ValidateResult, rhs: ValidateResult) -> Bool {
        return lhs.result == rhs.result && lhs.extra == rhs.extra
    }
}

// 校验
final class SecurityPolicyCheckTest: XCTestCase {
    
    let resolver: UserResolver = Container.shared.getCurrentUserResolver()

    func testAuthCheck() throws {
        guard let sceneCache = try? userResolver.resolve(assert: SecurityPolicyCacheProtocol.self),
                let userService = try? userResolver.resolve(assert: PassportUserService.self) else { return }
        let policyModel = PointCutOperate.ccmContentPreview(entityType: .doc,
                                                            operateTenantId: Int64(userService.user.tenant.tenantID) ?? 0,
                                                            operateUserId: Int64(userService.user.userID) ?? 0).asModel()
        
        let result = ValidateResponse(effect: .permit, actions: [], uuid: UUID().uuidString, type: .local)
        sceneCache.merge([policyModel.taskID: result], expirationTime: nil)
        let service: SecurityPolicyService? = try? resolver.resolve(assert: SecurityPolicyService.self)
        let cacheResult = service?.cacheValidate(policyModel: policyModel, authEntity: nil, config: nil)
        XCTAssertTrue(cacheResult?.result == .allow)
        
        service?.asyncValidate(policyModel: policyModel, authEntity: nil, config: nil, complete: { asyncResult in
            XCTAssertTrue(asyncResult.result == .allow)
        })
    }
}

// 结果聚合
final class SecurityPolicyResultAggregatorTest: XCTestCase {
    var aggregator: SecurityPolicy.ResultAggregator?
    override func setUpWithError() throws {
        let userResolver = Container.shared.getCurrentUserResolver()
        self.aggregator = try SecurityPolicy.ResultAggregator(resolver: userResolver)
        try? super.setUpWithError()
    }

    override func tearDownWithError() throws {
        try? super.tearDownWithError()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testAllAllowResultMerge() {
        let userResolver = Container.shared.getCurrentUserResolver()
        // 结果全部为allow
        let policyModel = PointCutOperate.ccmContentPreview(entityType: .doc, operateTenantId: 1, operateUserId: 111_111).asModel()
        let cache1 = SceneLocalCache(taskID: policyModel.taskID, validateResponse: ValidateResponse(effect: .permit, actions: [], uuid: UUID().uuidString, type: .local))
        let cache2 = SceneLocalCache(taskID: policyModel.taskID, validateResponse: ValidateResponse(effect: .notApplicable, actions: [], uuid: UUID().uuidString, type: .fastPass))
        let cache3 = SceneLocalCache(taskID: policyModel.taskID, validateResponse: ValidateResponse(effect: .indeterminate, actions: [], uuid: UUID().uuidString, type: .remote))
        let cache4 = SceneLocalCache(taskID: policyModel.taskID, validateResponse: ValidateResponse(effect: .permit, actions: [], uuid: UUID().uuidString, type: .local))
        let response1 = ValidateResponse(effect: .permit, actions: [], uuid: UUID().uuidString, type: .local)
        let response2 = ValidateResponse(effect: .permit, actions: [], uuid: UUID().uuidString, type: .remote)
        let response3 = ValidateResponse(effect: .permit, actions: [], uuid: UUID().uuidString, type: .downgrade)
        let response4 = ValidateResponse(effect: .permit, actions: [], uuid: UUID().uuidString, type: .downgrade, errorMsg: "error")

        // 返回降级
        let results1: [ValidateResultProtocol] = [
            cache1,
            cache2,
            cache3,
            cache4,
            response1,
            response2,
            response3,
            response4
        ]
        let result1 = aggregator?.merge(policyModel: policyModel, results: results1) { _ in }
        let targetResult1 = ValidateResult(userResolver: userResolver,
                                           result: .allow,
                                           extra: ValidateExtraInfo(resultSource: .unknown,
                                                                    errorReason: nil,
                                                                    resultMethod: .downgrade,
                                                                    isCredible: false))
        XCTAssertEqual(result1, targetResult1)

        // 返回服务端决策
        let results2: [ValidateResultProtocol] = [
            cache1,
            cache2,
            cache3,
            cache4,
            response1,
            response2
        ]
        let result2 = aggregator?.merge(policyModel: policyModel, results: results2) { _ in }
        let targetResult2 = ValidateResult(userResolver: userResolver,
                                            result: .allow,
                                           extra: ValidateExtraInfo(resultSource: .unknown,
                                                                    errorReason: nil,
                                                                    resultMethod: .serverStrategy,
                                                                    isCredible: true))
        XCTAssertEqual(result2, targetResult2)

        // 返回cache来源结果
        let results3: [ValidateResultProtocol] = [
            cache1,
            cache2,
            cache3,
            cache4
        ]
        let result3 = aggregator?.merge(policyModel: policyModel, results: results3) { _ in }
        let targetResult3 = ValidateResult(userResolver: userResolver,
                                           result: .allow,
                                           extra: ValidateExtraInfo(resultSource: .unknown,
                                                                    errorReason: nil,
                                                                    resultMethod: .cache,
                                                                    isCredible: true))
        XCTAssertEqual(result3, targetResult3)

        // 返回fallback结果
        let results4 = [response4]
        let result4 = aggregator?.merge(policyModel: policyModel, results: results4, interceptHandler: { _ in })
        XCTAssertEqual(result4?.extra.resultMethod, .fallback)
    }

    func testDenyResultMerge() {
        let userResolver = Container.shared.getCurrentUserResolver()
        // 结果中存在Deny
        let policyModel = PointCutOperate.ccmContentPreview(entityType: .doc, operateTenantId: 1, operateUserId: 111_111).asModel()
        let cache1 = SceneLocalCache(taskID: policyModel.taskID,
                                     validateResponse: ValidateResponse(effect: .deny, actions: [Action(name: "FILE_BLOCK_COMMON")], uuid: UUID().uuidString, type: .local))
        let cache2 = SceneLocalCache(taskID: policyModel.taskID,
                                     validateResponse: ValidateResponse(effect: .deny, actions: [Action(name: "DLP_CONTENT_DETECTING")], uuid: UUID().uuidString, type: .fastPass))
        let cache3 = SceneLocalCache(taskID: policyModel.taskID,
                                     validateResponse: ValidateResponse(effect: .deny, actions: [Action(name: "DLP_CONTENT_SENSITIVE")], uuid: UUID().uuidString, type: .remote))
        let cache4 = SceneLocalCache(taskID: policyModel.taskID,
                                     validateResponse: ValidateResponse(effect: .permit, actions: [Action(name: "DLP_CONTENT_SENSITIVE")], uuid: UUID().uuidString, type: .local))
        let response1 = ValidateResponse(effect: .deny, actions: [Action(name: "TT_BLOCK")], uuid: UUID().uuidString, type: .local)
        let response2 = ValidateResponse(effect: .permit, actions: [Action(name: "DLP_CONTENT_SENSITIVE")], uuid: UUID().uuidString, type: .remote)
        let response3 = ValidateResponse(effect: .permit, actions: [Action(name: "FALLBACK_COMMON")], uuid: UUID().uuidString, type: .downgrade)
        let response4 = ValidateResponse(effect: .permit, actions: [Action(name: "UNIVERSAL_FALLBACK_COMMON")], uuid: UUID().uuidString, type: .downgrade, errorMsg: "error")

        // 返回tt_block
        let results1: [ValidateResultProtocol] = [
            cache1,
            cache2,
            cache3,
            cache4,
            response1,
            response2,
            response3,
            response4
        ]
        let result1 = aggregator?.merge(policyModel: policyModel, results: results1) { _ in }
        let targetResult1 = ValidateResult(userResolver: userResolver,
                                           result: .deny,
                                           extra: ValidateExtraInfo(resultSource: .ttBlock,
                                                                    errorReason: nil,
                                                                    resultMethod: .localStrategy,
                                                                    isCredible: true))
        XCTAssertEqual(result1, targetResult1)

        // 返回file_block
        let results2: [ValidateResultProtocol] = [
            cache1,
            cache2,
            cache3,
            cache4,
            response2,
            response3,
            response4
        ]
        let result2 = aggregator?.merge(policyModel: policyModel, results: results2) { _ in }
        let targetResult2 = ValidateResult(userResolver: userResolver,
                                           result: .deny,
                                           extra: ValidateExtraInfo(resultSource: .fileStrategy,
                                                                    errorReason: nil,
                                                                    resultMethod: .cache,
                                                                    isCredible: true))
        XCTAssertEqual(result2, targetResult2)

        // 返回dlp_sensitive
        let results3: [ValidateResultProtocol] = [
            cache2,
            cache3,
            cache4
        ]
        let result3 = aggregator?.merge(policyModel: policyModel, results: results3) { _ in }
        let targetResult3 = ValidateResult(userResolver: userResolver,
                                           result: .deny,
                                           extra: ValidateExtraInfo(resultSource: .dlpSensitive,
                                                                    errorReason: nil,
                                                                    resultMethod: .cache,
                                                                    isCredible: true))
        XCTAssertEqual(result3, targetResult3)

        // 返回dlp_detecting
        let results4: [ValidateResultProtocol] = [
            cache4,
            cache2,
            response4
        ]
        let result4 = aggregator?.merge(policyModel: policyModel, results: results4, interceptHandler: { _ in })
        let targetResult4 = ValidateResult(userResolver: userResolver,
                                           result: .deny,
                                           extra: ValidateExtraInfo(resultSource: .dlpDetecting,
                                                                    errorReason: nil,
                                                                    resultMethod: .cache,
                                                                    isCredible: true))
        XCTAssertEqual(result4, targetResult4)
    }
}
