//
//  WikiInteractionHandlerTests.swift
//  SKWikiV2_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/8/18.
//
// swiftlint:disable file_length type_body_length

import XCTest
@testable import SKWorkspace
import SKFoundation
import SKCommon
import RxSwift
import UIKit
import SpaceInterface

class WikiInteractionHandlerTests: XCTestCase {

    typealias Handler = WikiInteractionHandler
    typealias Context = Handler.Context
    typealias TestError = MockWikiNetworkAPI.MockNetworkError
    typealias Util = WikiTreeTestUtil

    private var bag = DisposeBag()

    override func setUp() {
        // 没有设置baseURL，网路请求会中assert
        super.setUp()
        bag = DisposeBag()
        AssertionConfigForTest.disableAssertWhenTesting()
    }
    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    func testSetup() {
        let handler = Handler(networkAPI: MockWikiNetworkAPI(), synergyUUID: "MOCK")
        XCTAssertEqual(handler.synergyUUID, "MOCK")
    }

    func testContext() {
        let context1 = Context(wikiToken: "WIKI_TOKEN",
                               sourceLocation: .inWiki(wikiToken: "SOURCE_TOKEN", spaceID: "SOURCE_ID"),
                               objToken: "OBJ_TOKEN",
                               objType: .unknown(100),
                               name: "NAME",
                               isShortcut: false,
                               parent: ("PARENT_TOKEN", "PARENT_SPACE"))
        XCTAssertEqual(context1.wikiToken, "WIKI_TOKEN")
        XCTAssertEqual(context1.sourceLocation, .inWiki(wikiToken: "SOURCE_TOKEN", spaceID: "SOURCE_ID"))
        XCTAssertEqual(context1.objToken, "OBJ_TOKEN")
        XCTAssertEqual(context1.objType, .unknown(100))
        XCTAssertEqual(context1.name, "NAME")
        XCTAssertEqual(context1.parent?.token, "PARENT_TOKEN")
        XCTAssertEqual(context1.parent?.spaceID, "PARENT_SPACE")
        XCTAssertFalse(context1.isShortcut)

        let node = WikiTreeNodeMeta(wikiToken: "WIKI_TOKEN",
                                    spaceID: "SPACE_ID",
                                    objToken: "OBJ_TOKEN",
                                    objType: .unknown(200),
                                    title: "TITLE",
                                    hasChild: false,
                                    secretKeyDeleted: false,
                                    isExplorerStar: false,
                                    nodeType: .normal,
                                    originDeletedFlag: 0,
                                    isExplorerPin: false)
        let context2 = Context(meta: node, parentToken: "PARENT_TOKEN")
        XCTAssertEqual(context2.wikiToken, "WIKI_TOKEN")
        XCTAssertEqual(context2.sourceLocation, .inWiki(wikiToken: "WIKI_TOKEN", spaceID: "SPACE_ID"))
        XCTAssertEqual(context2.objToken, "OBJ_TOKEN")
        XCTAssertEqual(context2.objType, .unknown(200))
        XCTAssertEqual(context2.name, "TITLE")
        XCTAssertEqual(context2.parent?.token, "PARENT_TOKEN")
        XCTAssertEqual(context2.parent?.spaceID, "SPACE_ID")

        let shortcutNode = WikiTreeNodeMeta(wikiToken: "WIKI_TOKEN",
                                            spaceID: "SPACE_ID",
                                            objToken: "OBJ_TOKEN",
                                            objType: .unknown(300),
                                            title: "TITLE",
                                            hasChild: false,
                                            secretKeyDeleted: false,
                                            isExplorerStar: false,
                                            nodeType: .shortcut(location: .inWiki(wikiToken: "ORIGIN_TOKEN", spaceID: "ORIGIN_SPACE")),
                                            originDeletedFlag: 0,
                                            isExplorerPin: false)
        let context3 = Context(meta: shortcutNode)
        XCTAssertEqual(context3.wikiToken, "WIKI_TOKEN")
        XCTAssertEqual(context3.sourceLocation, .inWiki(wikiToken: "ORIGIN_TOKEN", spaceID: "ORIGIN_SPACE"))
        XCTAssertEqual(context3.objToken, "OBJ_TOKEN")
        XCTAssertEqual(context3.objType, .unknown(300))
        XCTAssertEqual(context3.name, "TITLE")
        XCTAssertNil(context3.parent)
    }

    func testGetNodeInfo() {
        class NetworkAPI: MockWikiNetworkAPI {
            override func getNodeMetaInfo(wikiToken: String) -> Single<WikiServerNode> {
                XCTAssertEqual(wikiToken, "MOCK")
                return .error(TestError.expectError)
            }
        }

        let handler = Handler(networkAPI: NetworkAPI(), synergyUUID: nil)
        let expect = expectation(description: #function)
        handler.getNodeInfo(wikiToken: "MOCK")
            .subscribe { _ in
                XCTFail("request should failed")
                expect.fulfill()
            } onError: { error in
                guard let testError = error as? TestError,
                      case .expectError = testError else {
                    XCTFail("un-expected error found \(error)")
                    expect.fulfill()
                    return
                }
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testFetchPermission() {
        class NetworkAPI: MockWikiNetworkAPI {
            override func getNodePermission(spaceId: String, wikiToken: String) -> Single<WikiTreeNodePermission> {
                XCTAssertEqual(wikiToken, "MOCK")
                XCTAssertEqual(spaceId, "MOCK_SPACE")
                return .error(TestError.expectError)
            }
        }

        let handler = Handler(networkAPI: NetworkAPI(), synergyUUID: nil)
        let expect = expectation(description: #function)
        handler.fetchPermission(wikiToken: "MOCK", spaceID: "MOCK_SPACE")
            .subscribe { _ in
                XCTFail("request should failed")
                expect.fulfill()
            } onError: { error in
                guard let testError = error as? TestError,
                      case .expectError = testError else {
                    XCTFail("un-expected error found \(error)")
                    expect.fulfill()
                    return
                }
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    // MARK: - Copy
    func testCopyPickerLocation() {
        typealias CopyLocation = Handler.CopyPickerLocation
        var target = CopyLocation.currentLocation
        XCTAssertEqual(target.getTargetSpaceID(currentSpaceID: "MOCK"), "MOCK")
        XCTAssertEqual(target.targetModule, .defaultLocation)
        XCTAssertNil(target.targetFolderType)
        let folderType = FolderType(ownerType: singleContainerOwnerTypeValue, shareVersion: nil, isShared: false)
        let location = WorkspacePickerLocation.folder(location: SpaceFolderPickerLocation(folderToken: "FOLDER",
                                                                                          folderType: folderType,
                                                                                          isExternal: false,
                                                                                          canCreateSubNode: true,
                                                                                          targetModule: .personal,
                                                                                          targetFolderType: .folder))
        target = .pick(location: location)
        XCTAssertEqual(target.getTargetSpaceID(currentSpaceID: "MOCK"), "FOLDER")
        XCTAssertEqual(target.targetModule, .personal)
        XCTAssertEqual(target.targetFolderType, .folder)
    }

    func testCopyToSpace() {
        class NetworkAPI: MockWikiNetworkAPI {
            override func copyWikiToSpace(sourceSpaceID: String,
                                          sourceWikiToken: String,
                                          objType: DocsType,
                                          title: String,
                                          folderToken: String) -> Single<(String, URL)> {
                XCTAssertEqual(sourceSpaceID, "MOCK_SPACE")
                XCTAssertEqual(sourceWikiToken, "MOCK_TOKEN")
                XCTAssertEqual(objType, .doc)
                XCTAssertEqual(folderToken, "FOLDER_TOKEN")
                return .just(("FOLDER_TOKEN", URL(string: "https://www.feishu.cn/folder")!))
            }
        }
        let handler = Handler(networkAPI: NetworkAPI(), synergyUUID: nil)
        let context = Context(meta: Util.mockNode(token: "MOCK_TOKEN", hasChild: false, spaceID: "MOCK_SPACE"))
        let expect = expectation(description: #function)
        let folderType = FolderType(ownerType: singleContainerOwnerTypeValue, shareVersion: nil, isShared: nil)
        let spaceLocation = SpaceFolderPickerLocation(folderToken: "FOLDER_TOKEN",
                                                      folderType: folderType,
                                                      isExternal: false,
                                                      canCreateSubNode: true,
                                                      targetModule: .personal,
                                                      targetFolderType: .folder)
        let location = WorkspacePickerLocation.folder(location: spaceLocation)
        handler.confirmCopyTo(location: location,
                              context: context,
                              picker: UIViewController())
        .subscribe { createResponse in
            XCTAssertEqual(createResponse.location, location)
            XCTAssertEqual(createResponse.node, .space(url: URL(string: "https://www.feishu.cn/folder")!))
            XCTAssertEqual(createResponse.statistic.pageToken, "FOLDER_TOKEN")
            XCTAssertEqual(createResponse.statistic.objToken, "FOLDER_TOKEN")
            XCTAssertEqual(createResponse.statistic.objType, .doc)
            expect.fulfill()
        } onError: { error in
            XCTFail("copy to space failed \(error)")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testCopyToWiki() {
        class NetworkAPI: MockWikiNetworkAPI {
            static var copyNode: WikiServerNode {
                WikiServerNode(meta: Util.mockNode(token: "COPY_TOKEN", hasChild: false, spaceID: "TARGET_TOKEN"),
                                          sortID: 10,
                                          parent: "TARGET_TOKEN")
            }
            override func copyWikiNode(sourceMeta: WikiMeta,
                                       objType: DocsType,
                                       targetMeta: WikiMeta,
                                       title: String,
                                       synergyUUID: String?) -> Single<(WikiServerNode, URL)> {
                XCTAssertEqual(sourceMeta, WikiMeta(wikiToken: "MOCK_TOKEN", spaceID: "MOCK_SPACE"))
                XCTAssertEqual(objType, .doc)
                XCTAssertEqual(targetMeta, WikiMeta(wikiToken: "TARGET_TOKEN", spaceID: "TARGET_SPACE"))
                XCTAssertEqual(synergyUUID, "MOCK_UUID")
                return .just((Self.copyNode, URL(string: "https://www.feishu.cn/wiki")!))
            }
        }
        let handler = Handler(networkAPI: NetworkAPI(), synergyUUID: "MOCK_UUID")
        let meta = Util.mockNode(token: "MOCK_TOKEN", hasChild: false, spaceID: "MOCK_SPACE")
        let context = Context(meta: meta)
        let expect = expectation(description: #function)
        let wikiLocation = WikiPickerLocation(wikiToken: "TARGET_TOKEN",
                                              nodeName: "TARGET_NAME",
                                              spaceID: "TARGET_SPACE",
                                              spaceName: "SPACE_NAME",
                                              isMylibrary: false)
        let location = WorkspacePickerLocation.wikiNode(location: wikiLocation)
        handler.confirmCopyTo(location: location,
                              context: context,
                              picker: UIViewController())
        .subscribe { createResponse in
            XCTAssertEqual(createResponse.location, location)
            XCTAssertEqual(createResponse.node, .wiki(node: NetworkAPI.copyNode, url: URL(string: "https://www.feishu.cn/wiki")!))
            XCTAssertEqual(createResponse.statistic.pageToken, "COPY_TOKEN")
            XCTAssertEqual(createResponse.statistic.objToken, "COPY_TOKEN")
            XCTAssertEqual(createResponse.statistic.objType, .doc)
            expect.fulfill()
        } onError: { error in
            XCTFail("copy to space failed \(error)")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testCopyToCurrentLocationWithParent() {
        class NetworkAPI: MockWikiNetworkAPI {
            static var copyNode: WikiServerNode {
                WikiServerNode(meta: Util.mockNode(token: "COPY_TOKEN", hasChild: false, spaceID: "MOCK_SPACE"),
                                          sortID: 10,
                                          parent: "TARGET_TOKEN")
            }
            override func copyWikiNode(sourceMeta: WikiMeta,
                                       objType: DocsType,
                                       targetMeta: WikiMeta,
                                       title: String,
                                       synergyUUID: String?) -> Single<(WikiServerNode, URL)> {
                XCTAssertEqual(targetMeta, WikiMeta(wikiToken: "PARENT_TOKEN", spaceID: "MOCK_SPACE"))
                return .just((Self.copyNode, URL(string: "https://www.feishu.cn/wiki")!))
            }
        }
        let handler = Handler(networkAPI: NetworkAPI(), synergyUUID: "MOCK_UUID")
        let meta = Util.mockNode(token: "MOCK_TOKEN", hasChild: false, spaceID: "MOCK_SPACE")
        let context = Context(meta: meta, parentToken: "PARENT_TOKEN")
        let expect = expectation(description: #function)
        handler.confirmCopyTo(location: .currentLocation, context: context, picker: UIViewController())
        .subscribe { createResponse in
            XCTAssertEqual(createResponse.location,
                           .wikiNode(location: WikiPickerLocation(wikiToken: "PARENT_TOKEN", nodeName: "", spaceID: "MOCK_SPACE", spaceName: "", isMylibrary: false)))
            expect.fulfill()
        } onError: { error in
            XCTFail("copy to wiki current location failed \(error)")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testCopyToCurrentLocationWithoutParent() {
        class NetworkAPI: MockWikiNetworkAPI {
            static var copyNode: WikiServerNode {
                WikiServerNode(meta: Util.mockNode(token: "COPY_TOKEN", hasChild: false, spaceID: "MOCK_SPACE"),
                                          sortID: 10,
                                          parent: "TARGET_TOKEN")
            }
            override func copyWikiNode(sourceMeta: WikiMeta,
                                       objType: DocsType,
                                       targetMeta: WikiMeta,
                                       title: String,
                                       synergyUUID: String?) -> Single<(WikiServerNode, URL)> {
                XCTAssertEqual(targetMeta, WikiMeta(wikiToken: "PARENT_TOKEN", spaceID: "MOCK_SPACE"))
                return .just((Self.copyNode, URL(string: "https://www.feishu.cn/wiki")!))
            }

            static var currentNode: WikiServerNode {
                WikiServerNode(meta: Util.mockNode(token: "MOCK_TOKEN", hasChild: true, spaceID: "MOCK_SPACE"),
                               sortID: 10,
                               parent: "PARENT_TOKEN")
            }
            override func getNodeMetaInfo(wikiToken: String) -> Single<WikiServerNode> {
                XCTAssertEqual(wikiToken, "MOCK_TOKEN")
                return .just(Self.currentNode)
            }
        }
        let handler = Handler(networkAPI: NetworkAPI(), synergyUUID: nil)
        let meta = Util.mockNode(token: "MOCK_TOKEN", hasChild: false, spaceID: "MOCK_SPACE")
        let context = Context(meta: meta)
        let expect = expectation(description: #function)
        handler.confirmCopyTo(location: .currentLocation, context: context, picker: UIViewController())
        .subscribe { createResponse in
            XCTAssertEqual(createResponse.location,
                           .wikiNode(location: WikiPickerLocation(wikiToken: "PARENT_TOKEN", nodeName: "", spaceID: "MOCK_SPACE", spaceName: "", isMylibrary: false)))
            expect.fulfill()
        } onError: { error in
            XCTFail("copy to wiki current location failed \(error)")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    // MARK: - Shortcut To
    func testShortcutToSpace() {
        class NetworkAPI: MockWikiNetworkAPI {
            override func shortcutWikiToSpace(objToken: String, objType: DocsType, folderToken: String) -> Single<(String, URL)> {
                XCTAssertEqual(objToken, "MOCK_TOKEN")
                XCTAssertEqual(objType, .doc)
                XCTAssertEqual(folderToken, "FOLDER_TOKEN")
                return .just(("FOLDER_TOKEN", URL(string: "https://www.feishu.cn/folder")!))
            }
        }
        let handler = Handler(networkAPI: NetworkAPI(), synergyUUID: nil)
        let context = Context(meta: Util.mockNode(token: "MOCK_TOKEN", hasChild: false, spaceID: "MOCK_SPACE"))
        let expect = expectation(description: #function)
        let folderType = FolderType(ownerType: singleContainerOwnerTypeValue, shareVersion: nil, isShared: nil)
        let spaceLocation = SpaceFolderPickerLocation(folderToken: "FOLDER_TOKEN",
                                                      folderType: folderType,
                                                      isExternal: false,
                                                      canCreateSubNode: true,
                                                      targetModule: .personal,
                                                      targetFolderType: .folder)
        let location = WorkspacePickerLocation.folder(location: spaceLocation)
        handler.confirmShortcutTo(location: location, context: context)
        .subscribe { createResponse in
            XCTAssertEqual(createResponse.location, location)
            XCTAssertEqual(createResponse.node, .space(url: URL(string: "https://www.feishu.cn/folder")!))
            XCTAssertEqual(createResponse.statistic.pageToken, "FOLDER_TOKEN")
            XCTAssertEqual(createResponse.statistic.objToken, "MOCK_TOKEN")
            XCTAssertEqual(createResponse.statistic.objType, .doc)
            expect.fulfill()
        } onError: { error in
            XCTFail("copy to space failed \(error)")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testShortcutToMySpace() {
        class NetworkAPI: MockWikiNetworkAPI {
            override func shortcutWikiToSpace(objToken: String, objType: DocsType, folderToken: String) -> Single<(String, URL)> {
                XCTAssertEqual(objToken, "MOCK_TOKEN")
                XCTAssertEqual(objType, .doc)
                XCTAssertEqual(folderToken, "")
                return .just(("FOLDER_TOKEN", URL(string: "https://www.feishu.cn/folder")!))
            }
        }
        let handler = Handler(networkAPI: NetworkAPI(), synergyUUID: nil)
        let context = Context(meta: Util.mockNode(token: "MOCK_TOKEN", hasChild: false, spaceID: "MOCK_SPACE"))
        let expect = expectation(description: #function)
        let folderType = FolderType(ownerType: singleContainerOwnerTypeValue, shareVersion: nil, isShared: nil)
        let spaceLocation = SpaceFolderPickerLocation(folderToken: "",
                                                      folderType: folderType,
                                                      isExternal: false,
                                                      canCreateSubNode: true,
                                                      targetModule: .personal,
                                                      targetFolderType: .folder)
        let location = WorkspacePickerLocation.folder(location: spaceLocation)
        handler.confirmShortcutTo(location: location, context: context)
        .subscribe { createResponse in
            XCTAssertEqual(createResponse.location, location)
            XCTAssertEqual(createResponse.node, .space(url: DocsUrlUtil.mySpaceURL))
            XCTAssertEqual(createResponse.url, DocsUrlUtil.mySpaceURL)
            XCTAssertEqual(createResponse.statistic.pageToken, "FOLDER_TOKEN")
            XCTAssertEqual(createResponse.statistic.objToken, "MOCK_TOKEN")
            XCTAssertEqual(createResponse.statistic.objType, .doc)
            expect.fulfill()
        } onError: { error in
            XCTFail("copy to space failed \(error)")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testShortcutToWiki() {
        class NetworkAPI: MockWikiNetworkAPI {
            static var shortcutNode: WikiServerNode {
                WikiServerNode(meta: Util.mockShortcutNode(token: "SHORTCUT_TOKEN",
                                                           spaceID: "TARGET_SPACE",
                                                           hasChild: false,
                                                           originWikiToken: "ORIGIN_TOKEN",
                                                           originSpaceID: "ORIGIN_SPACE"), sortID: 10, parent: "PARENT_TOKEN")
            }
            override func createShortcut(spaceID: String, parentWikiToken: String, originWikiToken: String, title: String?, synergyUUID: String?) -> Single<WikiServerNode> {
                XCTAssertEqual(spaceID, "TARGET_SPACE")
                XCTAssertEqual(parentWikiToken, "PARENT_TOKEN")
                XCTAssertEqual(originWikiToken, "MOCK_TOKEN")
                XCTAssertEqual(title, "MOCK_TOKEN")
                XCTAssertEqual(synergyUUID, "MOCK_UUID")
                return .just(Self.shortcutNode)
            }
        }
        let handler = Handler(networkAPI: NetworkAPI(), synergyUUID: "MOCK_UUID")
        let context = Context(meta: Util.mockNode(token: "MOCK_TOKEN", hasChild: false, spaceID: "MOCK_SPACE"))
        let expect = expectation(description: #function)
        let wikiLocation = WikiPickerLocation(wikiToken: "PARENT_TOKEN",
                                              nodeName: "PARENT_NAME",
                                              spaceID: "TARGET_SPACE",
                                              spaceName: "MOCK_SPACE",
                                              isMylibrary: false)
        let location = WorkspacePickerLocation.wikiNode(location: wikiLocation)
        handler.confirmShortcutTo(location: location, context: context)
        .subscribe { createResponse in
            XCTAssertEqual(createResponse.location, location)
            let url = DocsUrlUtil.url(type: .wiki, token: "SHORTCUT_TOKEN")
            XCTAssertEqual(createResponse.node, .wiki(node: NetworkAPI.shortcutNode,
                                                      url: url))
            XCTAssertEqual(createResponse.url, url)
            XCTAssertEqual(createResponse.statistic.pageToken, "SHORTCUT_TOKEN")
            XCTAssertEqual(createResponse.statistic.objToken, "SHORTCUT_TOKEN")
            XCTAssertEqual(createResponse.statistic.objType, .doc)
            expect.fulfill()
        } onError: { error in
            XCTFail("copy to space failed \(error)")
            expect.fulfill()
        }
        .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    // MARK: - Create Node
    func testCreateOnNormalNode() {
        class NetworkAPI: MockWikiNetworkAPI {
            static var newNode: WikiServerNode {
                Util.ServerTestTree.leaf3_1
            }
            override func createNode(spaceID: String, parentWikiToken: String, template: TemplateModel? = nil, objType: DocsType, synergyUUID: String?) -> Single<WikiServerNode> {
                XCTAssertEqual(spaceID, "MOCK_SPACE")
                XCTAssertEqual(parentWikiToken, "MOCK_TOKEN")
                XCTAssertEqual(objType, .doc)
                XCTAssertEqual(synergyUUID, "MOCK_UUID")
                return .just(Self.newNode)
            }
        }

        let meta = Util.mockNode(token: "MOCK_TOKEN", hasChild: false, spaceID: "MOCK_SPACE")
        let handler = Handler(networkAPI: NetworkAPI(), synergyUUID: "MOCK_UUID")
        let expect = expectation(description: #function)
        handler.confirmCreate(meta: meta, type: .doc)
            .subscribe { newNode, originNode in
                XCTAssertNil(originNode)
                XCTAssertEqual(newNode, NetworkAPI.newNode)
                expect.fulfill()
            } onError: { error in
                XCTFail("create wiki node failed \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testCreateOnShortcutNode() {
        class NetworkAPI: MockWikiNetworkAPI {
            static var newNode: WikiServerNode {
                Util.ServerTestTree.leaf3_1
            }
            override func createNode(spaceID: String, parentWikiToken: String, template: TemplateModel? = nil, objType: DocsType, synergyUUID: String?) -> Single<WikiServerNode> {
                XCTAssertEqual(spaceID, "MOCK_SPACE")
                XCTAssertEqual(parentWikiToken, "MOCK_TOKEN")
                XCTAssertEqual(objType, .doc)
                XCTAssertEqual(synergyUUID, "MOCK_UUID")
                return .just(Self.newNode)
            }

            static var originNode: WikiServerNode {
                Util.ServerTestTree.leaf3_3_1
            }
            override func getNodeMetaInfo(wikiToken: String) -> Single<WikiServerNode> {
                XCTAssertEqual(wikiToken, "MOCK_TOKEN")
                return .just(Self.originNode)
            }
        }

        let meta = Util.mockShortcutNode(token: "SHORTCUT_TOKEN",
                                         spaceID: "SHORTCUT_SPACE",
                                         hasChild: false,
                                         originWikiToken: "MOCK_TOKEN",
                                         originSpaceID: "MOCK_SPACE")
        let handler = Handler(networkAPI: NetworkAPI(), synergyUUID: "MOCK_UUID")
        let expect = expectation(description: #function)
        handler.confirmCreate(meta: meta, type: .doc)
            .subscribe { newNode, originNode in
                XCTAssertEqual(originNode, NetworkAPI.originNode)
                XCTAssertEqual(newNode, NetworkAPI.newNode)
                expect.fulfill()
            } onError: { error in
                XCTFail("create wiki node failed \(error)")
                expect.fulfill()
            }
            .disposed(by: bag)
        waitForExpectations(timeout: 1)
    }

    func testCreateItems() {
        let config = Handler.CreateConfig(docxEnable: true,
                                          mindnoteEnable: true,
                                          bitableEnable: true,
                                          createDocEnable: true)
        var expectType = Handler.CreateType.document(type: .docX)
        var items = Handler.createItems(enableChecker: { type in
            guard case .document = type else { return false }
            return true
        }, config: config, completion: { type in
            XCTAssertEqual(type, expectType)
        })
        XCTAssertEqual(items.count, 7)
        guard items.count == 7 else {
            return
        }
        XCTAssertEqual(items.map(\.enable), [true, true, true, true, true, false, false])
        var expectTypes: [Handler.CreateType] = [
            .document(type: .docX),
            .document(type: .sheet),
            .document(type: .mindnote),
            .document(type: .bitable),
            .document(type: .doc),
            .upload(isImage: true),
            .upload(isImage: false)
        ]
        for index in 0..<7 {
            expectType = expectTypes[index]
            items[index].action()
        }

        let docxOnlyConfig = Handler.CreateConfig(docxEnable: true,
                                                  mindnoteEnable: true,
                                                  bitableEnable: true,
                                                  createDocEnable: false)
        expectType = Handler.CreateType.document(type: .docX)
        items = Handler.createItems(enableChecker: { type in
            guard case .document = type else { return false }
            return true
        }, config: docxOnlyConfig, completion: { type in
            XCTAssertEqual(type, expectType)
        })
        XCTAssertEqual(items.count, 6)
        guard items.count == 6 else {
            return
        }
        XCTAssertEqual(items.map(\.enable), [true, true, true, true, false, false])
        expectTypes = [
            .document(type: .docX),
            .document(type: .sheet),
            .document(type: .mindnote),
            .document(type: .bitable),
            .upload(isImage: true),
            .upload(isImage: false)
        ]
        for index in 0..<6 {
            expectType = expectTypes[index]
            items[index].action()
        }

        let disableConfig = Handler.CreateConfig(docxEnable: false,
                                                 mindnoteEnable: false,
                                                 bitableEnable: false,
                                                 createDocEnable: false)
        items = Handler.createItems(enableChecker: { type in
            guard case .upload = type else { return false }
            return true
        }, config: disableConfig, completion: { type in
            XCTAssertEqual(type, expectType)
        })
        XCTAssertEqual(items.count, 4)
        guard items.count == 4 else {
            return
        }
        XCTAssertEqual(items.map(\.enable), [false, false, true, true])
        expectTypes = [
            .document(type: .doc),
            .document(type: .sheet),
            .upload(isImage: true),
            .upload(isImage: false)
        ]
        for index in 0..<4 {
            expectType = expectTypes[index]
            items[index].action()
        }
    }
}
