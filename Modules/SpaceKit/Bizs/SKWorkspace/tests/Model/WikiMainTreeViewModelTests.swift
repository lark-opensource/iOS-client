//
//  WikiMainTreeViewModelTests.swift
//  SKWikiV2_Tests-Unit-_Tests
//
//  Created by majie.7 on 2022/9/16.
//

import SKFoundation
import XCTest
@testable import SKWorkspace
import RxSwift
import SKCommon
import RxRelay
import RxCocoa
import SpaceInterface

class MockWikiMainTreeMoreProvider: WikiTreeMoreProvider {
    var spaceInput = PublishRelay<WikiSpace?>()
    
    var spacePermissionInput = PublishRelay<WikiSpacePermission>()
    
    var actionSignal: Signal<WikiTreeViewAction> {
        actionInput.asSignal()
    }
    
    var moreActionSignal: Signal<WikiTreeMoreAction> {
        moreActionInput.asSignal()
    }
    
    var parentProvider: ((String) -> String?)?
    
    var childCountProvider: ((String) -> Int?)?
    
    var clipChecker: ((String) -> Bool)?
    
    func createOnRootNode(rootMeta: WikiTreeNodeMeta, sourceView: UIView) {
    }
    
    func configSlideAction(meta: WikiTreeNodeMeta, node: TreeNode) -> [TreeSwipeAction]? {
        nil
    }
    
    func preloadPermission(meta: WikiTreeNodeMeta) {
    }
    
    let moreActionInput = PublishRelay<WikiTreeMoreAction>()
    let actionInput: PublishRelay<WikiTreeViewAction>
    
    init(actionInput: PublishRelay<WikiTreeViewAction>) {
        self.actionInput = actionInput
    }
}
class WikiMainTreeViewModelTests: XCTestCase {
    enum TestError: Error, Equatable {
        case invalidProcessOperation
        case expectError
    }
    typealias Util = WikiTreeTestUtil
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
    
    func testReloadTreeFailed() {
        class NetworkAPI: MockWikiNetworkAPI {
            override func loadTree(spaceID: String, initialWikiToken: String?, needPermission: Bool) -> Single<WikiTreeData> {
                .error(NSError(domain: "NodePermFail", code: 920004012))
            }
        }
        
        let initialState = WikiTreeState(viewState: WikiTreeViewState(),
                                         metaStorage: Util.TestTree.metaStorage,
                                         relation: Util.TestTree.relation)
        let initialContext = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: Util.TestTree.leaf1.wikiToken,
                                                                      section: .mainRoot,
                                                                      shortcutPath: ""),
                                             spaceID: Util.mockSpaceID,
                                             treeState: initialState,
                                             spaceInfo: nil,
                                             userSpacePermission: nil)
        
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: Util.TestTree.leaf1.wikiToken,
                                          scene: .spacePage,
                                          treeContext: initialContext,
                                          networkAPI: NetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: MockWikiTreeDataProcessor())
        
        let vm = WikiMainTreeViewModel(dataModel: dataModel, scene: .spacePage)
        vm.setup()
        vm.reload()
        let expect = expectation(description: "reload tree failed")
        expect.expectedFulfillmentCount = 2
        vm.actionInput.subscribe(onNext: { action in
            if case .showErrorPage = action {
                XCTAssertTrue(true)
            } else {
                XCTFail("not expected action")
            }
            expect.fulfill()
        }).disposed(by: bag)
        waitForExpectations(timeout: 1)
    }
    
    func testMoreHandler() {
        let initialState = WikiTreeState(viewState: WikiTreeViewState(),
                                         metaStorage: Util.TestTree.metaStorage,
                                         relation: Util.TestTree.relation)
        let initialContext = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: Util.TestTree.leaf1.wikiToken,
                                                                      section: .mainRoot,
                                                                      shortcutPath: ""),
                                             spaceID: Util.mockSpaceID,
                                             treeState: initialState,
                                             spaceInfo: nil,
                                             userSpacePermission: nil)
        
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: Util.TestTree.leaf1.wikiToken,
                                          scene: .spacePage,
                                          treeContext: initialContext,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: MockWikiTreeCacheAPI(),
                                          processor: MockWikiTreeDataProcessor())
        let provider = MockWikiMainTreeMoreProvider(actionInput: PublishRelay<WikiTreeViewAction>())
        let vm = WikiMainTreeViewModel(dataModel: dataModel,
                                       scene: .spacePage,
                                       initialNodeUID: nil,
                                       interactionHandler: WikiInteractionHandler(),
                                       moreProvider: provider,
                                       networkAPI: MockWikiNetworkAPI(),
                                       converterProvider: WikiMainTreeConverterProvider(offlineChecker: WikiMainTreeOfflineChecker()),
                                       synergyUUID: "")
        vm.setupMoreProvider()
        guard let provider = vm.moreProvider as? MockWikiMainTreeMoreProvider else {
            XCTFail("convert moreProvider error")
            return
        }
        let expect = expectation(description: "wiki tree delete node")
        expect.expectedFulfillmentCount = 2
        let meta = WikiTreeNodeMeta(wikiToken: "token",
                                    spaceID: "spaceID",
                                    objToken: "objToken",
                                    objType: .docX,
                                    title: "title",
                                    hasChild: true,
                                    secretKeyDeleted: false,
                                    isExplorerStar: false,
                                    nodeType: .normal,
                                    originDeletedFlag: 0,
                                    isExplorerPin: false)
        vm.treeStateRelay.subscribe(onNext: { _ in
            expect.fulfill()
        }).disposed(by: bag)
        provider.moreActionInput.accept(.delete(meta: meta, isSingleDelete: false))
        provider.moreActionInput.accept(.delete(meta: meta, isSingleDelete: true))
        
        waitForExpectations(timeout: 10)
    }
    
    func testHandleSyncToggleExplorerPin() {
        class MockProcessor: WikiTreeDataProcessorType {
            func process(operation: WikiTreeOperation, treeState: WikiTreeState) throws -> WikiTreeState {
                if case let .toggleExplorerPin(wikiToken, isPin) = operation {
                    XCTAssertEqual(wikiToken, "A")
                    XCTAssertTrue(isPin)
                    let state = WikiTreeState(viewState: WikiTreeViewState(),
                                              metaStorage: [
                                                "A": Util.mockNode(token: "A", hasChild: false)
                                              ],
                                              relation: WikiTreeRelation())
                    return state
                }
                if case let .toggleExplorerPinForExternalShortcut(objToken, isPin) = operation {
                    XCTAssertEqual(objToken, "B")
                    XCTAssertTrue(isPin)
                    let state = WikiTreeState(viewState: WikiTreeViewState(),
                                              metaStorage: [
                                                "B": Util.mockNode(token: "B", hasChild: false)
                                              ],
                                              relation: WikiTreeRelation())
                    return state
                }
                throw TestError.invalidProcessOperation
            }
        }
        class CacheAPI: MockWikiTreeCacheAPI {
            override func batchUpdate(metas: [WikiTreeNodeMeta], relation: WikiTreeRelation) -> Completable {
                XCTAssertEqual(metas.map(\.wikiToken), ["A"])
                return .empty()
            }
        }
        let initialState = WikiTreeState(viewState: WikiTreeViewState(),
                                         metaStorage: Util.TestTree.metaStorage,
                                         relation: Util.TestTree.relation)
        let initialContext = WikiTreeContext(nodeUID: WikiTreeNodeUID(wikiToken: Util.TestTree.leaf1.wikiToken,
                                                                      section: .mainRoot,
                                                                      shortcutPath: ""),
                                             spaceID: Util.mockSpaceID,
                                             treeState: initialState,
                                             spaceInfo: nil,
                                             userSpacePermission: nil)
        
        let dataModel = WikiTreeDataModel(spaceID: Util.mockSpaceID,
                                          initialWikiToken: Util.TestTree.leaf1.wikiToken,
                                          scene: .spacePage,
                                          treeContext: initialContext,
                                          networkAPI: MockWikiNetworkAPI(),
                                          cacheAPI: CacheAPI(),
                                          processor: MockProcessor())
        let provider = MockWikiMainTreeMoreProvider(actionInput: PublishRelay<WikiTreeViewAction>())
        let vm = WikiMainTreeViewModel(dataModel: dataModel,
                                       scene: .spacePage,
                                       initialNodeUID: nil,
                                       interactionHandler: WikiInteractionHandler(),
                                       moreProvider: provider,
                                       networkAPI: MockWikiNetworkAPI(),
                                       converterProvider: WikiMainTreeConverterProvider(offlineChecker: WikiMainTreeOfflineChecker()),
                                       synergyUUID: "")
        vm.setupSyncProcessor()
        let expect = expectation(description: "handle sync toggle explorer pin")
        expect.expectedFulfillmentCount = 2
        vm.treeStateRelay
            .skip(1)
            .subscribe(onNext: { _ in
            expect.fulfill()
        }).disposed(by: bag)
        
        let notificationInfo_1: [String: Any] = ["targetToken": "A", "objType": DocsType.wiki, "addPin": true]
        let notificationInfo_2: [String: Any] = ["targetToken": "B", "objType": DocsType.docX, "addPin": true]
        NotificationCenter.default.post(name: Notification.Name.Docs.WikiExplorerPinNode, object: nil, userInfo: notificationInfo_1)
        NotificationCenter.default.post(name: Notification.Name.Docs.WikiExplorerPinNode, object: nil, userInfo: notificationInfo_2)
        
        waitForExpectations(timeout: 10)
    }
}
