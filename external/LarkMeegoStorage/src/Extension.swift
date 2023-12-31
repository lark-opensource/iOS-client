//
//  Extension.swift
//  LarkMeegoStorage
//
//  Created by shizhengyu on 2023/3/15.
//

import Foundation
import RxSwift
import LarkMeegoLogger

extension MeegoLogger {
    static func debug(_ msg: String, domain: String) {
        debug(msg, customPrefix: "{\(domain)}")
    }

    static func warnWithAssert(_ msg: String, domain: String) {
        warn(msg, customPrefix: "{\(domain)}")
        assertionFailure(msg)
    }
}

extension AnyObserver {
    @inline(__always)
    func end(_ element: Self.Element) {
        onNext(element)
        onCompleted()
    }

    @inline(__always)
    func end(with error: LocalizedError) {
        onError(error)
        onCompleted()
    }
}
