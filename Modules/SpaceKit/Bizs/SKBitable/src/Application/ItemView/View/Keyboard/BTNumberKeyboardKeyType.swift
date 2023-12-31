//
//  BTNumberKeyboardKeyType.swift
//  SKBitable
//
//  Created by 曾浩泓 on 2022/4/12.
//  


import Foundation

enum BTNumberKeyboardKeyType {
    case digital(Int)
    case function(BTNumberKeyboardFunctionKeyType)
}
enum BTNumberKeyboardFunctionKeyType: String {
    case point
    case sign
    case delete
    case done
}
extension BTNumberKeyboardKeyType: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case let (.digital(num1), .digital(num2)): return num1 == num2
        case let (.function(funcType1), .function(funcType2)): return funcType1 == funcType2
        case (.digital(_), .function(_)), (.function(_), .digital(_)): return false
        }
    }
}
