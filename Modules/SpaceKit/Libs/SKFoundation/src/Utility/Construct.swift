//
//  Construct.swift
//  SpaceKit
//
//  Created by maxiao on 2019/5/21.
//

public protocol Construct {}

extension NSObject: Construct {}

extension Construct where Self: AnyObject {
    @discardableResult
    public func construct(_ closure: (Self) throws -> Void) rethrows -> Self {
        try closure(self)
        return self
    }
}
