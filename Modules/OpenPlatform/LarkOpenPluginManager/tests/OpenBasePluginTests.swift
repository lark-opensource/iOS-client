//
//  OpenBasePluginTests.swift
//  EcosystemTests
//
//  Created by Meng on 2021/12/29.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest
import ECOProbe
import LarkOpenAPIModel
import ECOInfra
@testable import LarkOpenPluginManager

class OpenBasePluginTests: XCTestCase {

    class TestAPIInput: OpenAPIBaseParams {
        @OpenAPIRequiredParam(userRequiredWithJsonKey: "inputData")
        var inputData: String

        override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
            return [_inputData]
        }
    }

    class TestAPIOutput: OpenAPIBaseResult {
        let outputData: String = "outputData"
        override func toJSONDict() -> [AnyHashable : Any] {
            return ["outputData": outputData]
        }
    }

    let plugin = OpenBasePlugin(resolver: OPUserScope.userResolver())
    let context = OpenAPIContext(trace: OPTrace(traceId: UUID().uuidString))

    func testAsyncRegister() throws {
        /// baseParamsWithBaseResult
        let expect1 = XCTestExpectation(description: "baseParamsWithBaseResult")
        plugin.registerAsyncHandler(for: "baseParamsWithBaseResult") { params, context, callback in
            callback(.success(data: nil))
        }
        XCTAssertNoThrow(try plugin.asyncHandle(
            apiName: "baseParamsWithBaseResult",
            params: OpenAPIBaseParams(with: [:]),
            context: context,
            callback: { response in
                if case let .success(data: data) = response {
                    XCTAssertNil(data, "data must be nil")
                    expect1.fulfill()
                } else {
                    XCTFail("response must success")
                }
            }
        ), "should not throw error")
        wait(for: [expect1], timeout: 1.0)

        /// baseParams
        let expect2 = XCTestExpectation(description: "baseParams")
        plugin.registerAsyncHandler(for: "baseParams", resultType: TestAPIOutput.self) { params, context, callback in
            callback(.success(data: TestAPIOutput()))
        }
        XCTAssertNoThrow(try plugin.asyncHandle(
            apiName: "baseParams",
            params: OpenAPIBaseParams(with: [:]),
            context: context,
            callback: { response in
                if case let .success(data: data) = response {
                    XCTAssertNotNil(data, "data must not be nil")
                    XCTAssertTrue(data! is TestAPIOutput, "data type must be TestAPIOutput")
                    XCTAssertTrue((data! as! TestAPIOutput).outputData == "outputData")
                    expect2.fulfill()
                } else {
                    XCTFail("response must success")
                }
            }
        ), "should not throw error")
        wait(for: [expect2], timeout: 1.0)

        /// baseResult
        let expect3 = XCTestExpectation(description: "baseResult")
        plugin.registerAsyncHandler(for: "baseResult", paramsType: TestAPIInput.self) { params, context, callback in
            XCTAssert(params.inputData == "inputData")
            callback(.success(data: nil))
        }
        XCTAssertNoThrow(try plugin.asyncHandle(
            apiName: "baseResult",
            params: TestAPIInput(with: ["inputData": "inputData"]),
            context: context,
            callback: { response in
                if case let .success(data: data) = response {
                    XCTAssertNil(data, "data must be nil")
                    expect3.fulfill()
                } else {
                    XCTFail("response must success")
                }
            }
        ), "should not throw error")
        wait(for: [expect3], timeout: 1.0)

        /// input/output
        let expect4 = XCTestExpectation(description: "input/output")
        plugin.registerAsyncHandler(
            for: "input/output",
            paramsType: TestAPIInput.self,
            resultType: TestAPIOutput.self
        ) { params, context, callback in
            XCTAssert(params.inputData == "inputData")
            callback(.success(data: TestAPIOutput()))
        }
        XCTAssertNoThrow(try plugin.asyncHandle(
            apiName: "input/output",
            params: TestAPIInput(with: ["inputData": "inputData"]),
            context: context,
            callback: { response in
                if case let .success(data: data) = response {
                    XCTAssertNotNil(data, "data must not be nil")
                    XCTAssertTrue(data! is TestAPIOutput, "data type must be TestAPIOutput")
                    XCTAssertTrue((data! as! TestAPIOutput).outputData == "outputData")
                    expect4.fulfill()
                } else {
                    XCTFail("response must success")
                }
            }
        ), "should not throw error")
        wait(for: [expect4], timeout: 1.0)
    }

    func testSyncRegister() throws {
        /// baseParamsWithBaseResult
        plugin.registerSyncHandler(for: "baseParamsWithBaseResult") { params, context in
            return .success(data: nil)
        }
        XCTAssertNoThrow(try {
            let response1 = try self.plugin.syncHandle(
                apiName: "baseParamsWithBaseResult",
                params: OpenAPIBaseParams(with: [:]),
                context: self.context
            )
            if case let .success(data: data) = response1 {
                XCTAssertNil(data, "data must be nil")
            } else {
                XCTFail("response must success")
            }
        }(), "should not throw error")

        /// baseParams
        plugin.registerSyncHandler(for: "baseParams", resultType: TestAPIOutput.self) { params, context in
            return .success(data: TestAPIOutput())
        }
        XCTAssertNoThrow(try {
            let response2 = try self.plugin.syncHandle(
                apiName: "baseParams",
                params: OpenAPIBaseParams(with: [:]),
                context: self.context
            )
            if case let .success(data: data) = response2 {
                XCTAssertNotNil(data, "data must not be nil")
                XCTAssertTrue(data! is TestAPIOutput, "data type must be TestAPIOutput")
                XCTAssertTrue((data! as! TestAPIOutput).outputData == "outputData")
            } else {
                XCTFail("response must success")
            }
        }(), "should not throw error")

        /// baseResult
        plugin.registerSyncHandler(for: "baseResult", paramsType: TestAPIInput.self) { params, context in
            XCTAssert(params.inputData == "inputData")
            return .success(data: nil)
        }
        XCTAssertNoThrow(try {
            let response3 = try self.plugin.syncHandle(
                apiName: "baseResult",
                params: TestAPIInput(with: ["inputData": "inputData"]),
                context: self.context
            )
            if case let .success(data: data) = response3 {
                XCTAssertNil(data, "data must be nil")
            } else {
                XCTFail("response must success")
            }
        }(), "should not throw error")

        /// input/output
        plugin.registerSyncHandler(
            for: "input/output",
            paramsType: TestAPIInput.self,
            resultType: TestAPIOutput.self
        ) { params, context in
            XCTAssert(params.inputData == "inputData")
            return .success(data: TestAPIOutput())
        }
        XCTAssertNoThrow(try {
            let response4 = try self.plugin.syncHandle(
                apiName: "input/output",
                params: TestAPIInput(with: ["inputData": "inputData"]),
                context: self.context
            )
            if case let .success(data: data) = response4 {
                XCTAssertNotNil(data, "data must not be nil")
                XCTAssertTrue(data! is TestAPIOutput, "data type must be TestAPIOutput")
                XCTAssertTrue((data! as! TestAPIOutput).outputData == "outputData")
            } else {
                XCTFail("response must success")
            }
        }(), "should not throw error")

    }

    func testEventRegister() throws {
        /// baseParamsAndBaseResult
        let except1 = XCTestExpectation(description: "baseParamsAndBaseResult")
        plugin.registerEvent(event: "baseParamsAndBaseResult") { params, context, callback in
            callback(.success(data: nil))
        }

        XCTAssertNoThrow(try plugin.postEvent(
            apiName: "baseParamsAndBaseResult",
            params: OpenAPIBaseParams(with: [:]),
            context: context,
            callback: { response in
                if case let .success(data: data) = response {
                    XCTAssertNil(data, "data must be nil")
                    except1.fulfill()
                } else {
                    XCTFail("response must success")
                }
            }
        ), "should not throw error")
        wait(for: [except1], timeout: 1.0)

        /// input/output
        let except2 = XCTestExpectation(description: "input/output")
        plugin.registerEvent(event: "input/output", paramsType: TestAPIInput.self) { params, context, callback in
            XCTAssert(params.inputData == "inputData")
            callback(.success(data: TestAPIOutput()))
        }

        XCTAssertNoThrow(try plugin.postEvent(
            apiName: "input/output",
            params: TestAPIInput(with: ["inputData": "inputData"]),
            context: context,
            callback: { response in
                if case let .success(data: data) = response {
                    XCTAssertNotNil(data, "data must not nil")
                    XCTAssert(data!.toJSONDict()["outputData"] is String)
                    XCTAssert(data!.toJSONDict()["outputData"] as! String == "outputData")
                    except2.fulfill()
                } else {
                    XCTFail("response must success")
                }
            }
        ), "should not throw error")
        wait(for: [except2], timeout: 1.0)
    }

    func testNotRegisters() throws {
        /// notExistAsyncAPI
        let except1 = XCTestExpectation(description: "notExistAsyncAPI")
        XCTAssertNoThrow(try plugin.asyncHandle(
            apiName: "notExistAsyncAPI",
            params: OpenAPIBaseParams(with: [:]),
            context: context,
            callback: { response in
                if case let .failure(error: error) = response {
                    XCTAssert(error.code.rawValue == OpenAPICommonErrorCode.unable.rawValue, "error code must be unable")
                    except1.fulfill()
                } else {
                    XCTFail("response must failure")
                }
            }
        ), "should not throw error")
        wait(for: [except1], timeout: 1.0)

        /// notExistSyncAPI
        XCTAssertNoThrow(try {
            let response = try self.plugin.syncHandle(
                apiName: "notExistSyncAPI",
                params: OpenAPIBaseParams(with: [:]),
                context: self.context
            )
            if case let .failure(error: error) = response {
                XCTAssert(error.code.rawValue == OpenAPICommonErrorCode.unable.rawValue, "error code must be unable")
            } else {
                XCTFail("response must failure")
            }
        }(), "should not throw error")


        /// notExistEvent
        let except2 = XCTestExpectation(description: "notExistEvent")
        XCTAssertNoThrow(try plugin.postEvent(
            apiName: "notExistEvent",
            params: OpenAPIBaseParams(with: [:]),
            context: context,
            callback: { response in
                if case let .failure(error: error) = response {
                    XCTAssert(error.code.rawValue == OpenAPICommonErrorCode.unknown.rawValue)
                    except2.fulfill()
                } else {
                    XCTFail("response must failure")
                }
            }
        ), "should not throw error")
        wait(for: [except2], timeout: 1.0)
    }

    func testMissMatchType() throws {
        /// paramsInherit
        let expect1 = XCTestExpectation(description: "paramsInherit")
        plugin.registerAsyncHandler(for: "paramsInherit") { params, context, callback in
            callback(.success(data: nil))
        }
        XCTAssertNoThrow(try plugin.asyncHandle(
            apiName: "paramsInherit",
            params: TestAPIInput(with: ["inputData": "inputData"]),
            context: context,
            callback: { response in
                if case let .success(data: data) = response {
                    XCTAssertNil(data, "data must be nil")
                    expect1.fulfill()
                } else {
                    XCTFail("response must success")
                }
            }
        ), "should not throw error")
        wait(for: [expect1], timeout: 1.0)

        /// paramsDownCasting
        let expect2 = XCTestExpectation(description: "paramsDownCasting")
        plugin.registerAsyncHandler(for: "paramsDownCasting", paramsType: TestAPIInput.self) { params, context, callback in
            callback(.success(data: nil))
        }
        XCTAssertNoThrow(try plugin.asyncHandle(
            apiName: "paramsDownCasting",
            params: OpenAPIBaseParams(with: ["inputData": "inputData"]),
            context: context,
            callback: { response in
                if case let .failure(error: error) = response {
                    XCTAssert(error.code.rawValue == OpenAPICommonErrorCode.invalidParam.rawValue, "error code must be invalidParam")
                    expect2.fulfill()
                } else {
                    XCTFail("response must failure")
                }
            }
        ), "should not throw error")
        wait(for: [expect2], timeout: 1.0)

        /// paramsInherit
        plugin.registerSyncHandler(for: "paramsInherit") { params, context in
            return .success(data: nil)
        }
        XCTAssertNoThrow(try {
            let response = try self.plugin.syncHandle(
                apiName: "paramsInherit",
                params: TestAPIInput(with: ["inputData": "inputData"]),
                context: context
            )
            if case let .success(data: data) = response {
                XCTAssertNil(data, "data must be nil")
            } else {
                XCTFail("response must success")
            }
        }(), "should not throw error")

        /// paramsDownCasting
        plugin.registerSyncHandler(for: "paramsDownCasting", paramsType: TestAPIInput.self) { params, context in
            return .success(data: nil)
        }
        XCTAssertNoThrow(try {
            let response = try self.plugin.syncHandle(
                apiName: "paramsDownCasting",
                params: OpenAPIBaseParams(with: ["inputData": "inputData"]),
                context: self.context
            )
            if case let .failure(error: error) = response {
                XCTAssert(error.code.rawValue == OpenAPICommonErrorCode.invalidParam.rawValue, "error code must be invalidParam")
            } else {
                XCTFail("response must failure")
            }
        }(), "should not throw error")
    }

    func testAsyncCallSync() throws {
        let expect = XCTestExpectation(description: "asyncCallSync")
        plugin.registerSyncHandler(
            for: "asyncCallSync",
            paramsType: TestAPIInput.self,
            resultType: TestAPIOutput.self,
            handler: { params, context in
                XCTAssert(params.inputData == "inputData")
                return .success(data: TestAPIOutput())
            }
        )
        XCTAssertNoThrow(try plugin.asyncHandle(
            apiName: "asyncCallSync",
            params: TestAPIInput(with: ["inputData": "inputData"]),
            context: context,
            callback: { response in
                if case .success(data: let data) = response {
                    XCTAssertNotNil(data, "data must not nil")
                    XCTAssertTrue(data! is TestAPIOutput)
                    XCTAssertTrue((data! as! TestAPIOutput).outputData == "outputData")
                    expect.fulfill()
                } else {
                    XCTFail("response must success")
                }
            }
        ), "should not throw error")
        wait(for: [expect], timeout: 1.0)
    }

}
