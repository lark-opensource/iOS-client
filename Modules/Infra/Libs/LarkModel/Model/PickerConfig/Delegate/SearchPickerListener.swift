//
//  SearchPickerListener.swift
//  LarkModel
//
//  Created by Yuri on 2023/8/3.
//

import Foundation

//public enum PickerObserverPriority {
//    case unique
//    case level(UInt)
//
//    var isUnique: Bool {
//        if case .unique = self {
//            return true
//        } else {
//            return false
//        }
//    }
//
//    var level: UInt {
//        if case .level(let uInt) = self {
//            return uInt
//        } else {
//            return UInt.max
//        }
//    }
//}

public protocol SearchPickerHandlerType: AnyObject, SearchPickerDelegate {
    /// 监听器id, 可以使用id进行移除
    /// 如果不设置id, 就不能移除
    var pickerHandlerId: String { get }
    func pickerWillSelect(item: PickerItem, isMultiple: Bool) -> Bool
}

extension SearchPickerHandlerType {
    func pickerWillSelect(item: PickerItem, isMultiple: Bool) -> Bool { return true }
}

//class PickerBlockUserObserver1: SearchPickerHandlerType {
//    var pickerObserverId: String { "BlockUser" }
//    func pickerDisableItem(_ item: PickerItem) -> Bool {
//        // if item is blocked
//        print("if item is blocked")
//        return true
//    }
//
//    func pickerWillSelect(pickerVc: SearchPickerControllerType, item: PickerItem, isMultiple: Bool) -> Bool {
//        // if item is blocked
//        // show alert
//        print("show alert")
//        return false
//    }
//}
