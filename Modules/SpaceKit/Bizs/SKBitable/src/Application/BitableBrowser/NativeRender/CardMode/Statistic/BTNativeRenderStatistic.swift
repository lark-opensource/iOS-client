//
//  BTNativeRenderStatistic.swift
//  SKBitable
//
//  Created by X-MAN on 2023/11/13.
//

import Foundation

protocol BTNativeRenderCardStatisticProtocol {
    var setData: TimeInterval { get }
    var layout: TimeInterval { get }
    var draw: TimeInterval { get }
    var type: NativeRenderViewType { get }
}

protocol BTNativeRenderFieldStatisticProtocol {
    var setData: TimeInterval { get }
    var layout: TimeInterval { get }
    var draw: TimeInterval { get }
    var type: BTFieldUIType { get }
}
