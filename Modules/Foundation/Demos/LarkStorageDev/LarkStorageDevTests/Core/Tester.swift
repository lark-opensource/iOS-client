//
//  Tester.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/5/20.
//

import Foundation
import XCTest
import LKCommonsLogging
@testable import LarkStorageCore
@testable import LarkStorage

protocol Tester {
    func run()
}

extension XCTestCase {
    static var typeName: String {
        String(describing: Self.self)
    }

    var typeName: String {
        String(describing: type(of: self))
    }

    var log: Log { Logger.log(Self.self, category: "LarkStorageDevTests.\(typeName)") }

    // 以 class 名为标识符的 Domain
    static var classDomain: Domain {
        Domain("UnitTest").child(String(describing: Self.self))
    }

    var classDomain: Domain { Self.classDomain }
}

extension DomainConvertible {
    func randomChild() -> Domain {
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        return self.child(uuid)
    }
}

extension Space {
    static func randomUser() -> Space {
        let uuid = UUID().uuidString.replacingOccurrences(of: "-", with: "")
        return .user(id: uuid)
    }
}
