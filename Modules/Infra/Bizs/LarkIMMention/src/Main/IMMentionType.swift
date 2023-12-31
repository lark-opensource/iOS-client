//
//  IMMentionType.swift
//  LarkIMMention
//
//  Created by ByteDance on 2022/9/16.
//

import UIKit
import Foundation

public protocol IMMentionPanelDelegate: AnyObject {
    // 选择items关闭panel回调
    func panel(didFinishWith items: [IMMentionOptionType])
    // 未选择关闭panel回调
    func panelDidCancel()
}

public protocol IMMentionChatConfigType {
    // 群组ID
    var id: String { get }
    // 群人数
    var userCount: Int32 { get }
    // 当前用户在本群能否ATALL
    var isEnableAtAll: Bool { get }
    // 是否在 @all 中显示群成员个数
    var showChatUserCount: Bool { get }
}

public struct IMMentionChatConfig: IMMentionChatConfigType {
    public let showChatUserCount: Bool
    // 群组ID
    public var id: String
    // 群人数
    public var userCount: Int32
    // 当前用户在本群能否ATALL
    public var isEnableAtAll: Bool
    
    public init(id: String, userCount: Int32, isEnableAtAll: Bool, showChatUserCount: Bool) {
        self.id = id
        self.userCount = userCount
        self.isEnableAtAll = isEnableAtAll
        self.showChatUserCount = showChatUserCount
    }
}

public protocol IMMentionType {
    // 事件回调
    var delegate: IMMentionPanelDelegate? { get set }
    // 展示
    func show(from vc: UIViewController)
}
