//
//  ToastModel.swift
//  WebAppBridge
//
//  Created by lijuyou on 2023/11/19.
//

import Foundation

enum ToastType: Int, Codable {
    case succ = 0
    case fail = 1
    case tipBottom = 2
    case tipCenter = 3
    case tipTop = 4
    case successWithAction = 5
    case tipWithAction = 6
    case warning = 7
    case loading = 8
}

struct ToastModel: Codable {
    let message: String
    let type: ToastType
    let duration: Float?
    let buttonMessage: String?
    
}
