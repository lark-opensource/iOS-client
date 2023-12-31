//
//  BannerController.swift
//  LarkHelpdesk
//
//  Created by yinyuan on 2021/8/26.
//

import Foundation
import LarkOpenChat
import EENavigator
import Swinject
import UniverseDesignDialog
import UniverseDesignToast
import RxSwift
import ECOProbe
import LKCommonsLogging
import ServerPB
import ECOProbeMeta

private typealias BannerActionCallback = (_ error: HelpDeskError?) -> Void

protocol BannerControllerProtocol: AnyObject {
    
    func refreshView()
    
}

class BannerController {
    
    weak var delegate: BannerControllerProtocol?
    
    private let dataManager: BannerDataManager
    private let chatID: String
    
    private let disposeBag: DisposeBag = DisposeBag()

    private(set) lazy var bannerView: BannerView = {
       return BannerView()
    }()
    
    init(model: ChatKeyboardTopExtendMetaModel, resolver: Resolver) {
        chatID = model.chat.id
        dataManager = BannerDataManager(resolver: resolver, chatID: model.chat.id)
        
        dataManager.delegate = self
        bannerView.delegate = self
        
        openBannerLogger.info("BannerController.init. chatID:\(chatID)")
        
        let targetType = ServerPB_Open_banner_TargetType.chat
        let containerTag = ServerPB_Open_banner_ContainerTag.chatFooterBanner
        OPMonitor(HelpDeskMonitorEvent.open_banner_load_start.rawValue)
            .addCategoryValue("target_id", chatID)
            .addCategoryValue("target_type", targetType.rawValue)
            .addCategoryValue("container_tag", containerTag.rawValue)
            .flush()
        
        // 进入时主动触发一次拉取数据
        let monitor = OPMonitor(HelpDeskMonitorEvent.open_banner_load_result.rawValue).timing()
        self.dataManager.pullBannerContainer { error, response in
            monitor
                .timing()
                .setBannerResponse(response)
                .setResultType(with: error)
                .flush()
        }
    }
    
    deinit {
        openBannerLogger.info("BannerController.deinit:\(chatID)")
    }
}

extension BannerController: BannerViewProtocol {
    
    func refreshView() {
        delegate?.refreshView()
    }
    
    func didSelectItem(
        bannerView: BannerView,
        bannerResponse: BannerResponse,
        bannerResource: BannerResource
    ) {
        openBannerLogger.info("BannerController.didSelectItem. resourceID:\(bannerResource.resourceID)")
        OPMonitor(HelpDeskMonitorEvent.open_banner_button_action_start.rawValue)
            .setBannerResource(bannerResource)
            .setBannerResponse(bannerResponse)
            .flush()
        let monitor = OPMonitor(HelpDeskMonitorEvent.open_banner_button_action_result.rawValue).timing()
        let callback: BannerActionCallback = { error in
            monitor
                .timing()
                .setBannerResource(bannerResource)
                .setBannerResponse(bannerResponse)
                .setResultType(with: error)
                .flush()
        }
        if let confirm = bannerResource.resourceView.confirm {
            showConfirm(
                confirm: confirm,
                bannerView: bannerView,
                bannerResponse: bannerResponse,
                bannerResource: bannerResource,
                callback: callback
            )
        } else if let action = bannerResource.resourceView.action {
            performAction(
                action: action,
                bannerResponse: bannerResponse,
                bannerResource: bannerResource,
                callback: callback
            )
        } else {
            openBannerLogger.error("bannerResource invalid without confirm or action config")
            callback(HelpDeskError(.invalidResourceActionOrConfirm))
        }
    }
    
    private func showConfirm(
        confirm: BannerResourceConfirm,
        bannerView: BannerView,
        bannerResponse: BannerResponse,
        bannerResource: BannerResource,
        callback: @escaping BannerActionCallback
    ) {
        openBannerLogger.info("BannerController.showConfirm. resourceID:\(bannerResource.resourceID), confirm:\(confirm)")
        guard let window = bannerView.window else {
            openBannerLogger.error("no valid window")
            callback(HelpDeskError(.noValidWindow))
            return
        }
        let dialog = UDDialog()
        if let title_i18n = confirm.title_i18n {
            dialog.setTitle(text: I18nUtils.getLocal(i18n: title_i18n))
        }
        if let content_i18n = confirm.content_i18n {
            dialog.setContent(text: I18nUtils.getLocal(i18n: content_i18n))
        }
        if let cancel_text_i18n = confirm.cancel_text_i18n {
            dialog.addSecondaryButton(text: I18nUtils.getLocal(i18n: cancel_text_i18n)) { [weak self] in
                // confirm action
                guard let self = self else {
                    openBannerLogger.info("BannerController released")
                    callback(HelpDeskError(.contextReleased))
                    return
                }
                guard let cancel_action = confirm.cancel_action else {
                    openBannerLogger.info("BannerController no cancel_action")
                    callback(nil)   // 这里是正常情况，不能算失败
                    return
                }
                openBannerLogger.info("cancel clicked and perform action. resourceID:\(bannerResource.resourceID)")
                self.performAction(
                    action: cancel_action,
                    bannerResponse: bannerResponse,
                    bannerResource: bannerResource,
                    callback: callback
                )
            }
        }
        if let confirm_text_i18n = confirm.confirm_text_i18n {
            dialog.addPrimaryButton(text: I18nUtils.getLocal(i18n: confirm_text_i18n), dismissCompletion: { [weak self] in
                // confirm action
                guard let self = self else {
                    openBannerLogger.info("BannerController released")
                    callback(HelpDeskError(.contextReleased))
                    return
                }
                openBannerLogger.info("confirm clicked and perform action. resourceID:\(bannerResource.resourceID)")

                if bannerResource.resourceType == "HELPDESK_TICKET_CLOSE" {
                    OPMonitor("lark_hpd_end_consultation_popup_click")
                        .addCategoryValue("click", "end")
                        .addCategoryValue("resource_type", bannerResource.resourceType)
                        .addCategoryValue("resource_id", bannerResource.resourceID)
                        .addCategoryValue("user_type", bannerResponse.contextDic?["user_type"])
                        .addCategoryValue("language", bannerResponse.contextDic?["language"])
                        .addCategoryValue("helpdesk_id", bannerResponse.contextDic?["helpdesk_id"])
                        .addCategoryValue("version", bannerResponse.resourceVersion)
                        .addCategoryValue("target", "none")
                        .setPlatform(.tea)
                        .timing()
                        .flush()
                }
                self.performAction(
                    action: confirm.confirm_action,
                    bannerResponse: bannerResponse,
                    bannerResource: bannerResource,
                    callback: callback
                )
            })
        }
        Navigator.shared.present(dialog, from: window)
    }
    
    private func performAction(
        action: BannerResourceAction,
        bannerResponse: BannerResponse,
        bannerResource: BannerResource,
        callback: @escaping BannerActionCallback) {
        openBannerLogger.info("BannerController.performAction. resourceID:\(bannerResource.resourceID). action:\(action)")
        guard action.isValidAction() else {
            openBannerLogger.error("invalid action.")
            callback(HelpDeskError(.invalidAction))
            return
        }
        
        if let url = action.getLinkUrl() {
            // jump link action
            OPMonitor(HelpDeskMonitorEvent.open_banner_button_jump_start.rawValue)
                .setBannerResource(bannerResource)
                .setBannerResponse(bannerResponse)
                .flush()
            let monitor = OPMonitor(HelpDeskMonitorEvent.open_banner_button_jump_result.rawValue).timing()
            jumpToLink(url: url) { error in
                monitor
                    .timing()
                    .setBannerResource(bannerResource)
                    .setBannerResponse(bannerResponse)
                    .setResultType(with: error)
                    .flush()
                
                callback(error)
            }
        } else {
            // post value action
            // show Loading
            self.bannerView.setItemLoading(resource: bannerResource, loading: true)
            
            dataManager.postBannerAction(
                actionValue: action.value,
                bannerResponse: bannerResponse,
                bannerResource: bannerResource
            ) { [weak self] error, response in
                executeOnMainQueueAsync { [weak self] in
                    guard let self = self else {
                        openBannerLogger.info("BannerController released")
                        callback(HelpDeskError(.contextReleased))
                        return
                    }
                    defer {
                        // hide Loading
                        self.bannerView.setItemLoading(resource: bannerResource, loading: false)
                    }
                    
                    let window = self.bannerView.window
                    if window == nil {
                        openBannerLogger.error("no valid window")
                    }
                    
                    if let error = error {
                        openBannerLogger.error("show failure tips")
                        if let window = window {
                            UDToast.showFailure(with: BundleI18n.HelpDesk.HelpDesk_Chat_NetworkError, on: window)
                        }
                        callback(error)
                    } else if let response = response {
                        if response.code == 0 {
                            if let tips_i18n = response.tipsI18N, let window = window {
                                openBannerLogger.error("show success tips:\(tips_i18n)")
                                UDToast.showSuccess(with: I18nUtils.getLocal(i18n: tips_i18n), on: window)
                            }
                            callback(nil)
                        } else {
                            if let tips_i18n = response.tipsI18N, let window = window {
                                openBannerLogger.error("show failure tips:\(tips_i18n)")
                                UDToast.showFailure(with: I18nUtils.getLocal(i18n: tips_i18n), on: window)
                            }
                            callback(HelpDeskError(.responseCodeError, message: "code:\(response.code)"))
                        }
                    } else {
                        // response 为空
                        if let window = window {
                            UDToast.showFailure(with: BundleI18n.HelpDesk.HelpDesk_Chat_NetworkError, on: window)
                        }
                        callback(HelpDeskError(.invalidResponse))
                    }
                }
            }
        }
    }
    
    private func jumpToLink(url: URL, callback: @escaping BannerActionCallback) {
        guard let window = self.bannerView.window else {
            openBannerLogger.error("no valid window")
            callback(HelpDeskError(.noValidWindow))
            return
        }
        Navigator.shared.push(url, from: window) { req, rsp in
            openBannerLogger.error("jump link response: \(rsp.error)")
            if let error = rsp.error {
                callback(HelpDeskError(error))
            } else {
                callback(nil)
            }
        }
    }
}

extension BannerController: BannerDataManagerProtocol {
    
    func didContainerChanged(container: BannerContainer, response: BannerResponse) {
        executeOnMainQueueAsync { [weak self] in
            guard let self = self else {
                openBannerLogger.info("BannerController released")
                return
            }
            openBannerLogger.info("updateContainerData")
            self.bannerView.updateContainerData(bannerContainer: container, bannerResponse: response)
        }
    }
}

