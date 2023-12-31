//
//  BizLogicBox.swift
//  Calendar
//
//  Created by Rico on 2021/9/16.
//

import Foundation

protocol BizLogicBox {

    associatedtype Base

    var source: Base { get }
}
