//
//  SearchAttributeStringTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/10/24.
//
// swiftlint:disable all
import XCTest
@testable import LarkListItem

final class SearchAttributeStringTest: XCTestCase {

    var icon: UIImage!

    override func setUp() {
        let bundle = Bundle(for: Self.self)
        let path = bundle.path(forResource: "icon", ofType: "jpg")!
        icon = UIImage(data: try! Data(contentsOf: URL(fileURLWithPath: path)))!
    }

    func testString() {
        let str = "Test"
        let attrStr = SearchAttributeString(searchHighlightedString: str).text
        XCTAssertEqual(attrStr, str)
    }

    func testMutableString() {
        let str = "Test"
        let attrStr = SearchAttributeString(searchHighlightedString: str).mutableAttributeText
        XCTAssertEqual(attrStr.string, str)
    }

    func testHitTerms() {
        let str = "Test<h>hit</h>"
        let hitTerms = SearchAttributeString(searchHighlightedString: str).hitTerms
        XCTAssertEqual(hitTerms.count, 1)
        XCTAssertEqual(hitTerms.first, "hit")
    }

    func testHighlightedStringH() {
        let str = "Test<h>Highlighted</h>"
        let attrStr = SearchAttributeString(searchHighlightedString: str).attributeText
        XCTAssertEqual(attrStr.string, "TestHighlighted")
    }

    func testHighlightedStringB() {
        let str = "Test<b>Highlighted</b>"
        let attrStr = SearchAttributeString(searchHighlightedString: str).attributeText
        XCTAssertEqual(attrStr.string, "TestHighlighted")
    }

    func testHighlightedStringHB() {
        let str = "Test<hb>Highlighted</hb>"
        let attrStr = SearchAttributeString(searchHighlightedString: str).attributeText
        XCTAssertEqual(attrStr.string, "TestHighlighted")
    }

    func testHighlightedStringDi() {
        let str = "Test<di color='grey' type='1'/>Highlighted"
        let attrStr = SearchAttributeString(searchHighlightedString: str).attributeText
        let attachment = findAttachments(in: attrStr)
        XCTAssertEqual(attrStr.string, "Test￼ Highlighted")
        XCTAssertEqual(attachment.count, 1)
        XCTAssertEqual(attachment.first?.image?.pngData()?.count, 1176)
        let image = attachment.first?.image
        XCTAssertEqual(attachment.first?.image?.size, CGSize(width: 14, height: 14))
    }

    func testHighlightedStringStyle() {
        let str = "Test<style>Highlighted</style>"
        let attrStr = SearchAttributeString(searchHighlightedString: str).attributeText
        XCTAssertEqual(attrStr.string, "TestHighlighted")
    }

    func testHighlightedStringWithPi() {
        let str = "Test<pi/>Highlighted"
        let attrStr = SearchAttributeString(searchHighlightedString: str, enableSupportURLIconInline: true).attributeText
        let attachment = findAttachments(in: attrStr)
        XCTAssertEqual(attrStr.string, "Test￼Highlighted")
        XCTAssertEqual(attachment.count, 1)
        XCTAssertEqual(attachment.first?.image?.pngData()?.count, 1701)
    }

    func testHighlightedStringWithUdPi() {
        let str = "Test<pi ud='-'/>Highlighted"
        let attrStr = SearchAttributeString(searchHighlightedString: str, enableSupportURLIconInline: true).attributeText
        let attachment = findAttachments(in: attrStr)
        XCTAssertEqual(attrStr.string, "Test￼Highlighted")
        XCTAssertEqual(attachment.count, 1)
        XCTAssertEqual(attachment.first?.image?.pngData()?.count, 1701)
    }

    func testHighlightedStringWithIconPi() {
        let str = "Test<pi icon='-'/>Highlighted"
        let attrStr = SearchAttributeString(searchHighlightedString: str, enableSupportURLIconInline: true).attributeText
        let attachment = findAttachments(in: attrStr)
        XCTAssertEqual(attrStr.string, "Test￼Highlighted")
        XCTAssertEqual(attachment.count, 1)
        XCTAssertEqual(attachment.first?.image?.pngData()?.count, 360)
    }

    func testErrorXML() {
        let str = "<h>Test"
        let attrStr = SearchAttributeString(searchHighlightedString: str).attributeText
        XCTAssertEqual(attrStr.string, "")
    }

    func testAddSearchImage() {
        let str = "Test"
        let attrStr = SearchAttributeString(searchHighlightedString: str)
        attrStr.mutableAttributeText.addSearchImageAttachment(image: icon, font: UIFont.systemFont(ofSize: 14), imageKey: "1", isWebImage: false)
        let res = attrStr.attributeText
        let attachments = findAttachments(in: attrStr.attributeText)
        XCTAssertEqual(attachments.first?.image?.size, CGSize(width: 18, height: 14))
    }

    func testUpdateSearchImage() {
        let str = "Test"
        let attrStr = SearchAttributeString(searchHighlightedString: str)
        attrStr.mutableAttributeText.addSearchImageAttachment(image: icon, font: UIFont.systemFont(ofSize: 14), imageKey: "1", isWebImage: false)
        let res = attrStr.mutableAttributeText.updateSearchImage(font: UIFont.systemFont(ofSize: 36), tintColor: .purple)
        let attachment = findAttachments(in: res)
        let image = attachment.first?.image
        XCTAssertEqual(attachment.first?.image?.size, CGSize(width: 40, height: 36))
    }

    func testAddSearchWebImage() {
        let str = "Test"
        let webImageKey = "webKey"
        let attrStr = SearchAttributeString(searchHighlightedString: str)
        attrStr.mutableAttributeText.addSearchImageAttachment(image: icon, font: UIFont.systemFont(ofSize: 14), imageKey: webImageKey, isWebImage: true)
        let res = attrStr.mutableAttributeText.searchWebImageKeysInAttachment
        XCTAssertEqual(res.first, webImageKey)
    }

    func testUpdateWebImageToLocalImage() {
        let str = "Test"
        let webImageKey = "webKey"
        let attrStr = SearchAttributeString(searchHighlightedString: str)
        attrStr.mutableAttributeText.addSearchImageAttachment(image: icon, font: UIFont.systemFont(ofSize: 14), imageKey: webImageKey, isWebImage: true)
        let res = attrStr.mutableAttributeText.updateSearchWebImageView(withImageResource: [(webImageKey, icon)], font: UIFont.systemFont(ofSize: 14))
        let attachment = findAttachments(in: res).first as? SearchTextAttachment
        XCTAssertEqual(attachment?.isWebImage, false)
        XCTAssertEqual(attachment?.originImage?.pngData()?.count, icon.pngData()?.count)
    }

    // MARK: - Privacy
    func findAttachments(in attributedString: NSAttributedString) -> [NSTextAttachment] {
        var attachments: [NSTextAttachment] = []

        attributedString.enumerateAttributes(in: NSRange(location: 0, length: attributedString.length), options: []) { attributes, range, _ in
            for (_, value) in attributes {
                if let attachment = value as? NSTextAttachment {
                    attachments.append(attachment)
                }
            }
        }

        return attachments
    }
}
// swiftlint:disable all
