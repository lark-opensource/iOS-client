//
//  SpaceListModifierTests.swift
//  SKSpace-Unit-Tests
//
//  Created by Weston Wu on 2022/3/22.
//

import XCTest
@testable import SKSpace
@testable import SKCommon

class SpaceListModifierTests: XCTestCase {

    func testSortEntries() {
        let a = SpaceEntry(type: .doc, nodeToken: "a", objToken: "a")
        let b = SpaceEntry(type: .doc, nodeToken: "b", objToken: "b")
        let c = SpaceEntry(type: .doc, nodeToken: "c", objToken: "c")

        a.updateEditTime(25)
        a.updateCreateTime(25)
        a.updateOwner("1")
        a.updateName("1")
        a.updateOpenTime(25)
        a.updateMyEditTime(25)
        a.updateActivityTime(25)
        a.updateShareTime(25)
        a.addManuOfflineTime = 25
        a.updateFavoriteTime(25)

        b.updateEditTime(100)
        b.updateCreateTime(100)
        b.updateOwner("3")
        b.updateName("3")
        b.updateOpenTime(100)
        b.updateMyEditTime(100)
        b.updateActivityTime(100)
        b.updateShareTime(100)
        b.addManuOfflineTime = 100
        b.updateFavoriteTime(100)

        c.updateEditTime(50)
        c.updateCreateTime(50)
        c.updateOwner("2")
        c.updateName("2")
        c.updateOpenTime(50)
        c.updateMyEditTime(50)
        c.updateActivityTime(50)
        c.updateShareTime(50)
        c.addManuOfflineTime = 50
        c.updateFavoriteTime(50)

        let expect = ["b", "c", "a"]

        SpaceSortHelper.SortType.allCases.forEach { sortType in
            var option = SpaceSortHelper.SortOption(type: sortType, descending: true, allowAscending: true)
            var sortModifier = SpaceListSortModifier(sortOption: option)
            var result = sortModifier.handle(entries: [a, b, c])
            XCTAssertEqual(result.map(\.objToken), expect)

            option = SpaceSortHelper.SortOption(type: sortType, descending: false, allowAscending: true)
            sortModifier = SpaceListSortModifier(sortOption: option)
            result = sortModifier.handle(entries: [a, b, c])
            XCTAssertEqual(result.map(\.objToken), expect.reversed())
        }
    }

    func testFilterModifier() {
        let doc = SpaceEntry(type: .doc, nodeToken: "doc", objToken: "doc")
        let docx = SpaceEntry(type: .docX, nodeToken: "docx", objToken: "docx")
        let sheet = SpaceEntry(type: .sheet, nodeToken: "sheet", objToken: "sheet")
        let bitable = SpaceEntry(type: .bitable, nodeToken: "bitable", objToken: "bitable")
        let slides = SpaceEntry(type: .slides, nodeToken: "slide", objToken: "slide")
        let mindnote = SpaceEntry(type: .mindnote, nodeToken: "mimdnote", objToken: "mindnote")
        let wiki = SpaceEntry(type: .wiki, nodeToken: "wiki", objToken: "wiki")
        let folder = SpaceEntry(type: .folder, nodeToken: "folder", objToken: "folder")
        let file = DriveEntry(type: .file, nodeToken: "drive", objToken: "drive")
        let image = DriveEntry(type: .file, nodeToken: "image", objToken: "image")
        image.updateFileType("jpg")

        let input: [SpaceEntry] = [doc, docx, sheet, bitable, slides, mindnote, wiki, folder, file, image]
        var modifier = SpaceListFilterModifier(filterOption: .all)
        var result = modifier.handle(entries: input).map(\.objToken)
        XCTAssertEqual(input.map(\.objToken), result)

        modifier = SpaceListFilterModifier(filterOption: .doc)
        result = modifier.handle(entries: input).map(\.objToken)
        XCTAssertEqual(["doc", "docx"], result)

        modifier = SpaceListFilterModifier(filterOption: .sheet)
        result = modifier.handle(entries: input).map(\.objToken)
        XCTAssertEqual(["sheet"], result)

        modifier = SpaceListFilterModifier(filterOption: .bitable)
        result = modifier.handle(entries: input).map(\.objToken)
        XCTAssertEqual(["bitable"], result)

        modifier = SpaceListFilterModifier(filterOption: .slides)
        result = modifier.handle(entries: input).map(\.objToken)
        XCTAssertEqual(["slide"], result)

        modifier = SpaceListFilterModifier(filterOption: .mindnote)
        result = modifier.handle(entries: input).map(\.objToken)
        XCTAssertEqual(["mindnote"], result)

        modifier = SpaceListFilterModifier(filterOption: .wiki)
        result = modifier.handle(entries: input).map(\.objToken)
        XCTAssertEqual(["wiki"], result)

        modifier = SpaceListFilterModifier(filterOption: .folder)
        result = modifier.handle(entries: input).map(\.objToken)
        XCTAssertEqual(["folder"], result)

        // 是否包括 image 取决于 FG，暂无 mock 的方式
//        modifier = SpaceListFilterModifier(filterOption: .file)
//        result = modifier.handle(entries: input).map(\.objToken)
//        XCTAssertTrue(result.contains("drive"))
//        XCTAssertTrue(result.count <= 2)
    }
}
