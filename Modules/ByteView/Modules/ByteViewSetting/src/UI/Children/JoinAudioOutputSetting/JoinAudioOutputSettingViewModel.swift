//
//  JoinAudioOutputSettingViewModel.swift
//  ByteViewSetting
//
//  Created by ByteDance on 2023/8/21.
//

import Foundation
import ByteViewTracker

final class JoinAudioOutputSettingViewModel: SettingViewModel<SettingSourceContext> {
    override func setup() {
        super.setup()
        self.title = I18n.View_G_DefaultAudioUse_Subtitle
    }

    override func buildSections(builder: SettingSectionBuilder) {
        builder.section()
        let joinAudioType = service.userjoinAudioOutputSetting
        models.forEach { type in
            builder.checkmark(.audioOutputDevice, title: type.text, isOn: type == joinAudioType) { [weak self] _ in
                guard let self = self else { return }
                self.service.saveUserjoinAudioOutputSetting(type.rawValue)
                self.track(type: type)
                self.reloadData()
            }
        }
    }

    func track(type: JoinAudioOutputSettingType) {
        var typeName = ""
        switch type {
        case .last:
            typeName = "last"
        case .receiver:
            typeName = "receiver"
        case .speaker:
            typeName = "speaker"
        }
        VCTracker.post(name: .setting_detail_click, params: [.click: typeName, "type": "audio_device"])
    }

    override var supportsRotate: Bool {
        context.supportsRotate
    }

    private var models: [JoinAudioOutputSettingType] = [.last, .receiver, .speaker]
}
