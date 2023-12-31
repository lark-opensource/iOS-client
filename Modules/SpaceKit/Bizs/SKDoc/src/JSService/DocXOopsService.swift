//
//  DocXOopsService.swift
//  SKDoc
//
//  Created by zoujie on 2021/5/27.
//  

import SKFoundation
import SKUIKit
import SKCommon
import SKBrowser
import EENavigator
import SKResource
import UniverseDesignDialog
import UniverseDesignColor
import UniverseDesignToast
import SKInfra
import SpaceInterface

class DocXOopsService: BaseJSService {
    enum ButtonType: Int {
        case REFRESH
        case COPY
        case CONTACT
        case CANCEL
    }

    private var dialog: UDDialog?
    private var director: DocsCreateDirectorV2?

    override init(ui: BrowserUIConfig, model: BrowserModelConfig, navigator: BrowserNavigator?) {
        super.init(ui: ui, model: model, navigator: navigator)
    }
}

extension DocXOopsService: JSServiceHandler {

    var handleServices: [DocsJSService] {
        return [.showOopsDialog,
                .hideOopsDialog,
                .contactUs,
                .createDocX]
    }

    func handle(params: [String: Any], serviceName: String) {
        switch serviceName {
        case DocsJSService.showOopsDialog.rawValue:
            showOopsDialog(params: params)
        case DocsJSService.contactUs.rawValue:
            openCustonService()
        case DocsJSService.createDocX.rawValue:
            createDocX()
        case DocsJSService.hideOopsDialog.rawValue:
            dismissDialog(params: params)
        default:
            return
        }
    }

    ///显示Oops弹框
    func showOopsDialog(params: [String: Any]) {
        guard let callback = params["callback"] as? String,
              let title = params["title"] as? String,
              let content = params["content"] as? String,
              let buttons = params["buttons"] as? [[String: Any]],
              var errorCode = params["code"] as? String else {
            DocsLogger.info("DocXOopsService showOopsDialog fail params error", component: LogComponents.fileOpen)
            return
        }
        let loadStatus = self.model?.browserInfo.loadStatus ?? .unknown
        if loadStatus.canContinue == false {
            //当加载状态已经是超时或失败，不再继续响应新的failEvent
            DocsLogger.error("ignore new fail/oops event(code:\(errorCode),content:\(content)) when loadStatus:\(String(describing: loadStatus))", component: LogComponents.fileOpen)
            return
        }
        if params["hideCode"] as? Bool == true {
            errorCode = ""
        }
        let dialogBlock = { [weak self] in
            guard let self = self else { return }
            let config = UDDialogUIConfig()
            config.contentMargin = UIEdgeInsets(top: 12, left: 20, bottom: 16, right: 20)
            // 新UI设计，三个按钮开始才是竖着放（后续二期工作，需要在API实现，不要遗漏）
            if buttons.count > 2 {
                config.style = .vertical
            } else {
                config.style = .horizontal
            }
            let dialog = UDDialog(config: config)
            dialog.setTitle(text: title)

            let contenView: UIView = UIView()

            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.lineHeightMultiple = 0.98

            let errorMessageLabel: UILabel = UILabel()
            errorMessageLabel.lineBreakMode = .byWordWrapping
            errorMessageLabel.numberOfLines = 0
            errorMessageLabel.font = UIFont.systemFont(ofSize: 16)
            errorMessageLabel.textColor = UDColor.textTitle

            let errorCodeLabel: UILabel = UILabel()
            errorCodeLabel.textAlignment = .center
            errorCodeLabel.font = UIFont.systemFont(ofSize: 12)
            errorCodeLabel.textColor = UDColor.N600


            errorMessageLabel.attributedText =
                NSMutableAttributedString(string: content,
                                          attributes: [NSAttributedString.Key.paragraphStyle: paragraphStyle])
            errorMessageLabel.textAlignment = .center
            let labelHeight = errorMessageLabel.sizeThatFits(CGSize(width: 260, height: CGFloat.greatestFiniteMagnitude)).height

            errorCodeLabel.text = errorCode
            contenView.addSubview(errorMessageLabel)
            contenView.addSubview(errorCodeLabel)

            dialog.setContent(view: contenView)

            errorMessageLabel.snp.makeConstraints { (make) in
                make.left.right.top.equalToSuperview()
                make.height.equalTo(labelHeight)
                make.bottom.equalTo(errorCodeLabel.snp.top).offset(-8)
            }

            errorCodeLabel.snp.makeConstraints { (make) in
                make.left.right.bottom.equalToSuperview()
                make.top.equalTo(errorMessageLabel.snp.bottom).offset(8)
            }

            var i = 0
            for button in buttons {
                guard let id = button["id"] as? Int,
                      let text = button["text"] as? String else {
                    return
                }

                if i == 0 {
                    dialog.addPrimaryButton(text: text) { [weak self] () -> Bool in
                        guard let self = self else {
                            DocsLogger.info("DocXOopsService is nil")
                            return true
                        }
                        
                        self.clickButton(callback: callback, id: id)
                        return false
                    }
                } else {
                    dialog.addSecondaryButton(text: text) { [weak self] () -> Bool in
                        guard let self = self else {
                            DocsLogger.info("DocXOopsService is nil")
                            return true
                        }
                        
                        self.clickButton(callback: callback, id: id)
                        return false
                    }
                }
                i += 1
            }

            guard let browserVC = self.navigator?.currentBrowserVC else { return }
            self.safePresent {
                self.model?.userResolver.navigator.present(dialog, from: UIViewController.docs.topMost(of: browserVC) ?? browserVC)
            }
            
            self.dialog = dialog
            HostAppBridge.shared.call(LaunchCustomerService())
        }

        if self.dialog != nil {
            self.dialog?.dismiss(animated: true, completion: { [weak self] in
                self?.dialog = nil
                dialogBlock()
            })
            return
        }

        dialogBlock()
    }

    func safePresent(safe: @escaping (() -> Void)) {
        if let presentedVC = registeredVC?.presentedViewController {
            presentedVC.dismiss(animated: false, completion: safe)
        } else {
            safe()
        }
    }

    func clickButton(callback: String, id: Int) {
        if ButtonType(rawValue: id) == .CANCEL {
            //取消按钮，native自己处理，避免前端完全卡死的情况下，无法退出当前页面
            dialog?.dismiss(animated: true, completion: nil)
            dialog = nil
        }
        if ButtonType(rawValue: id) == .REFRESH {
            let chatModeService = model?.jsEngine.fetchServiceInstance(AIChatModeService.self)
            chatModeService?.handleOopsRefresh()
        }
        self.model?.jsEngine.callFunction(DocsJSCallBack(rawValue: callback), params: ["buttonType": id], completion: nil)
    }

    ///打开客服界面
    func openCustonService() {
        guard let browserVC = navigator?.currentBrowserVC else { return }
        let service = LarkOpenEvent.customerService(controller: browserVC)
        NotificationCenter.default.post(name: Notification.Name(DocsSDK.mediatorNotification), object: service)
    }

    ///新建DocX文档
    func createDocX() {
        guard let fromVC = navigator?.currentBrowserVC?.navigationController else { return }
        let trackParams = DocsCreateDirectorV2.TrackParameters(source: .docCreate, module: .home(.recent), ccmOpenSource: .unknow)
        let ownerType = SettingConfig.singleContainerEnable ? singleContainerOwnerTypeValue : defaultOwnerType
        director = DocsCreateDirectorV2(type: .docX, ownerType: ownerType, name: nil, in: "", trackParamters: trackParams)
        director?.create { [weak self] (_, vc, _, _, error) in
            // 租户达到创建的上线，弹出付费提示
            if let error {
                if let permissionSDK = DocsContainer.shared.resolve(PermissionSDK.self) {
                    let context = PermissionCommonErrorContext(objToken: "", objType: .docX, operation: .createSubNode)
                    if let handler = permissionSDK.canHandle(error: error, context: context) {
                        handler(fromVC, BundleI18n.SKResource.Doc_Facade_CreateFailed)
                        return
                    }
                }
                if let docsError = error as? DocsNetworkError,
                    docsError.code == .createLimited {
                    DocsNetworkError.showTips(for: .createLimited, from: fromVC)
                } else {
                    guard let window = self?.navigator?.currentBrowserVC?.rootWindow() else { return }
                    UDToast.removeToast(on: window)
                    UDToast.showFailure(with: BundleI18n.SKResource.Doc_Facade_CreateFailed, on: window)
                }
            }
            // 成功创建
            if let browser = vc {
                self?.model?.userResolver.navigator.push(browser, from: fromVC)
            }
        }
    }

    ///隐藏弹框
    func dismissDialog(params: [String: Any]) {
        dialog?.dismiss(animated: true, completion: { [weak self] in
            guard let callback = params["callback"] as? String else { return }
            self?.model?.jsEngine.callFunction(DocsJSCallBack(rawValue: callback), params: nil, completion: nil)
        })
    }
}
