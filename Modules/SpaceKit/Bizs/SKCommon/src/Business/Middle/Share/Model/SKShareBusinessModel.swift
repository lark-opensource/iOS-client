//
//  SKShareBusinessModel.swift
//  SKCommon
//
//  Created by ByteDance on 2023/8/10.
//
import Foundation

/* 将该类从SKShareModel中隔离出来,主要存储跟业务关联比较密切的数据,避免破坏SKShareModel的抽象性 */




final public class SKShareQRConfig: NSObject, SKShareQrCodeConfigProtocol {
    public var shareTtile: String
    public var shareQrStr: String
    public var style: SKShareQrCodeViewStyle
    
    init(tilte: String, qrStr: String, style: SKShareQrCodeViewStyle) {
        self.shareTtile = tilte
        self.shareQrStr = qrStr
        self.style = style
        super.init()
    }
}
