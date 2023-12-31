//
//  WikiTreeNetworkAPITests.swift
//  SKWikiV2_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/7/14.
//

import XCTest
@testable import SKWorkspace
import SKCommon
import SKFoundation
import OHHTTPStubs
import SwiftyJSON
import RxSwift
import RxBlocking

class WikiTreeNetworkAPITests: XCTestCase {
    typealias NodeChildren = WikiTreeRelation.NodeChildren
    private var bag = DisposeBag()
    override func setUp() {
        // 没有设置baseURL，网路请求会中assert
        super.setUp()
        bag = DisposeBag()
        AssertionConfigForTest.disableAssertWhenTesting()
    }
    override func tearDown() {
        super.tearDown()
        HTTPStubs.removeAllStubs()
        AssertionConfigForTest.reset()
    }

    func testParseTree() {
        do {
            let data = try Self.loadJSON(path: TreeJSON.originData)["data"]
            let treeData = try WikiNetworkManager.parseTreeInfo(data: data,
                                                                spaceID: TreeJSON.mockSpaceID,
                                                                needPermission: true)
            XCTAssertEqual(treeData.mainRootToken, "wikcnTK56fS7m3crQKB3TSTjmXf")
            XCTAssertEqual(treeData.metaStorage.count, 7)
            XCTAssertEqual(treeData.relation.nodeParentMap, [
                "wikcn3JlZEN2bLAzbADnB3jsTwe": "wikcnO6c4klk6OfD7mcSSalLMGn",
                "wikcn7p3LmCVqJoMIO7Fodbmvyf": "wikcnTK56fS7m3crQKB3TSTjmXf",
                "wikcn8EGUj8SG3p03qF7q5v7Kbd": "wikcnO6c4klk6OfD7mcSSalLMGn",
                "wikcnO6c4klk6OfD7mcSSalLMGn": "wikcnTK56fS7m3crQKB3TSTjmXf",
                "wikcnTK56fS7m3crQKB3TSTjmXf": "",
                "wikcncE1zjxxr5xVztMXQdnuzRd": "wikcnTK56fS7m3crQKB3TSTjmXf",
                "wikcncVn9jI5DxaKHLroWfwV3Id": "wikcnTK56fS7m3crQKB3TSTjmXf"
            ])
            XCTAssertEqual(treeData.relation.nodeChildrenMap, [
                "wikcn3JlZEN2bLAzbADnB3jsTwe": [],
                "wikcnO6c4klk6OfD7mcSSalLMGn": [
                    NodeChildren(wikiToken: "wikcn3JlZEN2bLAzbADnB3jsTwe", sortID: 4503600701112319),
                    NodeChildren(wikiToken: "wikcn8EGUj8SG3p03qF7q5v7Kbd", sortID: 4503601774854143)
                ],
                "wikcnTK56fS7m3crQKB3TSTjmXf": [
                    NodeChildren(wikiToken: "wikcncE1zjxxr5xVztMXQdnuzRd", sortID: 4503600701112319),
                    NodeChildren(wikiToken: "wikcnO6c4klk6OfD7mcSSalLMGn", sortID: 4503601774854143),
                    NodeChildren(wikiToken: "wikcn7p3LmCVqJoMIO7Fodbmvyf", sortID: 4503602848595967),
                    NodeChildren(wikiToken: "wikcncVn9jI5DxaKHLroWfwV3Id", sortID: 4503603922337791)
                ]
            ])
        } catch {
            XCTFail("parse tree failed, \(error)")
        }
    }
    
    func testParseEmptyTeee() {
        do {
            let data = try Self.loadJSON(path: TreeJSON.emptyTreeData)["data"]
            let treeData = try WikiNetworkManager.parseTreeInfo(data: data,
                                                                spaceID: "7135715005953130524",
                                                                needPermission: true)
            XCTAssertEqual(treeData.mainRootToken, "wikcnCkY243fYXWhITe3AEi0wMe")
            XCTAssertEqual(treeData.metaStorage.count, 1)
            XCTAssertEqual(treeData.relation.nodeParentMap, [
                "wikcnCkY243fYXWhITe3AEi0wMe": ""
            ])
            XCTAssertEqual(treeData.relation.nodeChildrenMap, [
                "wikcnCkY243fYXWhITe3AEi0wMe": []
            ])
        } catch {
            XCTFail("parse tree failed, \(error)")
        }
    }
    
    func testParseFreeTree() {
        do {
            let data = try Self.loadJSON(path: TreeJSON.freeTreeData)["data"]
            let treeData = try WikiNetworkManager.parseTreeInfo(data: data,
                                                                spaceID: TreeJSON.mockSpaceID,
                                                                needPermission: true)
            let sharedRootToken = WikiTreeNodeMeta.sharedRootToken
            XCTAssertEqual(treeData.mainRootToken, "wikbcyXiHqYqqQTmYM2K4zAhgGf")
            XCTAssertNotNil(treeData.metaStorage[sharedRootToken])
            XCTAssertNotNil(treeData.metaStorage[treeData.mainRootToken])
            XCTAssertEqual(treeData.relation.nodeChildrenMap, [
                "wikbcyXiHqYqqQTmYM2K4zAhgGf": [],
                "wikbcxR2bNqfBhrB0kGzOsZpkTe": [NodeChildren(wikiToken: "wikbcawvDaE5UoaQK68mdxwy5Te", sortID: 4503600701112319)],
                sharedRootToken: [NodeChildren(wikiToken: "wikbcxR2bNqfBhrB0kGzOsZpkTe", sortID: 4503601774854143.0)]
            ])
        } catch {
            XCTFail("parse tree failed, \(error)")
        }
    }

    func testParseChildren() {
        do {
            let data = try Self.loadJSON(path: TreeJSON.AddNode.WithoutCache.getChildren)["data"]
            let (children, nodes) = try WikiNetworkManager.parseGetChild(data: data, wikiToken: "wikcn8EGUj8SG3p03qF7q5v7Kbd")
            XCTAssertEqual(children, [
                NodeChildren(wikiToken: "wikcnXDzzMnMbnZBpQwUFKByOlb", sortID: 4503600701112319),
                NodeChildren(wikiToken: "wikcnFtgrqncGhe1MN3rNfmNWCd", sortID: 4503601774854143),
                NodeChildren(wikiToken: "wikcnHgsK41DZHcWakOXCcSwC7c", sortID: 4503602848595967),
                NodeChildren(wikiToken: "wikcngmrw5o17xIlo0Ky93vBKkc", sortID: 4503603922337791)
            ])
            XCTAssertEqual(nodes.count, 4)
        } catch {
            XCTFail("parse get child failed, \(error)")
        }
    }

    func testParseFavoriteList() {
        do {
            let data = try Self.loadJSON(path: TreeJSON.getFavoriteInfo)["data"]
            let (relation, metas) = try WikiNetworkManager.parseFavoriteList(data: data)
            XCTAssertEqual(relation.nodeChildrenMap[WikiTreeNodeMeta.favoriteRootToken], [
                NodeChildren(wikiToken: "wikcnQGEFlVj6KlCI91WD2o8ZIe", sortID: 0),
                NodeChildren(wikiToken: "wikcn0h0AwQwmMCtOwqhTEGvwGc", sortID: 10)
            ])
            XCTAssertEqual(relation.nodeParentMap, [
                "wikcn0h0AwQwmMCtOwqhTEGvwGc": "wikcnQGEFlVj6KlCI91WD2o8ZIe",
                "wikcnQGEFlVj6KlCI91WD2o8ZIe": "wikcnDCUb0n8INnliQBj5pGPVbd"
            ])
            XCTAssertEqual(metas.count, 2)
        } catch {
            XCTFail("parse get child failed, \(error)")
        }
    }

    enum LoadTreeMapError: Error {
        case fileNotFound
    }

    static func loadJSON(path: PathRepresentable) throws -> JSON {
        guard let path = Bundle(for: WikiTreeNetworkAPITests.self)
            .url(forResource: path.fullPath, withExtension: nil) else {
            throw LoadTreeMapError.fileNotFound
        }
        let data = try Data(contentsOf: path)
        let json = try JSON(data: data)
        return json
    }
}
