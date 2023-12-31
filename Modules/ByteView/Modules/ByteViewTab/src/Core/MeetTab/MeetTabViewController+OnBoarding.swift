//
//  MeetTabViewController+OnBoarding.swift
//  ByteView
//
//  Created by fakegourmet on 2021/7/4.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import ByteViewUI

extension MeetTabViewController {
    func setupTabListOnboarding(refView: UIView) {
        //  判断是否展示onboarding
        guard viewModel.tabViewModel.shouldShowGuide(.tabList) else {
            return
        }
        let guideView = self.guideView ?? GuideView(frame: view.bounds)
        self.guideView = guideView
        if guideView.superview == nil {
            view.addSubview(guideView)
            guideView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        guideView.setStyle(.alert(content: I18n.View_G_ClickToViewMeetingDetails),
                           on: .top,
                           of: refView,
                           distance: 4)
        guideView.sureAction = { [weak self] _ in
            self?.viewModel.tabViewModel.didShowGuide(.tabList)
            self?.guideView?.removeFromSuperview()
            self?.guideView = nil
        }
    }
}
