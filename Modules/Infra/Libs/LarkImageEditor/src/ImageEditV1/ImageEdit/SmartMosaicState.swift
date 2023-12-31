//
//  SmartMosaicState.swift
//  LarkImageEditor
//
//  Created by Fan Xia on 2021/3/26.
//

import Foundation

enum SmartMosaicState: Equatable {
    case ready
    case loading
    case fail(_ reason: String)
}
