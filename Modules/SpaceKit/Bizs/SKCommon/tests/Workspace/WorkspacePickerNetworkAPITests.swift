//
//  WorkspacePickerNetworkAPITests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by Weston Wu on 2022/10/11.
//

import Foundation
@testable import SKCommon
import SKFoundation
import SKResource
import XCTest
import SwiftyJSON
import OHHTTPStubs

final class WorkspacePickerNetworkAPITests: XCTestCase {

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }

    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    // MARK: StandardAPI
    func testParseList() {
        do {
            let data = try Self.loadJSON(name: .recentOperation)["data"]
            let result = WorkspacePickerStandardNetworkAPI.parseRecentList(data: data)
            XCTAssertEqual(result.map(\.displayTitle), [
                "wiki title 1",
                "space name 1",
                "wiki title 2",
                "space name 2"
            ])
            XCTAssertEqual(result.map(\.subTitle), [
                "space 1",
                nil,
                "space 2",
                "space name 1"
            ])
        } catch {
            XCTFail("load json failed with error: \(error)")
        }
    }

    func testParseNodeList() {
        do {
            let data = try Self.loadJSON(name: .recentOperation)["data"]
            let result = WorkspacePickerStandardNetworkAPI.parseNodeList(data: data)
            XCTAssertEqual(result, [
                .init(containerToken: "wiki_token_1", containerType: .wiki),
                .init(containerToken: "space_token_1", containerType: .space),
                .init(containerToken: "wiki_token_2", containerType: .wiki),
                .init(containerToken: "space_token_2", containerType: .space)
            ])
        } catch {
            XCTFail("load json failed with error: \(error)")
        }
    }

    func testParseWikiData() {
        do {
            let data = try Self.loadJSON(name: .recentOperation)["data"]
            let result = WorkspacePickerStandardNetworkAPI.parseWikiData(data: data)
            XCTAssertEqual(result.count, 2)
            let token1 = result["wiki_token_1"]
            XCTAssertNotNil(token1)
            XCTAssertEqual(token1?.wikiToken, "wiki_token_1")
            XCTAssertEqual(token1?.spaceID, "SPACE_ID_1")
            XCTAssertEqual(token1?.objToken, "wiki_obj_token_1")
            XCTAssertEqual(token1?.objType, .doc)
            XCTAssertEqual(token1?.title, "wiki title 1")
            XCTAssertEqual(token1?.spaceName, "space 1")

            XCTAssertEqual(token1?.displayTitle, "wiki title 1")
            XCTAssertEqual(token1?.subTitle, "space 1")


            let token2 = result["wiki_token_2"]
            XCTAssertNotNil(token2)
            XCTAssertEqual(token2?.wikiToken, "wiki_token_2")
            XCTAssertEqual(token2?.spaceID, "SPACE_ID_2")
            XCTAssertEqual(token2?.objToken, "wiki_obj_token_2")
            XCTAssertEqual(token2?.objType, .docX)
            XCTAssertEqual(token2?.title, "wiki title 2")
            XCTAssertEqual(token2?.spaceName, "space 2")

            let token3 = result["wiki_token_3"]
            XCTAssertNil(token3)
        } catch {
            XCTFail("load json failed with error: \(error)")
        }
    }

    func testParseSpaceData() {
        do {
            let data = try Self.loadJSON(name: .recentOperation)["data"]
            let result = WorkspacePickerStandardNetworkAPI.parseSpaceData(data: data)
            XCTAssertEqual(result.count, 2)
            let token1 = result["space_token_1"]
            XCTAssertNotNil(token1)
            XCTAssertEqual(token1?.folderToken, "space_token_1")
            XCTAssertEqual(token1?.folderType, .v2Common)
            XCTAssertEqual(token1?.name, "space name 1")
            XCTAssertNil(token1?.subTitle)
            XCTAssertTrue(token1?.extra?.isEmpty ?? true)

            XCTAssertEqual(token1?.displayTitle, "space name 1")
            XCTAssertNil(token1?.subTitle)


            let token2 = result["space_token_2"]
            XCTAssertNotNil(token2)
            XCTAssertEqual(token2?.folderToken, "space_token_2")
            XCTAssertEqual(token2?.folderType, .v2Shared)
            XCTAssertEqual(token2?.name, "space name 2")
            XCTAssertEqual(token2?.subTitle, "space name 1")
            XCTAssertEqual(token2?.extra?["is_share_folder"] as? Bool, true)
            XCTAssertEqual(token2?.extra?["is_external"] as? Bool, true)

            XCTAssertEqual(token2?.displayTitle, "space name 2")
            XCTAssertEqual(token2?.subTitle, "space name 1")
        } catch {
            XCTFail("load json failed with error: \(error)")
        }
    }

    // MARK: LegacyAPI
    func testParseRecentFolder() {
        do {
            let data = try Self.loadJSON(name: .recentFolder)["data"]
            let result = WorkspacePickerLegacyNetworkAPI.parseRecentFolders(data: data)
                .compactMap { entry -> WorkspacePickerSpaceEntry? in
                    guard case let .folder(folderEntry) = entry else {
                        return nil
                    }
                    return folderEntry
                }
            XCTAssertEqual(result.count, 3)
            XCTAssertEqual(result.map(\.folderToken), ["folder_token_1", "folder_token_3", "folder_token_2"])
            XCTAssertEqual(result.map(\.folderType), [.v2Shared, .v2Common, .v2Shared])
            XCTAssertEqual(result.map(\.name), ["folder name 1", "folder name 3", "folder name 2"])
            XCTAssertEqual(result.map(\.displayTitle), ["folder name 1", "folder name 3", "folder name 2"])
            XCTAssertEqual(result.map(\.subTitle), [
                BundleI18n.SKResource.Doc_List_LastUpdateTime(1665653664.fileSubTitleDateFormatter),
                BundleI18n.SKResource.Doc_List_LastUpdateTime(1665653636.fileSubTitleDateFormatter),
                BundleI18n.SKResource.Doc_List_LastUpdateTime(1665653623.fileSubTitleDateFormatter)
            ])
            XCTAssertEqual(result.map { $0.extra?["is_share_folder"] as? Bool }, [
                true,
                false,
                true
            ])
            XCTAssertEqual(result.map { $0.extra?["is_external"] as? Bool }, [
                true,
                false,
                false
            ])
        } catch {
            XCTFail("load json failed with error: \(error)")
        }
    }

    enum LoadJSONError: Error {
        case fileNotFound
    }

    enum JSONFile: String {
        case recentOperation = "recent_operation"
        case recentFolder = "recent_folder"
    }

    static func loadJSON(name: JSONFile) throws -> JSON {
        guard let path = Bundle(for: WorkspacePickerNetworkAPITests.self)
            .url(forResource: "JSON/workspace/\(name.rawValue).json", withExtension: nil) else {
            throw LoadJSONError.fileNotFound
        }
        let data = try Data(contentsOf: path)
        let json = try JSON(data: data)
        return json
    }
}
