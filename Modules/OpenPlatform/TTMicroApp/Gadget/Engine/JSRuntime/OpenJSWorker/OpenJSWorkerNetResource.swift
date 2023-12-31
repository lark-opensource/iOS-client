//
//  OpenJSWorkerNetResource.swift
//  TTMicroApp
//
//  Created by yi on 2021/7/29.
//

import Foundation
import LarkOpenPluginManager

// jsworker 从网络下载js脚本的解释器协议
@objc
public protocol OpenJSWorkerNetResourceProtocol: NSObjectProtocol {
    var scriptVersion: String? { get }
    func updateJS(workerName: String)
    func scriptUrl(workerName: String, local: OpenJSWorkerResourceProtocol) -> URL?
}

