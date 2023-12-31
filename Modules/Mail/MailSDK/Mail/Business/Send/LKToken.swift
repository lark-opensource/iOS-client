//
//  LKToken.swift
//  LKTokenInputView
//
//  Created by majx on 05/26/19 from CLTokenInputView-Swift by Robert La Ferla.
//  
//

import Foundation

enum LKTokenStatus {
    case normal
    case error
}

class LKToken {
    var displayText: String {
        var text = ""
        if !forceDisplay.isEmpty {
            text = forceDisplay
        } else if !displayName.isEmpty {
            text = displayName
        } else if !name.isEmpty {
            text = name
        } else if !address.isEmpty {
            text = address
        } else {
            mailAssertionFailure("token displayName empty")
        }
        return text
    }

    var forceDisplay: String = ""
    var name: String = ""
    var displayName: String = ""
    var address: String = ""
    var context: AnyObject?
    var status: LKTokenStatus = .normal
    var selected: Bool = false
    var draging: Bool = false
}

extension LKToken: Equatable {}

func == (lhs: LKToken, rhs: LKToken) -> Bool {
    if lhs.displayText == rhs.displayText && lhs.context?.isEqual(rhs.context) == true {
        return true
    } else if !lhs.address.isEmpty && lhs.address.lowercased() == rhs.address.lowercased() {
        // 名字不同、地址为""的不会在这里被判为相同
        return true
    } else if lhs.displayText == rhs.displayText && ( lhs.address.isEmpty && rhs.address.isEmpty ) {
        return true
    }
    return false
}
