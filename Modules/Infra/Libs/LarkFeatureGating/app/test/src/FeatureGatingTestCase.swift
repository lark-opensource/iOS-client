//
//  FeatureGatingTestCase.swift
//  LarkFeatureGatingDevEEUnitTest
//
//  Created by huangjianming on 2020/2/20.
//

import Foundation
import XCTest
import RxSwift
@testable import LarkFeatureGating

/// 每个test方法中记得使用不同的key
class FeatureGatingTestCase: XCTestCase {
    override func setUp() {
        super.setUp()
        // 不触发内部的assert
        LarkFeatureGating.NDEBUG = true
        // 测试一个case前清空fg内部缓存
        LarkFeatureGating.shared.loadFeatureValues(with: "my_user_id")
    }

    @FeatureGating(.secretChat) private var featureGating: Bool
    @ABTest(.testRustABTestFunction) private var aBTest: Bool
    /// propertyWrapper
    func testPropertyWrapper() {
        XCTAssertNoThrow(self.featureGating)
        XCTAssertNoThrow(self.aBTest)
    }

    /// getFeatureBoolValue
    func testGetFeatureBoolValue() {
        let keyResult = LarkFeatureGating.shared.getFeatureBoolValue(for: .secretChat)
        let stringResul = LarkFeatureGating.shared.getFeatureBoolValue(for: "secretchat.main")
        XCTAssertEqual(keyResult, stringResul)
    }

    /// getABTestValue
    func testGetABTestValue() {
        let keyResult = LarkFeatureGating.shared.getABTestValue(for: .testRustABTestFunction)
        XCTAssertEqual(keyResult, false)
    }

    /// getStaticBoolValue
    func testGetStaticBoolValue() {
        let keyResult = LarkFeatureGating.shared.getStaticBoolValue(for: .secretChat)
        let stringResul = LarkFeatureGating.shared.getStaticBoolValue(for: "secretchat.main")
        XCTAssertEqual(keyResult, stringResul)
    }

    /// featureGatingKeyNotify
    func testFeatureGatingKeyNotify() {
        let disposeBag = DisposeBag()
        LarkFeatureGating.shared.featureGatingKeyNotify.subscribe(onNext: { (features) in
            if features[.larkTenantPenetrationEnable] ?? false == false {
                XCTAssert(false)
            }
        }).disposed(by: disposeBag)
        LarkFeatureGating.shared.updateFeatureBoolValue(for: "lark.tenant.penetration.enable", value: true)
    }

    /// featureGatingStringNotify
    func testFeatureGatingStringNotify() {
        let disposeBag = DisposeBag()
        LarkFeatureGating.shared.featureGatingStringNotify.subscribe(onNext: { (features) in
            if features["im_chat_config_page_redesign_202001"] ?? false == false {
                XCTAssert(false)
            }
        }).disposed(by: disposeBag)
        LarkFeatureGating.shared.updateFeatureBoolValue(for: "im_chat_config_page_redesign_202001", value: true)
    }

    /// updateFeatureBoolValue
    func testUpdateFeatureBoolValue() {
        XCTAssertFalse(LarkFeatureGating.shared.getFeatureBoolValue(for: "suite.ai.smart_camera_ocr_enabled"))
        LarkFeatureGating.shared.updateFeatureBoolValue(for: "suite.ai.smart_camera_ocr_enabled", value: true)
        XCTAssertTrue(LarkFeatureGating.shared.getFeatureBoolValue(for: "suite.ai.smart_camera_ocr_enabled"))
    }

    /// getFeatureSetCache
    func testGetFeatureSetCache() {
        LarkFeatureGating.shared.updateFeatureBoolValue(for: "byteview.asr.subtitle", value: true)
        XCTAssert(LarkFeatureGating.shared.getFeatureSetCache().keys.contains("byteview.asr.subtitle"))
    }
}
