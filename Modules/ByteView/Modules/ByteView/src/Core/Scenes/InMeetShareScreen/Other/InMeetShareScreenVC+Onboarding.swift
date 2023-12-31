//
//  InMeetShareScreenVC+Onboarding.swift
//  ByteView
//
//  Created by liurundong.henry on 2023/2/8.
//

import Foundation

extension InMeetShareScreenVC: GuideManagerDelegate {

    func guideCanShow(_ guide: GuideDescriptor) -> Bool {
        guard guide.type == .shareScreenToFollowViewOnYourOwn,
              viewModel.meeting.service.shouldShowGuide(.enabledNewMagicShare) else {
            return false
        }
        let canShowGuide = freeToBrowseButtonDisplayStyle == .operable && meetingLayoutStyle != .fullscreen
        if canShowGuide {
            showViewOnYourOwnGuideOnMainThread()
        } else {
            removeViewOnYourOwnGuideOnMainThread()
        }
        return canShowGuide
    }

}

// MARK: - “妙享模式已开启，点击即可进入自由浏览”Guide
extension InMeetShareScreenVC {

    func requestShowViewOnYourOwnGuide() {
        guard viewModel.meeting.service.shouldShowGuide(.enabledNewMagicShare) else {
            return
        }
        // nolint-next-line: magic number
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            guard let self = self else {
                return
            }
            let canShowGuide = self.freeToBrowseButtonDisplayStyle == .operable && self.meetingLayoutStyle != .fullscreen
            if canShowGuide {
                let guideDesc = GuideDescriptor(type: .shareScreenToFollowViewOnYourOwn,
                                                title: I18n.View_G_InviteClickViewMagicShare,
                                                desc: nil)
                GuideManager.shared.request(guide: guideDesc)
            }
        }
    }

    func showViewOnYourOwnGuideOnMainThread() {
        Util.runInMainThread { [weak self] in
            self?.showViewOnYourOwnGuide()
        }
    }

    func removeViewOnYourOwnGuideOnMainThread() {
        Util.runInMainThread { [weak self] in
            self?.removeViewOnYourOwnGuide()
        }
    }

    func showViewOnYourOwnGuide() {
        self.removeViewOnYourOwnGuideOnMainThread()
        guard self.viewOnYourOwnGuideView == nil else {
            return
        }

        if let inMeetViewContainer = self.container {
            // 生成锚点视图
            let freeToBrowseButton = self.bottomView.freeToBrowseButton
            let anchorRect = freeToBrowseButton.convert(freeToBrowseButton.bounds, to: inMeetViewContainer.view)
            let anchorView = UIView(frame: anchorRect)
            self.viewOnYourOwnGuideAnchorView = anchorView
            anchorView.isUserInteractionEnabled = false
            inMeetViewContainer.view.addSubview(anchorView)
            // 初始化引导页，放在GuideComponent上
            let guideView = GuideView(frame: .zero)
            self.viewOnYourOwnGuideView = guideView
            inMeetViewContainer.addContent(guideView, level: .guide)
            if isViewDidLoad {
                anchorView.snp.remakeConstraints { make in
                    make.edges.equalTo(self.bottomView.freeToBrowseButton)
                }
            }
            // 配置点击效果
            guideView.sureAction = { [weak self] _ in
                self?.viewModel.meeting.service.didShowGuide(.enabledNewMagicShare)
                self?.removeViewOnYourOwnGuideOnMainThread()
                ShareScreenToFollowTracks.trackClickOnboarding(with: .viewOnMyOwn, clickType: .check)
            }
            // 显示引导页
            guideView.snp.remakeConstraints {
                $0.edges.equalToSuperview()
            }
            guideView.setStyle(.plain(content: I18n.View_G_InviteClickViewMagicShare),
                               on: Display.phone ? .top : .bottom,
                               of: anchorView,
                               distance: 4)
            // 显示引导页数据埋点
            ShareScreenToFollowTracks.trackShowOnboarding(with: .viewOnMyOwn)
        } else {
            // 找到锚点视图
            let anchorView = self.bottomView.freeToBrowseButton
            // 初始化引导页
            let guideView = GuideView(frame: .zero)
            self.viewOnYourOwnGuideView = guideView
            view.addSubview(guideView)
            // 配置点击效果
            guideView.sureAction = { [weak self] _ in
                self?.viewModel.meeting.service.didShowGuide(.enabledNewMagicShare)
                self?.removeViewOnYourOwnGuideOnMainThread()
                ShareScreenToFollowTracks.trackClickOnboarding(with: .viewOnMyOwn, clickType: .check)
            }
            // 显示引导页
            guideView.snp.remakeConstraints {
                $0.edges.equalToSuperview()
            }
            guideView.setStyle(.plain(content: I18n.View_G_InviteClickViewMagicShare),
                               on: Display.phone ? .top : .bottom,
                               of: anchorView,
                               distance: 4)
            // 显示引导页数据埋点
            ShareScreenToFollowTracks.trackShowOnboarding(with: .viewOnMyOwn)
        }
    }

    func removeViewOnYourOwnGuide() {
        if let guideView = self.viewOnYourOwnGuideView {
            guideView.removeFromSuperview()
        }
        self.viewOnYourOwnGuideView = nil
        if let anchorView = self.viewOnYourOwnGuideAnchorView {
            anchorView.removeFromSuperview()
        }
        self.viewOnYourOwnGuideAnchorView = nil
        GuideManager.shared.dismissGuide(with: .shareScreenToFollowViewOnYourOwn)
    }

}

// MARK: - “可以自由浏览”Hint
extension InMeetShareScreenVC {

    func showPresenterAllowFreeToBrowseHintOnMainThread() {
        if meetingLayoutStyle == .fullscreen || !isViewLoaded {
            // nolint-next-line: magic number
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.showPresenterAllowFreeToBrowseHint()
            }
        } else {
            Util.runInMainThread { [weak self] in
                self?.showPresenterAllowFreeToBrowseHint()
            }
        }
        startBlockFullScreen()
    }

    func removePresenterAllowFreeToBrowseHint() {
        Util.runInMainThread { [weak self] in
            self?.endBlockFullScreen()
            guard let self = self, let hintView = self.presenterAllowFreeToBrowseHintView else {
                return
            }
            hintView.removeFromSuperview()
            self.presenterAllowFreeToBrowseHintView = nil
        }
    }

    private func showPresenterAllowFreeToBrowseHint() {
        self.removePresenterAllowFreeToBrowseHint()
        guard self.presenterAllowFreeToBrowseHintView == nil else {
            return
        }
        let hintView = GuideView(frame: .zero)
        self.presenterAllowFreeToBrowseHintView = hintView
        if container?.addContent(hintView, level: .guide) != nil {
            // 成功加到了GuideComponent
        } else {
            view.addSubview(hintView)
        }
        hintView.sureAction = { [weak self] _ in
            self?.removePresenterAllowFreeToBrowseHint()
        }
        hintView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        hintView.setStyle(
            .darkPlain(content: I18n.View_G_PresenterAllowedVOMO),
            on: Display.phone ? .top : .bottom,
            of: bottomView.freeToBrowseButton,
            distance: 5.0
        )

        DispatchQueue.global().asyncAfter(deadline: .now() + 5.0) { [weak self] in
            self?.removePresenterAllowFreeToBrowseHint()
        }
    }

}

extension InMeetShareScreenVC {

    func startBlockFullScreen() {
        blockFullScreenToken?.invalidate()
        blockFullScreenToken = fullScreenDetector?.requestBlockAutoFullScreen()
    }

    func endBlockFullScreen() {
        blockFullScreenToken?.invalidate()
    }

}
