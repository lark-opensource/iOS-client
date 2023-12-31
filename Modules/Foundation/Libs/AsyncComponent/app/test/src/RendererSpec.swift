//
//  RendererSpec.swift
//  AsyncComponentDevEEUnitTest
//
//  Created by Ping on 2023/3/8.
//

import UIKit
import Foundation
import XCTest

@testable import AsyncComponent

class UIViewComponent: ASComponent<ASComponentProps, EmptyState, UIView, EmptyContext> {
}

class RendererSpec: XCTestCase {
    func testComponentKey() {
        if true {
            let root = UIViewComponent(props: .empty, style: .init())
            let rootLayout = ASLayoutComponent<EmptyContext>(style: .init(), [])
            let sub1 = UIViewComponent(props: .empty, style: .init())
            let sub2 = UIViewComponent(props: .empty, style: .init())
            root.setSubComponents([rootLayout])
            rootLayout.setSubComponents([sub1, sub2])

            let renderer = ASComponentRenderer(tag: 1, root)

            XCTAssertEqual(root.key, "1")
            XCTAssertEqual(rootLayout.key, "1.0")
            XCTAssertEqual(sub1.key, "1.0.0")
            XCTAssertEqual(sub2.key, "1.0.1")
        }

        if true {
            let root = UIViewComponent(props: .empty, style: .init())
            root.props.key = "root"
            let rootLayout = ASLayoutComponent<EmptyContext>(key: "rootLayout", style: .init(), [])
            let sub1 = UIViewComponent(props: .empty, style: .init())
            let sub2 = UIViewComponent(props: .empty, style: .init())
            root.setSubComponents([rootLayout])
            rootLayout.setSubComponents([sub1, sub2])

            let renderer = ASComponentRenderer(tag: 1, root)
            XCTAssertEqual(root.key, "root")
            XCTAssertEqual(rootLayout.key, "rootLayout")
            XCTAssertEqual(sub1.key, "rootLayout.0")
            XCTAssertEqual(sub2.key, "rootLayout.1")
        }

        if true {
            let root = UIViewComponent(props: .empty, style: .init())
            root.props.key = "root"
            let rootLayout = ASLayoutComponent<EmptyContext>(key: "rootLayout", style: .init(), [])
            let sub1 = UIViewComponent(props: .empty, style: .init())
            let sub2 = UIViewComponent(props: .empty, style: .init())
            root.setSubComponents([rootLayout])
            rootLayout.setSubComponents([sub1, sub2])

            let renderer = ASComponentRenderer(tag: 1, root)
            XCTAssertEqual(root.key, "root")
            XCTAssertEqual(rootLayout.key, "rootLayout")
            XCTAssertEqual(sub1.key, "rootLayout.0")
            XCTAssertEqual(sub2.key, "rootLayout.1")

            let sub3 = UIViewComponent(props: .empty, style: .init())
            rootLayout.setSubComponents([sub1, sub3, sub2])
            renderer.update(rootComponent: root)

            XCTAssertEqual(root.key, "root")
            XCTAssertEqual(rootLayout.key, "rootLayout")
            XCTAssertEqual(sub1.key, "rootLayout.0")
            XCTAssertEqual(sub2.key, "rootLayout.2")
            XCTAssertEqual(sub3.key, "rootLayout.1")
        }
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
