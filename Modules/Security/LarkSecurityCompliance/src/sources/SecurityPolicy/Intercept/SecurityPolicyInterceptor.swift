//
//  SecurityPolicyInterceptor.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/11/16.
//
import Foundation
import LarkSecurityComplianceInterface
import LarkSecurityComplianceInfra
import UniverseDesignDialog
import UniverseDesignToast
import LarkContainer
import SwiftyJSON
import EENavigator
import RxSwift

protocol SecurityPolicyInterceptService {
    func showInterceptDialog(interceptorModel: NoPermissionRustActionModel)

    func showDowngradeDialog()

    func showUniversalFallbackToast()

    func dismissDialog(dialog: UDDialog)

    func showDialog(dialog: UDDialog)
}

final class SecurityPolicyInterceptorIMP: SecurityPolicyInterceptService {
    private let disposeBag = DisposeBag()
    let resolver: UserResolver
    private var windowGroups: [WindowGroup] = []

    init(resolver: UserResolver) {
        self.resolver = resolver
    }

    deinit {
        windowGroups.forEach {
            dismissDialog(dialog: $0.dialog)
        }
    }

    private func isEnableToIntercept(withWindow: UIWindow) -> Bool {
        guard !SecurityPolicyConstKey.disableFileOperateOrStrategy else {
            SPLogger.info("security policy: interceptor, settings is off")
            return false
        }
        if windowGroups.contains(where: { $0.window == withWindow }) {
            SPLogger.info("security policy: current window is showing dialog")
            return false
        }
        return true
    }

    func showInterceptDialog(interceptorModel: NoPermissionRustActionModel) {
        let params = interceptorModel.model?.params
        let operateStr = params?[Key.operate.rawValue]?.stringValue
        let operate = EntityOperate(rawValue: operateStr ?? "") ?? .unknown
        let fileBizStr = params?[Key.bizDomain.rawValue]?.stringValue
        let fileBiz = FileBizDomain(rawValue: fileBizStr ?? "") ?? .unknown
        let code = "\(operate.category.rawValue)" + getLowCode(operate: operate)
        let dialog = UDDialog()
        dialog.setTitle(text: operate.category.title)
        dialog.setContent(text: getInterceptText(code: code))
        dialog.addPrimaryButton(text: I18N.Lark_Conditions_GotIt, dismissCompletion: { [weak self, weak dialog] in
            guard let dialog else { return }
            self?.dismissDialog(dialog: dialog)
        })
        showDialog(dialog: dialog)
        SecurityPolicyEventTrack.larkSCSActionFailPopUpView(businessType: fileBiz.trackName, actionType: operate.category.trackName)
    }

    func showDowngradeDialog() {
        let dialog = UDDialog()
        dialog.setTitle(text: I18N.Lark_SecureDowngrade_Others_UnableToManage)
        dialog.setContent(text: I18N.Lark_SecureDowngrade_Others_UnableToManageDetails)
        dialog.addPrimaryButton(text: I18N.Lark_Conditions_GotIt, dismissCompletion: { [weak self, weak dialog] in
            guard let dialog else { return }
            self?.dismissDialog(dialog: dialog)
        })
        showDialog(dialog: dialog)
    }

    func showUniversalFallbackToast() {
        guard let window = resolver.navigator.mainSceneWindow else {
            SPLogger.error("security policy: cant find window to show toast")
            return
        }
        guard isEnableToIntercept(withWindow: window) else { return }
        UDToast().showFailure(with: I18N.Lark_SecureDowngrade_Toast_UnableToEditInternetError, on: window)
        SPLogger.info("security policy: show fallback toast")
    }

    func dismissDialog(dialog: UDDialog) {
        if let windowGroup = windowGroups.first(where: { $0.dialog == dialog }) {
            let bgView = windowGroup.bgView
            dialog.view.removeFromSuperview()
            bgView.removeFromSuperview()
            windowGroups.removeAll { $0.dialog == dialog }
        }
    }

    func showDialog(dialog: UDDialog) {
        guard let window = UIWindow.ud.keyWindow else {
            SPLogger.error("security policy: cant find window to show intercept dialog")
            return
        }
        guard isEnableToIntercept(withWindow: window) else { return }
        endAllWindowsEditing()
        let bgView = UIView(frame: UIWindow.ud.windowBounds)
        bgView.backgroundColor = .ud.bgMask
        window.addSubview(bgView)
        bgView.snp.makeConstraints { $0.edges.equalToSuperview() }
        bgView.addSubview(dialog.view)
        dialog.view.snp.makeConstraints { $0.edges.equalToSuperview() }
        let windowGroup = WindowGroup(window: window, dialog: dialog, bgView: bgView)
        windowGroups.append(windowGroup)
        SPLogger.info("security policy: show security policy dialog")
    }

    private func endAllWindowsEditing() {
        if #available(iOS 13.0, *) {
            UIApplication.shared.connectedScenes.forEach { scene in
                (scene as? UIWindowScene)?.windows.forEach({ $0.endEditing(true) })
            }
        } else {
            UIApplication.shared.windows.forEach { $0.endEditing(true) }
        }
    }
}

enum Key: String {
    case bizDomain = "file_biz_domain"
    case operate = "entity_operation"
}

private struct WindowGroup {
    weak var window: UIWindow?
    var dialog: UDDialog
    var bgView: UIView
}
