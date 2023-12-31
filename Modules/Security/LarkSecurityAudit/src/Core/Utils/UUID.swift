//
//  UUID.swift
//  LarkSecurityAudit
//
//  Created by Yiming Qu on 2020/12/29.
//

import Foundation

func uuid() -> String {
    let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    return String((0...9).map { _ in letters.randomElement()! })
}
