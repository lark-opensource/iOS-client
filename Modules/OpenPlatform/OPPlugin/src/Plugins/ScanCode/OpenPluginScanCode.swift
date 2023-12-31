//
//  OpenPluginScanCode.swift
//  OPPlugin
//
//  Created by yi on 2021/3/15.
//

import Foundation
import LarkOpenPluginManager
import LarkOpenAPIModel
import OPPluginManagerAdapter
import ECOProbe
import UIKit
import SnapKit
import QRCode
import UniverseDesignIcon
import OPPluginBiz
import LarkContainer

final class OpenPluginScanCode: OpenBasePlugin, TMAScanCodeControllerProtocol {

    var isScanningCode: Bool = false
    typealias ResultCallback = (_ isCanceled: Bool, _ detectedCode: String, _ type: OpenScanCodeResType)->Void
    var scanCodeCallback: ((OpenAPIBaseResponse<OpenAPIScanCodeResult>) -> Void)?
    var resultCallback: ResultCallback?
    func scanCode(params: OpenAPIScanCodeParams, context: OpenAPIContext, callback: @escaping (OpenAPIBaseResponse<OpenAPIScanCodeResult>) -> Void) {
        if isScanningCode {
            let error = OpenAPIError(code: OpenScanCodeErrorCode.scanCodeRunning)
                .setErrno(OpenAPIScanCodeErrno.scanning)
                .setOuterMessage(BundleI18n.OPPlugin.scan_code_running())
            callback(.failure(error: error))
            return
        }
        isScanningCode = true

        guard let controller = (context.gadgetContext)?.controller else {
            context.apiTrace.error("gadgetContext is nil")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setErrno(OpenAPICommonErrno.internalError)
                .setMonitorMessage("gadgetContext is nil")
            callback(.failure(error: error))
            return
        }
        guard let topMost = OPNavigatorHelper.topMostAppController(window: controller.view.window) else {
            context.apiTrace.error("fond no top most appController for \(controller)")
            let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                .setErrno(OpenAPICommonErrno.internalError)
                .setMonitorMessage("fond no top most appController for \(controller)")
            callback(.failure(error: error))
            return
        }
        //埋点
        OpenScanCodeMonitorUtils.report(scanType: params.scanType, context: context)
        
        //兜底开关，默认不打开，走主端新scanCode
        let newScanCodeAbilityDisabled = EMAFeatureGating.boolValue(forKey: "openplatform.api.scan_code_update_disable")
        context.apiTrace.info("scanCode, scanType=\(params.scanType), onlyFromCamera=\(params.onlyFromCamera), barCodeInput=\(params.barCodeInput), newScanCodeAbilityDisabled:\(newScanCodeAbilityDisabled)")

        if !newScanCodeAbilityDisabled {
            scanCodeCallback = callback

            let scanTypes = params.tranformScanTypeV2(scanType: params.scanType)
            let isShowInputView = (scanTypes.contains(.barCode) || scanTypes.contains(.all)) && params.barCodeInput
            let scanController = ScanCodeViewController(supportTypes: scanTypes)
            //手动输入条形码View注入到扫码界面
            if isShowInputView {
                injectCustomerViewToScanVC(scanController: scanController, callback: callback)
            }
            //扫码成功
            scanController.didScanSuccessHandler = {[weak self, weak controller] detectedCode, scanType in
                guard let self = self, let vc = controller else {
                    let apiError = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage("scanController didScanSuccessHandler controller nil")
                    callback(.failure(error: apiError))
                    return
                }
                self.isScanningCode = false
                context.apiTrace.info("scanController didScanSuccess resultLength:\(detectedCode.count)")
                
                vc.dismiss(animated: true) {
                    callback(.success(data: OpenAPIScanCodeResult(result: detectedCode)))
                }
            }
            //qrError是扫码界面打开相册后识别错误，扫码仍在正常工作，不需要callback
            scanController.didScanFailHandler = { qrError in
                var errMsg = ""
                switch qrError {
                case QRScanError.pickerCancel :
                    errMsg = "相册用户取消"
                case QRScanError.pickerError :
                    errMsg = "相册图片问题/网络问题"
                case QRScanError.imageScanFailure(_) :
                    errMsg = "相册图中未识别到二维码"
                case QRScanError.imageScanNoResult:
                    errMsg = "相册图中无二维码"
                case QRScanError.imageToCGImageError:
                    errMsg = "相册图中Image转CGImage失败"
                @unknown default:
                    errMsg = "相册unknow错误"
                }
                context.apiTrace.error("scanController album error:\(errMsg)")
            }
            //扫码界面用户主动取消
            scanController.didManualCancelHandler = {[weak self] _ in
                self?.isScanningCode = false
                let apiError = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setErrno(OpenAPIScanCodeErrno.userCanceled)
                    .setOuterMessage("user cancel")
                context.apiTrace.error("scanController user manualCancel")
                callback(.failure(error: apiError))
            }
            scanController.modalPresentationStyle = .fullScreen
            controller.present(scanController, animated: true, completion: nil)

        } else {
            let scanCodeType = params.tranformScanType(scanType: params.scanType)
            guard let scanController = TMAScanCodeController(scanType: BDPScanCodeType(rawValue: scanCodeType), onlyFromCamera: params.onlyFromCamera, barCodeInput: params.barCodeInput) else {
                context.apiTrace.error("can not generate scanController for scan type \(scanCodeType)")
                let error = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                    .setErrno(OpenAPICommonErrno.internalError)
                    .setMonitorMessage("an not generate scanController for scan type \(scanCodeType)")
                callback(.failure(error: error))
                return
            }
            scanCodeWithScanModel(scanCodeController: scanController, hostController: topMost) { [weak self] (canceled, detectedCode, type) in
                self?.isScanningCode = false
                if canceled {
                    // 原逻辑为 userCancel, CommoneErrorCode 不应当包含 userCancel（因为每个 API 场景含义不同）。
                    // 目前 APICode 整体还未开放，如果需要，业务应当在自己的业务 code 中专门定义。
                    // 三端一致会统一 CommoneCode，此处统一替换为 internalError，但仍然保持原 outerMessage 不变。
                    let apiError = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setErrno(OpenAPIScanCodeErrno.userCanceled)
                        .setOuterMessage("user cancel")
                    callback(.failure(error: apiError))
                    return
                }
                callback(.success(data: OpenAPIScanCodeResult(result: detectedCode)))
            }
        }
        
    }
    
    func injectCustomerViewToScanVC(scanController: ScanCodeViewController, callback: @escaping (OpenAPIBaseResponse<OpenAPIScanCodeResult>) -> Void){
        let customView = ScanCodeCustomView()
        customView.clickHandler = {[weak scanController] in
            if let scanController = scanController {
                guard let alertVC = EMAAlertController(title: BDPI18n.scan_please_enter_barcode, message: nil, preferredStyle: .alert) else{
                    let apiError = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                        .setMonitorMessage("alertVC init fail")
                    callback(.failure(error: apiError))
                    return
                }
                alertVC.addTextField(configurationHandler: { textField in
                    textField?.clearButtonMode = .whileEditing
                    textField?.placeholder = BDPI18n.scan_please_enter_barcode
                })
                alertVC.addAction(EMAAlertAction(title: BDPI18n.confirm, style: .default, handler: { [weak self, weak scanController, weak alertVC] action in
                    guard let self = self, let scanController = scanController,let alertVC = alertVC else{
                        let apiError = OpenAPIError(code: OpenAPICommonErrorCode.internalError)
                            .setMonitorMessage("alertVC addAction handler scanController or alertVC nil")
                        callback(.failure(error: apiError))
                        return
                    }
                    if let text = alertVC.textFields?.first?.text, !text.isEmpty {
                        self.isScanningCode = false
                        callback(.success(data: OpenAPIScanCodeResult(result: text)))
                        scanController.dismiss(animated: true, completion: nil)
                    }
                }))
                scanController.present(alertVC, animated: true, completion: nil)
            }
        }
        scanController.customView.addSubview(customView)
        var safeAreaBottom:CGFloat = 0.0
        var height:CGFloat = 60
        if let window = OPWindowHelper.fincMainSceneWindow() {
            safeAreaBottom = window.safeAreaInsets.bottom
        }
        if safeAreaBottom > 0 {
            height = 80
        }
        let bottomMargin:CGFloat = safeAreaBottom + 82.0 + 80.0
        customView.snp.makeConstraints { make in
            make.centerX.width.equalToSuperview()
            make.height.equalTo(height)
            make.bottom.equalToSuperview().offset(-bottomMargin)
        }
    }

    // 扫描二维码的功能
    func scanCodeWithScanModel(scanCodeController: TMAScanCodeController, hostController: UIViewController, completion: @escaping ResultCallback) -> Void {
        resultCallback = completion
        scanCodeController.delegate = self
        let navi = UINavigationController(rootViewController: scanCodeController)
        navi.modalPresentationStyle = .overFullScreen
        navi.navigationBar.isTranslucent = false
        hostController.present(navi, animated: true, completion: nil)
    }

    func scanCodeController(_ controller: TMAScanCodeController, didDetectCode code: String, type: TMAScanCodeType) {
        if code.count > 0 {
            resultCallback?(false, code, OpenScanCodeResType(rawValue: type.rawValue) ?? OpenScanCodeResType.QRCode)
        } else {
            resultCallback?(true, "", OpenScanCodeResType(rawValue: type.rawValue) ?? OpenScanCodeResType.QRCode)
        }
        resultCallback = nil
        controller.dismissSelf()
    }

    func didDismiss(_ controller: TMAScanCodeController) {
        resultCallback?(true, "", OpenScanCodeResType.QRCode)
        resultCallback = nil
    }

    required init(resolver: UserResolver) {
        super.init(resolver: resolver)
        registerInstanceAsyncHandler(for: "scanCode", pluginType: Self.self, paramsType: OpenAPIScanCodeParams.self, resultType: OpenAPIScanCodeResult.self) { (this, params, context, callback) in
            
            this.scanCode(params: params, context: context, callback: callback)
        }
    }
}

typealias CustomViewClickHandler = () -> Void

final class ScanCodeCustomView: UIView {
    private var tipLabel = UILabel()
    private var iconImageView = UIImageView()
    private var inputCodeButton = UIButton(type: .custom)
    var clickHandler: CustomViewClickHandler?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.addSubview(inputCodeButton)
        inputCodeButton.addTarget(self, action: #selector(inputCodeButtonClick), for: .touchUpInside)
        inputCodeButton.snp.makeConstraints { make in
            make.centerY.centerX.equalToSuperview()
            make.height.equalTo(38)
        }
        
        inputCodeButton.addSubview(tipLabel)
        inputCodeButton.addSubview(iconImageView)
        
        tipLabel.text = BDPI18n.scan_enter_barcode
        tipLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        tipLabel.font = UIFont.systemFont(ofSize: 16)
        tipLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.height.equalTo(22)
            make.left.equalToSuperview()
        }
        
        let image = UDIcon.getIconByKey(.rightOutlined, iconColor: UIColor.ud.primaryOnPrimaryFill, size: CGSize(width: 16, height: 16))
        iconImageView.image = image
        iconImageView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.size.equalTo(16)
            make.centerY.equalToSuperview()
            make.left.equalTo(tipLabel.snp.right).offset(4)
        }

    }
    
    @objc
    private func inputCodeButtonClick() {
        if let handler = clickHandler {
            handler()
        }
    }
}
