import Foundation
import LarkOpenAPIModel
import LKCommonsLogging
import QRCode
import SKFoundation

final class FormsScanCodeResult: OpenAPIBaseResult {
    
    let result: String
    
    init(result: String) {
        self.result = result
        super.init()
        
    }
    
    override func toJSONDict() -> [AnyHashable: Any] {
        [
            "result": result,
            "text": result, // 兼容独立容器
        ]
    }
}

// MARK: - ScanCode
extension FormsDevice {
    
    func scanCode(
        vc: UIViewController,
        success: @escaping (FormsScanCodeResult) -> Void,
        cancel: @escaping () -> Void
    ) {
        let scanController = ScanCodeViewController(supportTypes: [.all])
        
        scanController.didScanSuccessHandler = { [weak scanController] detectedCode, scanType in
            Self.logger.info("scanCode success and scanType is \(scanType)")
            scanController?.dismiss(animated: true)
            success(FormsScanCodeResult(result: detectedCode))
        }
        
        //qrError是扫码界面打开相册后识别错误，扫码仍在正常工作，不需要callback
        scanController.didScanFailHandler = { qrError in
            var errMsg = ""
            
            switch qrError {
            case QRScanError.pickerCancel :
                errMsg = "QRScanError.pickerCancel"
            case QRScanError.pickerError :
                errMsg = "QRScanError.pickerError"
            case QRScanError.imageScanFailure(_) :
                errMsg = "QRScanError.imageScanFailure"
            case QRScanError.imageScanNoResult:
                errMsg = "QRScanError.imageScanNoResult"
            case QRScanError.imageToCGImageError:
                errMsg = "QRScanError.imageToCGImageError"
            }
            
            Self.logger.error(errMsg)
        }
        
        //扫码界面用户主动取消
        scanController.didManualCancelHandler = { _ in
            let msg = "user cancel scanCode"
            Self.logger.info(msg)
            cancel()
        }
        
        scanController.modalPresentationStyle = .fullScreen
        
        vc.present(scanController, animated: true)
    }
    
}
