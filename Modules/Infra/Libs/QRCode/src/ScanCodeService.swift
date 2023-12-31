//
//  QRCodeViewController.swift
//  Lark
//
//  Created by zc09v on 2017/4/19.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit

public protocol ScanCodeViewControllerType where Self: BaseUIViewController {
    // Old
    var lifeCircle: QRCodeViewControllerLifeCircle? { get set }

    var firstDescribelText: String? { get set }
    var secondDescribelText: String? { get set }

    var didScanQRCodeBlock: ((String, VEQRCodeFromType) -> Void)? { get set }

    func startScanning()
    func stopScanning()

    // New
    var supportTypes: [ScanType]? { get set }
    var didScanSuccessHandler: ((String, ScanType) -> Void)? { get set }
    var didScanFailHandler: ((QRScanError) -> Void)? { get set }
    var didManualCancelHandler: ((ScanType) -> Void)? { get set }
}

public typealias ScanCodeResultsCallBack = ((Result<[CodeItemInfo], Error>) -> Void)

public struct CodeItemInfo: CustomStringConvertible {
    /// 目前使用 MultiQRCodeScanner.pickCode 会改变此属性。如果之后要回调给业务方，需要做改造
    var position: CGRect
    public var content: String
    public var type: ScanType

    public var description: String {
        var safeContent = ""
        #if DEBUG // content 有 UGC，线上不打印
        safeContent = " content: \(content),"
        #endif
        return "\(Self.self)(position: \(position),\(safeContent) type: \(type))"
    }
}

/// 扫描算法类型
public enum ScanEnigmaType: Int, Codable {
    /// 三方系统算法
    case system
    /// VE自研算法
    case veOwner
}

public enum QRScanError: Error {
    // 退出picker
    case pickerCancel
    // 图片问题/网络问题
    case pickerError
    // 图中未识别到二维码
    case imageScanFailure(Error)
    // 算法未识别出结果
    case imageScanNoResult
    // 图片转为CG格式错误
    case imageToCGImageError
}

public enum ScanType: Int {
    case unkonwn = 0b00000
    case qrCode = 0b00001
    case barCode = 0b00010
    case dataMatrix = 0b00100
    case pdf = 0b01000
    case all = 0b10000
}

public struct ScanCodeType: OptionSet {
    public let rawValue: Int

    public init(
        rawValue: Int
    ) {
        self.rawValue = rawValue
    }
    public static let unknown = ScanCodeType(rawValue: 0)
    public static let qrCode = ScanCodeType(rawValue: 1 << 0)
    public static let barCode = ScanCodeType(rawValue: 1 << 1)
    public static let dataMatrix = ScanCodeType(rawValue: 1 << 2)
    public static let pdf = ScanCodeType(rawValue: 1 << 3)
}

public protocol QRCodeViewControllerDelegate: AnyObject {
    func didClickAlbum()
    func didClickBack()
}

public extension QRCodeViewControllerDelegate {
    /// optional didClickAlbum() placeholder
    func didClickAlbum() { }
    /// optional didClickBack() placeholder
    func didClickBack() { }
}

final class AtomicBool: NSLock {
    private var _value: Bool
    public init(_ value: Bool = false) {
        self._value = value
    }

    func set(value: Bool) {
        defer { unlock() }
        self.lock()
        _value = value
    }

    var value: Bool {
        defer { unlock() }
        self.lock()
        return _value
    }
}

/// Life circle state
public enum QRCodeLifeCircleState {
    /// . start
    case start
    /// end
    case end
}
/// QRCode life circle handlers
public protocol QRCodeViewControllerLifeCircle: AnyObject {
    /// On view controller initilize
    /// - Parameter state: State
    func onInit(state: QRCodeLifeCircleState)

    /// On viewDidLoad
    /// - Parameter state: State
    func onViewDidLoad(state: QRCodeLifeCircleState)

    /// On camera ready to scan qrcode
    /// - Parameter state: State
    func onCameraReady(state: QRCodeLifeCircleState)

    /// On error
    /// - Parameter state: QRCodeError
    func onError(_ error: Error)
}

public enum VEQRCodeFromType {
    case camera
    case album
}

public enum QRCodeError: Error {
    case invalidCameraDevice
    case noCameraAccess

    public var code: Int {
        switch self {
        case .invalidCameraDevice:
            return 404
        case .noCameraAccess:
            return 401
        }
    }
}
