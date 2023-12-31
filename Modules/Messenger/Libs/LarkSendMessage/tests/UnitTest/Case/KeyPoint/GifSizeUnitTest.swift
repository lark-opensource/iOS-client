//
//  GifSizeUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2022/12/27.
//

import UIKit
import XCTest
import Foundation
import ByteWebImage // SendImageProcessor
import LarkContainer // InjectedSafeLazy

/// 发送Gif等图上屏，图片大小会变化：https://meego.feishu.cn/larksuite/issue/detail/6587956#comment
final class GifSizeUnitTest: CanSkipTestCase {
    @InjectedSafeLazy private var imageProcessor: SendImageProcessor

    /// Gif图处理，Gif处理没有原图非原图之分
    func testGifData() {
        let gifData = Resources.imageData(named: "300x400-GIF")
        let byteImage = try? ByteImage(gifData)
        XCTAssertNotNil(byteImage?.image)
        XCTAssertEqual(byteImage?.image?.size.scale(byteImage?.image?.scale ?? 1), CGSize(width: 300, height: 400))
    }

    /// HEIC 原图、WebP、Jpeg处理在SendImageProcessorUnitTest中已经有了，这里就不再写了
}
