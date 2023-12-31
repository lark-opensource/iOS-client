//
//  FieldViewModelAbstractable.swift
//  LarkContact
//
//  Created by SlientCat on 2019/6/9.
//

import Foundation
import UIKit

enum FieldState {
    case edit       // 编辑态
    case failed     // 错误态
}

protocol FieldViewModelAbstractable: NSObject {
    var cellMapping: String { get }
    var FieldCellHeight: CGFloat { get }
    var state: FieldState { get set }
    var content: String { get }            // 用户实际输入的内容
    var commitContent: String { get }      // 用户实际提交server的内容(可能会过滤一些无效字符)
    var failReason: String { get set }
}
