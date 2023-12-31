//
//  TabFeatureGating.swift
//  ByteViewTab
//
//  Created by kiri on 2023/6/20.
//

import Foundation
import ByteViewCommon

final class TabFeatureGating {
    private let dependency: TabDependency
    init(dependency: TabDependency) {
        self.dependency = dependency
    }

    private func fg(_ key: String) -> Bool {
        let value = dependency.fg(key)
        Logger.tab.info("get fg \(key) success: \(value)")
        return value
    }

    /// 电话服务fg
    var isPhoneServiceEnabled: Bool {
        fg("byteview.vc.pstn.phoneservice")
    }

    /// 投屏fg
    var isShareScreenEnabled: Bool {
        fg("byteview.callmeeting.ios.screenshare_entry")
    }

    var isTabMinutesEnabled: Bool {
        fg("byteview.callmeeting.ios.lm_tab")
    }

    var isTabWebinarEnabled: Bool {
        fg("byteview.meeting.pc.webinar")
    }

    /// 别名展示设置
    var isShowAnotherNameEnabled: Bool {
        fg("lark.chatter.name_with_another_name_p2")
    }

    // MARK: - sip
    var isSipInviteEnabled: Bool {
        fg("byteview.meeting.ios.invitesip")
    }

    var isOnewayRelationshipEnable: Bool {
        fg("lark.client.contact.opt")
    }

    var isSmartFolderEnabled: Bool {
        fg("byteview.meeting.ios.smartfolder")
    }

    var isNotesEnabled: Bool {
        fg("byteview.meeting.meetingnotes")
    }
}
