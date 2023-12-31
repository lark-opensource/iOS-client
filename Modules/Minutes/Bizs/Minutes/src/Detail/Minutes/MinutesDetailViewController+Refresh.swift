//
//  MinutesDetailViewController+Refresh.swift
//  Minutes
//
//  Created by panzaofeng on 2022/1/20.
//
import UniverseDesignToast

extension MinutesDetailViewController {
    func showRefreshView() {
        guard self.refreshNotice == nil else { return }
        let title = viewModel.minutes.basicInfo?.topic ?? ""
        let view = MinutesRefreshNoticeView(title)
        view.refreshHandler = { [weak self] in
            guard let self = self else { return }
            self.refreshNotice?.removeFromSuperview()
            self.refreshNotice = nil
            let params = ["click": "refresh", "target": "none", "popup_name": "recording_transcript_finish"]
            self.tracker.tracker(name: .popupClick, params: params)
            UDToast.showLoading(with: "", on: self.view, disableUserInteraction: false)
            self.viewModel.minutes.refresh(catchError: false, refreshAll: true, completionHandler: {
                DispatchQueue.main.async {
                    UDToast.removeToast(on: self.view)
                }
            })
        }
        self.refreshNotice = view

        view.alpha = 0
        self.view.addSubview(view)

        view.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview().inset(16)
            maker.height.equalTo(56)
            if isVideo {
                maker.bottom.equalTo(-3 - self.view.safeAreaInsets.bottom)
            } else {
                if videoControlView.frame.height == 0 {
                    maker.bottom.equalTo(-3 - self.view.safeAreaInsets.bottom)
                } else {
                    maker.bottom.lessThanOrEqualTo(self.videoControlView.snp.top).offset(-3)
                }
            }
        }

        UIView.animate(withDuration: 0.25) {
            view.alpha = 1
            self.tracker.tracker(name: .popupView, params: ["popup_name": "recording_transcript_finish"])
        }
    }

    func updateRefreshViewLayoutIfNeeded() {
        if refreshNotice == nil || refreshNotice?.superview == nil { return }
        refreshNotice?.snp.remakeConstraints({ maker in
            maker.left.right.equalToSuperview().inset(16)
            maker.height.equalTo(56)
            if isVideo {
                maker.bottom.equalTo(-3 - self.view.safeAreaInsets.bottom)
            } else {
                if videoControlView.frame.height == 0 {
                    maker.bottom.equalTo(-3 - self.view.safeAreaInsets.bottom)
                } else {
                    maker.bottom.lessThanOrEqualTo(self.videoControlView.snp.top).offset(-3)
                }
            }
        })
    }
}
