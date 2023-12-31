//
//  FollowableContent.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/4/9.
//  
// swiftlint:disable unused_setter_value

import Foundation


/// 可Follow的内容模块
/// 主要面向Native的支持Follow的内容的封装，屏蔽VC、FollowSDK内部等实现细节
public protocol FollowableContent {
    /// 模块名称
    var moduleName: String { get }
    
    /// Follow内容(同层渲染)在文档的位置标记
    var followMountToken: String? { get set }

    func onSetup(delegate: FollowableContentDelegate)

    /// Follow时派发主持人状态
    func setState(_ state: FollowModuleState)

    func getState() -> FollowModuleState?

    /// 自由浏览时派发主持人状态
    /// - Parameter state: 主持人状态
    func updatePresenterState(_ state: FollowModuleState?)
}

extension FollowableContent {
    public var followMountToken: String? {
        get { return nil }
        set {}
    }
}
