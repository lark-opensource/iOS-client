//
//  SendImageProcessorUnitTest.swift
//  LarkSendMessage-Unit-Tests
//
//  Created by 李勇 on 2022/12/19.
//

import UIKit
import XCTest
import Foundation
import ByteWebImage // SendImageProcessor
import LarkContainer // InjectedSafeLazy

/// 密聊无法发送非Gif图问题单测case：https://meego.feishu.cn/larksuite/issue/detail/6588333?parentUrl=%2Flarksuite%2FissueView%2FLkF2q2e7g
final class SendImageProcessorUnitTest: CanSkipTestCase {
    /// 和康思婉沟通后，不指定尺寸压缩内部逻辑比较复杂，所以只测原图模式、指定尺寸压缩WebP/Jpeg
    @InjectedSafeLazy private var imageProcessor: SendImageProcessor

    // MARK: - 原图模式压缩
    /// Data入参原图模式压缩，底层用的ByteImage进行压缩
    func testOriginWithData() {
        // ByteImage默认会降采样到 ImageManager.default.defaultDownsampleSize，单位：px
        let downsampleSize = ImageManager.default.defaultDownsampleSize.width * ImageManager.default.defaultDownsampleSize.height

        let jpegData = Resources.imageData(named: "1200x1400-JPEG")
        if let jpegResult = self.imageProcessor.process(source: .imageData(jpegData), option: [.useOrigin], scene: .Chat) {
            XCTAssertEqual(jpegResult.imageType, .jpeg)
            XCTAssertNotEqual(jpegResult.image.size, .zero)
            // 大于阀值才会压缩
            if jpegData.bt.imageSize.width * jpegData.bt.imageSize.height >= downsampleSize {
                XCTAssertTrue(jpegResult.image.size.width * jpegResult.image.size.height * jpegResult.image.scale * jpegResult.image.scale <= downsampleSize)
            } else {
                // 否则和原来一样，size * scale转换为px
                XCTAssertTrue(jpegResult.image.size.scale(jpegResult.image.scale) == jpegData.bt.imageSize)
            }
            // 测试其他属性
            XCTAssertTrue(jpegResult.cost > 0)
            XCTAssertNotNil(jpegResult.colorSpaceName)
            XCTAssertNil(jpegResult.compressRatio)
            XCTAssertNotNil(jpegResult.compressAlgorithm)
        } else {
            XCTExpectFailure("jpeg data process with origin, fail")
        }

        let pngData = Resources.imageData(named: "1200x1400-PNG")
        if let pngResult = self.imageProcessor.process(source: .imageData(pngData), option: [.useOrigin], scene: .Chat) {
            XCTAssertEqual(pngResult.imageType, .png)
            XCTAssertNotEqual(pngResult.image.size, .zero)
            if pngData.bt.imageSize.width * pngData.bt.imageSize.height >= downsampleSize {
                XCTAssertTrue(pngResult.image.size.width * pngResult.image.size.height * pngResult.image.scale * pngResult.image.scale <= downsampleSize)
            } else {
                XCTAssertTrue(pngResult.image.size.scale(pngResult.image.scale) == pngData.bt.imageSize)
            }
            // 测试其他属性
            XCTAssertTrue(pngResult.cost > 0)
            XCTAssertNotNil(pngResult.colorSpaceName)
            XCTAssertNil(pngResult.compressRatio)
            XCTAssertNotNil(pngResult.compressAlgorithm)
        } else {
            XCTExpectFailure("png data process with origin, fail")
        }

        let heicData = Resources.imageData(named: "1200x1400-HEIC")
        if let heicResult = self.imageProcessor.process(source: .imageData(heicData), option: [.useOrigin], scene: .Chat) {
            XCTAssertEqual(heicResult.imageType, .heic)
            XCTAssertNotEqual(heicResult.image.size, .zero)
            if heicData.bt.imageSize.width * heicData.bt.imageSize.height >= downsampleSize {
                XCTAssertTrue(heicResult.image.size.width * heicResult.image.size.height * heicResult.image.scale * heicResult.image.scale <= downsampleSize)
            } else {
                XCTAssertTrue(heicResult.image.size.scale(heicResult.image.scale) == heicData.bt.imageSize)
            }
            // 测试其他属性
            XCTAssertTrue(heicResult.cost > 0)
            XCTAssertNotNil(heicResult.colorSpaceName)
            XCTAssertNil(heicResult.compressRatio)
            XCTAssertNotNil(heicResult.compressAlgorithm)
        } else {
            XCTExpectFailure("heic data process with origin, fail")
        }
    }

    /// UIImage入参原图模式压缩，底层用的jpegData ?? pngData ?? nil
    func testOriginWithImage() {
        let jpegImage = Resources.image(named: "1200x1400-JPEG")
        if let jpegResult = self.imageProcessor.process(source: .image(jpegImage), option: [.useOrigin], scene: .Chat) {
            // 内部是从UIImage取的jpegData，基本都能取到，因为UIImage已经丢了格式
            XCTAssertEqual(jpegResult.imageType, .jpeg)
            // 预期不为空就算压缩成功
            XCTAssertNotEqual(jpegResult.imageData.count, 0)
            // 测试其他属性
            XCTAssertTrue(jpegResult.cost > 0)
            XCTAssertNil(jpegResult.colorSpaceName)
            XCTAssertNil(jpegResult.compressRatio)
            XCTAssertNotNil(jpegResult.compressAlgorithm)
        } else {
            XCTExpectFailure("jpeg image process with origin, fail")
        }

        let pngImage = Resources.image(named: "1200x1400-PNG")
        if let pngResult = self.imageProcessor.process(source: .image(pngImage), option: [.useOrigin], scene: .Chat) {
            XCTAssertEqual(pngResult.imageType, .jpeg)
            XCTAssertNotEqual(pngResult.imageData.count, 0)
            // 测试其他属性
            XCTAssertTrue(pngResult.cost > 0)
            XCTAssertNil(pngResult.colorSpaceName)
            XCTAssertNil(pngResult.compressRatio)
            XCTAssertNotNil(pngResult.compressAlgorithm)
        } else {
            XCTExpectFailure("png image process with origin, fail")
        }

        let heicImage = Resources.image(named: "1200x1400-HEIC")
        if let heicResult = self.imageProcessor.process(source: .image(heicImage), option: [.useOrigin], scene: .Chat) {
            XCTAssertEqual(heicResult.imageType, .jpeg)
            XCTAssertNotEqual(heicResult.imageData.count, 0)
            // 测试其他属性
            XCTAssertTrue(heicResult.cost > 0)
            XCTAssertNil(heicResult.colorSpaceName)
            XCTAssertNil(heicResult.compressRatio)
            XCTAssertNotNil(heicResult.compressAlgorithm)
        } else {
            XCTExpectFailure("heic image process with origin, fail")
        }
    }

    // MARK: - WebP模式压缩
    /// Data入参WebP格式压缩 - 指定压缩尺寸
    func testWebPWithData1() {
        // 指定压缩后的大小，单位：px
        let scaleImageSize = CGSize(width: 120, height: 140)

        let jpegData = Resources.imageData(named: "1200x1400-JPEG")
        if let jpegResult = self.imageProcessor.process(source: .imageData(jpegData), options: [.needConvertToWebp], destPixel: Int(scaleImageSize.width), compressRate: 0.9, scene: .Chat) {
            XCTAssertEqual(jpegResult.imageType, .webp)
            // size * scale转换为px
            XCTAssertEqual(jpegResult.image.size.scale(jpegResult.image.scale), scaleImageSize)
            // 测试其他属性
            XCTAssertTrue(jpegResult.cost > 0)
            XCTAssertNotNil(jpegResult.colorSpaceName)
            XCTAssertNotNil(jpegResult.compressRatio)
            XCTAssertNotNil(jpegResult.compressAlgorithm)
        } else {
            XCTExpectFailure("jpeg data process with webp, fail")
        }

        let pngData = Resources.imageData(named: "1200x1400-PNG")
        if let pngResult = self.imageProcessor.process(source: .imageData(pngData), options: [.needConvertToWebp], destPixel: Int(scaleImageSize.width), compressRate: 0.9, scene: .Chat) {
            XCTAssertEqual(pngResult.imageType, .webp)
            XCTAssertEqual(pngResult.image.size.scale(pngResult.image.scale), scaleImageSize)
            // 测试其他属性
            XCTAssertTrue(pngResult.cost > 0)
            XCTAssertNotNil(pngResult.colorSpaceName)
            XCTAssertNotNil(pngResult.compressRatio)
            XCTAssertNotNil(pngResult.compressAlgorithm)
        } else {
            XCTExpectFailure("png data process with webp, fail")
        }

        let heicData = Resources.imageData(named: "1200x1400-HEIC")
        if let heicResult = self.imageProcessor.process(source: .imageData(heicData), options: [.needConvertToWebp], destPixel: Int(scaleImageSize.width), compressRate: 0.9, scene: .Chat) {
            XCTAssertEqual(heicResult.imageType, .webp)
            XCTAssertEqual(heicResult.image.size.scale(heicResult.image.scale), scaleImageSize)
            // 测试其他属性
            XCTAssertTrue(heicResult.cost > 0)
            XCTAssertNotNil(heicResult.colorSpaceName)
            XCTAssertNotNil(heicResult.compressRatio)
            XCTAssertNotNil(heicResult.compressAlgorithm)
        } else {
            XCTExpectFailure("heic data process with webp, fail")
        }
    }

    /// UIImage入参WebP格式压缩 - 指定压缩尺寸
    func testWebPWithImage1() {
        // 指定压缩后的大小，单位：px
        let scaleImageSize = CGSize(width: 120, height: 140)

        let jpegImage = Resources.image(named: "1200x1400-JPEG")
        if let jpegResult = self.imageProcessor.process(source: .image(jpegImage), options: [.needConvertToWebp], destPixel: Int(scaleImageSize.width), compressRate: 0.9, scene: .Chat) {
            XCTAssertEqual(jpegResult.imageType, .webp)
            // size * scale转换为px
            XCTAssertEqual(jpegResult.image.size.scale(jpegResult.image.scale), scaleImageSize)
            // 测试其他属性
            XCTAssertTrue(jpegResult.cost > 0)
            XCTAssertNotNil(jpegResult.colorSpaceName)
            XCTAssertNotNil(jpegResult.compressRatio)
            XCTAssertNotNil(jpegResult.compressAlgorithm)
        } else {
            XCTExpectFailure("jpeg image process with webp, fail")
        }

        let pngImage = Resources.image(named: "1200x1400-PNG")
        if let pngResult = self.imageProcessor.process(source: .image(pngImage), options: [.needConvertToWebp], destPixel: Int(scaleImageSize.width), compressRate: 0.9, scene: .Chat) {
            XCTAssertEqual(pngResult.imageType, .webp)
            XCTAssertEqual(pngResult.image.size.scale(pngResult.image.scale), scaleImageSize)
            // 测试其他属性
            XCTAssertTrue(pngResult.cost > 0)
            XCTAssertNotNil(pngResult.colorSpaceName)
            XCTAssertNotNil(pngResult.compressRatio)
            XCTAssertNotNil(pngResult.compressAlgorithm)
        } else {
            XCTExpectFailure("png image process with webp, fail")
        }

        let heicImage = Resources.image(named: "1200x1400-HEIC")
        if let heicResult = self.imageProcessor.process(source: .image(heicImage), options: [.needConvertToWebp], destPixel: Int(scaleImageSize.width), compressRate: 0.9, scene: .Chat) {
            XCTAssertEqual(heicResult.imageType, .webp)
            XCTAssertEqual(heicResult.image.size.scale(heicResult.image.scale), scaleImageSize)
            // 测试其他属性
            XCTAssertTrue(heicResult.cost > 0)
            XCTAssertNotNil(heicResult.colorSpaceName)
            XCTAssertNotNil(heicResult.compressRatio)
            XCTAssertNotNil(heicResult.compressAlgorithm)
        } else {
            XCTExpectFailure("heic image process with webp, fail")
        }
    }

    // MARK: - Jpeg模式压缩
    /// Data入参Jpeg格式压缩 - 指定压缩尺寸
    func testJpegWithData1() {
        // 指定压缩后的大小，单位：px
        let scaleImageSize = CGSize(width: 120, height: 140)

        let jpegData = Resources.imageData(named: "1200x1400-JPEG")
        if let jpegResult = self.imageProcessor.process(source: .imageData(jpegData), destPixel: Int(scaleImageSize.width), compressRate: 0.9, scene: .Chat) {
            XCTAssertEqual(jpegResult.imageType, .jpeg)
            // size * scale转换为px
            XCTAssertEqual(jpegResult.image.size.scale(jpegResult.image.scale), scaleImageSize)
            // 测试其他属性
            XCTAssertTrue(jpegResult.cost > 0)
            XCTAssertNotNil(jpegResult.colorSpaceName)
            XCTAssertNotNil(jpegResult.compressRatio)
            XCTAssertNotNil(jpegResult.compressAlgorithm)
        } else {
            XCTExpectFailure("jpeg data process with jpeg, fail")
        }

        let pngData = Resources.imageData(named: "1200x1400-PNG")
        if let pngResult = self.imageProcessor.process(source: .imageData(pngData), destPixel: Int(scaleImageSize.width), compressRate: 0.9, scene: .Chat) {
            XCTAssertEqual(pngResult.imageType, .jpeg)
            XCTAssertEqual(pngResult.image.size.scale(pngResult.image.scale), scaleImageSize)
            // 测试其他属性
            XCTAssertTrue(pngResult.cost > 0)
            XCTAssertNotNil(pngResult.colorSpaceName)
            XCTAssertNotNil(pngResult.compressRatio)
            XCTAssertNotNil(pngResult.compressAlgorithm)
        } else {
            XCTExpectFailure("png data process with jpeg, fail")
        }

        let heicData = Resources.imageData(named: "1200x1400-HEIC")
        if let heicResult = self.imageProcessor.process(source: .imageData(heicData), destPixel: Int(scaleImageSize.width), compressRate: 0.9, scene: .Chat) {
            XCTAssertEqual(heicResult.imageType, .jpeg)
            XCTAssertEqual(heicResult.image.size.scale(heicResult.image.scale), scaleImageSize)
            // 测试其他属性
            XCTAssertTrue(heicResult.cost > 0)
            XCTAssertNotNil(heicResult.colorSpaceName)
            XCTAssertNotNil(heicResult.compressRatio)
            XCTAssertNotNil(heicResult.compressAlgorithm)
        } else {
            XCTExpectFailure("heic data process with jpeg, fail")
        }
    }

    /// UIImage入参Jpeg格式压缩 - 指定压缩尺寸
    func testJpegWithImage1() {
        // 指定压缩后的大小，单位：px
        let scaleImageSize = CGSize(width: 120, height: 140)

        let jpegImage = Resources.image(named: "1200x1400-JPEG")
        if let jpegResult = self.imageProcessor.process(source: .image(jpegImage), destPixel: Int(scaleImageSize.width), compressRate: 0.9, scene: .Chat) {
            XCTAssertEqual(jpegResult.imageType, .jpeg)
            // size * scale转换为px
            XCTAssertEqual(jpegResult.image.size.scale(jpegResult.image.scale), scaleImageSize)
            // 测试其他属性
            XCTAssertTrue(jpegResult.cost > 0)
            XCTAssertNotNil(jpegResult.colorSpaceName)
            XCTAssertNotNil(jpegResult.compressRatio)
            XCTAssertNotNil(jpegResult.compressAlgorithm)
        } else {
            XCTExpectFailure("jpeg image process with jpeg, fail")
        }

        let pngImage = Resources.image(named: "1200x1400-PNG")
        if let pngResult = self.imageProcessor.process(source: .image(pngImage), destPixel: Int(scaleImageSize.width), compressRate: 0.9, scene: .Chat) {
            XCTAssertEqual(pngResult.imageType, .jpeg)
            XCTAssertEqual(pngResult.image.size.scale(pngResult.image.scale), scaleImageSize)
            // 测试其他属性
            XCTAssertTrue(pngResult.cost > 0)
            XCTAssertNotNil(pngResult.colorSpaceName)
            XCTAssertNotNil(pngResult.compressRatio)
            XCTAssertNotNil(pngResult.compressAlgorithm)
        } else {
            XCTExpectFailure("png image process with jpeg, fail")
        }

        let heicImage = Resources.image(named: "1200x1400-HEIC")
        if let heicResult = self.imageProcessor.process(source: .image(heicImage), destPixel: Int(scaleImageSize.width), compressRate: 0.9, scene: .Chat) {
            XCTAssertEqual(heicResult.imageType, .jpeg)
            XCTAssertEqual(heicResult.image.size.scale(heicResult.image.scale), scaleImageSize)
            // 测试其他属性
            XCTAssertTrue(heicResult.cost > 0)
            XCTAssertNotNil(heicResult.colorSpaceName)
            XCTAssertNotNil(heicResult.compressRatio)
            XCTAssertNotNil(heicResult.compressAlgorithm)
        } else {
            XCTExpectFailure("heic image process with jpeg, fail")
        }
    }

    // MARK: - destPixel传0，预期不做处理
    func testDestPixelZeroWithImage1() {
        // 指定压缩后的大小，单位：px
        let scaleImageSize = CGSize.zero

        let jpegImage = Resources.image(named: "1200x1400-JPEG")
        if let jpegResult = self.imageProcessor.process(source: .image(jpegImage), destPixel: Int(scaleImageSize.width), compressRate: 0.9, scene: .Chat) {
            XCTAssertEqual(jpegResult.imageType, .jpeg)
            // size * scale转换为px
            XCTAssertEqual(jpegResult.image.size.scale(jpegResult.image.scale), jpegImage.size.scale(jpegImage.scale))
            // 测试其他属性
            XCTAssertTrue(jpegResult.cost > 0)
            XCTAssertNotNil(jpegResult.colorSpaceName)
            XCTAssertNotNil(jpegResult.compressRatio)
            XCTAssertNotNil(jpegResult.compressAlgorithm)
        } else {
            XCTExpectFailure("jpeg image process with jpeg, fail")
        }

        let pngImage = Resources.image(named: "1200x1400-PNG")
        if let pngResult = self.imageProcessor.process(source: .image(pngImage), destPixel: Int(scaleImageSize.width), compressRate: 0.9, scene: .Chat) {
            XCTAssertEqual(pngResult.imageType, .jpeg)
            XCTAssertEqual(pngResult.image.size.scale(pngResult.image.scale), pngImage.size.scale(pngImage.scale))
            // 测试其他属性
            XCTAssertTrue(pngResult.cost > 0)
            XCTAssertNotNil(pngResult.colorSpaceName)
            XCTAssertNotNil(pngResult.compressRatio)
            XCTAssertNotNil(pngResult.compressAlgorithm)
        } else {
            XCTExpectFailure("png image process with jpeg, fail")
        }

        let heicImage = Resources.image(named: "1200x1400-HEIC")
        if let heicResult = self.imageProcessor.process(source: .image(heicImage), destPixel: Int(scaleImageSize.width), compressRate: 0.9, scene: .Chat) {
            XCTAssertEqual(heicResult.imageType, .jpeg)
            XCTAssertEqual(heicResult.image.size.scale(heicResult.image.scale), heicImage.size.scale(heicImage.scale))
            // 测试其他属性
            XCTAssertTrue(heicResult.cost > 0)
            XCTAssertNotNil(heicResult.colorSpaceName)
            XCTAssertNotNil(heicResult.compressRatio)
            XCTAssertNotNil(heicResult.compressAlgorithm)
        } else {
            XCTExpectFailure("heic image process with jpeg, fail")
        }
    }

    func testDestPixelZeroWithData1() {
        // 指定压缩后的大小，单位：px
        let scaleImageSize = CGSize.zero

        let jpegData = Resources.imageData(named: "1200x1400-JPEG")
        if let jpegResult = self.imageProcessor.process(source: .imageData(jpegData), destPixel: Int(scaleImageSize.width), compressRate: 0.9, scene: .Chat) {
            XCTAssertEqual(jpegResult.imageType, .jpeg)
            // size * scale转换为px
            XCTAssertEqual(jpegResult.image.size.scale(jpegResult.image.scale), jpegData.bt.imageSize)
            // 测试其他属性
            XCTAssertTrue(jpegResult.cost > 0)
            XCTAssertNotNil(jpegResult.colorSpaceName)
            XCTAssertNotNil(jpegResult.compressRatio)
            XCTAssertNotNil(jpegResult.compressAlgorithm)
        } else {
            XCTExpectFailure("jpeg data process with jpeg, fail")
        }

        let pngData = Resources.imageData(named: "1200x1400-PNG")
        if let pngResult = self.imageProcessor.process(source: .imageData(pngData), destPixel: Int(scaleImageSize.width), compressRate: 0.9, scene: .Chat) {
            XCTAssertEqual(pngResult.imageType, .jpeg)
            XCTAssertEqual(pngResult.image.size.scale(pngResult.image.scale), jpegData.bt.imageSize)
            // 测试其他属性
            XCTAssertTrue(pngResult.cost > 0)
            XCTAssertNotNil(pngResult.colorSpaceName)
            XCTAssertNotNil(pngResult.compressRatio)
            XCTAssertNotNil(pngResult.compressAlgorithm)
        } else {
            XCTExpectFailure("png data process with jpeg, fail")
        }

        let heicData = Resources.imageData(named: "1200x1400-HEIC")
        if let heicResult = self.imageProcessor.process(source: .imageData(heicData), destPixel: Int(scaleImageSize.width), compressRate: 0.9, scene: .Chat) {
            XCTAssertEqual(heicResult.imageType, .jpeg)
            XCTAssertEqual(heicResult.image.size.scale(heicResult.image.scale), jpegData.bt.imageSize)
            // 测试其他属性
            XCTAssertTrue(heicResult.cost > 0)
            XCTAssertNotNil(heicResult.colorSpaceName)
            XCTAssertNotNil(heicResult.compressRatio)
            XCTAssertNotNil(heicResult.compressAlgorithm)
        } else {
            XCTExpectFailure("heic data process with jpeg, fail")
        }
    }
}
