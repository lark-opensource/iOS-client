//
//  PasswordRuleTests.swift
//  SKCommon-Unit-Tests
//
//  Created by Weston Wu on 2023/12/7.
//

import Foundation
@testable import SKCommon
import XCTest

private extension CodingUserInfoKey {
    static var passwordDecodeHelperCodingKey: CodingUserInfoKey {
        CodingUserInfoKey(rawValue: "passwordDecodeHelperCodingKey")!
    }
}

class PasswordRuleTests: XCTestCase {
    func testSetupDecoder() {
        let decoder = JSONDecoder()
        PasswordDecodeHelper.setup(decoder: decoder)
        XCTAssertNotNil(decoder.userInfo[.passwordDecodeHelperCodingKey])
    }

    func testDecodeRequirement() {
        let data = """
        {
            "match_reg": ["match1", "match2"],
            "not_match_reg": ["not_match1", "not_match2", "not_match3"],
            "msg": "test"
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let helper = PasswordDecodeHelper()
        helper.expressionMap = [
            "match1": "a",
            "match2": "b",
            "not_match1": "c",
            "not_match2": "d",
            "not_match3": "e"
        ]
        decoder.userInfo[.passwordDecodeHelperCodingKey] = helper
        do {
            let requirement = try decoder.decode(PasswordRequirement.self, from: data)
            XCTAssertEqual(requirement.matchExpressions.count, 2)
            XCTAssertEqual(requirement.notMatchExpressions.count, 3)
            XCTAssertEqual(requirement.message, "test")
        } catch {
            XCTFail("\(error)")
        }
    }

    func testDecodeRequirementFailed() {
        let data = """
        {
            "match_reg": ["match1", "match2"],
            "not_match_reg": ["not_match1", "not_match2", "not_match3"],
            "msg": "test"
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let helper = PasswordDecodeHelper()
        do {
            _ = try decoder.decode(PasswordRequirement.self, from: data)
            XCTFail("expect notFound error")
        } catch PasswordRuleError.decodeHelperNotFound {
            // expect
        } catch {
            XCTFail("unexpect error: \(error)")
        }

        decoder.userInfo[.passwordDecodeHelperCodingKey] = helper
        do {
            _ = try decoder.decode(PasswordRequirement.self, from: data)
            XCTFail("expect error")
        } catch let PasswordRuleError.expressionValueNotFound(key) {
            XCTAssertEqual(key, "match1")
        } catch {
            XCTFail("\(error)")
        }

        helper.expressionMap = [
            "match1": "a",
            "match2": "b",
            "not_match1": "c",
            "not_match2": "d",
        ]
        do {
            _ = try decoder.decode(PasswordRequirement.self, from: data)
            XCTFail("expect error")
        } catch let PasswordRuleError.expressionValueNotFound(key) {
            XCTAssertEqual(key, "not_match3")
        } catch {
            XCTFail("\(error)")
        }
    }

    func testValidateRequirement() {
        let data = """
        {
            "match_reg": ["match1"],
            "not_match_reg": ["not_match1"],
            "msg": "test"
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let helper = PasswordDecodeHelper()
        helper.expressionMap = [
            "match1": "a",
            "not_match1": "c"
        ]
        decoder.userInfo[.passwordDecodeHelperCodingKey] = helper
        do {
            let requirement = try decoder.decode(PasswordRequirement.self, from: data)
            XCTAssertTrue(requirement.validate(password: "ab"))
            XCTAssertFalse(requirement.validate(password: "bb"))
            XCTAssertFalse(requirement.validate(password: "ac"))
        } catch {
            XCTFail("\(error)")
        }
    }

    func testPasswordLevel() {
        let data = """
        {
            "weak": [{
                "match_reg": ["weak"],
                "not_match_reg": [],
                "msg": "Weak"
            }],
            "strong": [{
                "msg": "Strong",
                "match_reg": ["strong"],
                "not_match_reg": []
            }],
            "middle": [{
                "match_reg": ["middle"],
                "not_match_reg": [],
                "msg": "Fair"
            }]
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        let helper = PasswordDecodeHelper()
        helper.expressionMap = [
            "weak": "weak",
            "strong": "strong",
            "middle": "middle"
        ]
        decoder.userInfo[.passwordDecodeHelperCodingKey] = helper
        do {
            let levelRule = try decoder.decode(PasswordLevelRule.self, from: data)
            XCTAssertEqual(levelRule.strongRequirements.count, 1)
            XCTAssertEqual(levelRule.middleRequirements.count, 1)
            XCTAssertEqual(levelRule.weakRequirements.count, 1)
            XCTAssertEqual(levelRule.validate(password: "strong"), .strong(message: "Strong"))
            XCTAssertEqual(levelRule.validate(password: "middle"), .middle(message: "Fair"))
            XCTAssertEqual(levelRule.validate(password: "weak"), .weak(message: "Weak"))
            XCTAssertEqual(levelRule.validate(password: "other"), .unknown)
        } catch {
            XCTFail("\(error)")
        }
    }

    func testDecodeRuleSet() {
        let data = """
        {
            "reg_exp_map": {
                "match1": "1",
                "match2": "2",
                "not_match": "3",
                "weak": "weak",
                "middle": "middle",
                "strong": "strong"
            },
            "pwd_check_tips":{
                "match_tips":[
                    {
                        "match_reg": ["match1"],
                        "not_match_reg": [],
                        "msg": "match1"
                    },
                    {
                        "match_reg": ["match2"],
                        "not_match_reg": [],
                        "msg": "match2"
                    }
                ],
                "not_match_tips":[
                     {
                        "match_reg": [],
                        "not_match_reg": ["not_match"],
                        "msg": "not_match"
                    }
                ]
            },
            "pwd_level": {
                "weak": [{
                    "match_reg": ["weak"],
                    "not_match_reg": [],
                    "msg": "Weak"
                }],
                "strong": [{
                    "msg": "Strong",
                    "match_reg": ["strong"],
                    "not_match_reg": []
                }],
                "middle": [{
                    "match_reg": ["middle"],
                    "not_match_reg": [],
                    "msg": "Fair"
                }]
            }
        }
        """.data(using: .utf8)!
        let decoder = JSONDecoder()
        PasswordDecodeHelper.setup(decoder: decoder)
        do {
            let ruleSet = try decoder.decode(PasswordRuleSet.self, from: data)
            let levelRule = ruleSet.passwordLevelRule
            XCTAssertEqual(ruleSet.matchRequirements.count, 2)
            XCTAssertEqual(ruleSet.notMatchRequirements.count, 1)
            XCTAssertEqual(levelRule.strongRequirements.count, 1)
            XCTAssertEqual(levelRule.middleRequirements.count, 1)
            XCTAssertEqual(levelRule.weakRequirements.count, 1)
        } catch {
            XCTFail("\(error)")
        }
    }
}
