//
//  WebAppSDK.swift
//  SpaceInterface
//
//  Created by lijuyou on 2023/11/17.
//

import Foundation

public protocol WebAppSDK {
    func canOpen(url: String) -> Bool
    
    func canOpen(appId: String) -> Bool
    
    func convert(url: String) -> URL?
    
    func preload(appId: String) -> Bool
}
