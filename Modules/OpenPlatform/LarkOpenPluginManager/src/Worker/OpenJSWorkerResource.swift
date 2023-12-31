//
//  BDPJSWorkerResource.swift
//  TTMicroApp
//
//  Created by yi on 2021/7/21.
//

import Foundation
// js worker 的资源协议
@objc
public protocol OpenJSWorkerResourceProtocol: NSObjectProtocol {
    // local script url
    var scriptLocalUrl: URL? { get }

    // worker name
    @objc optional var workerName: String? { get }

    // script version
    var scriptVersion: String? { get }
}
