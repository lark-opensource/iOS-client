//
//  SBMigrationTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2022/11/14.
//

import Foundation
import XCTest
import LarkStorage

class SBMigrationTests: XCTestCase {

    typealias Registry = SBMigrationRegistry
    typealias Config = SBMigrationConfig

    func textData(for type: RootPathType.Normal) -> Data {
        switch type {
        case .document: return "document".data(using: .utf8)!
        case .library: return "library".data(using: .utf8)!
        case .cache: return "cache".data(using: .utf8)!
        case .temporary: return "temporary".data(using: .utf8)!
        }
    }

}
