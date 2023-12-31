//
//  BTOpenCardModelTest.swift
//  SKBitable-Unit-Tests
//
//  Created by X-MAN on 2023/3/8.
//

import Foundation
import XCTest
@testable import SKBitable
@testable import SKFoundation

class BTOpenCardModelTest: XCTestCase {
    
    func testDeserialized() {
        // 输入为空
        let segment = BTRichTextSegmentModel.deserialized(with: [:])
        // 验证默认值
        XCTAssert(segment.type == .text)
        // 验证nil
        XCTAssertNil(segment.editType)
        // 输入有效值
        let filterInfo = BTFilterInfos.deserialized(with: ["conjunction": "is", "conditions": [["invalidType": 1]]])
        XCTAssert(filterInfo.conjunction == "is")
        XCTAssert(filterInfo.conditions.count == 1)
        // 验证 model 包含子model 子subModel为 [subModel], 并且包含枚举
        XCTAssert(filterInfo.conditions.first?.invalidType == .fieldUnreadable)
        let meta = BTTableMeta.deserialized(with: ["fields": [
            "fieldId": ["id": "1111", "allowedEditModes": ["scan": true, "manual": false]]
        ]])
        XCTAssert(meta.fields["fieldId"]?.id == "1111")
        XCTAssert(meta.fields["fieldId"]?.allowedEditModes.scan == true)
        XCTAssert(meta.fields["fieldId"]?.allowedEditModes.manual == false)
        let mentionIcon = BTMentionIconModel.deserialized(with: [:])
        XCTAssert(mentionIcon.key == "")
        let option = BTOptionModel.deserialized(with: [:])
        XCTAssert(option.id == "")
        let dynamicRule = BTDynamicOptionRuleModel.deserialized(with: [:])
        XCTAssert(dynamicRule.conjunction == "and")
        let dynamicCondition = BTDynamicOptionConditionModel.deserialized(with: [:])
        XCTAssert(dynamicCondition.fieldType == .text)
        let action = BTActionParamsModel.deserialized(with: [:])
        XCTAssert(action.action == .showCard)
        let actionPayload = BTPayloadModel.deserialized(with: [:])
        XCTAssert(actionPayload.baseId == "")
        let formSubmmitError = BTFormSubmitCellError.deserialized(with: [:])
        XCTAssert(formSubmmitError.errorCode == 0)
        let submmitReason = ForbiddenSubmitReason.deserialized(with: [:])
        XCTAssert(submmitReason.reason == "")
        let button = BTButtonModel.deserialized(with: [:])
        XCTAssert(button.title == "")
        let buttonColor = BTButtonColorModel.deserialized(with: ["styles": ["style": ["bgColor": "0x000000", "textColor": "0x000000"]]])
        XCTAssert(buttonColor.name == "")
        XCTAssert(buttonColor.styles["style"]?.bgColor == "0x000000")
        let filterCondition = BTFilterCondition.deserialized(with: [:])
        XCTAssert(filterCondition.operator == "is")
        UserScopeNoChangeFG.setMockFG(key: "ccm.bitable.card_optimized", value: true)
        BTFieldMeta.desrializedGlobalAsync(with: [:], callbackInMainQueue: true) { model in
            XCTAssert(Thread.isMainThread)
            XCTAssert(model != nil)
        }
    }
    
}
