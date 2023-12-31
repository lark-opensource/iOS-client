//
//  SheetInputData.swift
//  SKBrowser
//
//  Created by lijuyou on 2022/11/30.
//  


import Foundation
import HandyJSON

public struct SheetInputData: HandyJSON {
    public init() {}
    
    public var value: [[String: Any]] = [] //单元格内局部样式数组
    public var style: SheetStyleJSON?    //单元格整体样式
    public var format: String = "text"
    public var dateType: String = "datetime"
    public var realValue: [SheetSegmentBase] = []
    public var cellInfo: String = "" //cellID,编辑后回传给web，检测是否在同一个cell上update
    
    public mutating func didFinishMapping() {
        realValue = SheetSegmentParser.parse(value, style: style)
    }
}
