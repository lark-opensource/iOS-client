//
//  patchSpec.swift
//  AsyncComponentDevEEUnitTest
//
//  Created by qihongye on 2019/5/16.
//

import UIKit
import Foundation
import XCTest

@testable import AsyncComponent

class patchSpec: XCTestCase {
    var view: UIView!
    var viewWithLayer: UIView!

    override func setUp() {
        if (true) {
            view = UIView()
            let v1 = UILabel()
            v1.componentKey = "label1"
            view.addSubview(v1)
            let v2 = UIImageView()
            v2.componentKey = "imageview1"
            view.addSubview(v2)
            let v3 = UILabel()
            view.addSubview(v3)
            let v4 = UIView()
            v4.componentKey = "uiview4"
            view.addSubview(v4)
            let v5 = UILabel()
            v5.componentKey = "label2"
            view.addSubview(v5)
        }

        if (true) {
            let view = UIView()
            view.layer.addSublayer(CALayer())
            view.layer.addSublayer(CALayer())
            let v1 = UILabel()
            v1.componentKey = "label1"
            view.addSubview(v1)
            let v2 = UIImageView()
            v2.componentKey = "imageview1"
            view.addSubview(v2)
            let v3 = UILabel()
            view.addSubview(v3)
            let v4 = UIView()
            v4.componentKey = "uiview4"
            view.addSubview(v4)
            let v5 = UILabel()
            v5.componentKey = "label2"
            view.addSubview(v5)
            viewWithLayer = view
        }
    }

    override func tearDown() {
        for subview in view.subviews {
            subview.removeFromSuperview()
        }
        for subview in viewWithLayer.subviews {
            subview.removeFromSuperview()
        }
    }

    func testViewTreeWithASCreatedView() {
        var viewTree = ViewTree(view)
        let uilabel = ObjectIdentifier(UILabel.self)
        let uiimageView = ObjectIdentifier(UIImageView.self)
        let uiview = ObjectIdentifier(UIView.self)
        let expectViewTagMap: [Int: [Int]] = [
            uilabel.hashValue: [0, 4],
            uiimageView.hashValue: [1],
            uiview.hashValue: [3]
        ]
        XCTAssertEqual(viewTree.viewTagMap, expectViewTagMap)
        viewTree.exchangeSubview(at: 0, withSubviewAt: 1)
        XCTAssertEqual(view.subviews[0].reflectingTag, uiimageView)
        XCTAssertEqual(view.subviews[1].reflectingTag, uilabel)

        let expectExchangedViewTagMap1: [Int: [Int]] = [
            uilabel.hashValue: [1, 4],
            uiimageView.hashValue: [0],
            uiview.hashValue: [3]
        ]
        XCTAssertEqual(viewTree.viewTagMap, expectExchangedViewTagMap1)

        viewTree.exchangeSubview(at: 2, withSubviewAt: 0)
        XCTAssertEqual(view.subviews[3].reflectingTag, uiview)
        XCTAssertEqual(view.subviews[0].reflectingTag, uiimageView)

        let expectExchangedViewTagMap2: [Int: [Int]] = [
            uilabel.hashValue : [1, 4],
            uiimageView.hashValue: [0],
            uiview.hashValue: [3]
        ]
        XCTAssertEqual(viewTree.viewTagMap, expectExchangedViewTagMap2)

        viewTree.exchangeSubview(at: 2, withSubviewAt: 0)
        viewTree.exchangeSubview(at: 0, withSubviewAt: 1)
        XCTAssertEqual(view.subviews.map({ $0.reflectingTag }), [uilabel, uiimageView, uilabel, uiview, uilabel])
        XCTAssertEqual(viewTree.viewTagMap, expectViewTagMap)
    }

    func testViewTreeWithLayerAndASCreated() {
        let view = self.viewWithLayer!
        var viewTree = ViewTree(view)
        let uilabel = ObjectIdentifier(UILabel.self)
        let uiimageView = ObjectIdentifier(UIImageView.self)
        let uiview = ObjectIdentifier(UIView.self)
        let expectViewTagMap: [Int: [Int]] = [
            uilabel.hashValue: [0, 4],
            uiimageView.hashValue: [1],
            uiview.hashValue: [3]
        ]
        XCTAssertEqual(viewTree.findAvalibleViewIndex(uilabel.hashValue), 0)
        XCTAssertEqual(viewTree.findAvalibleViewIndex(uiimageView.hashValue), 1)
        XCTAssertEqual(viewTree.findAvalibleViewIndex(uiview.hashValue), 3)
        XCTAssertEqual(viewTree.viewTagMap, expectViewTagMap)
        XCTAssertEqual(viewTree.subviews, [2, 3, 4, 5, 6])
        viewTree.exchangeSubview(at: 0, withSubviewAt: 1)
        XCTAssertEqual(view.subviews[0].reflectingTag, uiimageView)
        XCTAssertEqual(view.subviews[1].reflectingTag, uilabel)

        let expectExchangedViewTagMap1: [Int: [Int]] = [
            uilabel.hashValue: [1, 4],
            uiimageView.hashValue: [0],
            uiview.hashValue: [3]
        ]
        XCTAssertEqual(viewTree.viewTagMap, expectExchangedViewTagMap1)

        viewTree.exchangeSubview(at: 2, withSubviewAt: 0)
        XCTAssertEqual(view.subviews[3].reflectingTag, uiview)
        XCTAssertEqual(view.subviews[0].reflectingTag, uiimageView)

        let expectExchangedViewTagMap2: [Int: [Int]] = [
            uilabel.hashValue : [1, 4],
            uiimageView.hashValue: [0],
            uiview.hashValue: [3]
        ]
        XCTAssertEqual(viewTree.viewTagMap, expectExchangedViewTagMap2)

        viewTree.exchangeSubview(at: 2, withSubviewAt: 0)
        viewTree.exchangeSubview(at: 0, withSubviewAt: 1)
        XCTAssertEqual(view.subviews.map({ $0.reflectingTag }), [uilabel, uiimageView, uilabel, uiview, uilabel])
        XCTAssertEqual(viewTree.viewTagMap, expectViewTagMap)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
