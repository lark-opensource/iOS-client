//
//  WKWebview+BlankCheck.swift
//  Foundation
//
//  Created by haojin tang on 25/07/2022.
//

import WebKit
struct BlankCheckParam {
    var offsetY: Int = 0// 支撑截取部分进行判断（读信title作为同层渲染根据需要可以排除掉）
    var backgroundColors: [UIColor] //支持排除多颜色（读信需要排除白底和灰底）
    var snapConfig: WKSnapshotConfiguration? = nil
    
}
struct BlankCheckRes {
    var is_blank: Int = 0   // 是否白屏（透明占比>0.95或者有其他颜色像素点则判定为白屏）
    var blank_rate: Int = 0   // 白屏占比
    var clear_rate: Int = 0   // 透明像素占比
    var cut_screen_time: Int = 0 // 截屏耗时ms
    var total_time: Int = 0 // 总耗时
}
enum BlankCheckError: Error {
    case TakeSnapshotNoImageError
    case ImageSizeInvaild
    case NoCGImage
    case InitCGContextError
    case ContextHasNoImageData
}
extension BlankCheckError: CustomStringConvertible {
    var description: String {
        switch self {
        case .TakeSnapshotNoImageError:
            return "TakeSnapshotNoImageError"
        case .ImageSizeInvaild:
            return "ImageSizeInvaild"
        case .NoCGImage:
            return "NoCGImage"
        case .InitCGContextError:
            return "InitCGContextError"
        case .ContextHasNoImageData:
            return "ContextHasNoImageData" 
        }
    }
}
extension WKWebView {
    
    /// 是否白屏检测
    /// - Parameters:
    ///   - backgroundColor: 检测使用的基准色。推荐使用 webview.backgroundColor。不允许传入 nil，一旦传入 nil 导致了 Crash 请使用方承担 Crash 责任，需要 revert 代码，写 case study，做复盘，承担事故责任。
    ///   - completionHandler: 检测完成回调
    func mailCheckBlank(param: BlankCheckParam, completionHandler: @escaping (Result<BlankCheckRes, Error>) -> Void) {
        let start = MailTracker.getCurrentTime()
        takeSnapshot(with: param.snapConfig) { image, error in
            let screen_cost = MailTracker.getCurrentTime() - start
            if let error = error {
                MailLogger.error("[blank_check] take webview snapshot error: \(error)")
                completionHandler(.failure(error))
                return
            }
            guard let image = image else {
                completionHandler(.failure(BlankCheckError.TakeSnapshotNoImageError))
                return
            }
            DispatchQueue.global().async {
                do {
                    var res = try BlankDetect.checkWebContentIsBlank(image: image, param: param)
                    res.cut_screen_time = screen_cost
                    res.total_time = MailTracker.getCurrentTime() - start
                    DispatchQueue.main.async {
                        completionHandler(.success(res))
                    }
                } catch {
                    MailLogger.error("[blank_check] check image blank error:\(error)")
                    DispatchQueue.main.async {
                        completionHandler(.failure(error))
                    }
                }
            }
        }
    }
}

/// 白屏检测算法
private final class BlankDetect {
    struct RGBNode {
        var r: UInt32 = 0
        var g: UInt32 = 0
        var b: UInt32 = 0
        var a: UInt32 = 0
    }
    /// 检测是否白屏
    /// - Parameters:
    ///   - image: 需要检测的图片
    ///   - color: 背景色
    /// - Throws: 白屏检测中发生的错误
    /// - Returns: 结果
    class func checkWebContentIsBlank(image: UIImage, param: BlankCheckParam) throws -> BlankCheckRes {
        var contextImage = image
        let rgbMaxVal: CGFloat = 255
        // 需要先裁剪图片
        if param.offsetY > 0 {
            if let cgImage = image.cgImage?.cropping(to: CGRect(x: 0,
                                                                y: CGFloat(param.offsetY) * image.scale,
                                                                width: image.size.width * image.scale,
                                                                height: (image.size.height - CGFloat(param.offsetY)) * image.scale)) {
                contextImage = UIImage(cgImage: cgImage)
            }
        }
        var nodeArray:[RGBNode] = []
        let clearNode = RGBNode()
        nodeArray.append(clearNode)
        for color in param.backgroundColors {
            var (r, g, b, a) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            let node = RGBNode(r: UInt32(r * rgbMaxVal), g: UInt32(g * rgbMaxVal), b: UInt32(b * rgbMaxVal), a: UInt32(a * rgbMaxVal))
            nodeArray.append(node)
        }
        // 缩小到原来的 1/3 大，在保证准确率的情况下减少需要遍历像素点的数量
        let width: Int = Int(contextImage.size.width / 3)
        let height: Int = Int(contextImage.size.height / 3)
        guard width > 5, height > 5 else {
            throw BlankCheckError.ImageSizeInvaild
        }
        guard let cgImage = contextImage.cgImage else {
            throw BlankCheckError.NoCGImage
        }
        
        let colorSpaceRef = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageByteOrderInfo.order32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        var perRow = 0
        if FeatureManager.open(.mailCheckBlankOptDisable) {
            perRow = 4 * width
        }
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: perRow,
            space: colorSpaceRef,
            bitmapInfo: bitmapInfo
        ) else {
            throw BlankCheckError.InitCGContextError
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = context.data else {
            throw BlankCheckError.ContextHasNoImageData
        }
        var otherCount: UInt = 0
        var clearColorCount: Int = 0
        let totalCount = Double(width * height)
        let ctxData: UnsafeMutablePointer<UInt8> = data.bindMemory(to: UInt8.self, capacity: width * height)
        for i in 0..<height {
            for j in 0..<width {
                let pixelIndex = i * width * 4 + j * 4
                let _r = ctxData[pixelIndex]
                let _g = ctxData[pixelIndex + 1]
                let _b = ctxData[pixelIndex + 2]
                let _a = ctxData[pixelIndex + 3]
                var includeColor = false
                for node in nodeArray {
                    if _r == node.r && _g == node.g && _b == node.b && _a == node.a {
                        includeColor = true
                        break
                    }
                }
                var clearNode = false
                if _r == 0 && _g == 0 && _b == 0 && _a == 0 {
                    clearColorCount += 1
                    clearNode = true
                }
                if !includeColor && !clearNode {
                    otherCount += 1
                }
                
            }
        }
        var res = BlankCheckRes()
        res.blank_rate = Int((1 - Double(otherCount) / totalCount) * 1000)
        res.clear_rate = Int((Double(clearColorCount) / totalCount) * 1000)
        // 有其他点说明不是白屏(排除透明点),排除全部透明的异常case
        if otherCount <= 0 && res.clear_rate != 1000 {
            res.is_blank = 1
        }
        return res
    }
}
