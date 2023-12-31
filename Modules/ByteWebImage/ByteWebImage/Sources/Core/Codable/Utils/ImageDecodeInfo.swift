//
//  ImageDecodeInfo.swift
//  ByteWebImage
//
//  Created by xiongmin on 2021/11/18.
//

import Foundation
import zlib

public extension ImageWrapper where Base == Data {
    // disable-lint: magic number
    // MARK: - General

    /// Data 前 ofFirstBytes 个字节的 Hex 字符串
    ///
    /// 建议 ofFirstBytes 参数不要与 Data 总大小相关，因为相同长度的 Data 比对应的全量 hexString 内存占用更小，
    /// 全量转换成 hexString 可能会 OOM
    ///
    /// - Note: 在 Data 总长度不确定的情况下，不建议将 ofFirstBytes 设为 data.count，以免 OOM
    func hexString(ofFirstBytes count: Int, uppercase: Bool = true) -> String {
        let bytesCount = max(0, min(base.count, count))
        guard bytesCount > 0 else { return "" }
        return base.withUnsafeBytes { pointer -> String in
            var hexString = ""
            for index in 0..<bytesCount {
                var str = String(pointer[index], radix: 16, uppercase: uppercase)
                if str.count == 1 {
                    str = "0" + str
                }
                hexString += str
            }
            return hexString
        }
    }

    /// Data 前 16 bytes 的 Hex 字符串
    ///
    /// 一般可以用来判断文件格式，因为只判断 Data 头部 16 字节，所以对内存、CPU 无明显影响
    var formatHeader: String {
        guard !base.isEmpty else { return "" }
        let count = min(base.count, 16)
        return base.bt.hexString(ofFirstBytes: count)
    }

    /// Data 的 CRC32 校验码
    ///
    /// - Note: 线程安全，可在子线程调用，对内存、CPU 无明显影响，内部调用 zlib.crc32() 计算
    var crc32: String {
        String(base.withUnsafeBytes({ pointer in
            zlib.crc32(0, pointer.bindMemory(to: Bytef.self).baseAddress, uInt(base.count))
        }), radix: 16)
    }
    // enable-lint: magic number

    // MARK: - Image

    /// 判断 Data 对应的图片是否是动图
    /// - Note: 线程安全，可在子线程调用，对内存、CPU 无明显影响，原理是读 Data 的头部，匹配特征
    ///
    /// 目前可判断 GIF、APNG、WebP 三个类型的动图
    var isAnimatedImageData: Bool {
        let minBytes = 50
        guard base.count > minBytes else { return false }
        func toAscii(_ string: String) -> UInt8 {
            if string.count > 1 { return 0 }
            return UInt8(string.unicodeScalars.first?.value ?? 0)
        }
        return base.withUnsafeBytes { ptr -> Bool in
            guard let buffer = ptr.baseAddress?.bindMemory(to: UInt8.self, capacity: minBytes) else {
                return false
            }
            let format = self.imageFileFormat
            if format == .webp {
                if buffer[15] == toAscii("L") || buffer[15] == toAscii("X") {
                    if (buffer[20] & 0x02) == 0x02 {
                        return true
                    }
                }
            }
            if format == .gif {
                return true
            }
            if format == .png {
                if buffer[37] == toAscii("a") &&
                    buffer[38] == toAscii("c") &&
                    buffer[39] == toAscii("T") &&
                    buffer[40] == toAscii("L") {
                    return true
                }
            }
            return false
        }
    }

    /// 尝试解析 Data 对应的图片尺寸，单位 px
    /// - Note: 会涉及到图片的基本信息解码(Info 段)，不会解码整张图片的数据(Data 段)，对 CPU 和内存无明显影响
    ///
    /// 原理是将 Data 转换为 CGImageSource，然后 CGImageSourceCopyPropertiesAtIndex 0
    ///
    /// 理论上是线程安全的，但是实际上取决于 CGImageSource 内部的实现
    ///
    /// 性能影响上和 `let image = UIImage(data: data); let size = image?.size` 一样，
    /// 因为 UIImage 也是懒加载的，只要不把 UIImage 上屏，不会对性能有什么影响
    var imageSize: CGSize {
        guard let decodeBox = try? ImageDecodeBox(base),
              let pixelSize = try? decodeBox.pixelSize else {
            return .zero
        }
        return pixelSize
    }

    /// 尝试获取 Data 对应图片数量（动图帧数）
    /// - 如果是动图或者支持含有多张图的图片格式(如 HEIF)，会返回包含的图片数量
    /// - Note: 会涉及到图片的基本信息解码(Info 段)，不会解码整张图片的数据(Data 段)，对 CPU 和内存无明显影响
    ///
    /// 原理是将 Data 转换为 CGImageSource，然后 CGImageSourceGetCount
    ///
    /// 理论上是线程安全的，但是实际上取决于 CGImageSource 内部的实现
    var imageCount: Int {
        guard let decodeBox = try? ImageDecodeBox(base) else {
            return 0
        }
        return decodeBox.imageCount
    }
}
