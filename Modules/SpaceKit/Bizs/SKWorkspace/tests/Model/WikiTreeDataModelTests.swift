//
//  WikiTreeDataModelTests.swift
//  SKWikiV2_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/8/10.
//
// swiftlint:disable file_length type_body_length function_body_length

import XCTest
@testable import SKWorkspace
import SKFoundation
import RxSwift
import SKCommon
import SpaceInterface

class WikiTreeDataModelTests: XCTestCase {

    enum TestError: Error, Equatable {
        case invalidProcessOperation
        case expectError
    }

    typealias Util = WikiTreeTestUtil
    typealias NodeChildren = WikiTreeRelation.NodeChildren

    private var bag = DisposeBag()

    override func setUp() {
        super.setUp()
        bag = DisposeBag()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testSetup() {
        let nodeUID = WikiTreeNodeUID(wikiToken: "MOCK", section: .mainRoot, shortcutPath: "")
        let mockSpace = Util.mockSpace(spaceID: Util.mockSpaceID, name: "MOCK_SPACE")
        let mockPermission = Util.mockSpacePermission
        let state = WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: "MOCK", expandedUIDs: [nodeUID]),
                                  metaStorage: ["MOCK": Util.mockNode(token: "MOCK", hasChild: true)],
                                  relation: WikiTreeRelation())
        let context = WikiTreeContext(nodeUID: nodeUID,
                                      spaceID: Util.mockSpaceID,
                                      treeState: state,
                                      spaceInfo: mockSpace,
                                      userSpacePermission: mockPermission)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: "MOCK",
                                          treeContext: context,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: MockWikiTreeDataProcessor())
        XCTAssertEqual(dataModel.spaceID, Util.mockSpaceID)
        XCTAssertEqual(dataModel.initialWikiToken, "MOCK")

        var expect = expectation(description: "initial state")
        dataModel.initialStateUpdated.drive(onNext: { state in
            guard let cache = state.cacheState, let server = state.serverState else {
                XCTFail("initial state found nil")
                expect.fulfill()
                return
            }
            do {
                _ = try cache.get()
                _ = try server.get()
            } catch {
                XCTFail("initial state found error")
            }
            expect.fulfill()
        })
        .disposed(by: bag)
        waitForExpectations(timeout: 1)

        expect = expectation(description: "initial spaceInfo")
        dataModel.spaceInfoUpdated.drive(onNext: { spaceInfo in
            XCTAssertNotNil(spaceInfo)
            expect.fulfill()
        })
        .disposed(by: bag)
        waitForExpectations(timeout: 1)

        expect = expectation(description: "initial space permission")
        dataModel.userSpacePermissionUpdated.drive(onNext: { permission in
            XCTAssertNotNil(permission)
            expect.fulfill()
        })
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testReset() {
        class NetworkAPI: MockWikiNetworkAPI {
            override func loadTree(spaceID: String, initialWikiToken: String?, needPermission: Bool) -> Single<WikiTreeData> {
                XCTAssertEqual(spaceID, Util.mockSpaceID)
                XCTAssertEqual(initialWikiToken, Util.TestTree.leaf3_3_1.wikiToken)
                XCTAssertTrue(needPermission)
                let permission = WikiUserSpacePermission(canViewGeneralInfo: false, canStarWiki: false)
                let data = WikiTreeData(mainRootToken: Util.mainRootToken,
                                        metaStorage: Util.TestTree.metaStorage,
                                        relation: Util.TestTree.relation,
                                        spaceInfo: Util.mockSpace(spaceID: Util.mockSpaceID, name: "MOCK_NAME"),
                                        userSpacePermission: permission)
                return .just(data)
            }
        }

        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                switch operation {
                case let .reset(relation, metaStorage):
                    XCTAssertEqual(relation, Util.TestTree.relation)
                    XCTAssertEqual(metaStorage, Util.TestTree.metaStorage)
                case let .expandTo(wikiToken):
                    XCTAssertEqual(wikiToken, Util.TestTree.leaf3_3_1.wikiToken)
                default:
                    throw TestError.invalidProcessOperation
                }
                return .empty
            }
        }

        class CacheAPI: MockWikiTreeCacheAPI {
            override func batchUpdate(metas: [WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
                // 由于 array 顺序不可控，这里逐个比对内容
                let expectMetas = Util.TestTree.metaStorage
                XCTAssertEqual(metas.count, expectMetas.count)
                metas.forEach { meta in
                    XCTAssertEqual(meta, expectMetas[meta.wikiToken])
                }
                XCTAssertEqual(relation, Util.TestTree.relation)
                return .empty()
            }
        }

        let dataModel = WikiTreeDataModel(spaceID: "MOCK",
                                          initialWikiToken: nil,
                                          networkAPI: NetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockProcessor())

        var expect = expectation(description: "reset space")
        dataModel.reset(spaceID: Util.mockSpaceID, initialWikiToken: Util.TestTree.leaf3_3_1.wikiToken)
            .subscribe { state in
                // processor mock 返回了 empty
                XCTAssertTrue(state.metaStorage.isEmpty)
                XCTAssertTrue(state.relation.isEmpty)
                XCTAssertTrue(state.viewState.expandedUIDs.isEmpty)
                XCTAssertEqual(state.viewState.selectedWikiToken, Util.TestTree.leaf3_3_1.wikiToken)
                expect.fulfill()
            } onError: { error in
                XCTFail("reset failed with error \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)

        XCTAssertEqual(dataModel.spaceID, Util.mockSpaceID)
        XCTAssertEqual(dataModel.initialWikiToken, Util.TestTree.leaf3_3_1.wikiToken)
        expect = expectation(description: "check spaceInfo")
        dataModel.spaceInfoUpdated.drive(onNext: { spaceInfo in
            XCTAssertNotNil(spaceInfo)
            XCTAssertEqual(spaceInfo?.spaceID, Util.mockSpaceID)
            expect.fulfill()
        })
        .disposed(by: bag)
        waitForExpectations(timeout: 1)

        expect = expectation(description: "initial space permission")
        dataModel.userSpacePermissionUpdated.drive(onNext: { permission in
            XCTAssertFalse(permission.canStarWiki)
            XCTAssertFalse(permission.canViewGeneralInfo)
            expect.fulfill()
        })
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testResetWithContext() {
        let nodeUIDA = WikiTreeNodeUID(wikiToken: "A", section: .mainRoot, shortcutPath: "")
        let mockSpaceA = Util.mockSpace(spaceID: "A", name: "MOCK_SPACE")
        let mockPermissionA = WikiUserSpacePermission(canViewGeneralInfo: false, canStarWiki: false)
        let stateA = WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: "A", expandedUIDs: [nodeUIDA]),
                                   metaStorage: ["A": Util.mockNode(token: "A", hasChild: true)],
                                   relation: WikiTreeRelation())
        let contextA = WikiTreeContext(nodeUID: nodeUIDA,
                                       spaceID: "A",
                                       treeState: stateA,
                                       spaceInfo: mockSpaceA,
                                       userSpacePermission: mockPermissionA)

        let dataModel = WikiTreeDataModel(spaceID: "A",
                                          initialWikiToken: "A",
                                          treeContext: contextA,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: MockWikiTreeDataProcessor())

        let nodeUIDB = WikiTreeNodeUID(wikiToken: "B", section: .mainRoot, shortcutPath: "")
        let mockSpaceB = Util.mockSpace(spaceID: "B", name: "MOCK_SPACE")
        let stateB = WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: "B", expandedUIDs: [nodeUIDB]),
                                   metaStorage: ["B": Util.mockNode(token: "B", hasChild: true)],
                                   relation: WikiTreeRelation(nodeParentMap: ["B": "ROOT"],
                                                              nodeChildrenMap: [:]))
        let contextB = WikiTreeContext(nodeUID: nodeUIDB,
                                       spaceID: "B",
                                       treeState: stateB,
                                       spaceInfo: mockSpaceB,
                                       userSpacePermission: nil)

        var expect = expectation(description: "reset with context")
        dataModel.reset(context: contextB)
            .subscribe { state in
                XCTAssertEqual(state, stateB)
                expect.fulfill()
            } onError: { error in
                XCTFail("reset with context failed \(error)")
                expect.fulfill()
            }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)

        XCTAssertEqual(dataModel.spaceID, "B")

        expect = expectation(description: "check spaceInfo")
        dataModel.spaceInfoUpdated.drive(onNext: { spaceInfo in
            XCTAssertNotNil(spaceInfo)
            XCTAssertEqual(spaceInfo?.spaceID, "B")
            expect.fulfill()
        })
        .disposed(by: bag)
        waitForExpectations(timeout: 1)

        expect = expectation(description: "initial space permission")
        dataModel.userSpacePermissionUpdated.drive(onNext: { permission in
            // 这里的 permission 应该是 .default
            XCTAssertEqual(permission, WikiUserSpacePermission.default)
            expect.fulfill()
        })
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testRestoreWithCache() {
        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                switch operation {
                case let .expandTo(wikiToken):
                    let nodeUIDs: Set<WikiTreeNodeUID> = [
                        WikiTreeNodeUID(wikiToken: Util.TestTree.mainRoot.wikiToken, section: .mainRoot, shortcutPath: ""),
                        WikiTreeNodeUID(wikiToken: Util.TestTree.normal3.wikiToken, section: .mainRoot, shortcutPath: ""),
                        WikiTreeNodeUID(wikiToken: Util.TestTree.normal3_3.wikiToken, section: .mainRoot, shortcutPath: "")
                    ]
                    XCTAssertEqual(wikiToken, Util.TestTree.leaf3_3_1.wikiToken)
                    return WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: nil,
                                                                      expandedUIDs: nodeUIDs),
                                         metaStorage: treeState.metaStorage,
                                         relation: treeState.relation)
                case let .update(relation, metaStorage, onConflict):
                    XCTAssertEqual(relation, Util.TestTree.relation)
                    XCTAssertEqual(metaStorage, Util.TestTree.metaStorage)
                    XCTAssertEqual(onConflict, .ignore)
                    XCTAssertTrue(treeState.isEmpty)
                    return WikiTreeState(viewState: treeState.viewState, metaStorage: metaStorage, relation: relation)
                default:
                    throw TestError.invalidProcessOperation
                }
            }
        }

        class CacheAPI: MockWikiTreeCacheAPI {
            override func loadSpaceInfo(spaceID: String) -> Maybe<WikiSpace> {
                XCTAssertEqual(spaceID, Util.mockSpaceID)
                let space = Util.mockSpace(spaceID: Util.mockSpaceID, name: "MOCK_SPACE_NAME")
                return .just(space)
            }

            override func loadTree(spaceID: String, initialWikiToken: String?) -> Maybe<(WikiTreeRelation, MetaStorage)> {
                XCTAssertEqual(spaceID, Util.mockSpaceID)
                if let initialWikiToken = initialWikiToken {
                    XCTAssertEqual(initialWikiToken, Util.TestTree.leaf3_3_1.wikiToken)
                }
                return .just((Util.TestTree.relation, Util.TestTree.metaStorage))
            }
        }

        // with initial wiki token
        var dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: Util.TestTree.leaf3_3_1.wikiToken,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockProcessor())

        var expect = expectation(description: "restore with cache")
        dataModel.restore().subscribe { state in
            XCTAssertEqual(state.relation, Util.TestTree.relation)
            XCTAssertEqual(state.metaStorage, Util.TestTree.metaStorage)
            let expectViewState = WikiTreeViewState(selectedWikiToken: nil,
                                                    expandedUIDs: [
                                                        WikiTreeNodeUID(wikiToken: Util.TestTree.mainRoot.wikiToken, section: .mainRoot, shortcutPath: ""),
                                                        WikiTreeNodeUID(wikiToken: Util.TestTree.normal3.wikiToken, section: .mainRoot, shortcutPath: ""),
                                                        WikiTreeNodeUID(wikiToken: Util.TestTree.normal3_3.wikiToken, section: .mainRoot, shortcutPath: "")
                                                    ])
            XCTAssertEqual(state.viewState, expectViewState)
            expect.fulfill()
        } onError: { error in
            XCTFail("restore failed \(error)")
            expect.fulfill()
        } onCompleted: {
            XCTFail("restore should has result")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)

        expect = expectation(description: "initial state")
        dataModel.initialStateUpdated.drive(onNext: { state in
            XCTAssertNil(state.serverState)
            guard let cache = state.cacheState else {
                XCTFail("initial state found nil")
                expect.fulfill()
                return
            }
            do {
                _ = try cache.get()
            } catch {
                XCTFail("initial state found error")
            }
            expect.fulfill()
        })
        .disposed(by: bag)
        waitForExpectations(timeout: 1)

        expect = expectation(description: "check spaceInfo")
        dataModel.spaceInfoUpdated.drive(onNext: { spaceInfo in
            XCTAssertNotNil(spaceInfo)
            expect.fulfill()
        })
        .disposed(by: bag)
        waitForExpectations(timeout: 1)

        // without initial wiki token
        dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                      initialWikiToken: nil,
                                      networkAPI: MockWikiNetworkAPI(),
                                      cacheAPI: CacheAPI(),
                                      processor: MockProcessor())

        expect = expectation(description: "restore with cache but without initial wiki token")
        dataModel.restore().subscribe { state in
            XCTAssertEqual(state.relation, Util.TestTree.relation)
            XCTAssertEqual(state.metaStorage, Util.TestTree.metaStorage)
            // dataModel 在 restore 的时候不会直接选中
            let expectViewState = WikiTreeViewState(selectedWikiToken: nil,
                                                    expandedUIDs: [
                                                        WikiTreeNodeUID(wikiToken: Util.TestTree.mainRoot.wikiToken, section: .mainRoot, shortcutPath: "")
                                                    ])
            XCTAssertEqual(state.viewState, expectViewState)
            expect.fulfill()
        } onError: { error in
            XCTFail("restore failed \(error)")
            expect.fulfill()
        } onCompleted: {
            XCTFail("restore should has result")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testRestoreWithoutCache() {
        class CacheAPI: MockWikiTreeCacheAPI {
            override func loadSpaceInfo(spaceID: String) -> Maybe<WikiSpace> {
                XCTAssertEqual(spaceID, Util.mockSpaceID)
                return .empty()
            }

            override func loadTree(spaceID: String, initialWikiToken: String?) -> Maybe<(WikiTreeRelation, MetaStorage)> {
                XCTAssertEqual(spaceID, Util.mockSpaceID)
                return .empty()
            }
        }

        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: Util.TestTree.leaf3_3_1.wikiToken,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockWikiTreeDataProcessor())

        let expect = expectation(description: "restore with cache")
        dataModel.restore().subscribe { _ in
            XCTFail("should not receive state")
            expect.fulfill()
        } onError: { error in
            XCTFail("restore failed \(error)")
            expect.fulfill()
        } onCompleted: {
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testRestoreFailed() {
        class CacheAPI: MockWikiTreeCacheAPI {
            override func loadSpaceInfo(spaceID: String) -> Maybe<WikiSpace> {
                XCTAssertEqual(spaceID, Util.mockSpaceID)
                return .error(TestError.expectError)
            }

            override func loadTree(spaceID: String, initialWikiToken: String?) -> Maybe<(WikiTreeRelation, MetaStorage)> {
                XCTAssertEqual(spaceID, Util.mockSpaceID)
                return .error(TestError.expectError)
            }
        }

        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: Util.TestTree.leaf3_3_1.wikiToken,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockWikiTreeDataProcessor())

        var expect = expectation(description: "restore with failed")
        dataModel.restore().subscribe { _ in
            XCTFail("restore should failed")
            expect.fulfill()
        } onError: { error in
            guard let testError = error as? TestError else {
                XCTFail("un-expected error found \(error)")
                expect.fulfill()
                return
            }
            XCTAssertEqual(testError, TestError.expectError)
            expect.fulfill()

        } onCompleted: {
            XCTFail("restore should failed")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)

        expect = expectation(description: "initial state")
        dataModel.initialStateUpdated.drive(onNext: { state in
            XCTAssertNil(state.serverState)
            guard let cache = state.cacheState else {
                XCTFail("initial state found nil")
                expect.fulfill()
                return
            }
            do {
                _ = try cache.get()
                XCTFail("restore should failed")
            } catch {
                // 预期要抛 error
            }
            expect.fulfill()
        })
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testRestoreFavoriteList() {
        class CacheAPI: MockWikiTreeCacheAPI {
            override func loadFavoriteList(spaceID: String) -> Maybe<([NodeChildren], MetaStorage)> {
                XCTAssertEqual(spaceID, Util.mockSpaceID)
                return .just(([NodeChildren(wikiToken: "A", sortID: 10), NodeChildren(wikiToken: "B", sortID: 20)],
                              Util.TestTree.metaStorage))
            }
        }

        class MockProcessor: MockWikiTreeDataProcessor {
            override func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                guard case let .updateFavoriteList(spaceID, relation, metaStorage, onConflict) = operation else {
                    throw TestError.invalidProcessOperation
                }
                XCTAssertEqual(spaceID, Util.mockSpaceID)
                XCTAssertEqual(metaStorage, Util.TestTree.metaStorage)
                XCTAssertEqual(onConflict, .ignore)
                let expectFavList = [
                    NodeChildren(wikiToken: "A", sortID: 10),
                    NodeChildren(wikiToken: "B", sortID: 20)
                ]
                XCTAssertEqual(relation.nodeChildrenMap[WikiTreeNodeMeta.favoriteRootToken], expectFavList)
                return .empty
            }
        }

        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: Util.TestTree.leaf3_3_1.wikiToken,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockProcessor())

        let expect = expectation(description: "restore with failed")
        dataModel.restoreFavoriteList().subscribe { state in
            // mockProcessor 返回了 empty
            XCTAssertTrue(state.isEmpty)
            expect.fulfill()
        } onError: { error in
            XCTFail("restore should success \(error)")
            expect.fulfill()
        } onCompleted: {
            XCTFail("restore should success")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testMakeFavoriteRoot() {
        class MockProcessor: MockWikiTreeDataProcessor {
            override func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                guard case let .updateFavoriteList(spaceID, relation, metaStorage, onConflict) = operation else {
                    throw TestError.invalidProcessOperation
                }
                XCTAssertEqual(spaceID, Util.mockSpaceID)
                XCTAssertEqual(onConflict, .ignore)
                XCTAssertTrue(relation.isEmpty)
                XCTAssertEqual(metaStorage.count, 1)
                XCTAssertEqual(metaStorage[WikiTreeNodeMeta.favoriteRootToken],
                               WikiTreeNodeMeta.createFavoriteRoot(spaceID: Util.mockSpaceID))
                return .empty
            }
        }

        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: Util.TestTree.leaf3_3_1.wikiToken,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: MockProcessor())

        let expect = expectation(description: "restore with failed")
        dataModel.makeFavoriteRoot().subscribe { state in
            // mockProcessor 返回了 empty
            XCTAssertTrue(state.isEmpty)
            expect.fulfill()
        } onError: { error in
            XCTFail("restore should success \(error)")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    // reload 拆分为 4 个 case 处理
    // 1. 有 initialWikiToken，cache 未加载
    // 2. 没有 initialWikiToken，cache 未加载
    // 3. 有 initialWikiToken，cache 已加载
    // 4. 没有 initialWikiToken，cache 已加载

    // 1. 有 initialWikiToken，cache 未加载
    func testReloadCase1() {
        class NetworkAPI: MockWikiNetworkAPI {
            override func loadTree(spaceID: String, initialWikiToken: String?, needPermission: Bool) -> Single<WikiTreeData> {
                XCTAssertEqual(spaceID, Util.mockSpaceID)
                XCTAssertEqual(initialWikiToken, Util.TestTree.leaf3_3_1.wikiToken)
                XCTAssertTrue(needPermission)
                let permission = WikiUserSpacePermission(canViewGeneralInfo: false, canStarWiki: false)
                let data = WikiTreeData(mainRootToken: Util.mainRootToken,
                                        metaStorage: Util.TestTree.metaStorage,
                                        relation: Util.TestTree.relation,
                                        spaceInfo: Util.mockSpace(spaceID: Util.mockSpaceID, name: "MOCK_NAME"),
                                        userSpacePermission: permission)
                return .just(data)
            }
        }

        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                switch operation {
                case let .expandTo(wikiToken):
                    XCTAssertEqual(wikiToken, Util.TestTree.leaf3_3_1.wikiToken)
                case let .update(relation, metaStorage, onConflict):
                    XCTAssertEqual(relation, Util.TestTree.relation)
                    XCTAssertEqual(metaStorage, Util.TestTree.metaStorage)
                    XCTAssertEqual(onConflict, .override)
                default:
                    throw TestError.invalidProcessOperation
                }
                return .empty
            }
        }

        class CacheAPI: MockWikiTreeCacheAPI {
            override func batchUpdate(metas: [WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
                // 由于 array 顺序不可控，这里逐个比对内容
                let expectMetas = Util.TestTree.metaStorage
                XCTAssertEqual(metas.count, expectMetas.count)
                metas.forEach { meta in
                    XCTAssertEqual(meta, expectMetas[meta.wikiToken])
                }
                XCTAssertEqual(relation, Util.TestTree.relation)
                return .empty()
            }
        }

        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: Util.TestTree.leaf3_3_1.wikiToken,
                                          networkAPI: NetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockProcessor())

        var expect = expectation(description: "reload space case1")
        dataModel.reload()
            .subscribe { state, cacheLoaded in
                XCTAssertFalse(cacheLoaded)
                // processor mock 返回了 empty
                XCTAssertTrue(state.isEmpty)
                expect.fulfill()
            } onError: { error in
                XCTFail("reset failed with error \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)

        XCTAssertEqual(dataModel.spaceID, Util.mockSpaceID)
        XCTAssertEqual(dataModel.initialWikiToken, Util.TestTree.leaf3_3_1.wikiToken)
        expect = expectation(description: "check spaceInfo")
        dataModel.spaceInfoUpdated.drive(onNext: { spaceInfo in
            XCTAssertNotNil(spaceInfo)
            XCTAssertEqual(spaceInfo?.spaceID, Util.mockSpaceID)
            expect.fulfill()
        })
        .disposed(by: bag)
        waitForExpectations(timeout: 1)

        expect = expectation(description: "initial space permission")
        dataModel.userSpacePermissionUpdated.drive(onNext: { permission in
            XCTAssertFalse(permission.canStarWiki)
            XCTAssertFalse(permission.canViewGeneralInfo)
            expect.fulfill()
        })
        .disposed(by: bag)
        waitForExpectations(timeout: 1)

        expect = expectation(description: "check server initial state")
        dataModel.initialStateUpdated.drive(onNext: { state in
            XCTAssertNil(state.cacheState)
            guard let server = state.serverState else {
                XCTFail("initial state found nil")
                expect.fulfill()
                return
            }
            do {
                _ = try server.get()
            } catch {
                XCTFail("reload should success \(error)")
            }
            expect.fulfill()
        })
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    // 2. 没有 initialWikiToken，cache 未加载
    func testReloadCase2() {
        class NetworkAPI: MockWikiNetworkAPI {
            override func loadTree(spaceID: String, initialWikiToken: String?, needPermission: Bool) -> Single<WikiTreeData> {
                XCTAssertEqual(spaceID, Util.mockSpaceID)
                XCTAssertNil(initialWikiToken)
                XCTAssertTrue(needPermission)
                let permission = WikiUserSpacePermission(canViewGeneralInfo: false, canStarWiki: false)
                let data = WikiTreeData(mainRootToken: Util.mainRootToken,
                                        metaStorage: Util.TestTree.metaStorage,
                                        relation: Util.TestTree.relation,
                                        spaceInfo: Util.mockSpace(spaceID: Util.mockSpaceID, name: "MOCK_NAME"),
                                        userSpacePermission: permission)
                return .just(data)
            }
        }

        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                switch operation {
                case let .update(relation, metaStorage, onConflict):
                    XCTAssertEqual(relation, Util.TestTree.relation)
                    XCTAssertEqual(metaStorage, Util.TestTree.metaStorage)
                    XCTAssertEqual(onConflict, .override)
                default:
                    throw TestError.invalidProcessOperation
                }
                return .empty
            }
        }

        class CacheAPI: MockWikiTreeCacheAPI {
            override func batchUpdate(metas: [WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
                // 由于 array 顺序不可控，这里逐个比对内容
                let expectMetas = Util.TestTree.metaStorage
                XCTAssertEqual(metas.count, expectMetas.count)
                metas.forEach { meta in
                    XCTAssertEqual(meta, expectMetas[meta.wikiToken])
                }
                XCTAssertEqual(relation, Util.TestTree.relation)
                return .empty()
            }
        }

        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          networkAPI: NetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockProcessor())

        let expect = expectation(description: "reload space case2")
        dataModel.reload()
            .subscribe { state, cacheLoaded in
                XCTAssertFalse(cacheLoaded)
                // processor mock 返回了 empty
                XCTAssertTrue(state.relation.isEmpty)
                XCTAssertTrue(state.metaStorage.isEmpty)
                let expectUID = WikiTreeNodeUID(wikiToken: Util.TestTree.mainRoot.wikiToken,
                                                section: .mainRoot,
                                                shortcutPath: "")
                XCTAssertEqual(state.viewState, WikiTreeViewState(selectedWikiToken: nil, expandedUIDs: [expectUID]))
                expect.fulfill()
            } onError: { error in
                XCTFail("reload failed with error \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    // 3. 有 initialWikiToken，cache 已加载
    func testReloadCase3() {
        class NetworkAPI: MockWikiNetworkAPI {
            override func loadTree(spaceID: String, initialWikiToken: String?, needPermission: Bool) -> Single<WikiTreeData> {
                XCTAssertEqual(spaceID, Util.mockSpaceID)
                XCTAssertEqual(initialWikiToken, Util.TestTree.leaf3_3_1.wikiToken)
                XCTAssertTrue(needPermission)
                let permission = WikiUserSpacePermission(canViewGeneralInfo: false, canStarWiki: false)
                let data = WikiTreeData(mainRootToken: Util.mainRootToken,
                                        metaStorage: Util.TestTree.metaStorage,
                                        relation: Util.TestTree.relation,
                                        spaceInfo: Util.mockSpace(spaceID: Util.mockSpaceID, name: "MOCK_NAME"),
                                        userSpacePermission: permission)
                return .just(data)
            }
        }

        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                switch operation {
                case let .cleanDivergePath(wikiToken, newRelation):
                    XCTAssertEqual(wikiToken, Util.TestTree.leaf3_3_1.wikiToken)
                    XCTAssertEqual(newRelation, Util.TestTree.relation)
                case let .expandTo(wikiToken):
                    XCTAssertEqual(wikiToken, Util.TestTree.leaf3_3_1.wikiToken)
                case let .update(relation, metaStorage, onConflict):
                    XCTAssertEqual(relation, Util.TestTree.relation)
                    XCTAssertEqual(metaStorage, Util.TestTree.metaStorage)
                    XCTAssertEqual(onConflict, .override)
                default:
                    throw TestError.invalidProcessOperation
                }
                return .empty
            }
        }

        class CacheAPI: MockWikiTreeCacheAPI {
            override func batchUpdate(metas: [WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
                // 由于 array 顺序不可控，这里逐个比对内容
                let expectMetas = Util.TestTree.metaStorage
                XCTAssertEqual(metas.count, expectMetas.count)
                metas.forEach { meta in
                    XCTAssertEqual(meta, expectMetas[meta.wikiToken])
                }
                XCTAssertEqual(relation, Util.TestTree.relation)
                return .empty()
            }
        }

        let initialState = WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: "A", expandedUIDs: []),
                                         metaStorage: ["A": Util.mockNode(token: "A", hasChild: false)],
                                         relation: WikiTreeRelation())
        let initialContext = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: "A", section: .mainRoot, shortcutPath: ""),
                                             spaceID: Util.mockSpaceID,
                                             treeState: initialState,
                                             spaceInfo: nil,
                                             userSpacePermission: nil)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: Util.TestTree.leaf3_3_1.wikiToken,
                                          treeContext: initialContext,
                                          networkAPI: NetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockProcessor())

        let expect = expectation(description: "reload space case3")
        dataModel.reload()
            .subscribe { state, cacheLoaded in
                XCTAssertTrue(cacheLoaded)
                // processor mock 返回了 empty
                XCTAssertTrue(state.isEmpty)
                expect.fulfill()
            } onError: { error in
                XCTFail("reload failed with error \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    // 4. 没有 initialWikiToken，cache 已加载
    func testReloadCase4() {
        class NetworkAPI: MockWikiNetworkAPI {
            override func loadTree(spaceID: String, initialWikiToken: String?, needPermission: Bool) -> Single<WikiTreeData> {
                XCTAssertEqual(spaceID, Util.mockSpaceID)
                XCTAssertNil(initialWikiToken)
                XCTAssertTrue(needPermission)
                let permission = WikiUserSpacePermission(canViewGeneralInfo: false, canStarWiki: false)
                let data = WikiTreeData(mainRootToken: Util.mainRootToken,
                                        metaStorage: Util.TestTree.metaStorage,
                                        relation: Util.TestTree.relation,
                                        spaceInfo: Util.mockSpace(spaceID: Util.mockSpaceID, name: "MOCK_NAME"),
                                        userSpacePermission: permission)
                return .just(data)
            }
        }

        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                switch operation {
                case let .update(relation, metaStorage, onConflict):
                    XCTAssertEqual(relation, Util.TestTree.relation)
                    XCTAssertEqual(metaStorage, Util.TestTree.metaStorage)
                    XCTAssertEqual(onConflict, .override)
                default:
                    throw TestError.invalidProcessOperation
                }
                return .empty
            }
        }

        class CacheAPI: MockWikiTreeCacheAPI {
            override func batchUpdate(metas: [WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
                // 由于 array 顺序不可控，这里逐个比对内容
                let expectMetas = Util.TestTree.metaStorage
                XCTAssertEqual(metas.count, expectMetas.count)
                metas.forEach { meta in
                    XCTAssertEqual(meta, expectMetas[meta.wikiToken])
                }
                XCTAssertEqual(relation, Util.TestTree.relation)
                return .empty()
            }
        }

        let initialState = WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: "A", expandedUIDs: []),
                                         metaStorage: ["A": Util.mockNode(token: "A", hasChild: false)],
                                         relation: WikiTreeRelation())
        let initialContext = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: "A", section: .mainRoot, shortcutPath: ""),
                                             spaceID: Util.mockSpaceID,
                                             treeState: initialState,
                                             spaceInfo: nil,
                                             userSpacePermission: nil)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: initialContext,
                                          networkAPI: NetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockProcessor())

        let expect = expectation(description: "reload space case4")
        dataModel.reload()
            .subscribe { state, cacheLoaded in
                XCTAssertTrue(cacheLoaded)
                // processor mock 返回了 empty
                XCTAssertTrue(state.isEmpty)
                expect.fulfill()
            } onError: { error in
                XCTFail("reload failed with error \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testReloadFailed() {
        class NetworkAPI: MockWikiNetworkAPI {
            override func loadTree(spaceID: String, initialWikiToken: String?, needPermission: Bool) -> Single<WikiTreeData> {
                return .error(TestError.expectError)
            }
        }

        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          networkAPI: NetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: MockWikiTreeDataProcessor())

        var expect = expectation(description: "reload space case2")
        dataModel.reload()
            .subscribe { _, _ in
                XCTFail("reload should failed")
                expect.fulfill()
            } onError: { error in
                guard let testError = error as? TestError else {
                    XCTFail("reload failed with error \(error)")
                    expect.fulfill()
                    return
                }
                XCTAssertEqual(testError, TestError.expectError)
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)

        expect = expectation(description: "check server initial state")
        dataModel.initialStateUpdated.drive(onNext: { state in
            XCTAssertNil(state.cacheState)
            guard let server = state.serverState else {
                XCTFail("initial state found nil")
                expect.fulfill()
                return
            }
            do {
                _ = try server.get()
                XCTFail("reload should failed")
            } catch {
                guard let testError = error as? TestError else {
                    XCTFail("reload failed with error \(error)")
                    expect.fulfill()
                    return
                }
                XCTAssertEqual(testError, TestError.expectError)
            }
            expect.fulfill()
        })
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testReloadFavoriteList() {
        enum Case {
            static var relation: WikiTreeRelation {
                WikiTreeRelation(nodeParentMap: [:],
                                 nodeChildrenMap: [
                                    WikiTreeNodeMeta.favoriteRootToken: [
                                        NodeChildren(wikiToken: "A", sortID: 10),
                                        NodeChildren(wikiToken: "B", sortID: 20)
                                    ]
                                 ])
            }

            static var metas: [String: WikiTreeNodeMeta] {
                [
                    "A": Util.mockNode(token: "A", hasChild: false),
                    "B": Util.mockNode(token: "B", hasChild: false)
                ]
            }
            class NetworkAPI: MockWikiNetworkAPI {
                override func loadFavoriteList(spaceID: String) -> Single<(WikiTreeRelation, [WikiTreeNodeMeta])> {
                    XCTAssertEqual(spaceID, Util.mockSpaceID)
                    return .just((Case.relation, Array(Case.metas.values)))
                }
            }

            class MockProcessor: WikiTreeDataProcessorType {
                func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                    switch operation {
                    case let .updateFavoriteList(spaceID, relation, metaStorage, onConflict):
                        XCTAssertEqual(spaceID, Util.mockSpaceID)
                        XCTAssertEqual(relation, Case.relation)
                        XCTAssertEqual(metaStorage, Case.metas)
                        XCTAssertEqual(onConflict, .override)
                    default:
                        throw TestError.invalidProcessOperation
                    }
                    return .empty
                }
            }

            class CacheAPI: MockWikiTreeCacheAPI {
                override func updateFavoriteList(spaceID: String,
                                                 metaStorage: [String: WikiTreeNodeMeta],
                                                 relation: WikiTreeRelation) -> Completable {
                    // 由于 array 顺序不可控，这里逐个比对内容
                    XCTAssertEqual(spaceID, Util.mockSpaceID)
                    XCTAssertEqual(metas, Case.metas)
                    XCTAssertEqual(relation, Case.relation)
                    return .empty()
                }
            }
        }

        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          networkAPI: Case.NetworkAPI(),
                                          cacheAPI: Case.CacheAPI(),
                                          processor: Case.MockProcessor())

        let expect = expectation(description: "reload fav list")
        dataModel.reloadFavoriteList()
            .subscribe { state in
                // processor mock 返回了 empty
                XCTAssertTrue(state.isEmpty)
                expect.fulfill()
            } onError: { error in
                XCTFail("reload fav failed with error \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testReloadFavoriteListFailed() {
        class NetworkAPI: MockWikiNetworkAPI {
            override func loadFavoriteList(spaceID: String) -> Single<(WikiTreeRelation, [WikiTreeNodeMeta])> {
                return .error(TestError.expectError)
            }
        }
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          networkAPI: NetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: MockWikiTreeDataProcessor())

        let expect = expectation(description: "reload fav list")
        dataModel.reloadFavoriteList()
            .subscribe { _ in
                XCTFail("reload fav list should failed")
                expect.fulfill()
            } onError: { error in
                guard let testError = error as? TestError else {
                    XCTFail("reload failed with error \(error)")
                    expect.fulfill()
                    return
                }
                XCTAssertEqual(testError, TestError.expectError)
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testLoadChildren() {
        class NetworkAPI: MockWikiNetworkAPI {
            override func loadChildren(spaceID: String, wikiToken: String) -> Single<([NodeChildren], [WikiTreeNodeMeta])> {
                XCTAssertEqual(spaceID, Util.mockSpaceID)
                XCTAssertEqual(wikiToken, "A")
                let children = [
                    NodeChildren(wikiToken: "A1", sortID: 10),
                    NodeChildren(wikiToken: "A2", sortID: 20),
                    NodeChildren(wikiToken: "A3", sortID: 30)
                ]
                let metas = [
                    Util.mockNode(token: "A1", hasChild: false),
                    Util.mockNode(token: "A2", hasChild: false),
                    Util.mockNode(token: "A3", hasChild: false)
                ]
                return .just((children, metas))
            }
        }

        class CacheAPI: MockWikiTreeCacheAPI {
            override func batchUpdate(metas: [WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
                XCTAssertEqual(metas, [
                    Util.mockNode(token: "A1", hasChild: false),
                    Util.mockNode(token: "A2", hasChild: false),
                    Util.mockNode(token: "A3", hasChild: false),
                    Util.mockNode(token: "A", hasChild: true)
                ])
                XCTAssertTrue(relation.isEmpty)
                return .empty()
            }
        }

        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                switch operation {
                case let .update(relation, metaStorage, onConflict):
                    XCTAssertEqual(relation.nodeParentMap, [
                        "A1": "A",
                        "A2": "A",
                        "A3": "A"
                    ])
                    XCTAssertEqual(relation.nodeChildrenMap, [
                        "A": [
                            NodeChildren(wikiToken: "A1", sortID: 10),
                            NodeChildren(wikiToken: "A2", sortID: 20),
                            NodeChildren(wikiToken: "A3", sortID: 30)
                        ]
                    ])
                    XCTAssertEqual(metaStorage, [
                        "A1": Util.mockNode(token: "A1", hasChild: false),
                        "A2": Util.mockNode(token: "A2", hasChild: false),
                        "A3": Util.mockNode(token: "A3", hasChild: false)
                    ])
                    XCTAssertEqual(onConflict, .override)
                default:
                    throw TestError.invalidProcessOperation
                }
                return WikiTreeState(viewState: WikiTreeViewState(),
                                     metaStorage: [
                                        "A": Util.mockNode(token: "A", hasChild: true)
                                     ],
                                     relation: WikiTreeRelation())
            }
        }

        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          networkAPI: NetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockProcessor())

        let expect = expectation(description: "reload fav list")
        dataModel.loadChildren(wikiToken: "A", spaceID: Util.mockSpaceID)
            .subscribe { _ in
                expect.fulfill()
            } onError: { error in
                XCTFail("reload failed with error \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testExpandWithMemory() {
        let initialState = WikiTreeState(viewState: WikiTreeViewState(),
                                         metaStorage: Util.TestTree.metaStorage,
                                         relation: Util.TestTree.relation)
        let initialContext = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: "A", section: .mainRoot, shortcutPath: ""),
                                             spaceID: Util.mockSpaceID,
                                             treeState: initialState,
                                             spaceInfo: nil,
                                             userSpacePermission: nil)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: initialContext,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: MockWikiTreeDataProcessor())
        let expect = expectation(description: "expand with memory")
        let targetUID = WikiTreeNodeUID(wikiToken: Util.TestTree.normal3_3.wikiToken, section: .mainRoot, shortcutPath: "-A")
        dataModel.expand(wikiToken: Util.TestTree.normal3_3.wikiToken,
                         spaceID: Util.mockSpaceID,
                         nodeUID: targetUID)
        .subscribe(onNext: { state, fromCache in
            XCTAssertEqual(state.viewState.expandedUIDs, [targetUID])
            XCTAssertTrue(fromCache)
            expect.fulfill()
        })
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testExpandWithCache() {
        class NetworkAPI: MockWikiNetworkAPI {
            override func loadChildren(spaceID: String, wikiToken: String) -> Single<([NodeChildren], [WikiTreeNodeMeta])> {
                XCTAssertEqual(spaceID, Util.mockSpaceID)
                XCTAssertEqual(wikiToken, "A")
                let children = [
                    NodeChildren(wikiToken: "A1", sortID: 10),
                    NodeChildren(wikiToken: "A2", sortID: 20),
                    NodeChildren(wikiToken: "A3", sortID: 30)
                ]
                let metas = [
                    Util.mockNode(token: "A1", hasChild: false),
                    Util.mockNode(token: "A2", hasChild: false),
                    Util.mockNode(token: "A3", hasChild: false)
                ]
                return .just((children, metas))
            }
        }

        class CacheAPI: MockWikiTreeCacheAPI {
            override func loadChildren(spaceID: String, wikiToken: String) -> Maybe<([NodeChildren], MetaStorage)> {
                XCTAssertEqual(spaceID, Util.mockSpaceID)
                XCTAssertEqual(wikiToken, "A")
                return .just(([], [:]))
            }
            override func batchUpdate(metas: [WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
                return .empty()
            }
        }

        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                switch operation {
                case let .update(relation, metaStorage, onConflict):
                    switch onConflict {
                    case .ignore:
                        XCTAssertTrue(relation.nodeParentMap.isEmpty)
                        XCTAssertEqual(relation.nodeChildrenMap, ["A": []])
                        XCTAssertTrue(metaStorage.isEmpty)
                    case .override:
                        XCTAssertEqual(relation.nodeParentMap, [
                            "A1": "A",
                            "A2": "A",
                            "A3": "A"
                        ])
                        XCTAssertEqual(relation.nodeChildrenMap, [
                            "A": [
                                NodeChildren(wikiToken: "A1", sortID: 10),
                                NodeChildren(wikiToken: "A2", sortID: 20),
                                NodeChildren(wikiToken: "A3", sortID: 30)
                            ]
                        ])
                        XCTAssertEqual(metaStorage, [
                            "A1": Util.mockNode(token: "A1", hasChild: false),
                            "A2": Util.mockNode(token: "A2", hasChild: false),
                            "A3": Util.mockNode(token: "A3", hasChild: false)
                        ])
                    }
                default:
                    throw TestError.invalidProcessOperation
                }
                return WikiTreeState(viewState: WikiTreeViewState(),
                                     metaStorage: [:],
                                     relation: WikiTreeRelation())
            }
        }

        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          networkAPI: NetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockProcessor())

        let targetUID = WikiTreeNodeUID(wikiToken: "A", section: .mainRoot, shortcutPath: "-A")
        let expect = expectation(description: "expand with cache")
        expect.expectedFulfillmentCount = 2
        var cacheCalled = false
        dataModel.expand(wikiToken: "A", spaceID: Util.mockSpaceID, nodeUID: targetUID)
            .subscribe { state, fromCache in
                if !cacheCalled {
                    XCTAssertTrue(fromCache)
                    cacheCalled = true
                    XCTAssertEqual(state, WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: nil, expandedUIDs: [targetUID]),
                                                        metaStorage: [:],
                                                        relation: WikiTreeRelation()))
                } else {
                    XCTAssertFalse(fromCache)
                    XCTAssertTrue(state.isEmpty)
                }
                expect.fulfill()
            } onError: { error in
                XCTFail("expand failed with error \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testExpandWithoutCache() {
        class NetworkAPI: MockWikiNetworkAPI {
            override func loadChildren(spaceID: String, wikiToken: String) -> Single<([NodeChildren], [WikiTreeNodeMeta])> {
                XCTAssertEqual(spaceID, Util.mockSpaceID)
                XCTAssertEqual(wikiToken, "A")
                return .just(([], []))
            }
        }

        class CacheAPI: MockWikiTreeCacheAPI {
            override func loadChildren(spaceID: String, wikiToken: String) -> Maybe<([NodeChildren], MetaStorage)> {
                XCTAssertEqual(spaceID, Util.mockSpaceID)
                XCTAssertEqual(wikiToken, "A")
                return .empty()
            }
            override func batchUpdate(metas: [WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
                return .empty()
            }
        }

        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                return WikiTreeState(viewState: WikiTreeViewState(),
                                     metaStorage: [:],
                                     relation: WikiTreeRelation())
            }
        }

        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          networkAPI: NetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockProcessor())

        let targetUID = WikiTreeNodeUID(wikiToken: "A", section: .mainRoot, shortcutPath: "-A")
        let expect = expectation(description: "expand with cache")
        dataModel.expand(wikiToken: "A", spaceID: Util.mockSpaceID, nodeUID: targetUID)
            .subscribe { state, fromCache in
                XCTAssertFalse(fromCache)
                XCTAssertEqual(state, WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: nil, expandedUIDs: [targetUID]),
                                                    metaStorage: [:],
                                                    relation: WikiTreeRelation()))
                expect.fulfill()
            } onError: { error in
                XCTFail("expand failed with error \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testExpandWithCacheError() {
        class NetworkAPI: MockWikiNetworkAPI {
            override func loadChildren(spaceID: String, wikiToken: String) -> Single<([NodeChildren], [WikiTreeNodeMeta])> {
                XCTAssertEqual(spaceID, Util.mockSpaceID)
                XCTAssertEqual(wikiToken, "A")
                return .just(([], []))
            }
        }

        class CacheAPI: MockWikiTreeCacheAPI {
            override func loadChildren(spaceID: String, wikiToken: String) -> Maybe<([NodeChildren], MetaStorage)> {
                return .error(TestError.invalidProcessOperation)
            }
            override func batchUpdate(metas: [WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
                return .empty()
            }
        }

        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                return WikiTreeState(viewState: WikiTreeViewState(),
                                     metaStorage: [:],
                                     relation: WikiTreeRelation())
            }
        }

        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          networkAPI: NetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockProcessor())

        let targetUID = WikiTreeNodeUID(wikiToken: "A", section: .mainRoot, shortcutPath: "-A")
        let expect = expectation(description: "expand with cache")
        dataModel.expand(wikiToken: "A", spaceID: Util.mockSpaceID, nodeUID: targetUID)
            .subscribe { state, fromCache in
                XCTAssertFalse(fromCache)
                XCTAssertEqual(state, WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: nil, expandedUIDs: [targetUID]),
                                                    metaStorage: [:],
                                                    relation: WikiTreeRelation()))
                expect.fulfill()
            } onError: { error in
                XCTFail("expand failed with error \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testViewState() {
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: MockWikiTreeDataProcessor())
        let targetUID = WikiTreeNodeUID(wikiToken: "A", section: .mainRoot, shortcutPath: "-A")
        var expect = expectation(description: "force expand")
        dataModel.expand(nodeUID: targetUID)
            .subscribe { state in
                XCTAssertEqual(state, WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: nil, expandedUIDs: [targetUID]),
                                                    metaStorage: [:],
                                                    relation: WikiTreeRelation()))
                expect.fulfill()
            } onError: { error in
                XCTFail("expand failed with error \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)

        expect = expectation(description: "force collapse")
        dataModel.collapse(nodeUID: targetUID)
            .subscribe { state in
                XCTAssertTrue(state.isEmpty)
                expect.fulfill()
            } onError: { error in
                XCTFail("expand failed with error \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)

        expect = expectation(description: "force expand")
        dataModel.select(wikiToken: "A")
            .subscribe { state in
                XCTAssertEqual(state, WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: "A", expandedUIDs: []),
                                                    metaStorage: [:],
                                                    relation: WikiTreeRelation()))
                expect.fulfill()
            } onError: { error in
                XCTFail("expand failed with error \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testFocusMainRoot() {
        let targetToken = Util.TestTree.mainRoot.wikiToken
        let initialState = WikiTreeState(viewState: WikiTreeViewState(),
                                         metaStorage: Util.TestTree.metaStorage,
                                         relation: Util.TestTree.relation)
        let initialContext = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: targetToken,
                                                                      section: .mainRoot,
                                                                      shortcutPath: ""),
                                             spaceID: Util.mockSpaceID,
                                             treeState: initialState,
                                             spaceInfo: nil,
                                             userSpacePermission: nil)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: initialContext,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: MockWikiTreeDataProcessor())

        let expect = expectation(description: "focus main root")
        dataModel.focus(wikiToken: targetToken)
            .subscribe { state in
                XCTAssertEqual(state, WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: targetToken, expandedUIDs: []),
                                                    metaStorage: Util.TestTree.metaStorage,
                                                    relation: Util.TestTree.relation))
                expect.fulfill()
            } onError: { error in
                XCTFail("expand failed with error \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testFocusFromCache() {
        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                guard case .expandTo = operation else {
                    throw TestError.invalidProcessOperation
                }
                return .empty
            }
        }
        let targetToken = Util.TestTree.leaf3_3_1.wikiToken
        let initialState = WikiTreeState(viewState: WikiTreeViewState(),
                                         metaStorage: Util.TestTree.metaStorage,
                                         relation: Util.TestTree.relation)
        let initialContext = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: targetToken,
                                                                      section: .mainRoot,
                                                                      shortcutPath: ""),
                                             spaceID: Util.mockSpaceID,
                                             treeState: initialState,
                                             spaceInfo: nil,
                                             userSpacePermission: nil)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: initialContext,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: MockProcessor())

        let expect = expectation(description: "focus from memory cache")
        dataModel.focus(wikiToken: targetToken)
            .subscribe { state in
                XCTAssertEqual(state, WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: targetToken,
                                                                                 expandedUIDs: []),
                                                    metaStorage: [:],
                                                    relation: WikiTreeRelation()))
                expect.fulfill()
            } onError: { error in
                XCTFail("expand failed with error \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testFocusFromNetwork() {
        class NetworkAPI: MockWikiNetworkAPI {
            override func loadTree(spaceID: String, initialWikiToken: String?, needPermission: Bool) -> Single<WikiTreeData> {
                XCTAssertEqual(spaceID, Util.mockSpaceID)
                XCTAssertEqual(initialWikiToken, Util.TestTree.leaf3_3_1.wikiToken)
                let permission = WikiUserSpacePermission(canViewGeneralInfo: false, canStarWiki: false)
                let data = WikiTreeData(mainRootToken: Util.mainRootToken,
                                        metaStorage: Util.TestTree.metaStorage,
                                        relation: Util.TestTree.relation,
                                        spaceInfo: Util.mockSpace(spaceID: Util.mockSpaceID, name: "MOCK_NAME"),
                                        userSpacePermission: permission)
                return .just(data)
            }
        }

        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                switch operation {
                case let .cleanDivergePath(wikiToken, newRelation):
                    XCTAssertEqual(wikiToken, Util.TestTree.leaf3_3_1.wikiToken)
                    XCTAssertEqual(newRelation, Util.TestTree.relation)
                case let .update(relation, metaStorage, onConflict):
                    XCTAssertEqual(onConflict, .override)
                    XCTAssertEqual(relation, Util.TestTree.relation)
                    XCTAssertEqual(metaStorage, Util.TestTree.metaStorage)
                case let .expandTo(wikiToken):
                    XCTAssertEqual(wikiToken, Util.TestTree.leaf3_3_1.wikiToken)
                default:
                    XCTFail("invalid operation")
                    throw TestError.invalidProcessOperation
                }
                return WikiTreeState(viewState: WikiTreeViewState(),
                                     metaStorage: [:],
                                     relation: WikiTreeRelation())
            }
        }

        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          networkAPI: NetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: MockProcessor())

        let expect = expectation(description: "focus from network")
        dataModel.focus(wikiToken: Util.TestTree.leaf3_3_1.wikiToken)
            .subscribe { state in
                XCTAssertEqual(state, WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: Util.TestTree.leaf3_3_1.wikiToken,
                                                                                 expandedUIDs: []),
                                                    metaStorage: [:],
                                                    relation: WikiTreeRelation()))
                expect.fulfill()
            } onError: { error in
                XCTFail("expand failed with error \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    // MARK: - WikiTreeDataModel+Sync

    // 1. parent 不存在，则什么也不会发生
    func testSyncAddCase1() {
        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                guard case let .insert(parentWikiToken, _) = operation else {
                    XCTFail("invalid operation")
                    throw TestError.invalidProcessOperation
                }
                XCTAssertEqual(parentWikiToken, "A")
                throw WikiTreeOperation.InsertError.parentNotFound
            }
        }
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: MockProcessor())

        let expect = expectation(description: "sync add case 1")
        dataModel.syncAdd(node: WikiServerNode(meta: Util.mockNode(token: "A1", hasChild: false), sortID: 10, parent: "A"))
            .subscribe { _ in
                XCTFail("add should not success")
                expect.fulfill()
            } onError: { error in
                XCTFail("add should not failed \(error)")
                expect.fulfill()
            } onCompleted: {
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    // 2. parent 存在，parent 是非叶子节点，但 parent 的 children 未知，会拉取一次 parent 的 children
    func testSyncAddCase2() {
        class NetworkAPI: MockWikiNetworkAPI {
            override func loadChildren(spaceID: String, wikiToken: String) -> Single<([NodeChildren], [WikiTreeNodeMeta])> {
                XCTAssertEqual(spaceID, Util.mockSpaceID)
                XCTAssertEqual(wikiToken, Util.TestTree.normal3_3.wikiToken)
                return .error(TestError.expectError)
            }
        }
        let parentToken = Util.TestTree.normal3_3.wikiToken
        var childMap = Util.TestTree.relation.nodeChildrenMap
        // 清空 3_3 的 children 信息
        childMap[parentToken] = nil
        let relation = WikiTreeRelation(nodeParentMap: Util.TestTree.relation.nodeParentMap,
                                        nodeChildrenMap: childMap)
        let initialState = WikiTreeState(viewState: WikiTreeViewState(),
                                         metaStorage: Util.TestTree.metaStorage,
                                         relation: relation)
        let initialContext = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: "",
                                                                      section: .mainRoot,
                                                                      shortcutPath: ""),
                                             spaceID: Util.mockSpaceID,
                                             treeState: initialState,
                                             spaceInfo: nil,
                                             userSpacePermission: nil)
        let processor = MockWikiTreeDataProcessor()
        processor.result = .failure(WikiTreeOperation.InsertError.parentChildrenUnknown)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: initialContext,
                                          networkAPI: NetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: processor)

        let expect = expectation(description: "sync add case 2")
        dataModel.syncAdd(node: WikiServerNode(meta: Util.mockNode(token: "A1", hasChild: false), sortID: 10, parent: parentToken))
            .subscribe { _ in
                XCTFail("add should not success")
                expect.fulfill()
            } onError: { error in
                guard let testError = error as? TestError else {
                    XCTFail("un-expected error found \(error)")
                    expect.fulfill()
                    return
                }
                XCTAssertEqual(testError, TestError.expectError)
                expect.fulfill()
            } onCompleted: {
                XCTFail("add should failed")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    // 3. parent 存在，children 已知，会直接插入 children
    func testSyncAddCase3() {
        class CacheAPI: MockWikiTreeCacheAPI {
            override func batchUpdate(metas: [WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
                XCTAssertEqual(metas.map(\.wikiToken), ["A1", Util.TestTree.normal3_3.wikiToken])
                return .empty()
            }
        }
        let parentToken = Util.TestTree.normal3_3.wikiToken
        let initialState = WikiTreeState(viewState: WikiTreeViewState(),
                                         metaStorage: Util.TestTree.metaStorage,
                                         relation: Util.TestTree.relation)
        let initialContext = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: "",
                                                                      section: .mainRoot,
                                                                      shortcutPath: ""),
                                             spaceID: Util.mockSpaceID,
                                             treeState: initialState,
                                             spaceInfo: nil,
                                             userSpacePermission: nil)
        let processor = MockWikiTreeDataProcessor()
        processor.result = .success(initialState)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: initialContext,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: processor)

        let expect = expectation(description: "sync add case 3")
        dataModel.syncAdd(node: WikiServerNode(meta: Util.mockNode(token: "A1", hasChild: false), sortID: 10, parent: parentToken))
            .subscribe { _ in
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error found \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("add should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testSyncAddUnderShortcut() {
        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                XCTAssertNotNil(treeState.metaStorage["A"])
                return .empty
            }
        }
        class CacheAPI: MockWikiTreeCacheAPI {
            override func batchUpdate(nodes: [WikiServerNode], relation: WikiTreeRelation) -> Completable {
                XCTAssertEqual(nodes.map(\.meta.wikiToken), ["A"])
                return .empty()
            }
        }
        let initialState = WikiTreeState(viewState: WikiTreeViewState(),
                                         metaStorage: Util.TestTree.metaStorage,
                                         relation: Util.TestTree.relation)
        let initialContext = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: "",
                                                                      section: .mainRoot,
                                                                      shortcutPath: ""),
                                             spaceID: Util.mockSpaceID,
                                             treeState: initialState,
                                             spaceInfo: nil,
                                             userSpacePermission: nil)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: initialContext,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockProcessor())

        let expect = expectation(description: "sync add under shortcut")
        let newNode = WikiServerNode(meta: Util.mockNode(token: "A1", hasChild: false), sortID: 10, parent: "A")
        let originNode = WikiServerNode(meta: Util.mockNode(token: "A", hasChild: false), sortID: 10, parent: "ROOT")
        dataModel.syncAdd(node: newNode, originNode: originNode)
            .subscribe { _ in
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error found \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("add should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    // 删除非选中节点
    func testDeleteCase1() {
        class CacheAPI: MockWikiTreeCacheAPI {
            override func batchUpdate(metas: [WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
                XCTAssertEqual(metas.map(\.wikiToken), [Util.TestTree.normal3_3.wikiToken, WikiTreeNodeMeta.favoriteRootToken])
                return .empty()
            }

            override func delete(wikiTokens: [String]) -> Completable {
                XCTAssertEqual(wikiTokens, [Util.TestTree.leaf3_3_1.wikiToken])
                return .empty()
            }
        }
        // 初始化好收藏列表
        var metas = Util.TestTree.metaStorage
        metas[WikiTreeNodeMeta.favoriteRootToken] = WikiTreeNodeMeta.createFavoriteRoot(spaceID: Util.mockSpaceID)
        var relation = Util.TestTree.relation
        relation.setup(rootToken: WikiTreeNodeMeta.favoriteRootToken)
        let initialState = WikiTreeState(viewState: WikiTreeViewState(),
                                         metaStorage: metas,
                                         relation: relation)
        let initialContext = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: "A",
                                                                      section: .mainRoot,
                                                                      shortcutPath: ""),
                                             spaceID: Util.mockSpaceID,
                                             treeState: initialState,
                                             spaceInfo: nil,
                                             userSpacePermission: nil)
        let processor = MockWikiTreeDataProcessor()
        processor.result = .success(initialState)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: initialContext,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: processor)

        let expect = expectation(description: "delete case 1")
        dataModel.syncDelete(wikiToken: Util.TestTree.leaf3_3_1.wikiToken)
            .subscribe { result in
                XCTAssertFalse(result.selectedTokenDeleted)
                expect.fulfill()
            } onError: { error in
                XCTFail("delete should success \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("delete should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    // 删除当前选中的节点
    func testDeleteCase2() {
        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                guard case let .delete(token, response) = operation else {
                    throw TestError.invalidProcessOperation
                }
                XCTAssertEqual(token, Util.TestTree.leaf3_3_1.wikiToken)
                response([token])
                return .empty
            }
        }
        let initialState = WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: Util.TestTree.leaf3_3_1.wikiToken, expandedUIDs: []),
                                         metaStorage: [:],
                                         relation: WikiTreeRelation())
        let initialContext = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: "A",
                                                                      section: .mainRoot,
                                                                      shortcutPath: ""),
                                             spaceID: Util.mockSpaceID,
                                             treeState: initialState,
                                             spaceInfo: nil,
                                             userSpacePermission: nil)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: initialContext,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: MockProcessor())

        let expect = expectation(description: "delete case 1")
        dataModel.syncDelete(wikiToken: Util.TestTree.leaf3_3_1.wikiToken)
            .subscribe { result in
                XCTAssertTrue(result.selectedTokenDeleted)
                expect.fulfill()
            } onError: { error in
                XCTFail("delete should success \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("delete should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testBatchDelete() {
        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                guard case let .batchDelete(parentToken, tokens, response) = operation else {
                    throw TestError.invalidProcessOperation
                }
                XCTAssertEqual(parentToken, Util.TestTree.normal3_3.wikiToken)
                XCTAssertEqual(tokens, [Util.TestTree.leaf3_3_1.wikiToken])
                response(tokens)
                var metas = Util.TestTree.metaStorage
                metas[WikiTreeNodeMeta.favoriteRootToken] = WikiTreeNodeMeta.createFavoriteRoot(spaceID: Util.mockSpaceID)
                var relation = Util.TestTree.relation
                relation.setup(rootToken: WikiTreeNodeMeta.favoriteRootToken)
                return WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: Util.TestTree.leaf3_3_1.wikiToken,
                                                                  expandedUIDs: []),
                                     metaStorage: metas,
                                     relation: relation)
            }
        }
        class CacheAPI: MockWikiTreeCacheAPI {
            override func batchUpdate(metas: [WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
                XCTAssertEqual(metas.map(\.wikiToken), [Util.TestTree.normal3_3.wikiToken, WikiTreeNodeMeta.favoriteRootToken])
                return .empty()
            }

            override func delete(wikiTokens: [String]) -> Completable {
                XCTAssertEqual(wikiTokens, [Util.TestTree.leaf3_3_1.wikiToken])
                return .empty()
            }
        }
        // 初始化好收藏列表
        var metas = Util.TestTree.metaStorage
        metas[WikiTreeNodeMeta.favoriteRootToken] = WikiTreeNodeMeta.createFavoriteRoot(spaceID: Util.mockSpaceID)
        var relation = Util.TestTree.relation
        relation.setup(rootToken: WikiTreeNodeMeta.favoriteRootToken)
        let initialState = WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: Util.TestTree.leaf3_3_1.wikiToken,
                                                                      expandedUIDs: []),
                                         metaStorage: metas,
                                         relation: relation)
        let initialContext = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: "A",
                                                                      section: .mainRoot,
                                                                      shortcutPath: ""),
                                             spaceID: Util.mockSpaceID,
                                             treeState: initialState,
                                             spaceInfo: nil,
                                             userSpacePermission: nil)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: initialContext,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockProcessor())

        let expect = expectation(description: "batch delete")
        dataModel.syncBatchDelete(parentToken: Util.TestTree.normal3_3.wikiToken,
                                  wikiTokens: [Util.TestTree.leaf3_3_1.wikiToken])
            .subscribe { result in
                XCTAssertTrue(result.selectedTokenDeleted)
                expect.fulfill()
            } onError: { error in
                XCTFail("delete should success \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("delete should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testTitleUpdate() {
        class CacheAPI: MockWikiTreeCacheAPI {
            static var expectUpdateShortcut = false
            override func batchUpdate(metas: [WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
                if Self.expectUpdateShortcut {
                    XCTAssertEqual(metas.map(\.wikiToken), ["SHORTCUT_TARGET"])
                } else {
                    XCTAssertEqual(metas.map(\.wikiToken), ["TARGET"])
                }
                XCTAssertEqual(metas.map(\.title), ["NEW_TITLE"])
                return .empty()
            }
        }
        let metaStorage: [String: WikiTreeNodeMeta] = [
            "TARGET": Util.mockNode(token: "TARGET", hasChild: false),
            "SHORTCUT_TARGET": Util.mockShortcutNode(token: "SHORTCUT_TARGET", hasChild: false, originWikiToken: "TARGET", originSpaceID: Util.mockSpaceID),
            "SHORTCUT_EXTERNAL": Util.mockExternalShortcutNode(token: "SHORTCUT_EXTERNAL", hasChild: false),
            "SHORTCUT_UNKNOWN": Util.mockShortcutNode(token: "SHORTCUT_UNKNOWN", hasChild: false, originWikiToken: "UNKNOWN", originSpaceID: Util.mockSpaceID)
        ]
        let initialState = WikiTreeState(viewState: WikiTreeViewState(),
                                         metaStorage: metaStorage,
                                         relation: WikiTreeRelation())
        let initialContext = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: "A",
                                                                      section: .mainRoot,
                                                                      shortcutPath: ""),
                                             spaceID: Util.mockSpaceID,
                                             treeState: initialState,
                                             spaceInfo: nil,
                                             userSpacePermission: nil)
        var dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: initialContext,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockWikiTreeDataProcessor())

        // case 1 update 实体节点，updateForOrigin = false
        var expect = expectation(description: "update normal node title without updateForOrigin flag")
        CacheAPI.expectUpdateShortcut = false
        dataModel.syncTitleUpdate(wikiToken: "TARGET", newTitle: "NEW_TITLE")
            .subscribe { result in
                XCTAssertEqual(result.metaStorage["TARGET"]?.title, "NEW_TITLE")
                expect.fulfill()
            } onError: { error in
                XCTFail("update should success \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("update should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
        
        dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: initialContext,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockWikiTreeDataProcessor())
        // case 2 update 实体节点，updateForOrigin = true
        expect = expectation(description: "update normal node title with updateForOrigin flag")
        CacheAPI.expectUpdateShortcut = false
        dataModel.syncTitleUpdate(wikiToken: "TARGET", newTitle: "NEW_TITLE", updateForOrigin: true)
            .subscribe { result in
                XCTAssertEqual(result.metaStorage["TARGET"]?.title, "NEW_TITLE")
                expect.fulfill()
            } onError: { error in
                XCTFail("update should success \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("update should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
        
        dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: initialContext,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockWikiTreeDataProcessor())
        // case 3 update shortcut节点, 本体存在，updateForOrigin = false
        expect = expectation(description: "update shortcut node title without updateForOrigin flag")
        CacheAPI.expectUpdateShortcut = true
        dataModel.syncTitleUpdate(wikiToken: "SHORTCUT_TARGET", newTitle: "NEW_TITLE")
            .subscribe { result in
                XCTAssertEqual(result.metaStorage["SHORTCUT_TARGET"]?.title, "NEW_TITLE")
                expect.fulfill()
            } onError: { error in
                XCTFail("update should success \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("update should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
        
        dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: initialContext,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockWikiTreeDataProcessor())
        // case 4 update shortcut节点，本体存在，updateForOrigin = true
        expect = expectation(description: "update normal node title without updateForOrigin flag")
        CacheAPI.expectUpdateShortcut = false
        dataModel.syncTitleUpdate(wikiToken: "SHORTCUT_TARGET", newTitle: "NEW_TITLE", updateForOrigin: true)
            .subscribe { result in
                XCTAssertEqual(result.metaStorage["TARGET"]?.title, "NEW_TITLE")
                expect.fulfill()
            } onError: { error in
                XCTFail("update should success \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("update should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
        
        dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: initialContext,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockWikiTreeDataProcessor())
        // case 5 update shortcut节点，本体不存在，updateForOrigin = true
        expect = expectation(description: "update normal node title without updateForOrigin flag")
        CacheAPI.expectUpdateShortcut = false
        dataModel.syncTitleUpdate(wikiToken: "SHORTCUT_UNKNOWN", newTitle: "NEW_TITLE", updateForOrigin: true)
            .subscribe { _ in
                XCTFail("update should completed")
                expect.fulfill()
            } onError: { error in
                XCTFail("update should completed \(error)")
                expect.fulfill()
            } onCompleted: {
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
        
        dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: initialContext,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockWikiTreeDataProcessor())
        // case 5 update external shortcut节点，updateForOrigin = true
        expect = expectation(description: "update normal node title without updateForOrigin flag")
        CacheAPI.expectUpdateShortcut = false
        dataModel.syncTitleUpdate(wikiToken: "SHORTCUT_EXTERNAL", newTitle: "NEW_TITLE", updateForOrigin: true)
            .subscribe { _ in
                XCTFail("update should completed")
                expect.fulfill()
            } onError: { error in
                XCTFail("update should completed \(error)")
                expect.fulfill()
            } onCompleted: {
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
        
        // case 7 update 不存在的节点
        expect = expectation(description: "update unknown title")
        dataModel.syncTitleUpdate(wikiToken: "UNKNOWN", newTitle: "NEW_TITLE")
            .subscribe { _ in
                XCTFail("update should completed")
                expect.fulfill()
            } onError: { error in
                XCTFail("update should completed \(error)")
                expect.fulfill()
            } onCompleted: {
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    // 移动非选中节点
    func testMoveCase1() {
        class CacheAPI: MockWikiTreeCacheAPI {
            override func batchUpdate(metas: [WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
                XCTAssertEqual(metas.map(\.wikiToken), ["TARGET", "OLD", "NEW"])
                return .empty()
            }
        }
        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                guard case let .move(oldParent, newParent, nodes) = operation else {
                    throw TestError.invalidProcessOperation
                }
                XCTAssertEqual(oldParent, "OLD")
                XCTAssertEqual(newParent, "NEW")
                XCTAssertEqual(nodes.map(\.meta.wikiToken), ["TARGET"])
                return WikiTreeState(viewState: WikiTreeViewState(),
                                     metaStorage: [
                                        "OLD": Util.mockNode(token: "OLD", hasChild: false),
                                        "NEW": Util.mockNode(token: "NEW", hasChild: true)
                                     ],
                                     relation: WikiTreeRelation())
            }
        }

        let state = WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: "OLD", expandedUIDs: []),
                                  metaStorage: [
                                    "OLD": Util.mockNode(token: "OLD", hasChild: true),
                                    "NEW": Util.mockNode(token: "NEW", hasChild: false)
                                  ],
                                  relation: WikiTreeRelation())
        let context = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: "", section: .mainRoot, shortcutPath: ""),
                                      spaceID: Util.mockSpaceID,
                                      treeState: state,
                                      spaceInfo: nil,
                                      userSpacePermission: nil)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: context,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockProcessor())
        let target = WikiServerNode(meta: Util.mockNode(token: "TARGET", hasChild: false), sortID: 10, parent: "OLD")
        let expect = expectation(description: "move case 1")
        dataModel.syncMove(oldParentToken: "OLD",
                           newParentToken: "NEW",
                           movedToken: "TARGET",
                           movedNode: target,
                           allowSpaceRedirect: true)
            .subscribe { result in
                XCTAssertFalse(result.selectedTokenDeleted)
                XCTAssertFalse(result.selectedTokenMoved)
                expect.fulfill()
            } onError: { error in
                XCTFail("update should success \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("update should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    // 移动同库的选中节点
    func testMoveCase2() {
        class NetworkAPI: MockWikiNetworkAPI {
            override func loadTree(spaceID: String, initialWikiToken: String?, needPermission: Bool) -> Single<WikiTreeData> {
                XCTAssertEqual(spaceID, Util.mockSpaceID)
                XCTAssertEqual(initialWikiToken, Util.TestTree.leaf3_3_1.wikiToken)
                let result = WikiTreeData(mainRootToken: "ROOT", metaStorage: [:], relation: WikiTreeRelation())
                return .just(result)
            }
        }
        let state = WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: Util.TestTree.leaf3_3_1.wikiToken, expandedUIDs: []),
                                  metaStorage: Util.TestTree.metaStorage,
                                  relation: Util.TestTree.relation)
        let context = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: "", section: .mainRoot, shortcutPath: ""),
                                      spaceID: Util.mockSpaceID,
                                      treeState: state,
                                      spaceInfo: nil,
                                      userSpacePermission: nil)
        let processor = MockWikiTreeDataProcessor()
        processor.result = .success(state)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: context,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: processor)
        let target = WikiServerNode(meta: Util.TestTree.normal3_3, sortID: 10, parent: "NEW_PARENT")
        let expect = expectation(description: "move case 2")
        dataModel.syncMove(oldParentToken: Util.TestTree.normal3.wikiToken,
                           newParentToken: "NEW_PARENT",
                           movedToken: Util.TestTree.normal3_3.wikiToken,
                           movedNode: target,
                           allowSpaceRedirect: true)
            .subscribe { result in
                XCTAssertFalse(result.selectedTokenDeleted)
                XCTAssertTrue(result.selectedTokenMoved)
                expect.fulfill()
            } onError: { error in
                XCTFail("update should success \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("update should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    // 跨库移动选中节点
    func testMoveCase3() {
        class NetworkAPI: MockWikiNetworkAPI {
            override func loadTree(spaceID: String, initialWikiToken: String?, needPermission: Bool) -> Single<WikiTreeData> {
                XCTAssertEqual(spaceID, "NEW_SPACE")
                XCTAssertEqual(initialWikiToken, Util.TestTree.leaf3_3_1.wikiToken)
                let result = WikiTreeData(mainRootToken: "ROOT", metaStorage: [:], relation: WikiTreeRelation())
                return .just(result)
            }
        }
        let state = WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: Util.TestTree.leaf3_3_1.wikiToken, expandedUIDs: []),
                                  metaStorage: Util.TestTree.metaStorage,
                                  relation: Util.TestTree.relation)
        let context = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: "", section: .mainRoot, shortcutPath: ""),
                                      spaceID: Util.mockSpaceID,
                                      treeState: state,
                                      spaceInfo: nil,
                                      userSpacePermission: nil)
        let processor = MockWikiTreeDataProcessor()
        processor.result = .success(state)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: context,
                                          networkAPI: NetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: processor)
        var meta = Util.TestTree.normal3_3
        meta.spaceID = "NEW_SPACE"
        let target = WikiServerNode(meta: meta, sortID: 10, parent: "NEW_PARENT")
        let expect = expectation(description: "move case 3")
        dataModel.syncMove(oldParentToken: Util.TestTree.normal3.wikiToken,
                           newParentToken: "NEW_PARENT",
                           movedToken: Util.TestTree.normal3_3.wikiToken,
                           movedNode: target,
                           allowSpaceRedirect: true)
            .subscribe { result in
                XCTAssertFalse(result.selectedTokenDeleted)
                XCTAssertTrue(result.selectedTokenMoved)
                expect.fulfill()
            } onError: { error in
                XCTFail("update should success \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("update should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    // 移动导致节点从目录树上被删除
    func testMoveCase4() {
        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                let state = WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: Util.TestTree.leaf3_3_1.wikiToken,
                                                                       expandedUIDs: []),
                                          metaStorage: [:],
                                          relation: WikiTreeRelation())
                if case let .delete(token, response) = operation {
                    XCTAssertEqual(token, Util.TestTree.normal3_3.wikiToken)
                    response([Util.TestTree.normal3_3.wikiToken, Util.TestTree.leaf3_3_1.wikiToken])
                    return state
                }
                if case let .batchDelete(_, _, response) = operation {
                    response([Util.TestTree.normal3_3.wikiToken, Util.TestTree.leaf3_3_1.wikiToken])
                    return state
                }
                throw TestError.invalidProcessOperation
            }
        }
        let initialState = WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: Util.TestTree.leaf3_3_1.wikiToken, expandedUIDs: []),
                                         metaStorage: [:],
                                         relation: WikiTreeRelation())
        let initialContext = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: "A",
                                                                      section: .mainRoot,
                                                                      shortcutPath: ""),
                                             spaceID: Util.mockSpaceID,
                                             treeState: initialState,
                                             spaceInfo: nil,
                                             userSpacePermission: nil)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: initialContext,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: MockProcessor())

        var expect = expectation(description: "move case 4")
        dataModel.syncMove(oldParentToken: "OLD",
                           newParentToken: "NEW",
                           movedToken: Util.TestTree.normal3_3.wikiToken,
                           movedNode: nil,
                           allowSpaceRedirect: true)
            .subscribe { result in
                XCTAssertTrue(result.selectedTokenDeleted)
                XCTAssertFalse(result.selectedTokenMoved)
                expect.fulfill()
            } onError: { error in
                XCTFail("delete should success \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("delete should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)

        expect = expectation(description: "batch move case 4")
        dataModel.syncBatchMove(oldParentToken: "OLD",
                                targetMeta: WikiMeta(wikiToken: "NEW", spaceID: "NEW"),
                                movedTokens: [Util.TestTree.normal3_3.wikiToken],
                                movedNodes: [:],
                                allowSpaceRedirect: true)
            .subscribe { result in
                XCTAssertTrue(result.selectedTokenDeleted)
                XCTAssertFalse(result.selectedTokenMoved)
                expect.fulfill()
            } onError: { error in
                XCTFail("delete should success \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("delete should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    // 协同导致高亮节点被从树中删除
    func testMoveCase5() {
        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                let state = WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: Util.TestTree.leaf3_3_1.wikiToken,
                                                                       expandedUIDs: []),
                                          metaStorage: [:],
                                          relation: WikiTreeRelation())
                if case let .delete(token, response) = operation {
                    XCTAssertEqual(token, Util.TestTree.normal3_3.wikiToken)
                    response([Util.TestTree.normal3_3.wikiToken, Util.TestTree.leaf3_3_1.wikiToken])
                    return state
                }
                if case let .batchDelete(_, _, response) = operation {
                    response([Util.TestTree.normal3_3.wikiToken, Util.TestTree.leaf3_3_1.wikiToken])
                    return state
                }
                throw TestError.invalidProcessOperation
            }
        }
        let state = WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: Util.TestTree.leaf3_3_1.wikiToken, expandedUIDs: []),
                                  metaStorage: Util.TestTree.metaStorage,
                                  relation: Util.TestTree.relation)
        let context = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: "", section: .mainRoot, shortcutPath: ""),
                                      spaceID: Util.mockSpaceID,
                                      treeState: state,
                                      spaceInfo: nil,
                                      userSpacePermission: nil)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: context,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: MockProcessor())
        var meta = Util.TestTree.normal3_3
        meta.spaceID = "NEW_SPACE"
        let target = WikiServerNode(meta: meta, sortID: 10, parent: "NEW_PARENT")
        var expect = expectation(description: "move case 5")
        dataModel.syncMove(oldParentToken: Util.TestTree.normal3.wikiToken,
                           newParentToken: "NEW_PARENT",
                           movedToken: Util.TestTree.normal3_3.wikiToken,
                           movedNode: target,
                           allowSpaceRedirect: false)
            .subscribe { result in
                XCTAssertTrue(result.selectedTokenDeleted)
                XCTAssertFalse(result.selectedTokenMoved)
                expect.fulfill()
            } onError: { error in
                XCTFail("update should success \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("update should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)

        expect = expectation(description: "batch move case 5")
        dataModel.syncBatchMove(oldParentToken: Util.TestTree.normal3.wikiToken,
                                targetMeta: WikiMeta(wikiToken: "NEW_PARENT", spaceID: "NEW_SPACE"),
                                movedTokens: [Util.TestTree.normal3_3.wikiToken],
                                movedNodes: [Util.TestTree.normal3_3.wikiToken: target],
                                allowSpaceRedirect: false)
            .subscribe { result in
                XCTAssertTrue(result.selectedTokenDeleted)
                XCTAssertFalse(result.selectedTokenMoved)
                expect.fulfill()
            } onError: { error in
                XCTFail("delete should success \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("delete should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    // 失去权限表示被删除
    func testPermissionUpdateCase1() {
        class CacheAPI: MockWikiTreeCacheAPI {
            override func batchUpdate(metas: [WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
                XCTAssertEqual(metas.map(\.wikiToken), [Util.TestTree.normal3_3.wikiToken, WikiTreeNodeMeta.favoriteRootToken])
                return .empty()
            }

            override func delete(wikiTokens: [String]) -> Completable {
                XCTAssertEqual(wikiTokens, [Util.TestTree.leaf3_3_1.wikiToken])
                return .empty()
            }
        }
        // 初始化好收藏列表
        var metas = Util.TestTree.metaStorage
        metas[WikiTreeNodeMeta.favoriteRootToken] = WikiTreeNodeMeta.createFavoriteRoot(spaceID: Util.mockSpaceID)
        var relation = Util.TestTree.relation
        relation.setup(rootToken: WikiTreeNodeMeta.favoriteRootToken)
        let initialState = WikiTreeState(viewState: WikiTreeViewState(),
                                         metaStorage: metas,
                                         relation: relation)
        let initialContext = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: "A",
                                                                      section: .mainRoot,
                                                                      shortcutPath: ""),
                                             spaceID: Util.mockSpaceID,
                                             treeState: initialState,
                                             spaceInfo: nil,
                                             userSpacePermission: nil)
        let processor = MockWikiTreeDataProcessor()
        processor.result = .success(initialState)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: initialContext,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: processor)

        let expect = expectation(description: "permission update case 1")
        dataModel.syncNodePermissionUpdate(wikiToken: Util.TestTree.leaf3_3_1.wikiToken, node: nil)
            .subscribe { result in
                XCTAssertFalse(result.selectedTokenMoved)
                XCTAssertFalse(result.selectedTokenDeleted)
                expect.fulfill()
            } onError: { error in
                XCTFail("delete should success \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("delete should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    // 权限 update 前后节点信息都可知
    func testPermissionUpdateCase2() {
        let target = WikiServerNode(meta: Util.mockNode(token: "TARGET", hasChild: false), sortID: 10, parent: "NEW")
        let state = WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: "OLD", expandedUIDs: []),
                                  metaStorage: [
                                    "OLD": Util.mockNode(token: "OLD", hasChild: true),
                                    "TARGET": target.meta,
                                    "NEW": Util.mockNode(token: "NEW", hasChild: false)
                                  ],
                                  relation: WikiTreeRelation(nodeParentMap: ["TARGET": "OLD"], nodeChildrenMap: [:]))
        let context = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: "", section: .mainRoot, shortcutPath: ""),
                                      spaceID: Util.mockSpaceID,
                                      treeState: state,
                                      spaceInfo: nil,
                                      userSpacePermission: nil)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: context,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: MockWikiTreeDataProcessor())
        let expect = expectation(description: "permission update case 2")
        dataModel.syncNodePermissionUpdate(wikiToken: target.meta.wikiToken, node: target)
            .subscribe { result in
                XCTAssertFalse(result.selectedTokenDeleted)
                XCTAssertFalse(result.selectedTokenMoved)
                expect.fulfill()
            } onError: { error in
                XCTFail("update should success \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("update should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    // 权限从无到有
    func testPermissionUpdateCase3() {
        let parentToken = Util.TestTree.normal3_3.wikiToken
        let initialState = WikiTreeState(viewState: WikiTreeViewState(),
                                         metaStorage: Util.TestTree.metaStorage,
                                         relation: Util.TestTree.relation)
        let initialContext = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: "",
                                                                      section: .mainRoot,
                                                                      shortcutPath: ""),
                                             spaceID: Util.mockSpaceID,
                                             treeState: initialState,
                                             spaceInfo: nil,
                                             userSpacePermission: nil)
        let processor = MockWikiTreeDataProcessor()
        processor.result = .success(initialState)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: initialContext,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: processor)
        let target = WikiServerNode(meta: Util.mockNode(token: "A1", hasChild: false), sortID: 10, parent: parentToken)
        let expect = expectation(description: "permission update case 3")
        dataModel.syncNodePermissionUpdate(wikiToken: target.meta.wikiToken, node: target)
            .subscribe { result in
                XCTAssertFalse(result.selectedTokenDeleted)
                XCTAssertFalse(result.selectedTokenMoved)
                expect.fulfill()
            } onError: { error in
                XCTFail("un-expected error found \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("add should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testToggleStar() {
        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                guard case let .toggleWikiStar(wikiToken, isStar) = operation else {
                    throw TestError.invalidProcessOperation
                }
                XCTAssertEqual(wikiToken, "A")
                XCTAssertTrue(isStar)
                let state = WikiTreeState(viewState: WikiTreeViewState(),
                                          metaStorage: [
                                            WikiTreeNodeMeta.favoriteRootToken: WikiTreeNodeMeta.createFavoriteRoot(spaceID: Util.mockSpaceID)
                                          ], relation: WikiTreeRelation())
                return state
            }
        }
        class CacheAPI: MockWikiTreeCacheAPI {
            override func batchUpdate(metas: [WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
                XCTAssertEqual(metas.map(\.wikiToken), [WikiTreeNodeMeta.favoriteRootToken])
                return .empty()
            }
        }
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockProcessor())
        let expect = expectation(description: "toggle wiki star")
        dataModel.syncToggleStar(wikiToken: "A", isStar: true)
            .subscribe { _ in
                expect.fulfill()
            } onError: { error in
                XCTFail("toggle star should success \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("toggle star should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testToggleStarFailed() {
        let processor = MockWikiTreeDataProcessor()
        processor.result = .failure(WikiTreeOperation.UpdateError.targetNotFound)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: processor)
        let expect = expectation(description: "toggle wiki star failed")
        dataModel.syncToggleStar(wikiToken: "A", isStar: true)
            .subscribe { _ in
                XCTFail("toggle star should completed")
                expect.fulfill()
            } onError: { error in
                XCTFail("toggle star should completed \(error)")
                expect.fulfill()
            } onCompleted: {
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testToggleExplorerStar() {
        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                guard case let .toggleExplorerStar(wikiToken, isStar) = operation else {
                    throw TestError.invalidProcessOperation
                }
                XCTAssertEqual(wikiToken, "A")
                XCTAssertTrue(isStar)
                let state = WikiTreeState(viewState: WikiTreeViewState(),
                                          metaStorage: [
                                            "A": Util.mockNode(token: "A", hasChild: false)
                                          ],
                                          relation: WikiTreeRelation())
                return state
            }
        }
        class CacheAPI: MockWikiTreeCacheAPI {
            override func batchUpdate(metas: [WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
                XCTAssertEqual(metas.map(\.wikiToken), ["A"])
                return .empty()
            }
        }
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockProcessor())
        let expect = expectation(description: "toggle wiki star")
        dataModel.syncToggleExplorerStar(wikiToken: "A", isStar: true)
            .subscribe { _ in
                expect.fulfill()
            } onError: { error in
                XCTFail("toggle star should success \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("toggle star should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testToggleExplorerStarFailed() {
        let processor = MockWikiTreeDataProcessor()
        processor.result = .failure(WikiTreeOperation.UpdateError.targetNotFound)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: processor)
        let expect = expectation(description: "toggle wiki star failed")
        dataModel.syncToggleExplorerStar(wikiToken: "A", isStar: true)
            .subscribe { _ in
                XCTFail("toggle star should completed")
                expect.fulfill()
            } onError: { error in
                XCTFail("toggle star should completed \(error)")
                expect.fulfill()
            } onCompleted: {
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }
    
    func testToggleExplorerStarForExternalShortcut() {
        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                guard case let .toggleExplorerStarForExternalShortcut(objToken, isStar) = operation else {
                    throw TestError.invalidProcessOperation
                }
                XCTAssertEqual(objToken, "A")
                XCTAssertTrue(isStar)
                let state = WikiTreeState(viewState: WikiTreeViewState(),
                                          metaStorage: [
                                            "A": Util.mockExternalShortcutNode(token: "A", hasChild: false)
                                          ],
                                          relation: WikiTreeRelation())
                return state
            }
        }
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: MockProcessor())
        let expect = expectation(description: "toggle wiki star")
        dataModel.syncToggleExplorerStarForExternalShortcut(objToken: "A", isStar: true)
            .subscribe { _ in
                expect.fulfill()
            } onError: { error in
                XCTFail("toggle star should success \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("toggle star should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    // 目标不在树上
    func testDeleteAndMoveUpCase1() {
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: MockWikiTreeDataProcessor())
        let expect = expectation(description: "delete and move up case 1")
        dataModel.syncDeleteAndMoveUp(wikiToken: "TARGET", parentToken: "UNKNOWN", spaceID: Util.mockSpaceID)
            .subscribe { _ in
                XCTFail("case should completed")
                expect.fulfill()
            } onError: { error in
                XCTFail("case should completed \(error)")
                expect.fulfill()
            } onCompleted: {
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    // 移除节点
    func testDeleteAndMoveUpCase3() {
        class NetworkAPI: MockWikiNetworkAPI {
            override func loadChildren(spaceID: String, wikiToken: String) -> Single<([NodeChildren], [WikiTreeNodeMeta])> {
                .just(([], []))
            }
        }
        let initialState = WikiTreeState(viewState: WikiTreeViewState(selectedWikiToken: Util.TestTree.normal3_3.wikiToken,
                                                                      expandedUIDs: []),
                                         metaStorage: Util.TestTree.metaStorage,
                                         relation: Util.TestTree.relation)
        let initialContext = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: "A",
                                                                      section: .mainRoot,
                                                                      shortcutPath: ""),
                                             spaceID: Util.mockSpaceID,
                                             treeState: initialState,
                                             spaceInfo: nil,
                                             userSpacePermission: nil)
        let processor = MockWikiTreeDataProcessor()
        processor.result = .success(initialState)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          treeContext: initialContext,
                                          networkAPI: NetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: processor)

        let expect = expectation(description: "delete case 1")
        dataModel.syncDeleteAndMoveUp(wikiToken: Util.TestTree.normal3_3.wikiToken,
                                      parentToken: "",
                                      spaceID: "")
            .subscribe { result in
                XCTAssertFalse(result.selectedTokenDeleted)
                expect.fulfill()
            } onError: { error in
                XCTFail("delete should success \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("delete should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }
    
    func testToggleExplorerPin() {
        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                guard case let .toggleExplorerPin(wikiToken, isPin) = operation else {
                    throw TestError.invalidProcessOperation
                }
                XCTAssertEqual(wikiToken, "A")
                XCTAssertTrue(isPin)
                let state = WikiTreeState(viewState: WikiTreeViewState(),
                                          metaStorage: [
                                            "A": Util.mockNode(token: "A", hasChild: false)
                                          ],
                                          relation: WikiTreeRelation())
                return state
            }
        }
        class CacheAPI: MockWikiTreeCacheAPI {
            override func batchUpdate(metas: [WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
                XCTAssertEqual(metas.map(\.wikiToken), ["A"])
                return .empty()
            }
        }
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockProcessor())
        let expect = expectation(description: "toggle wiki pin")
        dataModel.syncToggleExplorerPin(wikiToken: "A", isPin: true)
            .subscribe { _ in
                expect.fulfill()
            } onError: { error in
                XCTFail("toggle pin error \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("toggle pin should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }
    
    func testToggleExplorerPinFailed() {
        let processor = MockWikiTreeDataProcessor()
        processor.result = .failure(WikiTreeOperation.UpdateError.targetNotFound)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: processor)
        let expect = expectation(description: "toggle wiki pin failed")
        dataModel.syncToggleExplorerPin(wikiToken: "A", isPin: true)
            .subscribe { _ in
                XCTFail("toggle pin should completed")
                expect.fulfill()
            } onError: { error in
                XCTFail("toggle pin should completed \(error)")
                expect.fulfill()
            } onCompleted: {
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }
    
    func testToggleExplorerPinForExternalShortcut() {
        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                guard case let .toggleExplorerPinForExternalShortcut(objToken, isPin) = operation else {
                    throw TestError.invalidProcessOperation
                }
                XCTAssertEqual(objToken, "A")
                XCTAssertTrue(isPin)
                let state = WikiTreeState(viewState: WikiTreeViewState(),
                                          metaStorage: [
                                            "A": Util.mockExternalShortcutNode(token: "A", hasChild: false)
                                          ],
                                          relation: WikiTreeRelation())
                return state
            }
        }
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: MockProcessor())
        let expect = expectation(description: "toggle wiki pin")
        dataModel.syncToggleExplorerPinForExternalShortcut(objToken: "A", isPin: true)
            .subscribe { _ in
                expect.fulfill()
            } onError: { error in
                XCTFail("toggle pin should success \(error)")
                expect.fulfill()
            } onCompleted: {
                XCTFail("toggle pin should success")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }
    
    func testToggleExplorerPinForExternalShortcutFailed() {
        let processor = MockWikiTreeDataProcessor()
        processor.result = .failure(WikiTreeOperation.UpdateError.targetNotFound)
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: nil,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: processor)
        let expect = expectation(description: "toggle wiki pin failed")
        dataModel.syncToggleExplorerPinForExternalShortcut(objToken: "A", isPin: true)
            .subscribe { _ in
                XCTFail("toggle pin should failed")
                expect.fulfill()
            } onError: { error in
                expect.fulfill()
            } onCompleted: {
                XCTFail("toggle pin should failed")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }
}
