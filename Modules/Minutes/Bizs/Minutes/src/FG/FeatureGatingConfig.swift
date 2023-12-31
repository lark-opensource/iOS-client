//
//  FeatureGatingConfig.swift
//  LarkLive
//
//  Created by panzaofeng on 2021/12/23.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import LarkSetting

extension FeatureGatingManager.Key {
    static let byteviewMMIOSRecording: Self = "byteview_mm_ios_recording"
    static let archUserOrganizationName: Self = "arch.user.organizationnametag"
    static let mintutsReport: Self = "lark.tns.minutes_report"
    static let aiSummaryVisible: Self = "byteview.vc.minutes.ai_summary_visible"
    static let minutesSearchVisible: Self = "byteview.meeting.minutes_search"
    static let aiChaptersVisible: Self = "byteview.vc.minutes.ai_summary_chapters_visible"
    static let aiSpeakersVisible: Self = "byteview.vc.minutes.ai_summary_speaker_visible"
    static let lingoEnabled: Self = "byteview.vc.minutes.lingo"
}

final class FeatureGatingConfig {

    static var minutesRecordingEnabled: Bool {
        FeatureGatingManager.shared.featureGatingValue(with: .byteviewMMIOSRecording)
    }
    
    static var newExternalTagEnabled: Bool {
        FeatureGatingManager.shared.featureGatingValue(with: .archUserOrganizationName)
    }

    static var isMinutesReportEnabled: Bool {
        FeatureGatingManager.shared.featureGatingValue(with: .mintutsReport)
    }
}
