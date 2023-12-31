//
//  IsoPath+MicroAppTests.swift
//  LarkStorageDevTests
//
//  Created by 7Up on 2023/1/3.
//

import Foundation
import XCTest
@testable import LarkStorageCore
@testable import LarkStorage

let timorPath = AbsPath.library + "Timor"

private struct User {
    var userId: String
    var tenantId: String

    var md5: String { "\(userId)_\(tenantId)" }
}

private struct Readme: Codable {
    static let fileName = "readme.txt"
    let userId: String
    let appType: String
    enum CodingKeys: CodingKey {
        case userId
        case appType
    }

    init(userId: String, appType: String) {
        self.userId = userId
        self.appType = appType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.userId = try container.decode(String.self, forKey: .userId)
        self.appType = try container.decode(String.self, forKey: .appType)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.userId, forKey: .userId)
        try container.encode(self.appType, forKey: .appType)
    }
}

private let appTypes = [
    "tma",          // 小程序
    "twebapp",      // web 应用
    "tcard",        // 卡片
    "tblock",       // block
    "dycomponent"   // 动态组件
]

private class TestUtil {
    static func prepareTimorData(for users: [User]) {
        let root = AbsPath.library + "Timor"
        let fm = FileManager()
        try? fm.createDirectory(at: root.url, withIntermediateDirectories: true)
        for type in appTypes {
            for user in users {
                let path = root + "\(type)/\(user.md5)"
                try? fm.createDirectory(at: path.url, withIntermediateDirectories: true)
                let filePath = path + Readme.fileName
                let data = Readme(userId: user.userId, appType: type)
                let d: Data = try! JSONEncoder().encode(data)
                try! d.write(to: filePath.url, options: [.atomic])
            }
        }
    }

    static func registerMigration(for users: [User], domain: DomainType, strategy: SBMigrationStrategy) {
        SBMigrationRegistry.registerMigration(forDomain: domain) { space in
            guard
                case .user(let uid) = space,
                let user = users.first(where: { $0.userId == uid })
            else {
                return [:]
            }
            return [
                .library: .partial(
                    fromRoot: AbsPath.library + "Timor",
                    strategy: strategy,
                    items: appTypes.map { type -> SBMigrationConfig.PathMatcher.PartialItem in
                        return .init(type + "/" + user.md5)
                    }
                )
            ]
        }
    }

    static func testReadme(for user: User, domain: DomainType) {
        let root = IsoPath.in(space: .user(id: user.userId), domain: domain).build(.library)
        for appType in appTypes {
            let filePath = root + "\(appType)/\(user.md5)/\(Readme.fileName)"
            XCTAssert(filePath.exists)
            let data = try! Data.read(from: filePath)
            let readme = try! JSONDecoder().decode(Readme.self, from: data)
            XCTAssert(readme.userId == user.userId)
            XCTAssert(readme.appType == appType)
        }
    }
}


// MARK: Redirect

/// 小程序迁移场景。migrate strategy: redirect
final class IsoPathMicroAppRedirectTests: XCTestCase {

    static let domain = Domain.biz.microApp.child("Redirect")

    // 随机生成的 users
    private static var allUsers: [User] = {
        return (0..<5).map { _ in User(userId: UUID().uuidString, tenantId: UUID().uuidString) }
    }()

    static override func setUp() {
        super.setUp()
        TestUtil.registerMigration(for: allUsers, domain: domain, strategy: .redirect)
        TestUtil.prepareTimorData(for: allUsers)
    }

    func testRootPath() {
        // 测试 rootPath，指向到原路径
        let testUserRootPath = { (user: User) in
            let root = IsoPath.in(space: .user(id: user.userId), domain: Self.domain).build(.library)
            XCTAssert(root.isSame(as: timorPath))
        }
        Self.allUsers.forEach(testUserRootPath)
    }

    func testReadme() {
        Self.allUsers.forEach { TestUtil.testReadme(for: $0, domain: Self.domain) }
    }
}

// MARK: Standard

/// 小程序迁移场景。migrate strategy: move or drop
final class IsoPathMicroStandardTests: XCTestCase {
    static let domain = Domain.biz.microApp.child("Standard")

    // 随机生成的 users
    private static var allUsers: [User] = {
        return (0..<5).map { _ in User(userId: UUID().uuidString, tenantId: UUID().uuidString) }
    }()

    static override func setUp() {
        super.setUp()
        TestUtil.registerMigration(
            for: allUsers,
            domain: domain,
            strategy: .moveOrDrop(allows: [.intialization])
        )
        TestUtil.prepareTimorData(for: allUsers)
    }

    func testRootPath() throws {
        // 测试 rootPath，指向到标准路径
        let testUserRootPath = { (user: User) in
            let (space, domain) = (Space.user(id: user.userId), Self.domain)
            let stdRootPath = AbsPath.rootPath(for: .library)
                .appendingComponent(with: space)
                .appendingComponent(with: domain)

            let root = IsoPath.in(space: space, domain: domain).build(.library)
            XCTAssert(root.starts(with: stdRootPath))
        }
        Self.allUsers.forEach(testUserRootPath)
    }

    func testReadme() {
        Self.allUsers.forEach { TestUtil.testReadme(for: $0, domain: Self.domain) }
    }

}
