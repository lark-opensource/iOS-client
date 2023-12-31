//
//  LiveSettingsViewController+Guide.swift
//  ByteView
//
//  Created by wulv on 2020/6/16.
//

import Foundation

extension LiveSettingsViewController {

    func showOnboardingIfNeeded() {
        setupOnboarding()
    }

    func dismissOnboardingIfNeeded() {
        guard let guideView = guideView, guideView.superview != nil else { return }
        viewModel.service.didShowGuide(.liveLayoutSetting)
        guideView.removeFromSuperview()
        self.guideView = nil
    }

    private func setupOnboarding() {
        setupOldGuide()
    }

    private func setupOldGuide() {
        guard viewModel.service.shouldShowGuide(.liveLayoutSetting) else { return }

        let guideView = self.guideView ?? GuideView(frame: view.bounds)
        self.guideView = guideView
        if guideView.superview == nil {
            view.addSubview(guideView)
            guideView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        guideView.setStyle(.plain(content: I18n.View_M_ChooseLayoutOnboarding),
                           on: .top,
                           of: viewForGuide,
                           forcesSingleLine: false,
                           distance: -8)
        guideView.sureAction = { [weak self] _ in
            self?.viewModel.service.didShowGuide(.liveLayoutSetting)
            self?.guideView?.removeFromSuperview()
            self?.guideView = nil
        }
    }
}
