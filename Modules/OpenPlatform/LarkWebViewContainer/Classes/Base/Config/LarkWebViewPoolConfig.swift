//
//  LarkWebViewPoolConfig.swift
//  LarkWebViewContainer
//
//  Created by Ryan on 2020/9/1.
//

import UIKit

@objcMembers
public class LarkWebviewPoolConfig: NSObject {
    /// The minimum size of the pool
    private let minimumCapacity = 1

    /// The capacity of the pool
    public let capacity: Int

    /// The capacity of the pool
    public let identifier: String

    public init(capacity: Int, identifier: String) {
        if capacity < minimumCapacity {
            assertionFailure("capacity must not smaller than 1")
        }
        self.capacity = capacity
        self.identifier = identifier
        super.init()
    }
}

@objcMembers
final class LarkWebviewFileTemplatePoolConfig: LarkWebviewPoolConfig {
    public let fileURL: URL
    public let readAccessURL: URL

    public init(capacity: Int, identifier: String, fileURL: URL, readAccessURL: URL) {
        self.fileURL = fileURL
        self.readAccessURL = readAccessURL
        super.init(capacity: capacity, identifier: identifier)
    }
}

@objcMembers
final class LarkWebviewRequestTemplatePoolConfig: LarkWebviewPoolConfig {
    public let request: URLRequest

    public init(capacity: Int, identifier: String, request: URLRequest) {
        self.request = request
        super.init(capacity: capacity, identifier: identifier)
    }
}
