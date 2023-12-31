//
//  RepleacemeSpec.swift
//  BDevEEUnitTest
//
//  Created by 董朝 on 2019/2/14.
//

import Foundation
import XCTest
import QRCode

class QRCodeToolTest: XCTestCase {

    func testQRCodeTool() {
        // 验证可以根据字符串生成二维码
        let image = QRCodeTool.createQRImg(str: "Test String")
        XCTAssertNotNil(image)

        // 验证通过生成的二维码可以扫描到字符串
        let code = QRCodeTool.scan(from: image!)
        XCTAssertNotNil(code)

        // 验证从图片中扫描到的二维码是正确的
        XCTAssertEqual(code!, "Test String")
    }
}
