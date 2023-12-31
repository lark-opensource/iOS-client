// 支持 Forms API 在文档容器下运行

import Foundation
import LarkOpenAPIModel
import LarkUIKit
import LarkWebViewContainer
import LKCommonsLogging
import SKBrowser
import SKCommon
import SKFoundation
import SKUIKit
import SpaceInterface
import UniverseDesignColor


// FormsAPI
extension BTJSService {
    
    var formsAPIForJSService: FormsAPI? {
        if let navigator = navigator {
            if let currentBrowserVC = navigator.currentBrowserVC {
                return currentBrowserVC.formsAPI
            } else {
                Self.logger.error("get formsAPI error, currentBrowserVC is nil")
                return nil
            }
        } else {
            Self.logger.error("get formsAPI error, navigator is nil")
            return nil
        }
    }
    
    var formsAPIOptionalForJSService: FormsAPI? {
        let result = browserVC()
        switch result {
        case .success(let vc):
            return vc.formsAPIOptional
        case .failure(let error):
            Self.logger.error("get formsAPIOptionalForJSService error, currentBrowserVC is nil", error: error)
            return nil
        }
    }
    
    private func browserVC() -> Result<UIViewController, Error> {
        let code = -999998
        let msg = "vc is nil"
        let e = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
            .setMonitorMessage(msg)
            .setOuterMessage(msg)
            .setOuterCode(code)

        if let navigator = navigator {
            if let currentBrowserVC = navigator.currentBrowserVC {
                return .success(currentBrowserVC)
            } else {
                Self.logger.error(msg)
                return .failure(e)
            }
        } else {
            Self.logger.error(msg)
            return .failure(e)
        }
    }
    
}

//  回调工具方法
extension BTJSService {
    
    private func callbackSuccess(callback: String, data: OpenAPIBaseResult?) {
        
        let result: [AnyHashable: Any] = [
            "data": data?.toJSONDict(),
            "callbackType": CallBackType
                .success
                .rawValue
        ]
        
        model?
            .jsEngine
            .callFunction(
                DocsJSCallBack(callback),
                params: result as? [String: Any],
                completion: nil
            )
        
    }
    
    private func callbackFailure(callback: String, error: OpenAPIError?) {
        
        let result: [AnyHashable: Any] = [
            "data": [
                "errMsg": error?.outerMessage,
                "errCode": error?.outerCode
            ],
            "callbackType": CallBackType
                .failure
                .rawValue
        ]
        
        model?
            .jsEngine
            .callFunction(
                DocsJSCallBack(callback),
                params: result as? [String: Any],
                completion: nil
            )
        
    }
    
    private func callbackCancel(callback: String) {
        
        let code = -3
        let result: [AnyHashable: Any] = [
            "data": [
                "errMsg": "user cancel",
                "errCode": code
            ],
            "callbackType": CallBackType
                .cancel
                .rawValue
        ]
        
        model?
            .jsEngine
            .callFunction(
                DocsJSCallBack(callback),
                params: result as? [String: Any],
                completion: nil
            )
        
    }
    
}

// 附件
extension BTJSService {
    
    func formConfiguration(_ params: [String: Any]) {
        guard let callback = params["callback"] as? String else { return }
        
        let result = FormsConfigurationResult()
        callbackSuccess(callback: callback, data: result)
    }
    
    func chooseAttachment(_ params: [String: Any]) {
        guard let callback = params["callback"] as? String else { return }
        
        let result = browserVC()
        
        switch result {
        case .success(let vc):
            do {
                let model = try FormsChooseAttachmentParams(with: params)
                formsAPIForJSService?
                    .formsAttachment
                    .chooseAttachment(
                        vc: vc,
                        params: model
                    ) { [weak self] infos in
                        guard let self = self else { return }
                        let data = BitableChooseAttachmentResult(infos: infos)
                        self.callbackSuccess(callback: callback, data: data)
                    } failure: { [weak self] error in
                        guard let self = self else { return }
                        self.callbackFailure(callback: callback, error: error)
                    } cancel: { [weak self] in
                        guard let self = self else { return }
                        self.callbackCancel(callback: callback)
                    }
                
            } catch {
                Self.logger.error("new FormsChooseAttachmentParams error", error: error)
                callbackFailure(callback: callback, error: error as? OpenAPIError)
            }
        case .failure(let error):
            callbackFailure(callback: callback, error: error as? OpenAPIError)
        }
        
    }
    
    func checkAttachmentValid(_ params: [String: Any]) {
        guard let callback = params["callback"] as? String else { return }
        
        do {
            let model = try FormsCheckAttachmentParams(with: params)
            
            formsAPIForJSService?
                .formsAttachment
                .checkAttachment(
                    params: model
                ) { [weak self] infos in
                    let data = FormsCheckAttachmentResult(infos: infos)
                    
                    self?.callbackSuccess(callback: callback, data: data)
                }
            
        } catch {
            Self.logger.error("new FormsCheckAttachmentResult error", error: error)
            callbackFailure(callback: callback, error: error as? OpenAPIError)
        }
    }
    
    func previewAttachment(_ params: [String: Any]) {
        guard let callback = params["callback"] as? String else { return }
        
        let result = browserVC()
        
        switch result {
            
        case .success(let vc):
            
            do {
                let model = try FormsPreviewAttachmentParams(with: params)
                
                formsAPIForJSService?
                    .formsAttachment
                    .previewAttachment(
                        vc: vc,
                        params: model
                    ) { [weak self] in
                        self?.callbackSuccess(callback: callback, data: nil)
                    } failure: { [weak self] error in
                        self?.callbackFailure(callback: callback, error: error)
                    }
                
            } catch  {
                Self.logger.error("new FormsPreviewAttachmentParams error", error: error)
                callbackFailure(callback: callback, error: error as? OpenAPIError)
            }
            
        case .failure(let error):
            callbackFailure(callback: callback, error: error as? OpenAPIError)
            
        }
        
    }
    
    func deleteAttachment(_ params: [String: Any]) {
        guard let callback = params["callback"] as? String else { return }
        
        do {
            let model = try FormsDeleteAttachmentParams(with: params)
            
            formsAPIForJSService?
                .formsAttachment
                .deleteAttachment(
                    params: model
                ) { [weak self] in
                    self?.callbackSuccess(callback: callback, data: nil)
                }
            
        } catch {
            Self.logger.error("new FormsDeleteAttachmentParams error", error: error)
            callbackFailure(callback: callback, error: error as? OpenAPIError)
        }
    }
    
    func uploadAttachment(_ params: [String: Any]) {
        guard let callback = params["callback"] as? String else { return }
        
        do {
            let model = try FormsUploadAttachmentBaseParams(with: params)
            
            formsAPIForJSService?
                .formsAttachment
                .baseUploadAttachment(
                    params: model
                ) { [weak self] token in
                    let data = FormsUploadAttachmentResult(token: token)
                    
                    self?.callbackSuccess(callback: callback, data: data)
                } failure: { [weak self] error in
                    self?.callbackFailure(callback: callback, error: error)
                }
            
        } catch {
            Self.logger.error("new FormsDeleteAttachmentParams error", error: error)
            callbackFailure(callback: callback, error: error as? OpenAPIError)
        }
    }
    
    /// 如果有正在上传或者上传完成但不需要消费的任务，则取消或者删除无用资源
    func cancelOrDeleteAllUploadTasksIfNeeded() {
        if let form = formsAPIOptionalForJSService {
            let infos = Array(
                FormsAttachment
                    .choosenAttachments
                    .values
            )
            form
                .formsAttachment
                .cancelOrDeleteUploadTasks(
                    attachmentInfos: infos,
                    needRemoveMemoryAndDeleteAttachment: false
                )
        }
    }
    
}

// 定位
extension BTJSService {
    
    func getLocation(_ params: [String: Any]) {
        guard let callback = params["callback"] as? String else { return }
        
        do {
            let model = try FormsGetLocationParams(with: params)
            
            formsAPIForJSService?
                .formsLocation
                .getLocation(
                    params: model
                ) { [weak self] result in
                    self?.callbackSuccess(callback: callback, data: result)
                } failure: { [weak self] error in
                    self?.callbackFailure(callback: callback, error: error)
                }
            
        } catch {
            Self.logger.error("new FormsGetLocationParams error", error: error)
            callbackFailure(callback: callback, error: error as? OpenAPIError)
        }
    }
    
    func reverseGeocodeLocation(_ params: [String: Any]) {
        guard let callback = params["callback"] as? String else { return }
        
        do {
            let model = try FormsReverseGeocodeLocationParams(with: params)
            
            formsAPIForJSService?
                .formsLocation
                .reverseGeocodeLocation(
                    params: model
                ) { [weak self] result in
                    self?.callbackSuccess(callback: callback, data: result)
                } failure: { [weak self] error in
                    self?.callbackFailure(callback: callback, error: error)
                }
            
        } catch {
            Self.logger.error("new FormsReverseGeocodeLocationParams error", error: error)
            callbackFailure(callback: callback, error: error as? OpenAPIError)
        }
    }
    
    func chooseLocation(_ params: [String: Any]) {
        guard let callback = params["callback"] as? String else { return }
        
        let result = browserVC()
        
        switch result {
        case .success(let vc):
            formsAPIForJSService?
                .formsLocation
                .chooseLocation(
                    vc: vc
                ) { [weak self] result in
                    self?.callbackSuccess(callback: callback, data: result)
                } failure: { [weak self] error in
                    self?.callbackFailure(callback: callback, error: error)
                }
        case .failure(let error):
            callbackFailure(callback: callback, error: error as? OpenAPIError)
        }
        
    }
    
    func openLocation(_ params: [String: Any]) {
        guard let callback = params["callback"] as? String else { return }
        
        let result = browserVC()
        
        switch result {
        case .success(let vc):
            do {
                let model = try FormsOpenLocationParams(with: params)
                
                formsAPIForJSService?
                    .formsLocation
                    .openLocation(
                        vc: vc,
                        params: model
                    ) { [weak self] in
                        self?.callbackSuccess(callback: callback, data: nil)
                    } failure: { [weak self] error in
                        self?.callbackFailure(callback: callback, error: error)
                    }
                
            } catch {
                Self.logger.error("new FormsOpenLocationParams error", error: error)
                callbackFailure(callback: callback, error: error as? OpenAPIError)
            }
        case .failure(let error):
            callbackFailure(callback: callback, error: error as? OpenAPIError)
        }
        
    }
    
}

// 设备
extension BTJSService {
    
    func scanCode(_ params: [String: Any]) {
        guard let callback = params["callback"] as? String else { return }
        
        let result = browserVC()
        
        switch result {
        case .success(let vc):
            formsAPIForJSService?
                .formsDevice
                .scanCode(
                    vc: vc
                ) { [weak self] result in
                    self?.callbackSuccess(callback: callback, data: result)
                } cancel: { [weak self] in
                    self?.callbackCancel(callback: callback)
                }
        case .failure(let error):
            Self.logger.error("scanCode error, currentBrowserVC is nil")
            callbackFailure(callback: callback, error: error as? OpenAPIError)
        }
    }
    
    func safeArea(_ params: [String: Any]) {
        guard let callback = params["callback"] as? String else { return }
        
        callbackSuccess(callback: callback, data: FormsSafeAreaResult())
        
    }
    
}

// 分享
extension BTJSService {
    
    func formsShare(_ params: [String: Any]) {
        
        let formsShareModel: FormsShareModel
        do {
            formsShareModel = try CodableUtility.decode(FormsShareModel.self, withJSONObject: params)
        } catch {
            Self.logger.error("formsShare error, new FormsShareModel error", error: error)
            return
        }
        
        Self.logger.info("formsShare params is: \(formsShareModel.logInfo())")
        
        PermissionStatistics.formEditable = true // 和PM进行了咨询，现在的业务逻辑，如果不能编辑完全进不来
        
        guard let model = model else {
            Self.logger.error("formsShare error, model is nil")
            return
        }
        guard let docsInfo = model.browserInfo.docsInfo else {
            Self.logger.error("formsShare error, model.browserInfo.docsInfo is nil")
            return
        }
        guard let containerView = ui?.editorView else {
            Self.logger.error("formsShare error, ui is nil")
            return
        }

        navigator?.currentBrowserVC?.view.window?.endEditing(true)
        
        let formShareMeta = FormShareMeta(
            token: formsShareModel.baseToken,
            tableId: formsShareModel.tableId,
            viewId: formsShareModel.viewId,
            shareType: 1,
            hasCover: false
        )
        formShareMeta.updateFlag(true) // 新收集表默认可以分享
        if let shareToken = formsShareModel.shareToken {
            formShareMeta.updateShareToken(shareToken)
        }
        
        // 下边代码和之前老表单分享入参一致
        if let url = model.browserInfo.currentURL,
           let shareHost = DocsUrlUtil.getDocsCurrentUrlInfo(url).srcHost,
           !shareHost.isEmpty {
            formShareMeta.updateShareHost(shareHost)
        }
        
        var onlyShowSocialShareComponent = false
        if formsShareModel.panelComponents.count == 1, formsShareModel.panelComponents.contains("memberSetting") {
            onlyShowSocialShareComponent = true
        }
        
        var shareEntity = SKShareEntity(
            objToken: formsShareModel.baseToken,
            type: ShareDocsType.form.rawValue,
            title: formsShareModel.formName,
            isOwner: docsInfo.isOwner,
            ownerID: docsInfo.ownerID ?? "",
            displayName: docsInfo.displayName,
            shareFolderInfo: docsInfo.shareFolderInfo,
            folderType: docsInfo.folderType,
            tenantID: docsInfo.tenantID ?? "",
            createTime: docsInfo.createTime ?? 0,
            createDate: docsInfo.createDate ?? "",
            creatorID: docsInfo.creatorID ?? "",
            wikiInfo: docsInfo.wikiInfo,
            isFromPhoenix: docsInfo.isFromPhoenix,
            shareUrl: docsInfo.shareUrl ?? "",
            fileType: docsInfo.fileType ?? "",
            defaultIcon: docsInfo.defaultIcon,
            enableShareWithPassWord: true,
            enableTransferOwner: true,
            onlyShowSocialShareComponent: onlyShowSocialShareComponent,
            formShareMeta: formShareMeta
        )
        shareEntity.formsShareModel = formsShareModel
        shareEntity.shareHandlerProvider = self
        
        let shareVC = SKShareViewController(
            shareEntity,
            delegate: self,
            router: self,
            source: .content,
            isInVideoConference: docsInfo.isInVideoConference ?? false
        )
        shareVC.watermarkConfig.needAddWatermark = docsInfo.shouldShowWatermark
        
        let nav = LkNavigationController(rootViewController: shareVC)
        
        if SKDisplay.pad, ui?.editorView.isMyWindowRegularSize() ?? false {
            /* 还有分享面板本身有兼容性问题，面板内部兼容问题搞定后正式接入location，否则会出现分享上边有一个很高的半透明view
            let location = formsShareModel.location
            let targetRect = CGRect(
                x: location.x,
                y: location.y,
                width: location.width,
                height: location.height
            )
            
            let tempTargetView = UIView(frame: targetRect)
            tempTargetView.backgroundColor = .clear
            containerView.addSubview(tempTargetView)
            tempTargetView.snp.makeConstraints { (make) in
                make.left.equalTo(containerView.safeAreaLayoutGuide.snp.left).offset(targetRect.minX)
                make.top.equalTo(containerView.safeAreaLayoutGuide.snp.top).offset(targetRect.minY)
                make.height.equalTo(targetRect.height)
                make.width.equalTo(targetRect.width)
            }
            nav.modalPresentationStyle = .popover
            nav.popoverPresentationController?.sourceView = tempTargetView
            nav.popoverPresentationController?.sourceRect = tempTargetView.bounds
            nav.popoverPresentationController?.permittedArrowDirections = .up
            shareVC.popoverDisappearBlock = {
                tempTargetView.removeFromSuperview()
            }
             */
            shareVC.modalPresentationStyle = .popover
            shareVC.popoverPresentationController?.backgroundColor = UDColor.bgFloat
            let browserVC = navigator?.currentBrowserVC as? BaseViewController
            var code = -1 // 新框架下，popover对齐最右边
            browserVC?.showPopover(to: nav, at: code, isNewForm: true)
        } else {
            nav.modalPresentationStyle = .overFullScreen
            navigator?.presentViewController(nav, animated: false, completion: nil)
        }
        
    }
    
}

// 生命周期
extension BTJSService {
    
    func formsUnmount(_ params: [String: Any]) {
        cancelOrDeleteAllUploadTasksIfNeeded()
    }
    
}

// 开放能力
extension BTJSService {
    func chooseContact(_ params: [String: Any]) {
        
        guard let callback = params["callback"] as? String else { return }
        
        let result = browserVC()
        
        switch result {
        case .success(let vc):
            do {
                let model = try FormsChooseContactParams(with: params)
                
                formsAPIForJSService?
                    .formsOpenAbility
                    .chooseContact(
                        vc: vc,
                        params: model
                    ) { [weak self] result in
                        self?.callbackSuccess(callback: callback, data: result)
                    } cancel: { [weak self] in
                        self?.callbackCancel(callback: callback)
                    }
                
            } catch {
                Self.logger.error("new FormsChooseContactParams error", error: error)
                callbackFailure(callback: callback, error: error as? OpenAPIError)
            }
        case .failure(let error):
            callbackFailure(callback: callback, error: error as? OpenAPIError)
        }
        
    }
}
