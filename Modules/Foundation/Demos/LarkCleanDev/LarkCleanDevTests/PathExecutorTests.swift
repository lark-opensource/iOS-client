//
//  PathExecutorTests.swift
//  LarkCleanDevTests
//
//  Created by 7Up on 2023/7/19.
//

import XCTest
import LarkStorage
@testable import LarkClean

/// Unit Testing for `CleanPathExecutor`
final class PathExecutorTests: XCTestCase {

    private let data: Data = {
        var str = ""
        (0..<1024).forEach { _ in str.append(UUID().uuidString) }
        return str.data(using: .utf8) ?? Data()
    }()

    private func createFile(atPath path: AbsPath) {
        FileManager.default.createFile(atPath: path.absoluteString, contents: data)
    }

    private func makeContext(userCount: Int) -> CleanContext {
        let users = (0..<max(1, userCount)).map { _ in
            let uid = UUID().uuidString
            let tid = UUID().uuidString
            return CleanContext.User(userId: uid, tenantId: tid)
        }
        return .init(userList: users)
    }

    private func makeParams(with context: CleanContext) -> ExecutorParams {
        ExecutorParams.create(identifier: makeIdentifier(), context: context, retryCount: 3)
    }

    // MARK: Test State Transition

    /// 下图从 PathExecutor.swift 同步而来

    /// ** --------------------------------------- state transition --------------------------------------- **
    /// *                                                                                                    *
    /// *                                                          ┌───── rescue ─────┐                      *
    /// *                                                          ▼       ┌─► inTrashDeleteFailed    (✘)    *
    /// *                          ┌─► trashSucceed ─► inTrashDeleteReady ─┤                                 *
    /// *                          │                                       └─► inTrashDeleteSucceed   (✔)    *
    /// *          ┌─► trashReady ─┤                                                                         *
    /// *          │               │                                       ┌─► inPlaceDeleteSucceed   (✔)    *
    /// *          │               └─► trashFailed  ─► inPlaceDeleteReady ─┤                                 *
    /// *    idle ─┤                                               ▲       └─► inPlaceDeleteFailed    (✘)    *
    /// *          │                                               └───── rescue ─────┘                      *
    /// *          │                                                                                         *
    /// *          └───────────────────────────────────────────────────────────► stop                 (✔)    *
    /// *                                                                                                    *
    /// ** ------------------------------------------------------------------------------------------------ **

    /// 验证状态机：验证上述的状态迁移（往前走一步）
    func testStateOneStep() throws {
        // 随便构建一个 executor 即可
        let executor = CleanPathExecutor(params: makeParams(with: makeContext(userCount: 1)))
        let moveForward = { (item: CleanPathItem) in
            executor.stepState(item, rescueMode: false, terminate: .steps(1))
        }
        // idle -> trashReady -> ...
        do {
            // prepare movableItem & unmovableItem
            let movableItem = CleanPathItem(absPath: AbsPath.library + UUID().uuidString, state: .idle, store: nil)
            createFile(atPath: movableItem.absPath)
            let unmovableItem = CleanPathItem(absPath: Bundle.main.bundlePath.asAbsPath(), state: .idle, store: nil)

            // idle -> trashReady
            do {
                moveForward(movableItem)
                moveForward(unmovableItem)
                XCTAssert(movableItem.state == .trashReady)
                XCTAssert(unmovableItem.state == .trashReady)
            }

            // trashReady -> trashSucceed -> ...
            do {
                XCTAssertTrue(movableItem.absPath.exists)
                XCTAssertFalse(executor.trashPath(for: movableItem)?.exists ?? true)

                moveForward(movableItem)
                XCTAssertTrue(movableItem.state == .trashSucceed)

                XCTAssertFalse(movableItem.absPath.exists)
                // 确保 movableItem 被移动到 trash 中了
                XCTAssertTrue(executor.trashPath(for: movableItem)?.exists ?? false)

                // trashSucceed -> inTrashDeleteReady
                do {
                    moveForward(movableItem)
                    XCTAssertTrue(movableItem.state == .inTrashDeleteReady)

                    // inTrashDeleteReady -> inTrashDeleteSucceed
                    do {
                        moveForward(movableItem)
                        XCTAssertTrue(movableItem.state == .inTrashDeleteSucceed)
                        // 验证 trash 中的内容已经被清掉了
                        XCTAssertFalse(executor.trashPath(for: movableItem)?.exists ?? true)
                    }

                    // inTrashDeleteReady -> inTrashDeleteFailed
                    do {
                        // TODO: 不太容易构建测试环境，以后再补充
                    }
                }
            }
            // trashReady -> trashFailed -> ...
            do {
                // unmovableItem 不可移动到 trash 中
                XCTAssertTrue(unmovableItem.absPath.exists)
                moveForward(unmovableItem)
                XCTAssertTrue(unmovableItem.state == .trashFailed)

                // trashFailed -> inPlaceDeleteReady
                do {
                    moveForward(unmovableItem)
                    XCTAssertTrue(unmovableItem.state == .inPlaceDeleteReady)

                    // inPlaceDeleteReady -> inPlaceDeleteFailed
                    do {
                        // TODO: 需补充，构建不可删除的 item
                        /*
                         let tmp = CleanPathItem(absPath: unmovableItem.absPath + UUID().uuidString, state: .inPlaceDeleteReady, store: nil)
                         moveForward(tmp)
                         XCTAssertTrue(tmp.state == .inPlaceDeleteFailed)
                         */
                    }

                    // inPlaceDeleteReady -> inPlaceDeleteSucceed
                    do {
                        let item = CleanPathItem(absPath: .cache + UUID().uuidString, state: .inPlaceDeleteReady, store: nil)
                        createFile(atPath: item.absPath)
                        moveForward(item)
                        XCTAssertTrue(item.state == .inPlaceDeleteSucceed)
                    }
                }
            }
        }

        // idle -> stop
        do {
            let nonExistsItem = CleanPathItem(absPath: AbsPath.library + UUID().uuidString, state: .idle, store: nil)
            moveForward(nonExistsItem)
            XCTAssert(nonExistsItem.state == .stop)
        }
    }

    func testStepRescue() {
        // 待补充...
    }

    func testStepAuto() throws {
        // 随便构建一个 executor 即可
        let executor = CleanPathExecutor(params: makeParams(with: makeContext(userCount: 1)))

        let item = CleanPathItem(absPath: AbsPath.library + UUID().uuidString, state: .idle, store: nil)
        createFile(atPath: item.absPath)

        executor.stepState(item, rescueMode: true, terminate: .auto)
        XCTAssertTrue(item.state == .inTrashDeleteSucceed)
    }

    // MARK: Test RunOnce

    func testRunLogout() throws {
//        var paths = [AbsPath]()
//        for _ in 0..<10 {
//            let path = AbsPath.cache + UUID().uuidString
//            createFile(atPath: path)
//            paths.append(path)
//        }
//        CleanRegistry.registerPaths(forGroup: "PathExecutorTests") { ctx in
//            return paths.map { .abs($0.absoluteString) }
//        }
//
//        let executor = CleanPathExecutor(params: makeParams(with: .init(userList: [])))
//        executor.setup()
//        executor.runOnce { event in
//            switch event {
//            case let .progress(finished, total):
//                print("zwfk event.progress. \(finished)/\(total)")
//            case .end(let fail):
//                print("zwfk event.end. fail: \(fail ?? 0)")
//            }
//        }
    }

    func testRunResume() {
        // 待补充...
    }

}
