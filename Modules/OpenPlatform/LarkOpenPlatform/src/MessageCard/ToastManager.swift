//
//  ToastManager.swift
//  ToastManager
//
//  Created by Songwen Ding on 2019/1/23.
//

import UIKit
import LarkUIKit
import RxSwift
import LarkContainer
import LarkModel
import RoundedHUD
import LKCommonsTracker
import Reachability
import CoreTelephony
import LarkExtensions
import LarkCompatible
import LarkMessageBase
import LKCommonsLogging
import LarkSDKInterface
import EENavigator
import RustPB

public protocol ToastManagerService: PageService {
    func showToast(key: String?, type: ToastType, info: String)
}

final class ToastManagerProvider {
    let cardStatusObservable: Observable<PushCardMessageActionResult>
    public init(cardStatusObservable: Observable<PushCardMessageActionResult>) {
        self.cardStatusObservable = cardStatusObservable
    }
}

struct ShowToastActionMessage {
    public enum ToastType {
        case loading
        case success
        case fail
        case tips
    }

    public let messageID: String
    public let type: ToastType
    public let info: String

    public init(messageID: String, type: ToastType, info: String) {
        self.messageID = messageID
        self.type = type
        self.info = info
    }
}

final class ToastManager: ToastManagerService {
    static let logger = Logger.log(ToastManager.self, category: "Module.IM.ToastManager")
    private var messageIdHudMap = [String: RoundedHUD]()
    private typealias Infos = (start: String, success: String, fail: String)
    private var messageIdInfos = [String: Infos]()
    private var messageIdActionIDs = [String: String]()

    private let provider: ToastManagerProvider
    private let disposeBag: DisposeBag = DisposeBag()
    private var messageIdCardActionTimeMap = [String: CFAbsoluteTime]()

    public init(provider: ToastManagerProvider) {
        self.provider = provider
        provider.cardStatusObservable
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (cardStatus) in
                if cardStatus.pushType == .pushLoadingStart {
                    self?.messageIdInfos[cardStatus.messageID] = cardStatus.infos
                    self?.messageIdActionIDs[cardStatus.messageID] = cardStatus.actionID
                }
                let infos = self?.messageIdInfos[cardStatus.messageID] ?? (start: "", success: "", fail: "")
                let actionID = self?.messageIdActionIDs[cardStatus.messageID] ?? ""
                if cardStatus.pushType != .pushLoadingStart {
                    self?.messageIdInfos[cardStatus.messageID] = nil
                    self?.messageIdActionIDs[cardStatus.messageID] = nil
                }
                // toast
                switch cardStatus.cardVersion {
                case 1:
                    self?.showLoading(pushType: cardStatus.pushType, messageID: cardStatus.messageID, infos: infos)
                case 2:
                    if cardStatus.pushType == .pushLoadingEndWithToastFailed {
                        self?.showFail(errorCode: cardStatus.errorCode, messageID: cardStatus.messageID, errMsg: cardStatus.errorMsg)
                    }
                default:
                    break
                }
                // log
                switch cardStatus.pushType {
                case .pushLoadingStart:
                    self?.messageIdCardActionTimeMap[cardStatus.messageID] = CFAbsoluteTimeGetCurrent()
                case .pushLoadingEndWithToastSuccess:
                    self?.logRequestAction(messageID: cardStatus.messageID, actionID: actionID, state: "success", errMsg: "")
                case .pushLoadingEndWithToastFailed:
                    self?.logRequestAction(messageID: cardStatus.messageID, actionID: actionID, state: "fail", errMsg: cardStatus.errorMsg)
                @unknown default:
                    assert(false, "new value")
                }
                let logMessage = "recived card action result"
                let logInfo = ["messageID": cardStatus.messageID,
                               "actionID": actionID,
                               "type": cardStatus.pushType.rawValue.description,
                               "errMsg": cardStatus.errorMsg]
                if cardStatus.pushType == .pushLoadingEndWithToastFailed {
                    ToastManager.logger.error(logMessage, additionalData: logInfo)
                } else {
                    ToastManager.logger.info(logMessage, additionalData: logInfo)
                }
            }).disposed(by: self.disposeBag)
    }

    private func showLoading(pushType: RustPB.Basic_V1_CardMessageActionResult.PushType, messageID: String, infos: Infos) {
        switch pushType {
        case .pushLoadingStart:
            self.showHud(message: ShowToastActionMessage(messageID: messageID,
                                                          type: .loading,
                                                          info: infos.start.isEmpty
                                                            ? BundleI18n.LarkOpenPlatform.Lark_Legacy_Cardbuttonloading
                                                            : infos.start))
        case .pushLoadingEndWithToastSuccess:
            self.showHud(message: ShowToastActionMessage(messageID: messageID,
                                                          type: .success,
                                                          info: infos.success.isEmpty
                                                            ? BundleI18n.LarkOpenPlatform.Lark_Legacy_Cardbuttonsuccess
                                                            : infos.success))
        case .pushLoadingEndWithToastFailed:
            self.showHud(message: ShowToastActionMessage(messageID: messageID,
                                                          type: .fail,
                                                          info: infos.fail.isEmpty
                                                            ? BundleI18n.LarkOpenPlatform.Lark_Legacy_Cardbuttonfail
                                                            : infos.fail))
        @unknown default:
            assert(false, "new value")
        }
    }

    private func showFail(errorCode: Int32, messageID: String, errMsg: String = "") {
        switch errorCode {
        case 1:
            self.showHud(message: ShowToastActionMessage(messageID: messageID,
                                                         type: .fail,
                                                         info: BundleI18n.LarkOpenPlatform.Lark_Legacy_MsgCardNoNetwork))
        case 2:
            self.showHud(message: ShowToastActionMessage(messageID: messageID,
                                                         type: .fail,
                                                         info: BundleI18n.LarkOpenPlatform.Lark_Legacy_MsgCardFail))
        case 100:
            self.showHud(message: ShowToastActionMessage(messageID: messageID,
                                                         type: .fail,
                                                         info: errMsg))
        default:
            break
        }
    }

    deinit {
        self.removeAll()
    }

    private func logRequestAction(messageID: String, actionID: String, state: String, errMsg: String) {
        var network: String = "unknown"
        if let reach = Reachability() {
            do {
                try reach.startNotifier()
                switch reach.connection {
                case .none, .wifi:
                    network = reach.connection.description.lowercased()
                case .cellular:
                    network = {
                        switch CTTelephonyNetworkInfo.lu.shared.lu.currentSpecificStatus {
                        case .📶2G: return "2g"
                        case .📶3G: return "3g"
                        case .📶4G: return "4g"
                        case .📶5G: return "5g"
                        case .📶unknown: return "unknown"
                        @unknown default:
                            assert(false, "new value")
                            return "unknown"
                        }
                    }()
                @unknown default:
                    assert(false, "new value")
                }
                try reach.startNotifier()
            } catch {
            }
        }
        if let startTime = self.messageIdCardActionTimeMap[messageID] {
            self.messageIdCardActionTimeMap[messageID] = nil
            var category = ["state": state, "network": network]
            if !errMsg.isEmpty {
                category["errMsg"] = errMsg
            }
            var extra = ["messageId": messageID]
            if !actionID.isEmpty {
                extra["actionId"] = actionID
            }
            Tracker.post(SlardarEvent(
                name: "messagecard_request_action",
                metric: ["duration": (CFAbsoluteTimeGetCurrent() - startTime) * 1000],
                category: category,
                extra: extra)
            )
        }
    }

    // loading 过的 hud 会复用 hud
    public func showHud(message: ShowToastActionMessage) {
        ToastManager.logger.info("toast with type",
                                 additionalData: ["type": "\(message.type)",
                                    "messageID": message.messageID,
                                    "info": message.info])
        guard let currentVC = Navigator.shared.mainSceneWindow?.fromViewController,
              let targetView = currentVC.view else {
            ToastManager.logger.error("ToastManager show toast can not find top vc")
            return
        }
        let hud = self.messageIdHudMap[message.messageID] ?? RoundedHUD()
        switch message.type {
        case .loading:
            self.messageIdHudMap[message.messageID] = hud
            hud.showLoading(with: message.info, on: targetView)
        case .success:
            self.messageIdHudMap[message.messageID] = nil
            hud.showSuccess(with: message.info, on: targetView)
        case .fail:
            self.messageIdHudMap[message.messageID] = nil
            hud.showFailure(with: message.info, on: targetView)
        case .tips:
            self.messageIdHudMap[message.messageID] = nil
            hud.showTips(with: message.info, on: targetView)
        }
    }

    public func hideHud(messageID: String) {
        if let hud = self.messageIdHudMap[messageID] {
            hud.remove()
            self.messageIdHudMap[messageID] = nil
        }
    }

    public func isLoading(messageID: String) -> Bool {
        return self.messageIdHudMap[messageID] != nil
    }

    public func removeAll() {
        self.messageIdHudMap.forEach { (_, hud) in
            hud.remove()
        }
        self.messageIdHudMap.removeAll()
    }

    /// 展示Toast
    ///
    /// - Parameter key: 弹窗标识符, type: 弹窗类型, info: 弹窗展示文案
    public func showToast(key: String?, type: ToastType, info: String) {
        guard let currentVC = Navigator.shared.mainSceneWindow?.fromViewController,
              let targetView = currentVC.view else {
            ToastManager.logger.error("ToastManager show toast can not find top vc")
            return
        }
        if let key = key {
            var toastType: ShowToastActionMessage.ToastType = .success
            switch type {
            case .fail:
                toastType = .fail
            case .success:
                toastType = .success
            case .loading:
                toastType = .loading
            case .tips:
                toastType = .tips
            @unknown default:
                fatalError("new value")
            }
            self.showHud(message:
                ShowToastActionMessage(messageID: key, type: toastType, info: info)
            )
            return
        }
        let hud = RoundedHUD()
        switch type {
        case .fail:
            hud.showFailure(with: info, on: targetView)
        case .success:
            hud.showSuccess(with: info, on: targetView)
        case .loading:
            hud.showLoading(with: info, on: targetView)
        case .tips:
            hud.showTips(with: info, on: targetView)
        @unknown default:
            assert(false, "new value")
        }
    }

    public func pageDidDisappear() {
        self.removeAll()
    }
}
