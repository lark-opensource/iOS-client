//
//  UserSettingManager+Service.swift
//  ByteViewSetting
//
//  Created by kiri on 2023/4/10.
//

import Foundation
import ByteViewCommon
import ByteViewNetwork

public extension UserSettingManager {
    func updateCustomRingtone(_ ringtone: String, completion: ((Result<PatchViewUserSettingResponse, Error>) -> Void)? = nil) {
        updateViewUserSetting({ $0.customRingtone = ringtone }, completion: completion)
    }

    func getMobileCode(for key: String) -> MobileCode? {
        mobileCodes.first { $0.key == key }
    }
//
//    var isLabEnabled: Bool {
//        isVirtualBgEnabled || isAnimojiEnabled || isFilterEnabled || isRetuschierenEnabled
//    }

//
//    /// MagicShare中DocX的灰度
//    /// 灰度内，灰度范围内能发起 DocX 的共享和看共享
//    /// 灰度外，支持在共享面板上搜索到 DocX 文档，但是不支持发起，同时隐藏新建 DocX 的入口
//    var isMSDocXEnabled: Bool {
//        fg("byteview.meeting.ios.magic_share_docx")
//    }
//
//    /// MagicShare中新建DocX选项后是否显示beta标签
//    var isMSCreateNewDocXBetaShow: Bool {
//        return fg("byteview.meeting.ios.magic_share_docx_beta")
//    }

    var isEnterprisePhoneEnabled: Bool {
        enterprisePhoneConfig.authorized && fg("byteview.meeting.businessphone")
    }

    /// 是否开启1v1密聊二次确认框
    var isSecretChatRemindEnabled: Bool {
        fg("byteview.videocall.icryptochat.remind")
    }

    ///  虚拟背景是否可以用coreml
    var isVirtualBgCoremlEnabled: Bool {
        if #available(iOS 14.0, *), fg("byteview.meeting.ios.background_coreml_enable") {
            // A12芯片以上
            if Display.phone {
                // nolint-next-line: magic number
                return DeviceUtil.modelNumber >= DeviceModelNumber(major: 11, minor: 2)
            } else if Display.pad {
                return DeviceUtil.modelNumber >= DeviceModelNumber(major: 8, minor: 1)
            }
        }
        return false
    }

    /// 是否展示关联标签
    var isRelationTagEnabled: Bool {
        fg("lark.suite_admin.orm.b2b.relation_tag_for_office_apps")
    }

    var nfdScanConfig: String {
        settings(for: .nfd_scan_config, defaultValue: "")
    }

    var pstnInviteConfig: PSTNInviteConfig {
        settings(for: .vc_phone_call_config, defaultValue: .default)
    }

    var enterpriseLimitLinkConfig: EnterpriseLimitLinkConfig {
        settings(for: .vc_enterprise_control_link, defaultValue: .default)
    }

    var floatReactionConfig: FloatReactionConfig {
        settings(for: .vc_float_reaction_config, defaultValue: .default)
    }

    var multiResolutionConfig: MultiResolutionConfig {
        if let debugConfig = DebugSettings.multiResolutionConfig {
            return debugConfig
        } else {
            return settings(for: .vc_multi_resolution_config, defaultValue: .default)
        }
    }
}
