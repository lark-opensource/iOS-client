//
//  File.swift
//  QRCode
//
//  Created by SuPeng on 4/15/19.
//

import Foundation
import UIKit
import LKCommonsLogging

/// 根据字符生成QRCode，或者根据QRCode图片生成字符
public final class QRCodeTool {
    static let logger = Logger.log(QRCodeTool.self, category: "QRCodeTool")
    /// 根据字符生成QRCode
    /// - Parameters:
    ///   - str: 要生成二维码的字符
    ///   - size: 图片的size
    public class func createQRImg(str: String, size: CGFloat = 100) -> UIImage? {
        guard let qrCIImg = createQRCIImage(str: str) else {
            return nil
        }
        guard let qrCGImageInfo = createQRCGImage(ciImage: qrCIImg) else {
            return nil
        }
        // 获取白边像素宽度
        let borderPixel = whiteBorderPixel(cgImage: qrCGImageInfo.cgImage, size: qrCGImageInfo.size)
        // 生成裁剪完白边的uiimage
        guard let clipImg = clipWhiteBorder(
            cgImage: qrCGImageInfo.cgImage,
            size: Int(qrCGImageInfo.size.width),
            partSize: borderPixel) else {
                return nil
        }
        // 生成指定size的image
        let newSize = CGSize(width: size, height: size)
        return resizedImage(image: clipImg, size: newSize)
    }
}

private extension QRCodeTool {

    // 生成二维码ciImage
    class func createQRCIImage(str: String) -> CIImage? {
        guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }
        filter.setDefaults()
        let data = str.data(using: String.Encoding.utf8)
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("L", forKey: "inputCorrectionLevel")
        return filter.outputImage
    }

    // 生成二维码cgImage及尺寸
    class func createQRCGImage(ciImage: CIImage) -> (cgImage: CGImage, size: CGSize)? {
        // 先由ciImage构建出image,但由ciImage构建出的image没有cgImage信息
        let imageWithoutCGImage = UIImage(ciImage: ciImage, scale: 1, orientation: .up)
        // 重新生成携带cgImage信息的image
        if let cgImage = convertCIImageToCGImage(inputImage: ciImage) {
            return (cgImage, imageWithoutCGImage.size)
        }
        return nil
    }

    // 获取白边像素宽度
    class func whiteBorderPixel(cgImage: CGImage?, size: CGSize) -> Int {
        guard let pixels = getPixels(cgImage: cgImage, size: size) else {
            return 0
        }
        var whiteBorderPixel: Int = 0
        for i in 0..<Int(size.width) {
            if let index = pixelIndex(for: CGPoint(x: i, y: i), size: size) {
                if isWhite(for: pixels[index]) {
                    whiteBorderPixel += 1
                } else {
                    break
                }
            }
        }
        return whiteBorderPixel
    }

    // 裁剪白边
    class func clipWhiteBorder(cgImage: CGImage, size: Int, partSize: Int) -> UIImage? {
        guard let clipWhiteBorder = cgImage.cropping(to: CGRect(x: partSize,
                                                                y: partSize,
                                                                width: size - 2 * partSize,
                                                                height: size - 2 * partSize)) else { return nil }
        return UIImage(cgImage: clipWhiteBorder, scale: 1, orientation: .up)
    }

    // 获取图像像素矩阵(一维数组)
    class func getPixels(cgImage: CGImage?, size: CGSize) -> [UInt32]? {
        guard let cgImage = cgImage else {
            return nil
        }
        let width = Int(size.width)
        let height = Int(size.height)
        // 一个像素 4 个字节，则一行共 4 * width 个字节
        let bytesPerRow = 4 * width
        // 每个像素元素位数为 8 bit，即 rgba 每位各 1 个字节
        let bitsPerComponent = 8
        // 颜色空间为 RGB
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        // 设置位图颜色分布为 RGBA
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue
        var pixelsData = [UInt32](repeatElement(0, count: width * height))
        guard let content = CGContext(data: &pixelsData,
                                      width: width,
                                      height: height,
                                      bitsPerComponent: bitsPerComponent,
                                      bytesPerRow: bytesPerRow,
                                      space: colorSpace,
                                      bitmapInfo: bitmapInfo) else { return nil }
        content.draw(cgImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        return pixelsData
    }

    // 根据像素坐标获取在图像像素矩阵(一维数组)中index
    class func pixelIndex(for point: CGPoint, size: CGSize) -> Int? {
        let size = size
        guard point.x >= 0 && point.x <= size.width
            && point.y >= 0 && point.y <= size.height else {
                return nil
        }
        return (Int(point.y) * Int(size.width) + Int(point.x))
    }

    // 判断该像素点是不是白色
    class func isWhite(for pixel: UInt32) -> Bool {
        let red = Int((pixel >> 0) & 0xff)
        let green = Int((pixel >> 8) & 0xff)
        let blue = Int((pixel >> 16) & 0xff)
        if red == 255, green == 255, blue == 255 {
            return true
        }
        return false
    }
}

extension QRCodeTool {

    class func convertCIImageToCGImage(inputImage: CIImage) -> CGImage? {
        let context = CIContext(options: nil)
        if let cgImage = context.createCGImage(inputImage, from: inputImage.extent) {
            return cgImage
        }
        return nil
    }

    class func resizedImage(image: UIImage, size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContext(size)
        guard let context = UIGraphicsGetCurrentContext() else {
            return nil
        }
        context.interpolationQuality = CGInterpolationQuality.none
        image.draw(in: CGRect(origin: .zero, size: size))
        let img = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return img
    }
}
