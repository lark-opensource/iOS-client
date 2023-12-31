//
//  Container+User.swift
//  LarkContainerDevEEUnitTest
//
//  Created by SolaWing on 2023/10/18.
//

import XCTest
import Swinject
@testable import LarkContainer

extension ContainerTest {
    // override func setUpWithError() throws {
    //     // Put setup code here. This method is called before the invocation of each test method in the class.
    // }

    // override func tearDownWithError() throws {
    //     // Put teardown code here. This method is called after the invocation of each test method in the class.
    // }
    func setupStorage() {
        UserStorageManager.shared.makeStorage(userID: "A", type: .foreground)
        UserStorageManager.shared.makeStorage(userID: "B", type: .background)
        UserStorageManager.shared.currentUserID = "A"
    }

    func testCanMakeAndOverwriteStorage() throws {
        UserStorageManager.shared.keepStorages(shouldKeep: { _ in false })

        let storage1 = UserStorageManager.shared.makeStorage(userID: "ABC")
        XCTAssertIdentical(storage1, UserStorageManager.shared["ABC"])
        XCTAssertEqual(storage1.type, .foreground) // default foreground

        let storage2 = UserStorageManager.shared.makeStorage(userID: "ABC", type: .background)
        XCTAssertIdentical(storage2, UserStorageManager.shared["ABC"]) // overwrite
        XCTAssertTrue(storage1.disposed) // after overwrite, old is disposed. only one valid storage at same time.
        XCTAssertEqual(storage2.type, .background)
    }

    func testGetUserResolver() throws {
        setupStorage()

        // CASE: currentUserResolver always return currentUserID respond container
        var r = Container.shared.getCurrentUserResolver()
        XCTAssertIdentical(r.storage, UserStorageManager.shared["A"])
        XCTAssertFalse(r.compatibleMode)

        // CASE: default only return foreground type storage
        var r2 = try r.getUserResolver(userID: "A")
        XCTAssertIdentical(r, r2) // return same userResolver for same userID and compatibleMode
        XCTAssertIdentical(r.storage, try Container.shared.getUserResolver(userID: "A", type: .foreground).storage)
        XCTAssertIdentical(r.storage, UserStorageManager.shared["A"])
        XCTAssertThrowsError(try Container.shared.getUserResolver(userID: "B"))

        // CASE: to get background storage, need to specify type
        r2 = try r.getUserResolver(userID: "B", type: .background) // return different userResolver when storage not match
        XCTAssertIdentical(r2.storage, try Container.shared.getUserResolver(userID: "B", type: .both).storage)
        XCTAssertIdentical(r2.storage, UserStorageManager.shared["B"])
        XCTAssertThrowsError(try Container.shared.getUserResolver(userID: "B", type: .foreground))

        // CASE: for compatible mode, only foreground can use currentStorage as backup
        r2 = try r.getUserResolver(userID: "B", threadCompatibleMode: true)
        XCTAssertIdentical(r, r2)
        XCTAssertIdentical(r2.storage, UserStorageManager.shared["A"]) // current A as backup
        XCTAssertFalse(r2.compatibleMode)

        r2 = try r.getUserResolver(userID: "B", compatibleMode: true)
        XCTAssertNotIdentical(r, r2)
        XCTAssertIdentical(r2.storage, UserStorageManager.shared["A"])
        XCTAssertTrue(r2.compatibleMode)

        r2 = try r.getUserResolver(userID: "C", threadCompatibleMode: true)
        XCTAssertIdentical(r, r2)
        XCTAssertIdentical(r2.storage, UserStorageManager.shared["A"]) // current A as backup
        XCTAssertFalse(r2.compatibleMode)

        // CASE: background ignore compatible option
        XCTAssertThrowsError(try Container.shared.getUserResolver(userID: "A", type: .background, compatibleMode: true))
        r2 = try r.getUserResolver(userID: "B", type: .background, compatibleMode: true)
        XCTAssertIdentical(r2.storage, UserStorageManager.shared["B"])
        XCTAssertFalse(r2.compatibleMode)

        // CASE: invalid userID throw error when no compatible, or return current user storage
        XCTAssertThrowsError(try Container.shared.getUserResolver(userID: "C"),
                             "", assert(error: UserScopeError.invalidUserID))
        XCTAssertThrowsError(try Container.shared.getUserResolver(userID: "C", type: .background),
                             "", assert(error: UserScopeError.invalidUserID))
        XCTAssertThrowsError(try Container.shared.getUserResolver(userID: nil, type: .both),
                             "", assert(error: UserScopeError.userNotFound))
    }

    func testBlockInvalidService() throws {
        let container = Container()
        UserStorageManager.shared.makeStorage(userID: "C", type: .foreground)
        UserStorageManager.shared.makeStorage(userID: "D", type: .background)
        let compatible = try container.getUserResolver(userID: "C", type: .foreground, compatibleMode: true)
        let expired = try container.getUserResolver(userID: "C", type: .foreground, compatibleMode: false)
        UserStorageManager.shared.disposeStorage(userID: "C")
        UserStorageManager.shared.disposeStorage(userID: "D")

        setupStorage()
        setup(container: container)

        let foreground = try container.getUserResolver(userID: "A", type: .foreground)
        let background = try container.getUserResolver(userID: "B", type: .background)

        // CASE: foreground can get foreground and global
        XCTAssertNoThrow(try foreground.resolve(type: UserService.self, name: "foreground"))
        XCTAssertNoThrow(try foreground.resolve(type: UserService.self, name: "both"))
        XCTAssertNoThrow(try foreground.resolve(type: UserService.self, name: "global"))
        XCTAssertNoThrow(try compatible.resolve(type: UserService.self, name: "foreground"))
        XCTAssertNoThrow(try compatible.resolve(type: UserService.self, name: "both"))
        XCTAssertNoThrow(try compatible.resolve(type: UserService.self, name: "global"))
        XCTAssertNoThrow(
            try {
                let v = try foreground.resolve(type: UserService.self, name: "compatible")
                // compatible service return compatible for foreground service
                XCTAssertTrue(v.userResolver.compatibleMode)
            }()
        )

        // CASE: background can only get background and global mark safe
        XCTAssertNoThrow(try background.resolve(type: UserService.self, name: "background"))
        XCTAssertNoThrow(try background.resolve(type: UserService.self, name: "both"))
        XCTAssertNoThrow(try background.resolve(type: UserService.self, name: "globalSafe"))

        // CASE: background service always ignore compatbile, even for thread compatible
        XCTAssertNoThrow(
            try {
                let v = try background.resolve(type: UserService.self, name: "compatible")
                XCTAssertFalse(v.userResolver.compatibleMode)
            }()
        )
        try UserResolver.ensureThreadCompatibleMode(true) {
            var v = try background.resolve(type: UserService.self, name: "compatible")
            XCTAssertIdentical(v.userResolver, background)
            XCTAssertFalse(v.userResolver.compatibleMode)

            v = try background.resolve(type: UserService.self, name: "compatibleGraph")
            XCTAssertIdentical(v.userResolver, background)
            XCTAssertFalse(v.userResolver.compatibleMode)

            v = try background.resolve(type: UserService.self, name: "compatibleTransient")
            XCTAssertIdentical(v.userResolver, background)
            XCTAssertFalse(v.userResolver.compatibleMode)
        }


        // CASE: block different type, and not globalSafe for background
        XCTAssertThrowsError(try foreground.resolve(type: UserService.self, name: "background"),
                             "", assert(error: UserScopeError.unsafeCall))
        XCTAssertThrowsError(try background.resolve(type: UserService.self, name: "foreground"),
                             "", assert(error: UserScopeError.unsafeCall))
        XCTAssertThrowsError(try background.resolve(type: UserService.self, name: "global"),
                             "", assert(error: UserScopeError.unsafeCall))

        // CASE: block expired calls
        XCTAssertThrowsError(try expired.resolve(type: UserService.self, name: "both"),
                             "", assert(error: UserScopeError.disposed))
        XCTAssertThrowsError(try expired.resolve(type: UserService.self, name: "foreground"),
                             "", assert(error: UserScopeError.disposed))
        // global not blocked by expired userResolver
        XCTAssertNoThrow(try expired.resolve(type: UserService.self, name: "global"))

        // CASE: block no user case for background Service, even for thread compatibleMode
        XCTAssertThrowsError(try container.resolve(type: UserService.self, name: "background"),
                             "", assert(error: UserScopeError.userNotFound))
        XCTAssertThrowsError(try container.resolve(type: UserService.self, name: "both"),
                             "", assert(error: UserScopeError.userNotFound))
        XCTAssertNoThrow( // service support foreground now keep compatible
            try {
                let v = try container.resolve(type: UserService.self, name: "foreground")
                XCTAssertEqual(v.userResolver.userID, "A")
                XCTAssertFalse(v.userResolver.compatibleMode)
            }()
        )

        XCTAssertThrowsError(try container.resolve(type: UserService.self, name: "backgroundGraph"),
                             "", assert(error: UserScopeError.userNotFound))
        XCTAssertThrowsError(try container.resolve(type: UserService.self, name: "bothGraph"),
                             "", assert(error: UserScopeError.userNotFound))
        XCTAssertNoThrow( // service support foreground now keep compatible
            try {
                let v = try container.resolve(type: UserService.self, name: "foregroundGraph")
                XCTAssertEqual(v.userResolver.userID, "A")
                XCTAssertFalse(v.userResolver.compatibleMode)
            }()
        )

        XCTAssertThrowsError(try container.resolve(type: UserService.self, name: "backgroundTransient"),
                             "", assert(error: UserScopeError.userNotFound))
        XCTAssertThrowsError(try container.resolve(type: UserService.self, name: "bothTransient"),
                             "", assert(error: UserScopeError.userNotFound))
        XCTAssertNoThrow( // service support foreground now keep compatible
            try {
                let v = try container.resolve(type: UserService.self, name: "foregroundTransient")
                XCTAssertEqual(v.userResolver.userID, "A")
                XCTAssertFalse(v.userResolver.compatibleMode)
            }()
        )
    }

    func testCreateUserScope() throws {
        ObjectScope.UserScopeManager.shared.storage = [:]

        for i: UserScopeType in [.foreground, .background, .both] {
            for lifetime: UserScopeLifeTime in [.user, .graph, .transient] {
                let scope = ObjectScope.user(type: i, lifetime: lifetime)
                XCTAssertEqual(scope.type, i)
                assertLifeTimeMatch(scope, lifetime: lifetime)
            }
            var scope = ObjectScope.userGraph(type: i)
            XCTAssertEqual(scope.type, i)
            assertLifeTimeMatch(scope, lifetime: .graph)

            scope = ObjectScope.userTransient(type: i)
            XCTAssertEqual(scope.type, i)
            assertLifeTimeMatch(scope, lifetime: .transient)
        }
        func assertLifeTimeMatch(_ v: ObjectScope, lifetime: UserScopeLifeTime) {
            switch lifetime {
            case .user: XCTAssert(v is UserLifeScope)
            case .graph: XCTAssert(v is UserGraphScope)
            case .transient: XCTAssert(v is UserTransientScope)
            }
        }
    }

    func assert<T: Equatable>(error: T) -> (Error) -> Void {
        return {
            XCTAssertEqual($0 as? T, error)
        }
    }
}
