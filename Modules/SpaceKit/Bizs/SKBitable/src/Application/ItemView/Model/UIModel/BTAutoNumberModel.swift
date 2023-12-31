//
//  BTAutoNumberModel.swift
//  SKBitable
//
//  Created by zoujie on 2022/5/10.
//  


import Foundation
import HandyJSON

/// 自动编号字段
struct BTAutoNumberModel: HandyJSON, Equatable {
    static func == (lhs: BTAutoNumberModel, rhs: BTAutoNumberModel) -> Bool {
        return lhs.sequence == rhs.sequence &&
               lhs.number == rhs.number

    }
    var sequence: String = ""
    var number: String = ""

}
