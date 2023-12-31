//
//  DriveMessageModel.swift
//  SpaceKit
//
//  Created by 邱沛 on 2019/8/16.

import Foundation
import SwiftyJSON

enum DriveMessageQuoteType: String {
    case page = "comment.quote.page"
    case text = "comment.quote.text"
    case comment = "common.comment"
    init(type: String) {
        if let type = DriveMessageQuoteType(rawValue: type) {
            self = type
        } else {
            self = DriveMessageQuoteType.comment
        }
    }
}
