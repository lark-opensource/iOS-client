//
//  BridgeHandler.swift
//  SKCommon
//
//  Created by 曾浩泓 on 2021/11/11.
//  


import Foundation
import BDXServiceCenter
import BDXBridgeKit

public protocol BridgeHandler {
    var methodName: String { get }
    var handler: BDXLynxBridgeHandler { get }
}
