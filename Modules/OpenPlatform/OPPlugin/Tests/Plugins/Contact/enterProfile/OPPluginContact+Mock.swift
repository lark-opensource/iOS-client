//
//  OPPluginContact+Mock.swift
//  OPPlugin-Unit-Tests
//
//  Created by baojianjun on 2023/7/25.
//

import XCTest
import OCMock

import OPUnitTestFoundation
import OPFoundation
@testable import LarkSetting

@available(iOS 13.0, *)
protocol OPPluginContact_Mock {
    
    var logID: String { get }
    
    func prepareForSuccessMock(responseContent: [String: AnyHashable], responseError: Int, responseMessage: String) throws
    
    func prepare_for_failed_response_mock(monitorMsgPrefix: String) throws
    
    func prepareForNoResponseFailedMock() -> String
    
    func release()
}

/// 联系人模块用于mock EMANetworkManager 的对象
/// discussion
/// 1. API实现需要用EMANetworkCipher加解密，并且得改造成调用`EMANetworkCipher.getCipher()`方法
/// 2. 在当前的单测链路，mock的是EMANetworkManager的下述方法
/// ```
/** postUrl:(NSString *)urlString
    params:(NSDictionary *)params
    header:(NSDictionary *)header
    completionWithJsonData:(nonnull void (^)(NSDictionary * _Nullable, NSURLResponse * _Nullable, NSError * _Nullable))completionHandler
    eventName:(nonnull NSString *)eventName
    requestTracing:(OPTrace * _Nullable)tracing
 */
/// ```
@available(iOS 13.0, *)
open class OPPluginContact_EMANetworkManager_POSTURL_Mock: OPPluginContact_Mock {
    
    let logID = "unit-test-logid"
    
    var mockObject: (EMANetworkCipher, OCMockObject, OCMockObject)?
    var mockObject2: OCMockObject?
    
    func prepareForSuccessMock(responseContent: [String: AnyHashable], responseError: Int = 0, responseMessage: String = "this is unit test message") throws {
        let innerCipher = EMANetworkCipher()
        
        guard let encryptString = innerCipher.encryptString(content: responseContent) else {
            throw NSError(domain: "cannot generate encryptString!", code: -1)
        }
        
        let mockRecorder = OCMockAssistant.mock_EMANetworkCipher {
            innerCipher
        }
        
        let mockInstance = OCMockAssistant.mock_PostUrl_EMANetworkManager_shared(EMANetworkManager.shared()) {
            [
                "encryptedData": encryptString,
                "error": responseError,
                "message": responseMessage
            ]
        } completionResponse: {
            guard let url = URL(string: "https://www.feishu.cn") else {
                return nil
            }
            return HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [
                "x-tt-logid" : self.logID
            ])
        } completionError: {
            nil
        }
        mockObject = (innerCipher, mockRecorder, mockInstance)
    }
    
    func prepare_for_failed_response_mock(monitorMsgPrefix: String) throws {
        
        let responseErrorCode = -2
        let responseMessage = "this is \(monitorMsgPrefix) unit test message"
        
        try prepareForSuccessMock(responseContent: ["unittestKey": "unittestValue"], responseError: responseErrorCode, responseMessage: responseMessage)
    }
    
    func prepareForNoResponseFailedMock() -> String {
        let monitorMsg = "server data error(logid:\(logID))"
        mockObject2 = OCMockAssistant.mock_PostUrl_EMANetworkManager_shared(EMANetworkManager.shared()) {
            nil
        } completionResponse: {
            guard let url = URL(string: "https://www.feishu.cn") else {
                return nil
            }
            return HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [
                "x-tt-logid" : self.logID
            ])
        } completionError: {
            nil
        }
        return monitorMsg
    }
    
    func release() {
        if let mockObject {
            mockObject.1.stopMocking()
            mockObject.2.stopMocking()
        }
        mockObject = nil
        mockObject2?.stopMocking()
        mockObject2 = nil
    }
}

/// 联系人模块用于mock EMANetworkManager 的对象
/// discussion
/// 1. API实现需要用EMANetworkCipher加解密，并且得改造成调用`EMANetworkCipher.getCipher()`方法
/// 2. 在当前的单测链路，mock的是EMANetworkManager的下述方法
/// ```
/**
 - (NSURLSessionTask *)requestUrl:(NSString *)urlString
                           method:(NSString *)method
                           params:(NSDictionary *)params
                           header:(NSDictionary *)header
           completionWithJsonData:(void (^)(NSDictionary * _Nullable json, NSURLResponse * _Nullable response, NSError * _Nullable error))completionHandler
                        eventName:(nonnull NSString *)eventName
                   requestTracing:(OPTrace * _Nullable)tracing;
 */
/// ```
@available(iOS 13.0, *)
open class OPPluginContact_EMANetworkManager_RequestURL_Mock: OPPluginContact_Mock {
    
    let logID = "unit-test-logid"
    
    var mockObject: (EMANetworkCipher, OCMockObject, OCMockObject)?
    var mockObject2: OCMockObject?
    
    func prepareForSuccessMock(responseContent: [String: AnyHashable], responseError: Int = 0, responseMessage: String = "this is unit test message") throws {
        let innerCipher = EMANetworkCipher()
        
        guard let encryptString = innerCipher.encryptString(content: responseContent) else {
            throw NSError(domain: "cannot generate encryptString!", code: -1)
        }
        
        let mockRecorder = OCMockAssistant.mock_EMANetworkCipher {
            innerCipher
        }
        
        let mockInstance = OCMockAssistant.mock_RequestUrl_EMANetworkManager_shared(EMANetworkManager.shared()) {
            [
                "encryptedData": encryptString,
                "error": responseError,
                "message": responseMessage
            ]
        } completionResponse: {
            guard let url = URL(string: "https://www.feishu.cn") else {
                return nil
            }
            return HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [
                "x-tt-logid" : self.logID
            ])
        } completionError: {
            nil
        }
        mockObject = (innerCipher, mockRecorder, mockInstance)
    }
    
    func prepare_for_failed_response_mock(monitorMsgPrefix: String) throws {
        
        let responseErrorCode = -2
        let responseMessage = "this is \(monitorMsgPrefix) unit test message"
        
        try prepareForSuccessMock(responseContent: ["unittestKey": "unittestValue"], responseError: responseErrorCode, responseMessage: responseMessage)
    }
    
    func prepareForNoResponseFailedMock() -> String {
        let monitorMsg = "server data error(logid:\(logID))"
        mockObject2 = OCMockAssistant.mock_RequestUrl_EMANetworkManager_shared(EMANetworkManager.shared()) {
            nil
        } completionResponse: {
            guard let url = URL(string: "https://www.feishu.cn") else {
                return nil
            }
            return HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [
                "x-tt-logid" : self.logID
            ])
        } completionError: {
            nil
        }
        return monitorMsg
    }
    
    func release() {
        if let mockObject {
            mockObject.1.stopMocking()
            mockObject.2.stopMocking()
        }
        mockObject = nil
        mockObject2?.stopMocking()
        mockObject2 = nil
    }
}

@available(iOS 13.0, *)
final class OPPluginEnterProfile_ECONetwork_Mock: OPPluginContact_Mock {
    
    let logID = "unit-test-logid"
    
    var mockObject: (EMANetworkCipher, OCMockObject, OCMockObject, OCMockObject)?
    var mockObject2: (OCMockObject, OCMockObject)?
    
    func prepareForSuccessMock(responseContent: [String: AnyHashable], responseError: Int = 0, responseMessage: String = "this is unit test message") throws {
        let innerCipher = EMANetworkCipher()
        
        guard let encryptString = innerCipher.encryptString(content: responseContent) else {
            throw NSError(domain: "cannot generate encryptString!", code: -1)
        }
        
        let mockRecorder = OCMockAssistant.mock_EMANetworkCipher {
            innerCipher
        }
        
        let mockEntry = OCMockAssistant.mock_OPECONetworkInterface()
        
        let mockInstance = OCMockAssistant.mock_OPECONetworkInterface_postForOpenDomain {
            [
                "encryptedData": encryptString,
                "error": responseError,
                "message": responseMessage
            ]
        } completionResponse: {
            guard let url = URL(string: "https://www.feishu.cn") else {
                return nil
            }
            return HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [
                "x-tt-logid" : self.logID
            ])
        } completionError: {
            nil
        }
        mockObject = (innerCipher, mockRecorder, mockEntry, mockInstance)
    }
    
    func prepare_for_failed_response_mock(monitorMsgPrefix: String) throws {
        
        let responseErrorCode = -2
        let responseMessage = "this is \(monitorMsgPrefix) unit test message"
        
        try prepareForSuccessMock(responseContent: ["unittestKey": "unittestValue"], responseError: responseErrorCode, responseMessage: responseMessage)
    }
    
    func prepare_for_no_chatid_failed_mock() throws -> String {
        
        let responseErrorCode = -2
        let responseMessage = "this is no chatid unit test message"
        let monitorMsgPrefix = "no chatid error"
        
        try prepareForSuccessMock(responseContent: ["unittestKey": "unittestValue"], responseError: responseErrorCode, responseMessage: responseMessage)
        
        return monitorMsgPrefix
    }
    
    func prepareForNoResponseFailedMock() -> String {
        let monitorMsg = "server data error(logid:\(logID))"
        
        let mockEntry = OCMockAssistant.mock_OPECONetworkInterface()
        
        let mockInstance = OCMockAssistant.mock_OPECONetworkInterface_postForOpenDomain {
            nil
        } completionResponse: {
            guard let url = URL(string: "https://www.feishu.cn") else {
                return nil
            }
            return HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: [
                "x-tt-logid" : self.logID
            ])
        } completionError: {
            nil
        }
        mockObject2 = (mockEntry, mockInstance)
        return monitorMsg
    }
    
    func release() {
        if let mockObject {
            mockObject.1.stopMocking()
            mockObject.2.stopMocking()
            mockObject.3.stopMocking()
        }
        mockObject = nil
        if let mockObject2 {
            mockObject2.0.stopMocking()
            mockObject2.1.stopMocking()
        }
        mockObject2 = nil
    }
}

struct OPECONetworkAPISettingMock {
    static let key = "use_econetwork_api"
    
    static func disableECONetwork() {
        SettingStorage.updateSettingValue(Self.disableValue, with: SettingManager.currentChatterID(), and: Self.key)
    }
    static func enableECONetwork() {
        SettingStorage.updateSettingValue(Self.enableValue, with: SettingManager.currentChatterID(), and: Self.key)
    }
    
    private static let enableValue = """
    {
        "default": true,
        "path": {
            "testPath": false
        }
    }
    """
    
    private static let disableValue = """
    {
        "default": false,
        "path": {
            "testPath": false
        }
    }
    """
}
