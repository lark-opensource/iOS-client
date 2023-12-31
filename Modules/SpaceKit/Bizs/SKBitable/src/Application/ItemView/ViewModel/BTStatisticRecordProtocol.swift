//
//  BTStatisticRecordProtocol.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/9/18.
//

import Foundation

protocol BTStatisticRecordProtocol {
    var drawCount: (layout: Int, draw: Int) { get }
    var drawTime: (layout: Double, draw: Double) { get }
    var fieldModel: BTFieldModel { get }
}
