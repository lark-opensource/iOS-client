//
//  WAPluginHost.swift
//  WebAppContainer
//
//  Created by lijuyou on 2023/11/13.
//

import Foundation

public protocol WAPluginHost: AnyObject {
    
    var lifeCycleObserver: WAContainerLifeCycleObserver { get }
    
    var container: WAContainer { get }
}
