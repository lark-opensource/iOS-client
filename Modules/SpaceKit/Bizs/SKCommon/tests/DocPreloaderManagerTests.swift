//
//  DocPreloaderManagerTests.swift
//  SKCommon-Unit-Tests
//
//  Created by liujinwei on 2023/9/14.
//  


import Foundation
@testable import SKCommon
import XCTest

final class DocPreloaderManagerTests: XCTestCase {
    
    private func filter<S: Sequence>(_ keys: S, with rules:  [String: [String]]) -> [PreloadKey] where S.Element == PreloadKey {
        return keys.filter { key in
            if let rules = rules[key.type.name] {
                return !rules.contains(key.fromSource?.rawValue ?? "")
            } else if let defaultRules = rules["default"] {
                return !defaultRules.contains(key.fromSource?.rawValue ?? "")
            }
            return true
        }
    }
    
    func testFilter() {
        let result1 = filter(preloadKeys1, with: rule1)
        let result2 = filter(preloadKeys1, with: rule2)
        let result3 = filter(preloadKeys1, with: rule3)
        let result4 = filter(preloadKeys2, with: rule1)
        let result5 = filter(preloadKeys2, with: rule2)
        let result6 = filter(preloadKeys2, with: rule3)
        let result7 = filter(preloadKeys3, with: rule1)
        let result8 = filter(preloadKeys3, with: rule2)
        let result9 = filter(preloadKeys3, with: rule3)
        XCTAssertTrue(result1.tokens.elementsEqual(["1", "2"]))
        XCTAssertTrue(result2.tokens.elementsEqual([]))
        XCTAssertTrue(result3.tokens.elementsEqual(["1", "2"]))
        XCTAssertTrue(result4.tokens.elementsEqual(["1", "2"]))
        XCTAssertTrue(result5.tokens.elementsEqual([]))
        XCTAssertTrue(result6.tokens.elementsEqual(["1"]))
        XCTAssertTrue(result7.tokens.elementsEqual(["1", "2"]))
        XCTAssertTrue(result8.tokens.elementsEqual(["2"]))
        XCTAssertTrue(result9.tokens.elementsEqual(["1"]))
    }
    
    let rule1: [String: [String]] = [:]
    
    let rule2 = [
        "default": ["tab_recent"]
    ]
    
    let rule3 = [
        "default": ["tab_recent", "chat_p2p"],
        "docx": ["chat_p2p"]
    ]
    
    let preloadKeys1 = [
        PreloadKey(objToken: "1", type: .docX, source: .recent),
        PreloadKey(objToken: "2", type: .docX, source: .recent)
    ]
    
    let preloadKeys2 = [
        PreloadKey(objToken: "1", type: .docX, source: .recent),
        PreloadKey(objToken: "2", type: .sheet, source: .recent)
    ]
    
    let preloadKeys3 = [
        PreloadKey(objToken: "1", type: .docX, source: .recent),
        PreloadKey(objToken: "2", type: .sheet, source: .chatP2P)
    ]
}

extension Sequence where Element == PreloadKey {
    var tokens: [String] {
        return self.map { $0.objToken }
    }
}
