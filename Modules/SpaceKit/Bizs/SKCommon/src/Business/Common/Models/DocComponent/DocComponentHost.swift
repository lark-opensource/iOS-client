//
//  DocComponentHost.swift
//  SpaceInterface
//
//  Created by lijuyou on 2023/5/25.
//  


import SKFoundation
import UIKit
import SpaceInterface


public protocol DocComponentHost: UIViewController {
    
    var docComponentHostDelegate: DocComponentHostDelegate? { get set }
    
    var browserView: BrowserModelConfig? { get }
    
    func onSetup(hostDelegate: DocComponentHostDelegate?)
    
    func invokeDCCommand(function: String, params: [String: Any]?)
}

public protocol DocComponentContainerHost: DocComponentHost {
    
    var contentHost: DocComponentHost? { get }
    
    func changeContentHost(_ newHost: DocComponentHost)
}
