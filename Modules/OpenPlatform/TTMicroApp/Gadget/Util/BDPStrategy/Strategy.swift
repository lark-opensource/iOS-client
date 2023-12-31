//
//  Strategy.swift
//  Timor
//
//  Created by changrong on 2020/9/25.
//

import Foundation
import LarkOPInterface
import OPFoundation

enum StrategyActionOp: String, Decodable {
    case equal = "="
    case less = "<"
    case lessOrEqual = "<="
    case more = ">"
    case moreOrEqual = ">="
}

enum StrategyActionType: String, Decodable {
    case actionBreak = "break"
    case actionContinue = "continue"
}


enum StrategyValue: Comparable {
    case string(String)
    case number(Float)
    case bool(Bool)

    static func < (lhs: StrategyValue, rhs: StrategyValue) -> Bool {
        switch (lhs, rhs) {
        case (.number(let l), .number(let r)):
            return l < r
        default:
            return false
        }
    }
    
    static func == (lhs: StrategyValue, rhs: StrategyValue) -> Bool {
        switch (lhs, rhs) {
        case (.number(let l), .number(let r)):
            return l == r
        case (.string(let l), .string(let r)):
            return l == r
        case (.bool(let l), .bool(let r)):
            return l == r
        default:
            return false
        }
    }
}

struct StrategyOption: Decodable {
    var type: String
    var op: StrategyActionOp
    var value: StrategyValue
    
    enum CodingKeys: String, CodingKey {
        case type
        case op
        case value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(String.self, forKey: .type)
        op = try container.decode(StrategyActionOp.self, forKey: .op)
        if let v = try? container.decode(String.self, forKey: .value) {
            value = .string(v)
        } else if let v = try? container.decode(Bool.self, forKey: .value) {
            value = .bool(v)
        } else if let v = try? container.decode(Int.self, forKey: .value) {
            value = .number(Float(v))
        } else if let v = try? container.decode(Float.self, forKey: .value) {
            value = .number(v)
        } else {
            throw OPError.error(monitorCode: CommonMonitorCode.invalid_params, message: "strategy config value decode fail!")
        }
    }
    
    func compare(_ lhs: StrategyValue) -> Bool {
        switch op {
        case .equal:
            return lhs == value
        case .less:
            return lhs < value
        case .lessOrEqual:
            return lhs <= value
        case .more:
            return lhs > value
        case .moreOrEqual:
            return lhs >= value
        }
    }
}

struct StrategyAction: Decodable {
    var commands: [String]
    var options: [[String]]
}

struct StrategyConfig: Decodable {
    var configs: [String: StrategyOption]
    var actions: [StrategyAction]
    var actionMethod: StrategyActionType?
    
    enum CodingKeys: String, CodingKey {
        case configs = "configs"
        case actions = "actions"
        case actionMethod = "action_method"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        configs = try container.decode([String: StrategyOption].self, forKey: .configs)
        actions = try container.decode([StrategyAction].self, forKey: .actions)
        if container.contains(.actionMethod) {
            actionMethod = try container.decode(StrategyActionType.self, forKey: .actionMethod)
        }
    }
}
