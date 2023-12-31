//
//  Interface+Badge.swift
//  LarkBadge
//
//  Created by KT on 2019/4/18.
//

import UIKit
import Foundation

// CallBack When The Node Changed
public typealias OnChanged<T: TrieValueble, U: TrieValueble> = ((T, U) -> Void)
public typealias NodeName = String

// MARK: - Represent The behavor of `Observer`
protocol BadgeObservable {

    associatedtype Observer: TrieValueble
    associatedtype Badge: TrieValueble

    /// 添加观察者
    ///
    /// - Parameters:
    ///   - path: 目标节点的完整路径
    ///   - onChanged: 回调
    func observe(for path: Path, onChanged: OnChanged<Observer, Badge>?)

    /// 移除观察者, 一般不需要手动调用, deinit()时自动调用
    ///
    /// - Parameters:
    ///   - path: 目标节点的完整路径
    func removeObserver(of path: Path)

    // 移除View绑定的所有观察者
    func removeAllObserver()

    /// 关联路径
    ///
    /// - Parameter targetPath: 要关联的目标路径
    func combine(to targetPath: Path)
}

// MARK: - UI 初始化配置
protocol BadgeUIInitialization {

    /// 样式
    ///
    /// - Parameter type: 默认 .none
    func set(type: BadgeType)

    /// 中心点偏移
    ///
    /// - Parameter offset: 默认对其View右上角
    func set(offset: CGPoint)

    /// 本地图片
    ///
    /// - Parameter locoalName: 资源名称
    func set(locoalName: String)

    /// 网络图片
    ///
    /// - Parameter webImageURL: url 字符串
    func set(webImageURL: String)

    /// 尺寸
    ///
    /// - Parameter size: 默认 none -> zero
    func set(size: CGSize)

    /// 圆角
    ///
    /// - Parameter cornerRadius: 默认size.hight/2
    func set(cornerRadius: CGFloat)

    /// 容器背景色
    ///
    /// - Parameter backgroundColor: 默认.red
    func set(backgroundColor: UIColor)

    /// label 文字颜色
    ///
    /// - Parameter textColor: 默认 .white
    func set(textColor: UIColor)

    /// 文字尺寸
    ///
    /// - Parameter textSize: -
    func set(textSize: CGFloat)

    /// 水平margin
    ///
    /// - Parameter horizontalMargin: .label(text) 默认10
    func set(horizontalMargin: CGFloat)

    /// 文本
    ///
    /// - Parameter text: -
    func set(text: String)

    /// 数字
    ///
    /// - Parameter number: -
    func set(number: Int)
}

// MARK: - Represent The `Ability` of Badge
protocol BadgeAbility {
    // 获取当前view的BadgeView
    var badgeView: BadgeView? { get }
    // 显示/隐藏 BadgeView
    var isHidden: Bool { get set }
    // 本身消息数
    var bodyCount: Int { get }
    // 本身+递归子节点 总消息数
    var totalCount: Int { get }
    // 清除View上的Badge
    func clearBadge(force: Bool)
}

// MARK: - Badge路径
protocol PathRepresentable {
    init()

    /// 由前缀构造路径
    ///
    /// - Parameters:
    ///   - prefix: 已经注册的前缀名
    ///   - identifies: 拼接id
    func prefix(_ prefix: Path, with identifies: String...) -> Path

    /// 由参数构造路径
    ///
    /// - Parameter values: 参数
    /// - Returns: 路径
    func raw(_ values: String...) -> Path

    // Dynamic Member Lookup
    subscript(dynamicMember member: String) -> Path { get }
}

// Represent the `value` can store in Trie
protocol TrieValueble: Equatable {
    associatedtype UpdateInfo
    // the name of the node
    var name: NodeName { get }
    // whether the node is an `Element`
    var isElement: Bool { get set }
    // the info can be updated by outside
    var info: UpdateInfo { get set }
    // init with name
    init(_ name: NodeName)
}
