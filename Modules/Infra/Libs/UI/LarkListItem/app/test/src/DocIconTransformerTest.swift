//
//  DocIconTransformerTest.swift
//  UnitTests
//
//  Created by Yuri on 2023/9/27.
//

import XCTest
import LarkModel
@testable import LarkListItem

final class DocIconTransformerTest: XCTestCase {

    func testTransformCustomIcon() {
        var meta = DocMetaMocker.mockDoc()
        meta.iconInfo = "{\"type\":1,\"key\":\"0033-fe0f-20e3\",\"obj_type\":22,\"file_type\":null,\"token\":\"H2gld1G47ojDoixA6w1bpoemcib\",\"version\":4}"
            let icon = DocIconTransformer.transform(doc: meta, fileName: "", iconSize: .zero)
            if case .docIcon(let docIcon) = icon {
                XCTAssertFalse(docIcon.iconInfo.isEmpty)
            } else {
                XCTFail()
            }
    }

    func testNoMeta() {
        var meta = DocMetaMocker.mockDoc()
        meta.meta = nil
        let icon = DocIconTransformer.transform(doc: meta, fileName: "", iconSize: .zero)
        if case .local(let uIImage) = icon {
            XCTAssertNil(uIImage)
        } else {
            XCTFail()
        }
    }
}
