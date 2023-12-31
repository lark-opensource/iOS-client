//
//  InMeetFlowAndWhiteBoardViewController.swift
//  ByteView
//
//  Created by fakegourmet on 2022/6/17.
//

import Foundation

class InMeetFlowAndWhiteBoardViewControllerV2: InMeetFlowAndShareContainerViewControllerV2 {

    var menuGuide: UILayoutGuide? {
        guard let vc = shareScreenVC as? InMeetWhiteboardViewController else { return nil }
        return vc.whiteboardVC.phoneToolBarGuide
    }

    weak var shareDelegate: InMeetWhiteboardDelegate?

    convenience init(gridViewModel: InMeetGridViewModel, whiteBoardVC: InMeetWhiteboardViewController, shareDelegate: InMeetWhiteboardDelegate) {
        self.init(gridViewModel: gridViewModel, shareVC: whiteBoardVC, hasShrinkView: true)
        self.shareDelegate = shareDelegate
        whiteBoardVC.delegate = self
        gridViewModel.context.addListener(self, for: .whiteboardOperateStatus)
        addChild(whiteBoardVC)
    }


    override func updateShareScreenPageControl() {
        super.updateShareScreenPageControl()
        shareScreenPageControl.isHidden = viewModel.context.isWhiteboardMenuEnabled
    }
}

// 横屏工具菜单布局适配
extension InMeetFlowAndWhiteBoardViewControllerV2: InMeetWhiteboardDelegate {
    func whiteboardDidShowMenu() {
        shareDelegate?.whiteboardDidShowMenu()
        updateShareScreenPageControl()
    }

    func whiteboardDidHideMenu(isUpdate: Bool) {
        shareDelegate?.whiteboardDidHideMenu(isUpdate: isUpdate)
        updateShareScreenPageControl()
        // TODO: isUpdate参数为临时方案（iOS15系统+主动横屏会导致悬浮组件重叠）
        if isUpdate {
            self.updateMeetingLayoutStyle()
        }
    }

    func isWhiteboardMenuEnabled() -> Bool {
        shareDelegate?.isWhiteboardMenuEnabled() ?? viewModel.context.isWhiteboardMenuEnabled
    }

    func whiteboardEditAuthorityChanged(canEdit: Bool) {
        shareDelegate?.whiteboardEditAuthorityChanged(canEdit: canEdit)
    }
}

extension InMeetFlowAndWhiteBoardViewControllerV2: InMeetViewChangeListener {
    func viewDidChange(_ change: InMeetViewChange, userInfo: Any?) {
        if change == .whiteboardOperateStatus, let isOpaque = userInfo as? Bool {
            shareScreenShrinkView.didChangeWhiteboardOperateStatus(isOpaque: isOpaque)
        }
    }
}
