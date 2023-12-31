//
//  OPRouter.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/2.
//

import Foundation

@objc
public protocol OPRouterProtocol: NSObjectProtocol {
    
    /// 当前的Component
    var currentComponent: OPComponentProtocol? { get }
    
    /// 创建一个 Component
    func createComponent(fileReader: OPPackageReaderProtocol, containerContext: OPContainerContext) throws -> OPComponentProtocol
    
    /// 卸载路由
    func unload()
}
