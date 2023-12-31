//
//  LarkInterface+Rust.swift
//  LarkAccountInterface
//
//  Created by bytedance on 2022/1/25.
//

import Foundation

public protocol RustImplProtocol: AnyObject {

    ///  rust online 实现接口
    func rustOnlineRequest(account: Account)
}

