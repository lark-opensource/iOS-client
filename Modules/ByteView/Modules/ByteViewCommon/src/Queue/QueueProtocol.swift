//
//  Queue.swift
//  ByteViewCommon
//
//  Created by fakegourmet on 2023/4/11.
//

import Foundation

public protocol QueueProtocol {
    associatedtype Element
    mutating func enqueue(_ element: Element) -> Bool
    mutating func dequeue() -> Element?
    mutating func clear()
    var isEmpty: Bool { get }
    var peek: Element? { get }
}
