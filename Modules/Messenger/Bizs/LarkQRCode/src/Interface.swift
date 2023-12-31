//
//  Interface.swift
//  LarkQRCode
//
//  Created by Supeng on 2020/12/4.
//

import UIKit
import Foundation
import EENavigator
import LarkUIKit
import Swinject

var forcePresentURLs: [String] = []

/// 添加强制presentURL
public func appendForcePresentURL(_ urlString: String) {
    forcePresentURLs.append(urlString)
}

/*
 二维码扫描分析回调
 HandleStatus - 二维码扫描结果状态
 (() -> Void) - 回调内部会处理一些逻辑，处理完成之后会调用此回调
 */
public typealias QRCodeAnalysisCallBack = ((HandleStatus, (() -> Void)?) -> Void)?

// 扫码
public struct QRCodeControllerBody: CodablePlainBody {
    public static let pattern = "//client/scan"

    public var firstDescribeText: String? /// 二维码扫描框下的第一行描述文本
    public var secondDescribeText: String? /// 二维码扫描框下的第二行描述文本
    public init(firstDescribeText: String? = nil, secondDescribeText: String? = nil) {
        self.firstDescribeText = firstDescribeText
        self.secondDescribeText = secondDescribeText
    }
}

public enum QRCodeFromType {
    case camera /// 相机扫描
    case album /// 从相册选取扫描
    case pressImage /// 长按图片识别
}

public protocol QRCodeAnalysisService {
    func handle(code: String, status: QRCodeAnalysisCallBack, from: QRCodeFromType, fromVC: UIViewController)
}

public enum HandleStatus {
    case preFinish
    case fail(errorInfo: String?)
}

public struct QRCodeDetectLinkBody: CodablePlainBody {
    public static let pattern = "//client/detectLink"

    public let code: String
    public init(code: String) {
        self.code = code
    }
}
