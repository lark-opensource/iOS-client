//
//  QRCodeScanManager.swift
//  SKBitable
//
//  Created by zengsenyuan on 2022/9/5.
//  


import SKFoundation
import QRCode
import UniverseDesignToast

enum QRCodeScanScene: String {
    case album
    case camera
}

enum QRCodeScanEvent {
    // 关闭整个扫码
    case close
    // 点击相册
    case clickAlbum
    // 关闭相册
    case closeAlbum
    // 识别成功
    case scanSuccess(content: String, qrType: ScanType, scene: QRCodeScanScene)
    // 识别失败，只有相册有失败事件。
    case scanAlbumFail
}

protocol QRCodeScanManagerDelegate: AnyObject {
    func qrCodeScanDidTrigerEvent(_ event: QRCodeScanEvent)
}

final class QRCodeScanManager: QRCodeViewControllerDelegate {
    
    var currentScene: QRCodeScanScene = .camera
    
    weak var qRCodeVC: ScanCodeViewController?
    
    weak var delegate: QRCodeScanManagerDelegate?
    
    @discardableResult
    func showQRCodeScan(from hostVC: UIViewController) -> UIViewController {
        currentScene = .camera
        let qRCodeVC = ScanCodeViewController(supportTypes: [.all]) { [weak self] text, type in
            guard let self = self else { return }
            DocsLogger.info("QRCodeScanManager showQRCodeScan success: \(text.encryptToShort) type: \(type)")
            self.qRCodeVC?.dismiss(animated: false, completion: nil)
            self.delegate?.qrCodeScanDidTrigerEvent(.scanSuccess(content: text, qrType: type, scene: self.currentScene))
        } didScanFailHandler: { [weak self] error in
            guard let self = self else { return }
            self.currentScene = .camera
            switch error {
            case .pickerCancel:
                self.delegate?.qrCodeScanDidTrigerEvent(.closeAlbum)
                DocsLogger.info("QRCodeScanManager showQRCodeScan didCancelAlbum")
            case .pickerError, .imageScanFailure, .imageToCGImageError, .imageScanNoResult:
                self.delegate?.qrCodeScanDidTrigerEvent(.scanAlbumFail)
                DocsLogger.info("QRCodeScanManager showQRCodeScan error: \(error)")
            }
        } didManualCancelHandler: { _ in
            DocsLogger.info("QRCodeScanManager showQRCodeScan cancel")
        }
        qRCodeVC.modalPresentationStyle = .overFullScreen
        qRCodeVC.delegate = self
        self.qRCodeVC = qRCodeVC
        hostVC.present(qRCodeVC, animated: true, completion: nil)
        return qRCodeVC
    }
    
    func didClickAlbum() {
        self.delegate?.qrCodeScanDidTrigerEvent(.clickAlbum)
        currentScene = .album
    }
    
    func didClickBack() {
        self.delegate?.qrCodeScanDidTrigerEvent(.close)
    }
}
