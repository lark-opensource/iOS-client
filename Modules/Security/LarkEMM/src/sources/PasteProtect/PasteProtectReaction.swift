//
//  PasteProtectReaction.swift
//  LarkEMM
//
//  Created by ByteDance on 2022/7/25.
//

import UIKit
import LarkContainer
import UniverseDesignDialog
import EENavigator
import UniverseDesignCheckBox
import UniverseDesignToast
import LarkSecurityComplianceInfra
import SnapKit
import AppContainer

final class PasteProtectUDDialog: UDDialog {}

final class PasteProtectReaction {
    var pasteboardService: PasteboardService? {
        return try? userResolver.resolve(assert: PasteboardService.self)
    }
    var isShowing: Bool { dialog != nil }

    private var pointId: String?
    private var isCheckBoxSelected: Bool = false

    private let udkv: SCKeyValueStorage

    private var dialog: PasteProtectUDDialog?

    private var pasteboardRemindKey: String {
        return "lark.securityCompliance.\(self.pasteboardService?.currentEncryptUserId() ?? "" ).pasteboardRemindCopied"
    }

    private var pasteboardRemindClickTimes: String {
        return "lark.securityCompliance.\(self.pasteboardService?.currentEncryptUserId() ?? "").pasteboardRemindClickTimes"
    }

    let userResolver: UserResolver

    init(resolver: UserResolver, pointId: String?) {
        self.pointId = pointId
        self.userResolver = resolver
        self.udkv = SCKeyValue.userDefaultEncrypted(userId: resolver.userID, business: .pasteProtect)
    }

    deinit {
        dismiss()
    }

    func show() {
        if let pointId = pointId {
            showToastIfNeeded(pointId)
        } else {
            showDialogIfNeeded()
        }
    }

    func dismiss() {
        dialog?.view.removeFromSuperview()
        dialog = nil
    }

    private func showToastIfNeeded(_ pointId: String) {
        if let window = UIWindow.ud.keyWindow {
            UDToast.showTips(with: I18N.Lark_TerminalSecurity_Toast_OnlyPasteInCurrentDoc, on: window)
            SCLogger.info("SCPasteboard: show pointId toast ")
        }
    }

    private func showDialogIfNeeded() {
        guard let window = UIWindow.ud.keyWindow else { return }
        guard let tenantName = pasteboardService?.currentTenantName() else { return }
        guard canShowDialog() else { return }
        window.endEditing(true)

        let config = UDDialogUIConfig()
        config.style = .vertical
        let dialog: PasteProtectUDDialog = PasteProtectUDDialog(config: config)
        let title = I18N.Lark_TerminalSecurity_Dialog_Notification
        let subTitle = I18N.Lark_TerminalSecurity_Dialog_CannotPasteExternal(tenantName)
        dialog.setTitle(text: title)
        dialog.setContent(view: remindeBox(subTitle: subTitle))
        dialog.addPrimaryButton(text: I18N.Lark_TerminalSecurity_Button_GotIt, dismissCompletion: { [weak self, weak dialog] in
            guard let self = self else { return }
            dialog?.view.removeFromSuperview()
            self.cacheClickTimesAndRemindKey()
            let service = try? self.userResolver.resolve(assert: PasteboardService.self)
            service?.dismissDialog()
        })
        self.dialog = dialog

        let bgView: UIView = UIView()
        bgView.backgroundColor = UIColor.ud.bgMask
        dialog.view.addSubview(bgView)
        dialog.view.sendSubviewToBack(bgView)
        bgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        window.addSubview(dialog.view)
        dialog.view.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        pasteboardService?.onWaterMarkViewCovered(window)
        Events.track("paste_remind_view")
        SCLogger.info("SCPasteboard: showDialogIfNeed")
    }

    private func canShowDialog() -> Bool {
        let hasReminded = udkv.bool(forKey: pasteboardRemindKey)
        guard !hasReminded else {
            SCLogger.info("SCPasteboard: dialog has clicked reminded")
            return false
        }

        guard let window = UIWindow.ud.keyWindow else { return false }
        let hasShown = window.subviews.contains { view in
          if let childViewController = view.next as? UIViewController, childViewController.isKind(of: PasteProtectUDDialog.self) {
            return true
          }
          return false
        }
        guard !hasShown else {
            SCLogger.info("SCPasteboard: dialog has shown")
            return false
        }

        return true
    }
}

extension PasteProtectReaction {
    private func remindeBox(subTitle: String) -> UIView {
        let contentView = UIView()

        let contentLabel = UILabel()
        contentLabel.numberOfLines = 0
        contentLabel.text = subTitle
        contentLabel.textColor = UIColor.ud.textTitle
        contentLabel.font = UIFont.systemFont(ofSize: 16)
        contentView.addSubview(contentLabel)
        contentLabel.snp.makeConstraints { make in
            make.left.equalTo(contentView.snp.left)
            make.right.equalTo(contentView.snp.right)
            make.top.equalToSuperview()
        }

        let checkbox: UDCheckBox = UDCheckBox(boxType: .multiple) { [weak self] checkBox in
            guard let self = self else { return }
            checkBox.isSelected = !checkBox.isSelected
            self.isCheckBoxSelected = checkBox.isSelected
        }
        contentView.addSubview(checkbox)
        checkbox.snp.makeConstraints { make in
            make.left.equalTo(contentView.snp.left)
            make.size.equalTo(CGSize(width: 16, height: 16))
            make.top.equalTo(contentLabel.snp.bottom).offset(15)
        }

        let remindLabel = UILabel()
        remindLabel.font = UIFont.systemFont(ofSize: 16)
        remindLabel.textColor = UIColor.ud.textTitle
        contentView.addSubview(remindLabel)
        remindLabel.text = I18N.Lark_TerminalSecurity_Button_DoNotShowAgain
        remindLabel.snp.makeConstraints { make in
            make.left.equalTo(checkbox.snp.right).offset(8)
            make.centerY.equalTo(checkbox.snp.centerY)
            make.bottom.equalTo(contentView.snp.bottom)
        }

        return contentView
    }

    private func cacheClickTimesAndRemindKey() {
        let clickTimes = udkv.integer(forKey: pasteboardRemindClickTimes) + 1
        Events.track("paste_remind_click", params: ["click": "got_it",
                                                    "target": "none",
                                                    "is_no_more_remind": self.isCheckBoxSelected ? "true" : "false",
                                                    "times": clickTimes])
        let cacheTimes = self.isCheckBoxSelected ? 0 : clickTimes
        udkv.set(cacheTimes, forKey: pasteboardRemindClickTimes)
        if self.isCheckBoxSelected {
            udkv.set(true, forKey: pasteboardRemindKey)
        }
        SCLogger.info("SCPasteboard: click diaglog no reminder, checkbox selected:\(self.isCheckBoxSelected), click times:\(clickTimes)")
    }
}
