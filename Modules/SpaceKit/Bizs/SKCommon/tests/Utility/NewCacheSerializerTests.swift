//
//  NewCacheSerializerTests.swift
//  SpaceDemoTests
//
//  Created by chensi on 2023/9/5.
//  Copyright © 2023 Bytedance.All rights reserved.


import Foundation
import XCTest
@testable import SKCommon
import SKFoundation

final class NewCacheSerializerTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }
    
    override func tearDown() {
        super.tearDown()
    }
    
    //MARK: 测试素材
    
    func getNormalString() -> String {
        "this is normal string"
    }
    
    func getEmptyString() -> String {
        ""
    }
    
    func getSpecialString() -> String {
        // TODO.chensi 待添加更多特殊字符
        "😀😇🀋🀋🀏🀗🀗xzxknapiosca\\\\∨∨＜＜Πογβμǜǜǜü😀😇bos😀😇bos😀"
    }
    
    func getNull() -> NSNull {
        NSNull()
    }
    
    func getNormalNumber1() -> NSNumber {
        NSNumber(floatLiteral: 9.527123456789001)
    }
    
    func getNormalNumber2() -> NSNumber {
        NSNumber(integerLiteral: 398164961294398)
    }
    
    func getInvalidNumber1() -> NSNumber {
        NSNumber(floatLiteral: Double.infinity)
    }
    
    func getInvalidNumber2() -> NSNumber {
        NSNumber(floatLiteral: Double.nan)
    }
    
    func getSampleDict() -> [String: Any] {
        var dict = [String: Any]()
        dict["string1"] = getNormalString()
        dict["string2"] = getEmptyString()
        dict["string3"] = getSpecialString()
        dict["number1"] = getNormalNumber1()
        dict["number2"] = getNormalNumber2()
        dict["number3"] = getInvalidNumber1()
        dict["number4"] = getInvalidNumber2()
        dict["null"] = getNull()
        return dict
    }
    
    
    
    //MARK: 测试方法
    
    func testNSCoding_encode_decode() {
        let input = getSampleDict()
        let data = _encode(useJSONSerialization: false, input: input)
        let output = _decode(useJSONSerialization: false, input: data)
        
        let allMatched = output.allSatisfy { (key, valueA) in
            let valueB = input[key]
            return "\(valueA)" == "\(valueB!)"
        }
        
        XCTAssert(allMatched, "input & output not match, input:\(input), output:\(output)")
    }
    
    func testJSON_encode_decode() {
        let input = getSampleDict()
        let data = _encode(useJSONSerialization: true, input: input)
        let output = _decode(useJSONSerialization: true, input: data)
        
        let allMatched = output.allSatisfy { (key, valueA) in
            let valueB = input[key]
            return "\(valueA)" == "\(valueB!)"
        }
        
        XCTAssert(allMatched, "input & output not match, input:\(input), output:\(output)")
    }
    
    func testNSCoding_encode_JSON_decode() {
        let input = getSampleDict()
        let data = _encode(useJSONSerialization: false, input: input)
        let output = _decode(useJSONSerialization: true, input: data)
        
        let allMatched = output.allSatisfy { (key, valueA) in
            let valueB = input[key]
            return "\(valueA)" == "\(valueB!)"
        }
        
        XCTAssert(allMatched, "input & output not match, input:\(input), output:\(output)")
    }
    
    func testJSON_encode_NSCoding_decode() {
        let input = getSampleDict()
        let data = _encode(useJSONSerialization: true, input: input)
        let output = _decode(useJSONSerialization: false, input: data)
        
        let allMatched = output.allSatisfy { (key, valueA) in
            let valueB = input[key]
            return "\(valueA)" == "\(valueB!)"
        }
        
        XCTAssert(allMatched, "input & output not match, input:\(input), output:\(output)")
    }
    
    
    //MARK: 辅助方法
    
    func _encode(useJSONSerialization: Bool, input: [String: Any]) -> Data {
        
        let serializer = NewCacheSerializer(userID: "user")
        serializer.setJsonSerializationEnabeld(useJSONSerialization)
        
        let data: Data
        do {
            data = try serializer.encodeObject(input as NSDictionary)
        } catch {
            NSLog("encode error:\(error), useJSONSerialization:\(useJSONSerialization), input:\(input)")
            data = Data()
        }
        return data
    }
    
    func _decode(useJSONSerialization: Bool, input: Data) -> [String: Any] {
        
        let serializer = NewCacheSerializer(userID: "user")
        serializer.setJsonSerializationEnabeld(useJSONSerialization)
        
        let object: [String: Any]
        do {
            object = (try serializer.decodeData(input)) as? [String: Any] ?? [:]
        } catch {
            NSLog("decode error:\(error), useJSONSerialization:\(useJSONSerialization), input:\(input.count)")
            object = [String: Any]()
        }
        return object
    }
}
