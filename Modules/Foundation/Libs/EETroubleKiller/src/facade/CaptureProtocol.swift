//
//  CaptureProtocol.swift
//  EETroubleKiller
//
//  Created by lixiaorui on 2019/5/13.
//

import Foundation
import UIKit

public protocol DomainProtocol {
    var domainKey: [String: String] { get }
}

public protocol CaptureProtocol: AnyObject {
    /// 自己是否要打印log
    var handle: Bool { get }

    /// 是否要打印log subview的log
    var isLeaf: Bool { get }
}

public protocol RouterResourceProtocol {
    static var tkName: String { get }
}

extension RouterResourceProtocol {
    var tkName: String {
        return Self.tkName
    }
}

extension CaptureProtocol {
    public var handle: Bool {
        return true
    }

    public var isLeaf: Bool {
        return false
    }
}

extension DomainProtocol {
    public var domainKey: [String: String] {
        return [:]
    }
}
