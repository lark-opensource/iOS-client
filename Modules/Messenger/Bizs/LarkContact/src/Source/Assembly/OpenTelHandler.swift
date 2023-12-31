//
//  OpenTelHandler.swift
//  Lark
//
//  Created by lichen on 2018/4/28.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkActionSheet
import LarkAlertController
import RxSwift
import LarkContainer
import LarkFoundation
import EENavigator
import UniverseDesignToast
import LarkUIKit
import LarkMessengerInterface
import Homeric
import LKCommonsTracker
import LarkEMM
import LarkNavigator
import UniverseDesignActionPanel
import LarkFeatureGating
import LarkSensitivityControl
import LarkSetting

final class OpenTelHandler: UserTypedRouterHandler {
    @ScopedInjectedLazy var dependency: ContactMeetingDependency?
    private lazy var saveToContactsFG: Bool = userResolver.fg.staticFeatureGatingValue(with: "lark.core.save_to_contacts")
    func handle(_ body: OpenTelBody, req: EENavigator.Request, res: Response) throws {
        let number = body.number
        guard !number.isEmpty else {
            res.end(error: RouterError.invalidParameters("Telnumber"))
            return
        }
        let regExp = try? NSRegularExpression(pattern: "^\\d{9}$", options: [])
        let noSpaceNumber = number.replacingOccurrences(of: " ", with: "", options: .literal, range: nil)
        let isMeetingId = !(regExp?.matches(in: noSpaceNumber, options: [], range: NSRange(location: 0, length: noSpaceNumber.count)).isEmpty ?? true)
        let title = isMeetingId ? BundleI18n.LarkContact.View_G_IdOrPhoneNumber(number) : number + BundleI18n.LarkContact.Lark_Legacy_DialogPhoneDetermine
        Tracker.post(TeaEvent(Homeric.IM_CHAT_MEETING_ID_RECOGNIZE_VIEW))
        if saveToContactsFG ? true : Display.phone {
            let actionSheet = ActionSheet(title: title)

            if isMeetingId {
                actionSheet.addItem(title: BundleI18n.LarkContact.View_G_JoinMeeting) {
                    Tracker.post(TeaEvent(Homeric.IM_CHAT_MEETING_ID_RECOGNIZE_CLICK,
                                          params: ["click": "join_meeting",
                                                   "target": "vc_meeting_pre_view"]))

                    self.dependency?.joinMeetingByNumber(meetingNumber: noSpaceNumber, entrySource: body.source)
                }
            }
            actionSheet.addItem(title: BundleI18n.LarkContact.Lark_Legacy_LarkCall) {
                if isMeetingId {
                    Tracker.post(TeaEvent(Homeric.IM_CHAT_MEETING_ID_RECOGNIZE_CLICK,
                                          params: ["click": "call",
                                                   "target": "none"]))
                }
                LarkFoundation.Utils.telecall(phoneNumber: number)
            }

            actionSheet.addItem(title: BundleI18n.LarkContact.Lark_Legacy_Copy) {
                if isMeetingId {
                    Tracker.post(TeaEvent(Homeric.IM_CHAT_MEETING_ID_RECOGNIZE_CLICK,
                                          params: ["click": "copy",
                                                   "target": "im_chat_main_view"]))
                }
                if ContactPasteboard.writeToPasteboard(string: number) {
                    if let window = req.from.fromViewController?.view.window {
                        UDToast.showSuccess(with: BundleI18n.LarkContact.Lark_Legacy_Copied, on: window)
                    }
                } else {
                    if let window = req.from.fromViewController?.view.window {
                        UDToast.showFailure(with: BundleI18n.LarkContact.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: window)
                    }
                }
            }
            if saveToContactsFG {
                actionSheet.addItem(title: BundleI18n.LarkContact.Lark_Core_AddToPhoneContacts_Button) {
                    self.showContactActionSheet(from: req.from, phoneNumber: number)
                }
            }

            actionSheet.addCancelItem(title: BundleI18n.LarkContact.Lark_Legacy_Cancel) {
                if isMeetingId {
                    Tracker.post(TeaEvent(Homeric.IM_CHAT_MEETING_ID_RECOGNIZE_CLICK,
                                          params: ["click": "cancel",
                                                   "target": "im_chat_main_view"]))
                }
            }
            userResolver.navigator.present(actionSheet, from: req.from)
        } else {
            let alertVC = LarkAlertController()
            alertVC.setContent(text: title)
            alertVC.addCancelButton()
            alertVC.addPrimaryButton(text: BundleI18n.LarkContact.Lark_Legacy_Copy, dismissCompletion: {
                if ContactPasteboard.writeToPasteboard(string: number) {
                    if let window = req.from.fromViewController?.view.window {
                        UDToast.showSuccess(with: BundleI18n.LarkContact.Lark_Legacy_Copied, on: window)
                    }
                } else {
                    if let window = req.from.fromViewController?.view.window {
                        UDToast.showFailure(with: BundleI18n.LarkContact.Lark_IM_CopyContent_CopyingIsForbidden_Toast, on: window)
                    }
                }
            })
            userResolver.navigator.present(alertVC, from: req.from)
        }

        res.end(resource: EmptyResource())
    }

    private func showContactActionSheet(from: EENavigator.NavigatorFrom, phoneNumber: String) {
        let config = UDActionSheetUIConfig(isShowTitle: false)
        let actionSheet = UDActionSheet(config: config)
        guard let fromVC = from.fromViewController else { return }
        actionSheet.addDefaultItem(text: BundleI18n.LarkContact.Lark_Core_AddToPhoneContacts_CreateNew_Button) {
            ContactSaveUtil.contactSaveUtilSharedInstance.createContact(phoneNumber: phoneNumber, fromVC: fromVC)
        }
        actionSheet.addDefaultItem(text: BundleI18n.LarkContact.Lark_Core_AddToPhoneContacts_Existing_Button) {
            ContactSaveUtil.contactSaveUtilSharedInstance.pickerContact(phoneNumber: phoneNumber, fromVC: fromVC)
        }
        actionSheet.setCancelItem(text: BundleI18n.LarkContact.Lark_Core_AddToPhoneContacts_Cancel_Button)
        userResolver.navigator.present(actionSheet, from: from)
    }
}
