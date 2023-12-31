//
//  SKBrowserInterface.swift
//  SpaceInterface
//
//  Created by huangzhikai on 2023/4/13.
//  从SKCommonDependency拆分迁移的接口

import Foundation
import RxSwift
import RxRelay

public protocol SKBrowserInterface {
    
    /// 重用池清理并预加载
    func editorPoolDrainAndPreload()
    
    /// 监听DocsBrowserVC栈是否为空
    var browsersStackIsEmptyObsevable: BehaviorRelay<Bool> { get }
}
