//   
//   LiveSettingUnavailableView.swift
//   ByteView
// 
//  Created by hubo on 2023/2/9.
//  Copyright © 2023 Bytedance.Inc. All rights reserved.
//   


import ByteViewNetwork
import ByteViewUI
import UniverseDesignEmpty

final class LiveSettingUnavailableAlert {
    static func unavailableAlert(type: ByteLiveUnavailableType, role: GetLiveProviderInfoResponse.ByteLiveUserRole) -> ByteViewDialog.Builder {
        var title = ""
        var description = ""
        var buttonTitle = I18n.View_G_OkButton
        var emptyType = UDEmptyType.noAccess

        switch type {
        case .inactive:
            emptyType = .noAccess
            title = BundleI18n.ByteView.View_MV_LiveServiceUnavailable
        case .versionExpired:
            emptyType = .ccmAdvancedPermissionUpgrade
            title = BundleI18n.ByteView.View_MV_ServiceExpired
        case .packageExpired:
            emptyType = .ccmAdvancedPermissionUpgrade
            title = BundleI18n.ByteView.View_MV_NoBilling
        case .noAppPermission:
            emptyType = .noAccess
            title = BundleI18n.ByteView.View_G_NoAppPermit_LiveNote
            buttonTitle = BundleI18n.ByteView.View_G_SendRequest_LiveButton
        case .needCreateSubAccount:
            emptyType = .noAccess
            title = BundleI18n.ByteView.View_MV_LiveServiceUnavailable
            buttonTitle = BundleI18n.ByteView.View_G_SendRequest_LiveButton
        default:
            break
        }

        switch role {
        case .admin:
            switch type {
            case .inactive:
                description = BundleI18n.ByteView.View_MV_NotActivateGoWebConsole
            case .versionExpired:
                description = BundleI18n.ByteView.View_MV_ServiceExpiredGoOrContact
            case .packageExpired:
                description = BundleI18n.ByteView.View_MV_NoDemandBillingGoConsole
            case .noAppPermission:
                description = BundleI18n.ByteView.View_G_SendRequestToAdmin_LivePop
            case .needCreateSubAccount:
                description = BundleI18n.ByteView.View_MV_NotActivateGoRequest
            default:
                description = BundleI18n.ByteView.View_MV_NotActivateGoWebConsole
            }
        case .normal:
            switch type {
            case .inactive:
                description = BundleI18n.ByteView.View_MV_NotActivateGoRequest
            case .versionExpired:
                description = BundleI18n.ByteView.View_MV_ExpireGoContactRenew
            case .packageExpired:
                description = BundleI18n.ByteView.View_MV_NoDemandBillingGoContact
            case .noAppPermission:
                description = BundleI18n.ByteView.View_G_SendRequestToAdmin_LivePop
            case .needCreateSubAccount:
                description = BundleI18n.ByteView.View_MV_NotActivateGoRequest
            default:
                description = BundleI18n.ByteView.View_MV_NotActivateGoWebConsole
            }
        default:
            break
        }

        let style = NSMutableParagraphStyle()
        style.lineHeightMultiple = 1.12
        let attributeDescription = NSAttributedString(string: description,
                                                      attributes: [
                                                        .paragraphStyle: style,
                                                        .font: UIFont.systemFont(ofSize: 14)
                                                      ])

        let config = UDEmptyConfig(title: UDEmptyConfig.Title(titleText: title),
                                   description: UDEmptyConfig.Description(descriptionText: attributeDescription),
                                   type: emptyType)
        let emptyView = UDEmpty(config: config)
        var builder = ByteViewDialog.Builder()
            .contentView(emptyView)
            .needAutoDismiss(true)
            .rightTitle(buttonTitle)
        if type == .noAppPermission
            || type == .needCreateSubAccount {
            builder = builder.leftTitle(BundleI18n.ByteView.View_G_CancelButton)
        }
        return builder
    }
}
