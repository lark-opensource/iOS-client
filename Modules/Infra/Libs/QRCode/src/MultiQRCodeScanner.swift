//
//  MultiQRCodeScanner.swift
//  QRCode
//
//  Created by Saafo on 2023/10/7.
//

import UIKit
import LarkSetting
import ByteWebImage
import LarkExtensions
import LKCommonsLogging
import ThreadSafeDataStructure

public enum MultiQRCodeScanner {

    /// 二维码扫描和展示所需要的图片信息
    public struct ImageInfos {
        /// 原始的图片数据，UIImage / Data 二选一
        ///
        ///- Important: 如果传入 UIImage，需要避免其为解码后的超大图。如果是超大图，建议传 data，内部会降采样
        public enum ImageSource: CustomStringConvertible {
            case uiImage(UIImage)
            case data(Data)
        }
        public private(set) var image: ImageSource
        /// 图片标识，用于缓存二维码识别结果
        public var identifier: String?

        /// 相比于图片初始态的放大倍数，主要是大图查看器场景使用
        public var zoomFactor: CGFloat = 1
        /// 基于原图片坐标的可视区域（单位：px）
        ///
        /// 如果传入，则不会展示整张图片，而只展示该部分。
        /// 如果只传了 visibleRect 而没传 customDisplayImage，展示时会内部裁剪后展示。
        /// - Note: 如果Orientation 非 .up，需要调整为 .up 时的方向。
        public var visibleRect: CGRect?
        /// 指定展示的图片，主要是大图查看器场景使用。
        ///
        /// 必须同时和 visibleRect 传入，并且大小位置和其对应
        public var customDisplayImage: UIImage?

        /// 扫描页出现时，是否添加动画
        ///
        /// 非页面 present 动画，是图片遮罩层动画和箭头渐现动画
        public var needAppearAnimation: Bool = false

        public init(image: ImageSource) {
            self.image = image
        }
    }

    public enum ScanError: Error {
        case invalidImageData
        case invalidImage
        case logicalError
    }

    private static let cache = SafeLRUDictionary<String, [CodeItemInfo]>()
    private static let logger = Logger.log(MultiQRCodeScanner.self, category: "MultiQRCodeScanner")

    /// 输入图像，输出一个二维码结果
    ///
    /// 如果有多个二维码，会自动展示选择器，让用户选择一个二维码
    public static func scanAndPickCode(image: ImageInfos,
                                       from: UIViewController,
                                       setting: SettingService,
                                       didPickQRCode: ((CodeItemInfo?) -> Void)?) {
        if case .success(let infos) = scanCodes(image: image, setting: setting) {
            pickCode(image: image, from: from, codeInfos: infos, setting: setting, didPickQRCode: didPickQRCode)
        } else {
            didPickQRCode?(nil)
        }
    }

    /// 输入图像，输出扫码结果
    ///
    /// 扫码结果可能是多个二维码，典型的使用方式是再回传到 pickCode 中让用户选择一个二维码
    public static func scanCodes(image: ImageInfos,
                                 setting: SettingService) -> Result<[CodeItemInfo], Error> {
        logger.debug("scanCodes \(image)")
        let (limitPixels, limitRatio) = dynamicLimit(setting)

        var scanImage: UIImage
        let scanImageType: ScanImageType
        do {
            scanImageType = try getScanImageType(image: image, limit: (limitPixels, limitRatio))
        } catch {
            return .failure(error)
        }
        let useCache: Bool // 全图才用缓存
        switch scanImageType {
        case .cropped:
            useCache = false
            do {
                guard let croppedImage = try image.croppedImage() else {
                    return .failure(ScanError.logicalError) // 不应该取不到
                }
                scanImage = croppedImage
            } catch {
                return .failure(error)
            }
        default:
            useCache = true
            // 先确认是否有缓存
            if let identifier = image.identifier, let cacheResult = cache[identifier] {
                logger.debug("get cache: \(cacheResult)")
                return .success(cacheResult)
            } else {
                // 否则判断 image 大小，过大则降采样后再扫描
                do {
                    scanImage = try image.image.safeImage(limitPixels: limitPixels)
                } catch {
                    return .failure(error)
                }
            }
        }
        scanImage = scanImage.lu.fixOrientation()
        logger.debug("scanImage: \(scanImage) pixelSize: \(scanImage.pixelSize) scanImageType: \(scanImageType)")
        let result = QRCodeTool.scanV2(from: scanImage)
        if case .success(let infos) = result, !infos.isEmpty, let identifier = image.identifier, useCache {
            cache[identifier] = infos
        }
        logger.debug("scanCodes finished result: \(result)")
        return result
    }

    /// 输入图片和扫码结果，如果有多个二维码在视图中，会弹出选择器让用户选择一个二维码
    ///
    /// - Note: 需要在主线程调用
    public static func pickCode(image: ImageInfos,
                                from: UIViewController,
                                codeInfos: [CodeItemInfo],
                                setting: SettingService,
                                didPickQRCode: ((CodeItemInfo?) -> Void)?) {
        logger.debug("pickCode \(image), infos: \(codeInfos)")
        // 1. 先根据数量判断是否要展示 picker
        guard codeInfos.count > 1 else {
            if let info = codeInfos.first {
                didPickQRCode?(info)
            } else {
                didPickQRCode?(nil)
            }
            return
        }
        // 2. 坐标转换
        let (limitPixels, limitRatio) = dynamicLimit(setting)
        guard let scanImageType = try? getScanImageType(image: image, limit: (limitPixels, limitRatio)) else {
            didPickQRCode?(nil)
            return
        }
        let scanImageSize: CGSize = {
            switch scanImageType {
            case .cropped(let rect):
                return rect.size
            case .downsampled(let size):
                return size
            case .origin:
                return image.image.pixelSize
            }
        }()
        /// 相对于扫描图&左上角&图片旋转后的坐标的位置信息
        let convertedInfos = codeInfos.map {
            var info = $0
            // 原 info 是左下角的归一化坐标，这里做下转换
            info.position = CGRect(x: $0.position.minX * scanImageSize.width,
                                   y: scanImageSize.height - $0.position.maxY * scanImageSize.height,
                                   width: $0.position.width * scanImageSize.width,
                                   height: $0.position.height * scanImageSize.height)
            return info
        }
        let (displayCodes, displayImage): ([CodeItemInfo], UIImage)

        // visibleRect 本来相对于原图坐标，如果降采样了，也需要转换
        var downsampleScale: CGFloat = 1
        if case .downsampled(let size) = scanImageType {
            downsampleScale = size.width / image.image.pixelSize.width
        }
        var visibleRect = image.visibleRect
        if let rect = visibleRect {
            visibleRect = CGRect(x: rect.minX * downsampleScale,
                                 y: rect.minY * downsampleScale,
                                 width: rect.width * downsampleScale,
                                 height: rect.height * downsampleScale)
        }
        // 3. 是否需要展示局部图片
        // 3.1. 如果 visibleRect 非空，计算可视区域内的 codeInfo 数量
        if let visibleRect {

            // 当扫描图和展示图一致，直接展示
            if case .cropped = scanImageType {
                if let croppedImage = try? image.croppedImage() {
                    displayImage = croppedImage
                    displayCodes = convertedInfos
                } else {
                    didPickQRCode?(nil) // 有 visibleRect 时，一定会返回 croppedImage，除非解码错误
                    return
                }
            } else {
                // 当展示图和扫描图范围不一时，需要确定可视码数量&转换坐标
                let visibleInfos = visibleInfos(visibleRect: visibleRect, convertedInfos: convertedInfos)
                switch visibleInfos.count {
                case 0:
                    didPickQRCode?(nil)
                    return
                case 1:
                    didPickQRCode?(visibleInfos.first)
                    return
                default:
                    guard let croppedImage = try? image.croppedImage() else {
                        didPickQRCode?(nil) // 有 visibleRect 时，一定会返回 croppedImage，除非解码错误
                        return
                    }
                    (displayCodes, displayImage) = (visibleInfos, croppedImage)
                }
            }
        } else {
            // 3.2. 展示所有码
            if let safeImage = try? image.image.safeImage(limitPixels: limitPixels) {
                displayImage = safeImage
                displayCodes = convertedInfos
            } else {
                didPickQRCode?(nil)
                return
            }
        }
        let picker = MultiQRCodePickerVC()
        picker.image = displayImage
        picker.imageSize = visibleRect?.size
        picker.codeInfos = displayCodes
        picker.didPickQRCode = { [weak picker] codeContent in
            logger.debug("picker didPickQRCode: \(String(describing: codeContent))")
            picker?.dismiss(animated: false, completion: {
                didPickQRCode?(codeContent)
            })
        }
        picker.needAppearAnimation = image.needAppearAnimation
        picker.modalPresentationStyle = .currentContext
        #if DEBUG
        picker.debug = true
        #endif
        from.present(picker, animated: false)
        logger.debug("present picker, image: \(displayImage), codes: \(displayCodes)")
    }

    // MARK: - private utils functions

    /// 当扫描整张图片时（原图/降采样图）并且有可视区域，需要确定可视码数量&转换坐标
    private static func visibleInfos(visibleRect: CGRect,
                                     convertedInfos: [CodeItemInfo]) -> [CodeItemInfo] {
        var preferredCodes: [CodeItemInfo] = [] // 二维码中心在图中的码
        var visibleCodes: [CodeItemInfo] = [] // 二维码和展示图有交集的码
        var invisibleCodes: [CodeItemInfo] = [] // 二维码完全在展示图外的码
        convertedInfos.forEach { info in
            if visibleRect.intersects(info.position) {
                visibleCodes.append(info)
                if visibleRect.contains(info.position.center) {
                    preferredCodes.append(info)
                }
            } else {
                invisibleCodes.append(info)
            }
        }
        logger.debug("preferred: \(preferredCodes), visible: \(visibleCodes), invisible: \(invisibleCodes)")
        // 然后决定直接跳转还是展示 Picker
        switch visibleCodes.count {
        case 0:
            // 如果可视区域 为 0，寻找区域外最近的 code
            var (nearestCode, nearestDistance): (CodeItemInfo?, CGFloat?)
            invisibleCodes.forEach { info in
                let distance = info.position.center.distance(to: visibleRect.center)
                if let currentNearestDistance = nearestDistance, distance >= currentNearestDistance {
                    return
                }
                (nearestCode, nearestDistance) = (info, distance)
            }
            if let nearestCode {
                return [nearestCode]
            } else {
                return []
            }
        case 1:
            // 如果可视区域 为 1，直接返回
            if let visibleCode = visibleCodes.first {
                return [visibleCode]
            } else {
                return []
            }
        default:
            // 如果中心点本身在图中的二维码只有一个，也直接跳转
            if preferredCodes.count == 1, let preferredCode = preferredCodes.first {
                return [preferredCode]
            }
            // 如果可视区域 大于 1，展示可视区域所有码
                let displayCodes: [CodeItemInfo]
                // 如果扫描时用的原图/降采样图，二维码坐标转换到裁剪后的图片
                let croppedCodes = visibleCodes.map { code in
                    var croppedCode = code
                    croppedCode.position = CGRect(x: code.position.minX - visibleRect.minX,
                                                  y: code.position.minY - visibleRect.minY,
                                                  width: code.position.width,
                                                  height: code.position.height)
                    return croppedCode
                }
                displayCodes = croppedCodes
                return displayCodes
        }
    }

    private static func dynamicLimit(_ setting: SettingService) -> (Int, Double) {
        var limitPixels = 1440 * 2560
        var limitRatio: Double = 3
        if let dynamicSetting = try? setting
            .setting(with: UserSettingKey.make(userKeyLiteral: "image_qr_code_settings")) {
            if let smallSide = dynamicSetting["super_size_small_side"] as? Int,
               let bigSide = dynamicSetting["super_size_big_side"] as? Int {
                limitPixels = smallSide * bigSide
            }
            if let ratio = dynamicSetting["super_ratio"] as? Double {
                limitRatio = ratio
            }
        }
        return (limitPixels, limitRatio)
    }

    private enum ScanImageType {
        case cropped(rect: CGRect)
        case downsampled(size: CGSize)
        case origin
    }

    private static func getScanImageType(image: ImageInfos,
                                         limit: (limitPixels: Int, limitRatio: Double)) throws -> ScanImageType {
        let pixelSize = image.image.pixelSize
        let pixels = Int(pixelSize.width * pixelSize.height)
        guard pixels != 0 else {
            logger.error("Image data is invalid")
            throw ScanError.invalidImageData
        }
        let ratio = { // 长边/短边比
            let whRatio = pixelSize.width / pixelSize.height
            return whRatio < 1 ? 1 / whRatio : whRatio // 前面已经做过不为 0 的防护了
        }()
        // 如果有 visibleRect，且 image 为大图/长图，并且缩放比大于 1，则扫描 visibleRect
        if let visibleRect = image.visibleRect,
           (pixels > limit.limitPixels || ratio >= limit.limitRatio),
           image.zoomFactor > 1 {
            return .cropped(rect: visibleRect)
        } else {
            if pixels > limit.limitPixels {
                let downsampleSize = ImageDecoderUtils.downsampleSize(for: pixelSize,
                                                                      targetPixels: limit.limitPixels)
                return .downsampled(size: downsampleSize)
            } else {
                return .origin
            }
        }
    }
}

// MARK: Public conformances

extension MultiQRCodeScanner.ImageInfos.ImageSource {
    public var description: String {
        switch self {
        case .uiImage(let uiImage):
            return """
                    UIImage(pixelSize: \(uiImage.pixelSize), scale: \(uiImage.scale), \
                    orientation: \(uiImage.imageOrientation.rawValue)), image: \(uiImage)
                    """
        case .data(let data):
            return "Data(\(data.count) bytes, imageSize: \(data.bt.imageSize))"
        }
    }
}

// MARK: Private utils

private extension MultiQRCodeScanner.ImageInfos.ImageSource {

    /// orientation 为 .up 时的大小
    var pixelSize: CGSize {
        switch self {
        case .uiImage(let uiImage):
            return uiImage.pixelSize
        case .data(let data):
            return (try? ImageDecodeBox(data).rotatedPixelSize) ?? .zero
        }
    }

    func safeImage(limitPixels: Int) throws -> UIImage {
        let pixelSize = pixelSize
        let pixels = Int(pixelSize.width * pixelSize.height)
        let downsampleSize = ImageDecoderUtils.downsampleSize(for: pixelSize, targetPixels: limitPixels)
        switch self {
        case .uiImage(let uiImage):
            if pixels > limitPixels {
                let format = UIGraphicsImageRendererFormat()
                format.opaque = true // keep alpha channel
                format.scale = 1 // downsampleSize is px
                return UIGraphicsImageRenderer(size: downsampleSize, format: format).image { _ in
                    uiImage.draw(in: CGRect(origin: .zero, size: downsampleSize))
                }
            } else {
                return uiImage
            }
        case .data(let data):
            do {
                return try ByteImage(data, downsampleSize: downsampleSize)
            } catch {
                MultiQRCodeScanner.logger.error("Image data is invalid: \(error)")
                throw MultiQRCodeScanner.ScanError.invalidImageData
            }
        }
    }
}
private extension MultiQRCodeScanner.ImageInfos {

    /// 是否有区域图
    /// - Throws: 如果处理过程中有异常，会抛出错误
    /// - Returns: 如果有区域图，则返回，没有则返回 nil
    func croppedImage() throws -> UIImage? {
        guard let visibleRect else { return nil }
        if let customDisplayImage = self.customDisplayImage {
            return customDisplayImage
        } else {
            // 如果没有 customDisplayImage，根据 visibleRect 裁剪图片
            switch self.image {
            case .uiImage(let uiImage):
                guard let cgImage = uiImage.cgImage else {
                    throw MultiQRCodeScanner.ScanError.invalidImage
                }
                let rawSize = CGSize(width: cgImage.width, height: cgImage.height)
                let cropRect = ImageDecoderUtils.rawRect(of: visibleRect, in: rawSize,
                                                         orientation: uiImage.imageOrientation)
                guard let croppedCGImage = cgImage.cropping(to: cropRect) else {
                    MultiQRCodeScanner.logger.error("""
                        invalid cropRect: \(cropRect), visibleRect: \(visibleRect), \
                        image: \(rawSize) \(uiImage.imageOrientation)
                        """)
                    throw MultiQRCodeScanner.ScanError.invalidImage
                }
                let croppedUIImage = UIImage(cgImage: croppedCGImage, scale: 1,
                                             orientation: uiImage.imageOrientation)
                return croppedUIImage
            case .data(let data):
                do {
                    let decodeBox = try ImageDecodeBox(data, needCrop: true)
                    let cropRect = ImageDecoderUtils.rawRect(of: visibleRect, in: try decodeBox.pixelSize,
                                                             orientation: try decodeBox.orientation)
                    let croppedImage = try ByteImage(data, cropRect: cropRect)
                    return croppedImage
                } catch {
                    throw MultiQRCodeScanner.ScanError.invalidImageData
                }
            }
        }
    }
}

private extension CGPoint {
    @inline(__always)
    func distance(to point: CGPoint) -> CGFloat {
        return hypot(point.x - x, point.y - y)
    }
}
