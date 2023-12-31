//
//  OPContainerAPIContext.swift
//  OPSDK
//
//  Created by yinyuan on 2020/11/22.
//

import Foundation

extension OPEventContext {
    
    public var containerContext: OPContainerContext? {
        get {
            contextInfo("containerContext") as? OPContainerContext
        }
        
        set {
            setContextInfo("containerContext", value: newValue, weak: true)
        }
    }
    
    public var presentBasedViewController: UIViewController? {
        get {
            contextInfo("presentBasedViewController") as? UIViewController
        }
        
        set {
            setContextInfo("presentBasedViewController", value: newValue, weak: true)
        }
    }
    
    public var navigationController: UINavigationController? {
        get {
            contextInfo("navigationController") as? UINavigationController
        }
        
        set {
            setContextInfo("navigationController", value: newValue, weak: true)
        }
    }
    
    public var bridge: OPBridgeProtocol? {
        get {
            contextInfo("bridge") as? OPBridgeProtocol
        }
        
        set {
            setContextInfo("bridge", value: newValue, weak: true)
        }
    }
}
