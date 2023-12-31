//
//  OpenScanCodeModel.swift
//  OPPlugin
//
//  Created by yi on 2021/3/15.
//

import Foundation
import LarkOpenAPIModel
import QRCode

/**
 * 扫码类型
 */
enum OpenScanCodeType: Int {
    case unknow = 0b00
    case barCode = 0b01 // 一维码
    case QRCode = 0b10 // 二维码
    case datamatrix = 0b100 // Data Matrix 码
    case PDF417 = 0b1000 // PDF417 码

}

/**
 * 扫码的结果返回类型
 */
enum OpenScanCodeResType: UInt {
    case QRCode = 0 // 二维码
    case Aztec // 一维码
    case Codabar // 一维码
    case Code_39 // 一维码
    case Code_93 // 一维码
    case Code_128 // 一维码
    case Matrix // 一维码
    case EAN_8 // 一维码
    case EAN_13 // 一维码
    case ITF // 一维码
    case MaxiCode // 一维码
    case PDF_417 // 一维码
    case RSS_14 // 一维码
    case RSS_Expanded // 一维码
    case UPC_E // 一维码
    case PC_EAN_Extension // 一维码
    case WX_code // 二维码
    case Code_25 // 一维码
}

final class OpenAPIScanCodeParams: OpenAPIBaseParams {
    @OpenAPIRequiredParam(userOptionWithJsonKey: "scanType", defaultValue: [])
    var scanType: [String]

    @OpenAPIRequiredParam(userOptionWithJsonKey: "onlyFromCamera", defaultValue: false)
    var onlyFromCamera: Bool

    var barCodeInput: Bool = false

    required init(with params: [AnyHashable: Any]) throws {
        try super.init(with: params)
        if let barCodeInputParam = params["barCodeInput"] as? Bool {
            self.barCodeInput = barCodeInputParam
        } else if let barCodeInputParam = params["barCodeInput"] as? NSNumber {
            self.barCodeInput = (barCodeInputParam.intValue != 0)
        }
    }

    func tranformScanType(scanType: [String]) -> Int {
        var scanCodeType = 0
        if scanType.isEmpty || scanType.contains("qrCode") {
            scanCodeType = scanCodeType | OpenScanCodeType.QRCode.rawValue
        }
        if scanType.isEmpty || scanType.contains("barCode") {
            scanCodeType = scanCodeType | OpenScanCodeType.barCode.rawValue
        }
        if scanType.contains("datamatrix") {
            scanCodeType = scanCodeType | OpenScanCodeType.datamatrix.rawValue
        }
        if scanType.contains("pdf417") {
            scanCodeType = scanCodeType | OpenScanCodeType.PDF417.rawValue
        }
        if scanCodeType == 0 {
            scanCodeType = OpenScanCodeType.QRCode.rawValue | OpenScanCodeType.barCode.rawValue
        }
        return scanCodeType
    }
    
    func tranformScanTypeV2(scanType: [String]) -> [ScanType] {
        var scanTypes:[ScanType] = []
        if scanType.contains("qrCode") {
            scanTypes.append(.qrCode)
        }
        if scanType.contains("barCode") {
            scanTypes.append(.barCode)
        }
        if scanType.contains("datamatrix") {
            scanTypes.append(.dataMatrix)
        }
        if scanType.contains("pdf417") {
            scanTypes.append(.pdf)
        }
        //默认不传都支持
        if scanTypes.isEmpty {
            scanTypes.append(.all)
        }
        return scanTypes
    }

    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_scanType, _onlyFromCamera]
    }

}

final class OpenAPIScanCodeResult: OpenAPIBaseResult {
    var result: String
    init(result: String) {
        self.result = result
        super.init()
    }
    override func toJSONDict() -> [AnyHashable : Any] {
        return ["result": result]
    }
}

