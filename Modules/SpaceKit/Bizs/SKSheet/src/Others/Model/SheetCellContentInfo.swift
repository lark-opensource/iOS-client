//
//  SheetCellContentInfo.swift
//  SKSheet
//
//  Created by lijuyou on 2022/4/5.
//  


import SKFoundation
import HandyJSON
import SKBrowser

struct SheetCellContentInfo: HandyJSON {
    var copyable: Bool = false
    var hideFAB: Bool = false
    var callback: String?
    var data: SheetInputData?
}
