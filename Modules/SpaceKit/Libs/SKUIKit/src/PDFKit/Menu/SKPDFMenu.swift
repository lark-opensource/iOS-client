//
//  SKPDFMenu.swift
//  SKUIKit
//
//  Created by huayufan on 2023/10/11.
//  


import UIKit

public protocol PDFMenuType {
    /// 气泡菜单标题
    var title: String { get }
    /// 气泡菜单唯一标识，要保证唯一
    var identifier: String { get }
    /// 点击气泡菜单后将选区内容回调给外部 参数分别为：（滑词选中的内容，pointId）
    var callback: ((String, String?) -> Void) { get }
}
