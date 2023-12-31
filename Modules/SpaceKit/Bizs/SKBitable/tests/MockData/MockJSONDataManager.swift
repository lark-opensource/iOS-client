//
//  MockJSONDataManager.swift
//  SKBitable_Tests-Unit-_Tests
//
//  Created by zengsenyuan on 2022/8/5.
//  


import XCTest
import SKCommon
import HandyJSON
import SKInfra
@testable import SKBitable



class MockJSONDataManager {
    
    static func getJSONData(filePath: String) -> Data {
        guard let path = Bundle(for: MockJSONDataManager.self).path(forResource: filePath, ofType: "json"),
            let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            fatalError("MockJSONDataManager load fail")
        }
        return data
    }
    
    static func getJSONObjc(filePath: String) -> Any {
        let data = getJSONData(filePath: filePath)
        guard let obj = try? JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed) else {
            fatalError("MockJSONDataManager parse obj error")
        }
        return obj
    }
    
    static func getCodableModelByParseData<T: Codable>(filePath: String) -> T {
        let obj = getJSONObjc(filePath: filePath)
        guard let model: T = MockJSFunc.parseCodable(obj) else {
            fatalError("MockJSONDataManager parse model error: \(filePath)")
        }
        return model
    }
    
    static func getHandyJSONModelByParseData<T: HandyJSON>(filePath: String) -> T {
        let obj = getJSONObjc(filePath: filePath)
        guard let model: T = MockJSFunc.parseHandyJSON(obj) else {
            fatalError("MockJSONDataManager parse model error: \(filePath)")
        }
        return model
    }
    
    static func getFastDecodableByParseData<T: SKFastDecodable>(filePath: String) -> T {
        let obj = getJSONObjc(filePath: filePath)
        guard let model: T = MockJSFunc.parseFastDecodable(obj) else {
            fatalError("MockJSONDataManager parse model error: \(filePath)")
        }
        return model
    }
}

class MockJSFunc: SKExecJSFuncService {
    func callFunction(_ function: DocsJSCallBack, params: [String: Any]?, completion: ((Any?, Error?) -> Void)?) {
        
    }
}
