//
//  WikiSpaceTests.swift
//  SKWikiV2-Unit-Tests
//
//  Created by Weston Wu on 2023/3/2.
//

import XCTest
@testable import SKWorkspace
import SKFoundation
import SKCommon
import SKResource
import SQLite

final class WikiSpaceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        AssertionConfigForTest.disableAssertWhenTesting()
    }
    override func tearDown() {
        super.tearDown()
        AssertionConfigForTest.reset()
    }

    static func mockCover(originPath: String = "MOCK_ORIGIN_PATH",
                          thumbnailPath: String = "MOCK_THUMBNAIL_PATH",
                          name: String = "MOCK_NAME",
                          isDarkStyle: Bool = false,
                          rawColor: String = "#000000") -> WikiSpace.Cover {
        WikiSpace.Cover(originPath: originPath,
                        thumbnailPath: thumbnailPath,
                        name: name,
                        isDarkStyle: isDarkStyle,
                        rawColor: rawColor)
    }

    static func mockSpace(spaceID: String = "MOCK_SPACE_ID",
                          spaceName: String = "MOCK_SPACE_NAME",
                          rootToken: String = "MOCK_ROOT_TOKEN",
                          tenantID: String? = nil,
                          description: String = "MOCK_DESCRIPTION",
                          isStar: Bool? = nil,
                          cover: WikiSpace.Cover = mockCover(),
                          lastBrowseTime: TimeInterval? = nil,
                          wikiScope: Int? = nil,
                          ownerPermType: Int? = nil,
                          migrateStatus: WikiSpace.MigrateStatus? = nil,
                          openSharing: Int? = nil,
                          spaceType: WikiSpace.SpaceType? = nil,
                          createUID: String? = nil,
                          displayTag: WikiSpace.DisplayTag? = nil) -> WikiSpace {
        WikiSpace(spaceId: spaceID,
                  spaceName: spaceName,
                  rootToken: rootToken,
                  tenantID: tenantID,
                  wikiDescription: description,
                  isStar: isStar,
                  cover: cover,
                  lastBrowseTime: lastBrowseTime,
                  wikiScope: wikiScope,
                  ownerPermType: ownerPermType,
                  migrateStatus: migrateStatus,
                  openSharing: openSharing,
                  spaceType: spaceType,
                  createUID: createUID,
                  displayTag: displayTag)
    }

    func testIsPublic() {
        var space = Self.mockSpace(wikiScope: 1)
        XCTAssertTrue(space.isPublic)
        space = Self.mockSpace()
        XCTAssertFalse(space.isPublic)
        space = Self.mockSpace(wikiScope: 2)
        XCTAssertFalse(space.isPublic)
    }

    func testSharingType() {
        var space = Self.mockSpace()
        XCTAssertEqual(space.sharingType, .none)
        XCTAssertFalse(space.isOpenSharing)

        space = Self.mockSpace(openSharing: 0)
        XCTAssertEqual(space.sharingType, .notSetting)
        XCTAssertFalse(space.isOpenSharing)

        space = Self.mockSpace(openSharing: 1)
        XCTAssertEqual(space.sharingType, .open)
        XCTAssertTrue(space.isOpenSharing)

        space = Self.mockSpace(openSharing: 2)
        XCTAssertEqual(space.sharingType, .close)
        XCTAssertFalse(space.isOpenSharing)

        space = Self.mockSpace(openSharing: 3)
        XCTAssertEqual(space.sharingType, .none)
        XCTAssertFalse(space.isOpenSharing)

        space = Self.mockSpace(openSharing: 4)
        XCTAssertEqual(space.sharingType, .none)
        XCTAssertFalse(space.isOpenSharing)
    }

    func testMyLibrary() {
        let mockUserID = "mock-owner-id"
        let originUserInfo = User.current.info
        let mockUserInfo = UserInfo(mockUserID)
        User.current.info = mockUserInfo
        defer {
            User.current.info = originUserInfo
        }

        var space = Self.mockSpace()
        XCTAssertFalse(space.isLibrary)
        space = Self.mockSpace(spaceType: .team)
        XCTAssertFalse(space.isLibrary)
        space = Self.mockSpace(spaceType: .personal)
        XCTAssertFalse(space.isLibrary)
        space = Self.mockSpace(spaceType: .library)
        XCTAssertTrue(space.isLibrary)

        space = Self.mockSpace(spaceType: .library, createUID: mockUserID)
        XCTAssertTrue(space.isLibraryOwner)
        XCTAssertEqual(space.displayTitle, BundleI18n.SKResource.LarkCCM_CM_MyLib_Menu)
        space = Self.mockSpace(spaceType: .team, createUID: mockUserID)
        XCTAssertFalse(space.isLibraryOwner)
        XCTAssertEqual(space.displayTitle, space.spaceName)
        space = Self.mockSpace(spaceType: .library)
        XCTAssertFalse(space.isLibraryOwner)
        XCTAssertEqual(space.displayTitle, space.spaceName)
    }

    func testComparable() {
        var lhs = Self.mockSpace(lastBrowseTime: 100)
        var rhs = Self.mockSpace(lastBrowseTime: 10)
        XCTAssertTrue(rhs < lhs)
        lhs = Self.mockSpace(spaceName: "L-Name", lastBrowseTime: 100)
        rhs = Self.mockSpace(spaceName: "R-Name", lastBrowseTime: 100)
        XCTAssertEqual(lhs < rhs, lhs.spaceName > rhs.spaceName)

        lhs = Self.mockSpace()
        rhs = Self.mockSpace()
        XCTAssertEqual(lhs, rhs)

        lhs = Self.mockSpace(spaceID: "L-SpaceID")
        rhs = Self.mockSpace(spaceID: "R-SpaceID")
        XCTAssertNotEqual(lhs, rhs)
    }

    func testDisplayProps() {
        var space = Self.mockSpace()
        XCTAssertEqual(space.displayDescription, space.wikiDescription)
        space = Self.mockSpace(description: "")
        XCTAssertEqual(space.displayDescription, BundleI18n.SKResource.Doc_Wiki_Home_DescriptionEmptyText)

        space = Self.mockSpace(isStar: nil)
        XCTAssertFalse(space.displayIsStar)
        space = Self.mockSpace(isStar: false)
        XCTAssertFalse(space.displayIsStar)
        space = Self.mockSpace(isStar: true)
        XCTAssertTrue(space.displayIsStar)
    }


    func testDisplayTag() {
        var tag = WikiSpace.DisplayTag(tagType: 1, tagValue: "")
        XCTAssertTrue(tag.isPublicType)
        tag = WikiSpace.DisplayTag(tagType: 5, tagValue: "")
        XCTAssertTrue(tag.isPublicType)
        tag = WikiSpace.DisplayTag(tagType: 2, tagValue: "")
        XCTAssertFalse(tag.isPublicType)
        tag = WikiSpace.DisplayTag(tagType: 3, tagValue: "")
        XCTAssertFalse(tag.isPublicType)
        tag = WikiSpace.DisplayTag(tagType: 0, tagValue: "")
        XCTAssertFalse(tag.isPublicType)

        let mockTenantID = "mock-tenant-id"
        var space = Self.mockSpace(tenantID: mockTenantID)
        XCTAssertNil(space.getDisplayTag(preferTagFromServer: false, currentTenantID: mockTenantID))
        XCTAssertNil(space.getDisplayTag(preferTagFromServer: false, currentTenantID: "other-tenant-id"))
        XCTAssertNil(space.getDisplayTag(preferTagFromServer: true, currentTenantID: mockTenantID))
        XCTAssertNil(space.getDisplayTag(preferTagFromServer: true, currentTenantID: "other-tenant-id"))

        space = Self.mockSpace(tenantID: mockTenantID, openSharing: 1)
        XCTAssertEqual(space.getDisplayTag(preferTagFromServer: false, currentTenantID: mockTenantID),
                       BundleI18n.SKResource.LarkCCM_Wiki_WebAccess_Tag)
        XCTAssertNil(space.getDisplayTag(preferTagFromServer: false, currentTenantID: "other-tenant-id"))
        XCTAssertEqual(space.getDisplayTag(preferTagFromServer: true, currentTenantID: mockTenantID),
                       BundleI18n.SKResource.LarkCCM_Wiki_WebAccess_Tag)
        XCTAssertNil(space.getDisplayTag(preferTagFromServer: true, currentTenantID: "other-tenant-id"))

        space = Self.mockSpace(tenantID: mockTenantID, wikiScope: 1)
        XCTAssertEqual(space.getDisplayTag(preferTagFromServer: false, currentTenantID: mockTenantID),
                       BundleI18n.SKResource.LarkCCM_Wiki_OrgAccess_Tag)
        XCTAssertNil(space.getDisplayTag(preferTagFromServer: false, currentTenantID: "other-tenant-id"))
        XCTAssertEqual(space.getDisplayTag(preferTagFromServer: true, currentTenantID: mockTenantID),
                       BundleI18n.SKResource.LarkCCM_Wiki_OrgAccess_Tag)
        XCTAssertNil(space.getDisplayTag(preferTagFromServer: true, currentTenantID: "other-tenant-id"))

        space = Self.mockSpace()
        XCTAssertNil(space.getDisplayTag(preferTagFromServer: true, currentTenantID: nil))

        tag = WikiSpace.DisplayTag(tagType: 1, tagValue: "mock-tag-value")
        space = Self.mockSpace(tenantID: mockTenantID, displayTag: tag)
        XCTAssertNil(space.getDisplayTag(preferTagFromServer: true, currentTenantID: "other-tenant-id"))
        XCTAssertEqual(space.getDisplayTag(preferTagFromServer: true, currentTenantID: mockTenantID),
                       tag.tagValue)

        tag = WikiSpace.DisplayTag(tagType: 2, tagValue: "mock-tag-value")
        space = Self.mockSpace(tenantID: mockTenantID, displayTag: tag)
        XCTAssertEqual(space.getDisplayTag(preferTagFromServer: true, currentTenantID: "other-tenant-id"),
                       tag.tagValue)
    }

    func testDBReadWrite() {
        do {
            let connection = try Connection()
            let table = WikiSpaceTable(connection: connection)
            try table.setup()
            let originCover = Self.mockCover(originPath: "MOCK_ORIGIN_PATH",
                                             thumbnailPath: "MOCK_THUMBNAIL_PATH",
                                             name: "MOCK_COVER_NAME",
                                             isDarkStyle: true,
                                             rawColor: "MOCK_RAW_COLOR")
            let originTag = WikiSpace.DisplayTag(tagType: 1, tagValue: "MOCK_TAG_VALUE")
            let originSpace = Self.mockSpace(spaceID: "MOCK_SPACE_ID",
                                             spaceName: "MOCK_SPACE_NAME",
                                             tenantID: "MOCK_TENANT_ID",
                                             description: "MOCK_DESCRIPTION",
                                             isStar: true,
                                             cover: originCover,
                                             lastBrowseTime: Double.random(in: 0..<100),
                                             wikiScope: 1,
                                             ownerPermType: 1,
                                             migrateStatus: .migrating,
                                             openSharing: 1,
                                             spaceType: .personal,
                                             createUID: "MOCK_CREATE_UID",
                                             displayTag: originTag)
            table.insert(space: originSpace)
            guard let space = table.getSpace(originSpace.spaceID) else {
                XCTFail("read from table failed")
                return
            }

            XCTAssertEqual(space.spaceID, originSpace.spaceID)
            XCTAssertEqual(space.spaceName, originSpace.spaceName)
            XCTAssertEqual(space.tenantID, originSpace.tenantID)
            XCTAssertEqual(space.wikiDescription, originSpace.wikiDescription)
            XCTAssertEqual(space.isStar, originSpace.isStar)
            XCTAssertEqual(space.lastBrowseTime, originSpace.lastBrowseTime)
            XCTAssertEqual(space.wikiScope, originSpace.wikiScope)
            // ownerPermType 目前没有存到 DB，固定为 0
            XCTAssertEqual(space.ownerPermType, 0)
            // XCTAssertEqual(space.ownerPermType, originSpace.ownerPermType)
            // migrateStatus 不写入 DB
            XCTAssertNil(space.migrateStatus)
            XCTAssertEqual(space.openSharing, originSpace.openSharing)
            XCTAssertEqual(space.spaceType, originSpace.spaceType)
            XCTAssertEqual(space.createUID, originSpace.createUID)

            XCTAssertEqual(space.displayTag?.tagValue, originTag.tagValue)
            XCTAssertEqual(space.displayTag?.tagType, originTag.tagType)

            XCTAssertEqual(space.cover.rawColor, originCover.rawColor)
            XCTAssertEqual(space.cover.thumbnailPath, originCover.thumbnailPath)
            XCTAssertEqual(space.cover.name, originCover.name)
            XCTAssertEqual(space.cover.isDarkStyle, originCover.isDarkStyle)
            XCTAssertEqual(space.cover.originPath, originCover.originPath)
        } catch {
            XCTFail("DB exec failed with error: \(error)")
        }
    }

    func testSpaceListDBReadWrite() {
        do {
            let connection = try Connection()
            let table = WikiSpaceTable(connection: connection)
            try table.setup()
            let originCover = Self.mockCover(originPath: "MOCK_ORIGIN_PATH",
                                             thumbnailPath: "MOCK_THUMBNAIL_PATH",
                                             name: "MOCK_COVER_NAME",
                                             isDarkStyle: true,
                                             rawColor: "MOCK_RAW_COLOR")
            let originTag = WikiSpace.DisplayTag(tagType: 1, tagValue: "MOCK_TAG_VALUE")
            let originSpace = Self.mockSpace(spaceID: "MOCK_SPACE_ID",
                                             spaceName: "MOCK_SPACE_NAME",
                                             tenantID: "MOCK_TENANT_ID",
                                             description: "MOCK_DESCRIPTION",
                                             isStar: true,
                                             cover: originCover,
                                             lastBrowseTime: Double.random(in: 0..<100),
                                             wikiScope: 1,
                                             ownerPermType: 1,
                                             migrateStatus: .migrating,
                                             openSharing: 1,
                                             spaceType: .personal,
                                             createUID: "MOCK_CREATE_UID",
                                             displayTag: originTag)
            table.insert(space: originSpace)
            guard let space = table.getSpace(originSpace.spaceID) else {
                XCTFail("read from table failed")
                return
            }

            XCTAssertEqual(space.spaceID, originSpace.spaceID)
            XCTAssertEqual(space.spaceName, originSpace.spaceName)
            XCTAssertEqual(space.tenantID, originSpace.tenantID)
            XCTAssertEqual(space.wikiDescription, originSpace.wikiDescription)
            XCTAssertEqual(space.isStar, originSpace.isStar)
            XCTAssertEqual(space.lastBrowseTime, originSpace.lastBrowseTime)
            XCTAssertEqual(space.wikiScope, originSpace.wikiScope)
            // ownerPermType 目前没有存到 DB，固定为 0
            XCTAssertEqual(space.ownerPermType, 0)
            // XCTAssertEqual(space.ownerPermType, originSpace.ownerPermType)
            // migrateStatus 不写入 DB
            XCTAssertNil(space.migrateStatus)
            XCTAssertEqual(space.openSharing, originSpace.openSharing)
            XCTAssertEqual(space.spaceType, originSpace.spaceType)
            XCTAssertEqual(space.createUID, originSpace.createUID)

            XCTAssertEqual(space.displayTag?.tagValue, originTag.tagValue)
            XCTAssertEqual(space.displayTag?.tagType, originTag.tagType)

            XCTAssertEqual(space.cover.rawColor, originCover.rawColor)
            XCTAssertEqual(space.cover.thumbnailPath, originCover.thumbnailPath)
            XCTAssertEqual(space.cover.name, originCover.name)
            XCTAssertEqual(space.cover.isDarkStyle, originCover.isDarkStyle)
            XCTAssertEqual(space.cover.originPath, originCover.originPath)
        } catch {
            XCTFail("DB exec failed with error: \(error)")
        }
    }
}
