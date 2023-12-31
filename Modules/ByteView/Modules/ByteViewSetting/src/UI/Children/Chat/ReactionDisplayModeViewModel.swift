//
//  ReactionDisplayModeViewModel.swift
//  ByteViewSetting
//
//  Created by YizhuoChen on 2023/10/13.
//

import Foundation
import ByteViewTracker

final class ReactionDisplayModeViewModel: SettingViewModel<SettingSourceContext> {
    override func setup() {
        super.setup()
        self.pageId = .reactionDisplayMode
        self.title = I18n.View_G_ReactionDisplay_Desc
    }

    override func buildSections(builder: SettingSectionBuilder) {
        let selectedDisplay = service.reactionDisplayMode
        builder.section()
        ReactionDisplayMode.allCases.forEach { mode in
            builder.checkmark(.reactionDisplayMode, title: mode.title, isOn: mode == selectedDisplay) { [weak self] _ in
                guard let self = self else { return }
                VCTracker.post(name: .vc_meeting_setting_click, params: [.click: mode.trackName, "setting_lab": "general"])
                self.service.reactionDisplayMode = mode
                self.reloadData()
            }
        }
    }

    override var supportsRotate: Bool {
        context.supportsRotate
    }
}

public enum ReactionDisplayMode: Int, CaseIterable {
    case floating
    case bubble

    var title: String {
        switch self {
        case .floating: return I18n.View_G_FloatUp_Options
        case .bubble: return I18n.View_G_PopUp_Options
        }
    }

    var trackName: String {
        switch self {
        case .floating: return "Float"
        case .bubble: return "Bubble"
        }
    }
}
