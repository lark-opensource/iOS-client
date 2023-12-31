//
//  QRCodeTool+Biz.swift
//  QRCode
//
//  Created by su on 2022/3/23.
//

import UIKit
import Foundation
import LKCommonsLogging

public extension QRCodeTool {
    /// 从图片中扫描二维码
    /// - Parameter img: 要扫描的图片
    @available(*, deprecated, message: "接口已废弃，请直接使用 scanV2")
    class func scan(from img: UIImage, type: QRCodeDecoderType = QRCodeDecoderType()) -> String? {
        var newType = type
        newType.insert(.image)
        let resultCode = QRCodeDecoder(type: newType)?.scanImage(img).code
        if resultCode != nil {
            Self.logger.info("ScanCode.QRCodeTool: scan has result")
        } else {
            Self.logger.info("ScanCode.QRCodeTool: scan result is nil")
        }
        return resultCode
    }
    
    /// 从图片中扫描二维码V2
    /// - Parameters:
    ///   - img: 要扫描的图片
    ///   - enigmaType: 算法类型，默认ve自研算法，自研算法暂不支持多码识别；system算法支持多码识别
    ///   - completionBlock: 扫描结果回调
    class func scanV2(from img: UIImage, enigmaType: ScanEnigmaType = .system, completionBlock: ScanCodeResultsCallBack?) {
        Self.logger.info("ScanCode.QRCodeTool scanV2 img:\(img.size) enigmaType:\(enigmaType)")
        VECodeScanner.scanImageUtil(by: img, enigmaType: enigmaType, completionBlock: completionBlock)
    }

    /// 从图片中扫描二维码V2 - 同步回调(大图识别使用，业务方使用需注意超时逻辑)
    class func scanV2(from img: UIImage, enigmaType: ScanEnigmaType = .system) -> Result<[CodeItemInfo], Error> {
        let semaphore = DispatchSemaphore(value: 0)
        var scanResult: Result<[CodeItemInfo], Error>?
        Self.logger.info("ScanCode.QRCodeTool scanV2 img:\(img.size) enigmaType:\(enigmaType)")
        VECodeScanner.scanImageUtil(by: img, enigmaType: enigmaType) { result in
            scanResult = result
            semaphore.signal()
        }
        let waitResult = semaphore.wait(timeout: .now() + .seconds(4))
        Self.logger.info("ScanCode.QRCodeTool scanV2 finished, result: \((try? scanResult?.get().count) ?? 0)")
        switch waitResult {
        case .success:
            Self.logger.info("ScanCode.QRCodeTool scanV2 success")
            return scanResult ?? .success([])
        case .timedOut:
            Self.logger.info("ScanCode.QRCodeTool scanV2 timedOut")
            return .failure(NSError(domain: "ScanCode.QRCodeTool scan timedOut", code: 000100))
        }
        
    }
}
