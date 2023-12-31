//
//  ImageUtilTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/11/10.
//
// swiftlint:disable all
import XCTest
@testable import LarkListItem
final class ImageUtilTest: XCTestCase {

    func testCombineImage() {
        let bundle = Bundle(for: Self.self)
        let path1 = bundle.path(forResource: "combine_source1", ofType: "png")!
        let path2 = bundle.path(forResource: "combine_source2", ofType: "png")!
        let path3 = bundle.path(forResource: "combine_result", ofType: "png")!
        let data = try! Data(contentsOf: URL(fileURLWithPath: path3))
        let source1 = UIImage(data: try! Data(contentsOf: URL(fileURLWithPath: path1)))
        let source2 = UIImage(data: try! Data(contentsOf: URL(fileURLWithPath: path2)))
        let target = UIImage(data: data)!
        let result = ImageUtil.combineImages(source1!, source2!)!
        XCTAssertEqual(target.pngData()?.count, result.pngData()?.count)
    }
}
// swiftlint:enable all
