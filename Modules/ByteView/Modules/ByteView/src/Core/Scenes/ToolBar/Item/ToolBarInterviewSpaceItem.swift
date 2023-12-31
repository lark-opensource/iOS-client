//
//  ToolBarInterviewSpaceItem.swift
//  ByteView
//
//  Created by YizhuoChen on 2023/7/14.
//

import Foundation

final class ToolBarInterviewSpaceItem: ToolBarItem {
    override var itemType: ToolBarItemType { .interviewSpace }

    override var title: String {
        I18n.View_G_InterviewSpace_Button
    }

    override var filledIcon: ToolBarIconType {
        .icon(key: .hirelogoFilled)
    }

    override var outlinedIcon: ToolBarIconType {
        .icon(key: .hirelogoOutlined)
    }

    override var phoneLocation: ToolBarItemPhoneLocation {
        entranceEnable ? .more : .none
    }

    override var desiredPadLocation: ToolBarItemPadLocation {
        entranceEnable ? .right : .none
    }

    /// 标记接收自动开启事件
    private var receiveAutoOpenEvent: Bool = false
    private var viewModel: InMeetInterviewSpaceViewModel?
    private var entranceEnable: Bool = false
    private var hasShownGuide: Bool = false
    private var shouldShowGuide: Bool = false {
        didSet {
            if shouldShowGuide != oldValue {
                if shouldShowGuide {
                    showGuide()
                } else {
                    hideGuide()
                }
            }
        }
    }

    required init(meeting: InMeetMeeting,
                  provider: ToolBarServiceProvider?,
                  resolver: InMeetViewModelResolver) {
        self.viewModel = resolver.resolve()
        super.init(meeting: meeting, provider: provider, resolver: resolver)
        guard viewModel?.isInterviewSpaceEnabled == true else { return }
        viewModel?.addListener(self, fireImmediately: false)
        updateEntrance()
    }

    override func clickAction() {
        shrinkToolBar { [weak self] in
            self?.viewModel?.openInterviewSpace()
        }
    }

    private func updateEntrance() {
        let hasData = viewModel?.hasData == true
        entranceEnable = receiveAutoOpenEvent && hasData
    }

    private func updateGuide() {
        shouldShowGuide = receiveAutoOpenEvent && !hasShownGuide && entranceEnable && meeting.service.shouldShowGuide(.interviewSpace)
    }

    private func showGuide() {
        let guide = GuideDescriptor(type: .interviewSpace, title: nil, desc: I18n.View_G_Interview_Onboarding)
        guide.style = .alert
        guide.sureAction = { [weak self] in
            self?.hasShownGuide = true
            self?.meeting.service.didShowGuide(.interviewSpace)
        }
        GuideManager.shared.request(guide: guide)
    }

    private func hideGuide() {
        GuideManager.shared.dismissGuide(with: .interviewSpace)
    }
}

extension ToolBarInterviewSpaceItem: InMeetInterviewSpaceDataObserver {
    func didChangeUrl(urlString: String) {
        receiveAutoOpenEvent = true
        Util.runInMainThread {
            self.updateEntrance()
            self.updateGuide()
            self.notifyListeners()
        }
    }
}
