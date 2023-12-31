//
//  SearchPickerDelegate.swift
//  LarkModel
//
//  Created by Yuri on 2023/5/6.
//

import UIKit

public protocol SearchPickerType {
    /// 功能配置参数
//    var featureConfig: PickerFeatureConfig { get set }
    /// 功能配置参数
    var searchConfig: PickerSearchConfig { get set }
//    /// 推荐视图
//    var defaultView: PickerDefaultViewType? { get set }
//    /// 自定义头部视图, 展示在多选列表上方, 需要在PickerVC调起前设置
//    var headerView: UIView? { get set }
//    /// 自定义顶部视图, 展示在多选列表下方, 需要在PickerVC调起前设置
//    var topView: UIView? { get set }
    /// 代理回调事件
    var pickerDelegate: SearchPickerDelegate? { get set }
    /// 刷新推荐列表和搜索列表
    func reload(search: Bool, recommend: Bool)
    func reload()
}

public protocol SearchPickerControllerType: UIViewController, SearchPickerType {}

public protocol SearchPickerDelegate: AnyObject {
    /// item收到点击之前, 单选时点击触发, 多选时选中时触发
    /// - Parameters:
    ///   - pickerVc: 持有picker的顶层vc, picker模式是SearchPickerNavigationController, 大搜模式是SearchPickerViewController, 可用于调用pickerVc的方法, 也可用于手动关闭Picker
    ///   - isMultiple: 当前Picker是否是多选模式
    /// - Returns: 返回false时, 不再响应该点击事件
    func pickerWillSelect(pickerVc: SearchPickerControllerType, item: PickerItem, isMultiple: Bool) -> Bool
    /// item点击, 单选模式下选中该item并关闭Picker, 多选模式下切换item的选中态
    /// - Parameters:
    ///   - pickerVc: 持有picker的顶层vc, picker模式是SearchPickerNavigationController, 大搜模式是SearchPickerViewController, 可用于调用pickerVc的方法, 也可用于手动关闭Picker
    ///   - isMultiple: 当前Picker是否是多选模式
    func pickerDidSelect(pickerVc: SearchPickerControllerType, item: PickerItem, isMultiple: Bool)
    /// Picker完成,回调选中的item数组, 单选模式下返回一个item, 多选模式下返回所有选中的items
    /// - Parameters:
    ///   - pickerVc: 持有picker的顶层vc, picker模式是SearchPickerNavigationController, 大搜模式是SearchPickerViewController, 可用于调用pickerVc的方法, 也可用于手动关闭Picker
    /// - Returns: 返回true时, 完成后默认关闭Picker, 返回false时, 不关闭Picker, 由业务处理后续逻辑
    func pickerDidFinish(pickerVc: SearchPickerControllerType, items: [PickerItem]) -> Bool
    /// 设置置灰的item
    /// - Returns: 返回true时, 置灰对应的item
    func pickerDisableItem(_ item: PickerItem) -> Bool
    /// 设置强制选择的item, 该item不可点击为置灰状态, 不可取消选中状态, 仅多选模式下可用
    /// - Returns: 返回true时, 默认选择对应的item
    func pickerForceSelectedItem(_ item: PickerItem) -> Bool
    /// 多选模式下, item将被取消选择时触发
    /// - Returns: 返回false时, 不再取消选择
    func pickerWillDeselect(item: PickerItem) -> Bool
    /// 多选模式下, item被取消选择时触发
    func pickerDidDeselect(item: PickerItem)
    /// Picker点击关闭或取消按钮, 关闭Picker时的触发时机
    /// 注意!!!: 如果是Sheet present出来的Picker, 下拉关闭时不会触发cancel, 需要使用dismiss覆盖全部手动关闭场景
    /// - Returns: 返回false时, 不会关闭Picker,需要业务手动实现
    func pickerDidCancel(pickerVc: SearchPickerControllerType) -> Bool
    /// Picker present时, 下拉dismiss时触发
    func pickerDidDismiss(pickerVc: SearchPickerControllerType)
}

public extension SearchPickerDelegate {
    func pickerWillSelect(pickerVc: SearchPickerControllerType, item: PickerItem, isMultiple: Bool) -> Bool { return true }
    func pickerDidSelect(pickerVc: SearchPickerControllerType, item: PickerItem, isMultiple: Bool) {}
    func pickerDidFinish(pickerVc: SearchPickerControllerType, items: [PickerItem]) -> Bool { return true }
    func pickerDidCancel(pickerVc: SearchPickerControllerType) -> Bool { return true }
    func pickerDisableItem(_ item: PickerItem) -> Bool { return false }
    func pickerPreselectedItem(_ item: PickerItem) -> Bool { return false }
    func pickerForceSelectedItem(_ item: PickerItem) -> Bool { return false }
    func pickerWillDeselect(item: PickerItem) -> Bool { return true }
    func pickerDidDeselect(item: PickerItem) {}
    func pickerDidDismiss(pickerVc: SearchPickerControllerType) {}
}
