//
//  XMLTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/11/13.
//
// swiftlint:disable all
import XCTest
@testable import LarkListItem

final class XMLTest: XCTestCase {

    override func setUp() {

    }

    func testInnerText() {
        let data = "<r>123</r>".data(using: .utf8)!
        let xml = try! XML.Document(data: data)
        XCTAssertEqual(xml.root.innerText, "123")
    }

    func testInnerXML() {
        let data = "<r>123</r>".data(using: .utf8)!
        let xml = try! XML.Document(data: data)
        XCTAssertEqual(xml.root.innerXML, "123")
    }

    func testEscapeXML() {
        XCTContext.runActivity(named: "&") { _ in
            let data = "<r>123&amp;</r>".data(using: .utf8)!
            let xml = try! XML.Document(data: data)
            XCTAssertEqual(xml.root.innerText, "123&")
        }
        XCTContext.runActivity(named: "<") { _ in
            let data = "<r>123&lt;</r>".data(using: .utf8)!
            let xml = try! XML.Document(data: data)
            XCTAssertEqual(xml.root.innerText, "123<")
        }
        XCTContext.runActivity(named: ">") { _ in
            let data = "<r>123&gt;</r>".data(using: .utf8)!
            let xml = try! XML.Document(data: data)
            XCTAssertEqual(xml.root.innerText, "123>")
        }
    }

}
// swiftlint:enable all
