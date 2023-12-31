//
//  LarkWebView+BlankCheck.swift
//  LarkWebViewContainer
//
//  Created by lijuyou on 2020/9/4.
//

import Foundation
import WebKit
import ECOInfra
import LarkSetting

/// Tips：白屏中的“白”不单纯指白色，这里是空白的意思
/// 白屏检测详细数据
struct BlankDetectRate {
    /// 白点的比例（如 1/1000 为1000个点有1个为白点）
    public let blankPixelsRate: Double
    /// 纯透明点的比例 （如 1/1000 为1000个点有1个为透明点）
    public let lucencyPixelsRate: Double
}

///线上稳定后，与 BlankDetectRate 合并
public struct PureDetectRate {
    /// 白点的比例（如 1/1000 为1000个点有1个为白点）
    public let blankPixelsRate: Double
    /// 纯透明点的比例 （如 1/1000 为1000个点有1个为透明点）
    public let lucencyPixelsRate: Double
    /// 占比最多的纯色颜色
    public let maxPureColor : String
    /// 最多的纯色颜色占比
    public let maxPureColorRate : Double
}


extension LarkWebView {
    /// 是否白屏检测
    /// - Parameters:
    ///   - backgroundColor: 检测使用的基准色。推荐使用 webview.backgroundColor。不允许传入 nil，一旦传入 nil 导致了 Crash 请使用方承担 Crash 责任，需要 revert 代码，写 case study，做复盘，承担事故责任。
    ///   - completionHandler: 检测完成回调
    public func checkBlank(backgroundColor: UIColor, completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        takeSnapshot(with: nil) { image, error in
            if let error = error {
                logger.error("take webview snapshot error", error: error)
                completionHandler(.failure(error))
                return
            }
            guard let image = image else {
                completionHandler(.failure(OPError.error(monitorCode: BlankDetectMonitorCode.takeSnapshotNoImage)))
                return
            }
            DispatchQueue.global().async {
                do {
                    var isBlank = false
                    if FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.larkwebview.checkblank.purecolor.disable")) {// user:global
                        ///原线上逻辑, Pro Max和iPad上，内容少的情况误判白屏偏多
                        isBlank = try BlankDetect.checkWebContentIsBlank(image: image, color: backgroundColor)
                        logger.info("check web content is blank")
                    } else {
                        isBlank = try BlankDetect.checkWebContentIsBlankPureColor(image: image, color: backgroundColor)
                        logger.info("check web content is blank pure color")
                    }
                    DispatchQueue.main.async {
                        completionHandler(.success(isBlank))
                    }
                } catch {
                    logger.error("check image blank error", error: error)
                    DispatchQueue.main.async {
                        completionHandler(.failure(error))
                    }
                }
            }
        }
    }
    
    /// DOM数量检测
    public func checkContentDOM(completionHandler: @escaping (Result<Int, Error>) -> Void) {
        let start = CFAbsoluteTimeGetCurrent()
        let script = "document.body.getElementsByTagName('div').length"
        evaluateJavaScript(script) { result, error in
            let duration = Int((CFAbsoluteTimeGetCurrent() - start) * 1000)
            if let error = error {
                logger.error("check webview dom error, duration:\(duration)", error: error)
                completionHandler(.failure(error))
                return
            }
            
            guard let count = result as? Int else {
                logger.error("fail to check webview content DOM")
                completionHandler(.failure(OPError.error(monitorCode: BlankDetectMonitorCode.failToCheckContentDOM)))
                return
            }
            
            logger.info("check webview dom success, count: \(count), mainThread:\(Thread.isMainThread), duration:\(duration)")
            completionHandler(.success(count))
        }
    }
    
    
    /// 检测纯色比例，原因见： https://bytedance.feishu.cn/docs/doccnJ4RU3itXPnX24lbYnnIYCd
    public func checkPureRate(backgroundColor: UIColor, _ completionHandler: @escaping (Result<PureDetectRate, Error>) -> Void) {
        takeSnapshot(with: nil) { image, error in
            if let error = error {
                logger.error("take webview snapshot error", error: error)
                completionHandler(.failure(error))
                return
            }
            guard let image = image else {
                completionHandler(.failure(OPError.error(monitorCode: BlankDetectMonitorCode.takeSnapshotNoImage)))
                return
            }
            DispatchQueue.global().async {
                do {
                    let rate = try BlankDetect.checkWebContentPureColorRate(image: image, color: backgroundColor)
                    DispatchQueue.main.async {
                        completionHandler(.success(rate))
                    }
                } catch {
                    logger.error("check image blank error", error: error)
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
    /// 检测是否白屏
    /// - Parameters:
    ///   - image: 需要检测的图片
    ///   - color: 背景色
    /// - Throws: 白屏检测中发生的错误
    /// - Returns: 结果
    class func checkWebContentIsBlank(image: UIImage, color: UIColor) throws -> Bool {
        var (r, g, b, a) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = UInt32(r * 255)
        let gi = UInt32(g * 255)
        let bi = UInt32(b * 255)
        let ai = UInt32(a * 255)
        // 缩小到原来的 1/6 大，在保证准确率的情况下减少需要遍历像素点的数量
        let width = Int(image.size.width / 6)
        let height = Int(image.size.height / 6)
        guard width > 0, height > 0 else {
            throw OPError.error(monitorCode: BlankDetectMonitorCode.imageSizeInvaild)
        }
        guard let cgImage = image.cgImage else {
            throw OPError.error(monitorCode: BlankDetectMonitorCode.noCGImage)
        }
        let colorSpaceRef = CGColorSpaceCreateDeviceRGB()
        //顺序 + rgba => rgba，对应下面的取值对比
        let bitmapInfo = CGImageByteOrderInfo.order32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        //CGContext的data传nil, 应取0自动计算
        let bytesPerRow = 0
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpaceRef,
            bitmapInfo: bitmapInfo
        ) else {
            throw OPError.error(monitorCode: BlankDetectMonitorCode.initCGContextError)
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = context.data else {
            throw OPError.error(monitorCode: BlankDetectMonitorCode.contextHasNoImageData)
        }

        var clearColorCount: UInt = 0
        var otherCount: UInt = 0
        // 如果存在大于总像素点的5%个非背景像素点则认为不是白屏
        let availableCount = Int(Double(width * height) * 0.05)
        // 如果存在大于总像素点的95%个透明像素点则认为是白屏
        let limitCount = Int(Double(width * height) * 0.95)
        let ctxData: UnsafeMutablePointer<UInt8> = data.bindMemory(to: UInt8.self, capacity: width * height)
        for i in 0..<height {
            for j in 0..<width {
                let pixelIndex = i * width * 4 + j * 4
                let _r = ctxData[pixelIndex]
                let _g = ctxData[pixelIndex + 1]
                let _b = ctxData[pixelIndex + 2]
                let _a = ctxData[pixelIndex + 3]

                if _r != ri || _g != gi || _b != bi || _a != ai {
                    otherCount += 1
                }

                if _r == 0 && _g == 0 && _b == 0 && _a == 0 {
                    clearColorCount += 1
                }

                if otherCount > availableCount && clearColorCount != otherCount {
                    return false
                }

                if clearColorCount >= limitCount {
                    return true
                }
            }
        }
        return true
    }
    
    /// 检测是否白屏(纯色)(对齐Android白屏(纯色)检测)
    /// - Parameters:
    ///   - image: 需要检测的图片
    ///   - color: 背景色
    /// - Throws: 检测中发生的错误
    /// - Returns: 结果
    class func checkWebContentIsBlankPureColor(image: UIImage, color: UIColor) throws -> Bool {
        var (r, g, b, a) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = UInt32(r * 255)
        let gi = UInt32(g * 255)
        let bi = UInt32(b * 255)
        let ai = UInt32(a * 255)
        // 宽高都缩小到原来的 1/6
        let width = Int(image.size.width / 6)
        let height = Int(image.size.height / 6)
        guard width > 0, height > 0 else {
            throw OPError.error(monitorCode: BlankDetectMonitorCode.imageSizeInvaild)
        }
        guard let cgImage = image.cgImage else {
            throw OPError.error(monitorCode: BlankDetectMonitorCode.noCGImage)
        }
        
        let colorSpaceRef = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageByteOrderInfo.order32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpaceRef,
            bitmapInfo: bitmapInfo
        ) else {
            throw OPError.error(monitorCode: BlankDetectMonitorCode.initCGContextError)
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = context.data else {
            throw OPError.error(monitorCode: BlankDetectMonitorCode.contextHasNoImageData)
        }
        
        var otherCount: Int = 0
        let ctxData: UnsafeMutablePointer<UInt8> = data.bindMemory(to: UInt8.self, capacity: width * height)
        let optimizeEnable = FeatureGatingManager.shared.featureGatingValue(with: FeatureGatingManager.Key(stringLiteral: "openplatform.webbrowser.delayrelease.optimize.enable"))// user:global
        for i in 0..<height {
            for j in 0..<width {
                let pixelIndex = i * width * 4 + j * 4
                let r = ctxData[pixelIndex]
                let g = ctxData[pixelIndex + 1]
                let b = ctxData[pixelIndex + 2]
                let a = ctxData[pixelIndex + 3]
                
                ///剔除非透明像素点(截图API和缩放会带入透明像素点)
                if r == 0 && g == 0 && b == 0 && a == 0 {
                    continue
                }
                
                if optimizeEnable {
                    if !similarColorValue(Int(r), Int(ri)) || !similarColorValue(Int(g), Int(gi)) || !similarColorValue(Int(b), Int(bi)) || !similarColorValue(Int(a), Int(ai)) {
                        otherCount += 1
                    }
                } else {
                    if r != ri || g != gi || b != bi || a != ai {
                        otherCount += 1
                    }
                }
     
                ///otherCount: 非背景像素、非透明像素点的数量
                if (otherCount >= 1) {
                #if DEBUG
                    print("check blank end, has other pixel")
                #endif
                    return false
                }
            }
        }
    #if DEBUG
        print("check blank end, other pixel count: \(otherCount)")
    #endif
        return true
    }

    class func similarColorValue(_ value1: Int, _ value2: Int) -> Bool {
        return abs(value1 - value2) <= 1
    }
        
    class func checkWebContentPureColorRate(image: UIImage, color: UIColor) throws -> PureDetectRate {
        var (r, g, b, a) = (CGFloat(0), CGFloat(0), CGFloat(0), CGFloat(0))
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        let ri = UInt32(r * 255)
        let gi = UInt32(g * 255)
        let bi = UInt32(b * 255)
        let ai = UInt32(a * 255)
        // 缩小到原来的 1/6 大，在保证准确率的情况下减少需要遍历像素点的数量
        let width = Int(image.size.width / 6)
        let height = Int(image.size.height / 6)
        guard width > 0, height > 0 else {
            throw OPError.error(monitorCode: BlankDetectMonitorCode.imageSizeInvaild)
        }
        guard let cgImage = image.cgImage else {
            throw OPError.error(monitorCode: BlankDetectMonitorCode.noCGImage)
        }
        let colorSpaceRef = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageByteOrderInfo.order32Big.rawValue | CGImageAlphaInfo.premultipliedFirst.rawValue
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpaceRef,
            bitmapInfo: bitmapInfo
        ) else {
            throw OPError.error(monitorCode: BlankDetectMonitorCode.initCGContextError)
        }
        context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
        guard let data = context.data else {
            throw OPError.error(monitorCode: BlankDetectMonitorCode.contextHasNoImageData)
        }

        var clearColorCount: Int = 0
        var otherCount: Int = 0
        let totalCount = Double(width * height)
        let ctxData: UnsafeMutablePointer<UInt8> = data.bindMemory(to: UInt8.self, capacity: width * height)
        var pureColorDic = [String: Int]()
        for i in 0..<height {
            for j in 0..<width {
                let pixelIndex = i * width * 4 + j * 4
                let r = ctxData[pixelIndex]
                let g = ctxData[pixelIndex + 1]
                let b = ctxData[pixelIndex + 2]
                let a = ctxData[pixelIndex + 3]

                if r != ri || g != gi || b != bi || a != ai {
                    otherCount += 1
                }

                if r == 0 && g == 0 && b == 0 && a == 0 {
                    clearColorCount += 1
                }
                ///加入纯色检测字典，因为进行过缩小1/6，且小程序场景颜色基本比较类似，实测key不会过大，具体可见：https://bytedance.feishu.cn/docs/doccnJ4RU3itXPnX24lbYnnIYCd
                let key = String(format: "r%dg%db%da%d", r,g,b,a)
                if let currentValue = pureColorDic[key]{
                    pureColorDic[key] = currentValue + 1
                } else {
                    pureColorDic[key] = 1
                }
            }
        }
        let max_values = pureColorDic.max{a,b in a.value < b.value}
        guard let maxPureColor = max_values?.key, let maxPureColorCount = max_values?.value else {
            throw OPError.error(monitorCode: BlankDetectMonitorCode.failToDetectPureColor)
        }

        return PureDetectRate(blankPixelsRate: (totalCount - Double(otherCount)) / totalCount, lucencyPixelsRate: Double(clearColorCount) / totalCount, maxPureColor: maxPureColor , maxPureColorRate:(Double(maxPureColorCount)/totalCount))
    }

}
