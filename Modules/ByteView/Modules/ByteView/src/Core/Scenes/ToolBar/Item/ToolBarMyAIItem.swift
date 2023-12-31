//
//  ToolbarMyAIItem.swift
//  ByteView
//
//  Created by 陈乐辉 on 2023/7/12.
//

import Foundation
import ByteViewSetting
import UniverseDesignIcon
import ByteViewNetwork

final class ToolBarMyAIItem: ToolBarItem {

    private let viewModel: MyAIViewModel

    override var itemType: ToolBarItemType { .myai }

    override var title: String {
        viewModel.displayName
    }

    override var titleColor: ToolBarColorType {
        if viewModel.isShowListening {
            .obliqueGradientColor(colors: [UIColor(hex: "#4752E6"), UIColor(hex: "#CF5ECF")])
        } else {
            .none
        }
    }

    override var filledIcon: ToolBarIconType {
        let image = UIImage.dynamic(light: UDIcon.getIconByKey(.myaiColorful), dark: UDIcon.getIconByKey(.myaiColorful))
        return .image(image)
    }

    override var outlinedIcon: ToolBarIconType {
        filledIcon
    }

    override var isEnabled: Bool {
        viewModel.isEnabled
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        viewModel.isEnabled ? .more : .none
    }

    required init(meeting: InMeetMeeting, provider: ToolBarServiceProvider?, resolver: InMeetViewModelResolver) {
        self.viewModel = resolver.resolve()!
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        meeting.setting.addListener(self, for: .isMyAIEnabled)
        self.viewModel.addListener(self)
    }

    override func clickAction() {
        shrinkToolBar { [weak self] in
            self?.viewModel.open()
        }
    }
}

extension ToolBarMyAIItem: MeetingSettingListener {
    func didChangeMeetingSetting(_ settings: MeetingSettingManager, key: MeetingSettingKey, isOn: Bool) {
        Util.runInMainThread {
            self.notifyListeners()
        }
    }
}

extension ToolBarMyAIItem: MyAIViewModelListener {
    func myAITitleDidUpdated() {
        notifyListeners()
    }
}
