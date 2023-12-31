//
//  DocsRustSessionManager.swift
//  SKFoundation
//
//  Created by huangzhikai on 2023/5/17.
//

import Foundation
import LarkRustHTTP

//用来包装RustHTTPSession和deleage，目前看是多设计了一层，后续如果扩展使用rustDeleage方法，可以跟方便使用
public class DocsRustSessionManager {
    
    public let rustSession: RustHTTPSession

    public weak var delegate: DocsRustSessionDelegate?
    
    init(configuration: RustHTTPSessionConfig, delegate: DocsRustSessionDelegate = DocsRustSessionDelegate()) {
        self.rustSession = RustHTTPSession(configuration: configuration, delegate: delegate, delegateQueue: nil)
        self.delegate = delegate
    }
}
