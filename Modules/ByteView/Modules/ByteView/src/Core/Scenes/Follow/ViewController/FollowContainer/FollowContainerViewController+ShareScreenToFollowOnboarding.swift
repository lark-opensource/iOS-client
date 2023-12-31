//
//  FollowContainerViewController+ShareScreenToFollowOnboarding.swift
//  ByteView
//
//  Created by liurundong.henry on 2023/1/31.
//

import Foundation

extension FollowContainerViewController: GuideManagerDelegate {

    func guideCanShow(_ guide: GuideDescriptor) -> Bool {
        guard guide.type == .shareScreenToFollowReturnToShareScreen,
              viewModel.service.shouldShowGuide(.enteredNewMagicShare),
              viewModel.manager.currentRuntime?.documentInfo.isSSToMS == true else {
            return false
        }
        showReturnToShareScreenGuideOnMainThread()
        return true
    }

}

extension FollowContainerViewController {

    /// 请求显示“点击回到共享屏幕”引导页
    func requestShowReturnToShareScreenGuide() {
        guard viewModel.manager.currentRuntime?.documentInfo.isSSToMS == true,
              viewModel.service.shouldShowGuide(.enteredNewMagicShare) else {
            return
        }
        // nolint-next-line: magic number
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let guideDesc = GuideDescriptor(type: .shareScreenToFollowReturnToShareScreen,
                                            title: I18n.View_G_ClickReturnToSharing,
                                            desc: nil)
            GuideManager.shared.request(guide: guideDesc)
        }
    }

    func showReturnToShareScreenGuideOnMainThread() {
        Util.runInMainThread { [weak self] in
            self?.showReturnToShareScreenGuide()
        }
    }

    func removeReturnToShareScreenGuideOnMainThread() {
        Util.runInMainThread { [weak self] in
            self?.removeReturnToShareScreenGuide()
        }
    }

    func showReturnToShareScreenGuide() {
        self.removeReturnToShareScreenGuideOnMainThread()
        guard self.returnToShareScreenGuideView == nil,
              let inMeetViewContainer = self.container else {
            return
        }
        // 生成锚点视图
        let backToPresenterButton = operationView.backToPresenterButton
        let anchorRect = backToPresenterButton.convert(backToPresenterButton.bounds, to: inMeetViewContainer.view)
        let anchorView = UIView(frame: anchorRect)
        self.returnToShareScreenGuideAnchorView = anchorView
        anchorView.isUserInteractionEnabled = false
        inMeetViewContainer.view.addSubview(anchorView)
        // 初始化引导页，放在GuideComponent上
        let guideView = GuideView(frame: .zero)
        self.returnToShareScreenGuideView = guideView
        inMeetViewContainer.addContent(guideView, level: .guide)
        // 配置点击效果
        guideView.sureAction = { [weak self] _ in
            self?.viewModel.service.didShowGuide(.enteredNewMagicShare)
            self?.removeReturnToShareScreenGuideOnMainThread()
            ShareScreenToFollowTracks.trackClickOnboarding(with: .backToScreen, clickType: .check)
        }
        // 显示引导页
        guideView.snp.remakeConstraints {
            $0.edges.equalToSuperview()
        }
        guideView.setStyle(.plain(content: I18n.View_G_ClickReturnToSharing),
                           on: Display.phone ? .top : .bottom,
                           of: anchorView,
                           distance: 4)
        // 显示引导页数据埋点
        ShareScreenToFollowTracks.trackShowOnboarding(with: .backToScreen)
    }

    /// 移除GuideView和AnchorView
    func removeReturnToShareScreenGuide() {
        if let guideView = self.returnToShareScreenGuideView {
            guideView.removeFromSuperview()
        }
        self.returnToShareScreenGuideView = nil
        if let anchorView = self.returnToShareScreenGuideAnchorView {
            anchorView.removeFromSuperview()
        }
        self.returnToShareScreenGuideAnchorView = nil
        GuideManager.shared.dismissGuide(with: .shareScreenToFollowReturnToShareScreen)
    }

}
