//
//  QRCodeMock.swift
//  QRCode
//
//  Created by su on 2022/3/22.
//

import UIKit
import Foundation
import LarkUIKit

open class ScanCodeViewController: BaseUIViewController, ScanCodeViewControllerType {
    public var lifeCircle: QRCodeViewControllerLifeCircle?

    public var firstDescribelText: String?

    public var secondDescribelText: String?

    public func stopScanning() {
    }

    public var supportTypes: [ScanType]?

    public var didScanSuccessHandler: ((String, ScanType) -> Void)?

    public var didScanFailHandler: ((QRScanError) -> Void)?

    public var didManualCancelHandler: ((ScanType) -> Void)?

    public var didScanQRCodeBlock: ((String, VEQRCodeFromType) -> Void)?

    public weak var delegate: QRCodeViewControllerDelegate?

    public init(
        supportTypes: [ScanType] = [.all],
        didScanSuccessHandler: ((String, ScanType) -> Void)? = nil,
        didScanFailHandler: ((QRScanError) -> Void)? = nil,
        didManualCancelHandler: ((ScanType) -> Void)? = nil,
        isFullScreen: Bool = true
    ) {
        super.init(nibName: nil, bundle: nil)
    }

    public init(
        type: ScanCodeType = .qrCode,
        lifeCircle: QRCodeViewControllerLifeCircle? = nil,
        isFullScreen: Bool = true
    ) {
        super.init(nibName: nil, bundle: nil)
    }
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func startScanning() {}
}
