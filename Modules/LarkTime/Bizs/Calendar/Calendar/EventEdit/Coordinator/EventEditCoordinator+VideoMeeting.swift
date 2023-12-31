//
//  EventEditCoordinator+VideoMeeting.swift
//  Calendar
//
//  Created by zhuheng on 2021/4/7.
//

import Foundation
import LarkUIKit

/// 编辑日程日历

extension EventEditCoordinator: EventEditVideoMeetingDelegate {
    func selectVideoMeeting(from fromVC: EventEditViewController) {
        guard let event = fromVC.viewModel.eventModel?.rxModel?.value,
              let permissions = fromVC.viewModel.permissionModel?.rxPermissions.value.videoMeeting  else { return }
        let viewModle = VideoMeetingSettingViewModel(event: event, permissions: permissions, userResolver: self.userResolver)
        let toVC = VideoMeetingSettingViewController(viewModel: viewModle, userResolver: userResolver)
        toVC.delegate = self
        CalendarTracer.shared.editVCSet(actionSource: fromVC.viewModel.actionSource)
        enter(from: fromVC, to: toVC)
    }
}

extension EventEditCoordinator: VideoMeetingSettingViewControllerDelegate {
    func didFinishEdit(from viewController: VideoMeetingSettingViewController) {
        eventViewController?.viewModel.updateVideoMeeting(viewController.viewModel.rxVideoMeeting.value, zoomConfig: viewController.viewModel.localZoomConfig)
        exit(from: viewController)
    }
}
