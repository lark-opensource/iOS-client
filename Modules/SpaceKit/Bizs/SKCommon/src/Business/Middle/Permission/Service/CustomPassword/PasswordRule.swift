//
//  PasswordRule.swift
//  SKCommon
//
//  Created by Weston Wu on 2023/11/28.
//

import Foundation
import SKFoundation
import SKInfra

private extension CodingUserInfoKey {
    static var passwordDecodeHelperCodingKey: CodingUserInfoKey? {
        CodingUserInfoKey(rawValue: "passwordDecodeHelperCodingKey")
    }
}

private extension Decoder {
    var passwordDecodeHelper: PasswordDecodeHelper? {
        guard let codingKey = CodingUserInfoKey.passwordDecodeHelperCodingKey,
              let proxy = userInfo[codingKey] as? PasswordDecodeHelper else {
            return nil
        }
        return proxy
    }
}

enum PasswordRuleError: Error, Equatable {
    case decodeHelperNotFound
    case expressionValueNotFound(key: String)
}


class PasswordDecodeHelper {
    var expressionMap: [String: String] = [:]

    static func setup(decoder: JSONDecoder) {
        guard let codingKey = CodingUserInfoKey.passwordDecodeHelperCodingKey else {
            spaceAssertionFailure()
            return
        }
        decoder.userInfo[codingKey] = PasswordDecodeHelper()
    }
}

struct PasswordRequirement: Decodable {

    let matchExpressions: [NSRegularExpression]
    let notMatchExpressions: [NSRegularExpression]
    let message: String

    enum CodingKeys: String, CodingKey {
        case matchExpressions = "match_reg"
        case notMatchExpressions = "not_match_reg"
        case message = "msg"
    }

    init(from decoder: Decoder) throws {
        guard let expressionMap = decoder.passwordDecodeHelper?.expressionMap else {
            throw PasswordRuleError.decodeHelperNotFound
        }
        let container = try decoder.container(keyedBy: CodingKeys.self)
        matchExpressions = try container.decode([String].self, forKey: .matchExpressions)
            .map { key in
                guard let pattern = expressionMap[key] else {
                    throw PasswordRuleError.expressionValueNotFound(key: key)
                }
                return try NSRegularExpression(pattern: pattern)
            }
        notMatchExpressions = try container.decode([String].self, forKey: .notMatchExpressions)
            .map { key in
                guard let pattern = expressionMap[key] else {
                    throw PasswordRuleError.expressionValueNotFound(key: key)
                }
                return try NSRegularExpression(pattern: pattern)
            }
        message = try container.decode(String.self, forKey: .message)
    }

    init(matchExpressions: [NSRegularExpression], notMatchExpressions: [NSRegularExpression], message: String) {
        self.matchExpressions = matchExpressions
        self.notMatchExpressions = notMatchExpressions
        self.message = message
    }

    func validate(password: String) -> Bool {
        let range = NSRange(location: 0, length: (password as NSString).length)
        for expression in matchExpressions {
            guard expression.firstMatch(in: password, range: range) != nil else {
                return false
            }
        }
        for expression in notMatchExpressions {
            if expression.firstMatch(in: password, range: range) != nil {
                return false
            }
        }
        return true
    }
}

struct PasswordLevelRule: Decodable {

    enum Level: Equatable {
        case strong(message: String)
        case middle(message: String)
        case weak(message: String)
        case unknown
    }

    let strongRequirements: [PasswordRequirement]
    let middleRequirements: [PasswordRequirement]
    let weakRequirements: [PasswordRequirement]

    enum CodingKeys: String, CodingKey {
        case strong
        case middle
        case weak
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        strongRequirements = try container.decode([PasswordRequirement].self, forKey: .strong)
        middleRequirements = try container.decode([PasswordRequirement].self, forKey: .middle)
        weakRequirements = try container.decode([PasswordRequirement].self, forKey: .weak)
    }

    init(strongRequirements: [PasswordRequirement],
         middleRequirements: [PasswordRequirement],
         weakRequirements: [PasswordRequirement]) {
        self.strongRequirements = strongRequirements
        self.middleRequirements = middleRequirements
        self.weakRequirements = weakRequirements
    }

    static var empty: PasswordLevelRule {
        PasswordLevelRule(strongRequirements: [], middleRequirements: [], weakRequirements: [])
    }

    func validate(password: String) -> Level {
        if let fullfillRequirement = strongRequirements.first(where: { $0.validate(password: password) }) {
            return .strong(message: fullfillRequirement.message)
        }

        if let fullfillRequirement = middleRequirements.first(where: { $0.validate(password: password) }) {
            return .middle(message: fullfillRequirement.message)
        }

        if let fullfillRequirement = weakRequirements.first(where: { $0.validate(password: password) }) {
            return .weak(message: fullfillRequirement.message)
        }
        return .unknown
    }
}

struct PasswordRuleSet: Decodable {
    let matchRequirements: [PasswordRequirement]
    let notMatchRequirements: [PasswordRequirement]
    let passwordLevelRule: PasswordLevelRule

    enum CodingKeys: String, CodingKey {
        case expressionMap = "reg_exp_map"
        case passwordRequirements = "pwd_check_tips"
        case passwordLevel = "pwd_level"
    }

    enum RequirementCodingKeys: String, CodingKey {
        case matchRequirements = "match_tips"
        case notMatchRequirements = "not_match_tips"
    }

    static var empty: PasswordRuleSet {
        PasswordRuleSet(matchRequirements: [], notMatchRequirements: [], passwordLevelRule: .empty)
    }

    init(matchRequirements: [PasswordRequirement], notMatchRequirements: [PasswordRequirement], passwordLevelRule: PasswordLevelRule) {
        self.matchRequirements = matchRequirements
        self.notMatchRequirements = notMatchRequirements
        self.passwordLevelRule = passwordLevelRule
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let expressionMap = try container.decode([String: String].self, forKey: .expressionMap)
        decoder.passwordDecodeHelper?.expressionMap = expressionMap
        let requirementContainer = try container.nestedContainer(keyedBy: RequirementCodingKeys.self, forKey: .passwordRequirements)
        matchRequirements = try requirementContainer.decode([PasswordRequirement].self, forKey: .matchRequirements)
        notMatchRequirements = try requirementContainer.decode([PasswordRequirement].self, forKey: .notMatchRequirements)
        passwordLevelRule = try container.decode(PasswordLevelRule.self, forKey: .passwordLevel)
    }
}
