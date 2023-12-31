//
//  FloatingSelfShareScreenViewController.swift
//  ByteView
//
//  Created by Prontera on 2021/3/30.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift

class FloatingSelfShareScreenViewController: VMViewController<InMeetSelfShareScreenViewModel> {

    private lazy var content = FloatingHintView.makeSelfShareScreenHint()

    private var shareImageView: UIImageView {
        content.hintImageView
    }

    private let disposeBag = DisposeBag()

    private var titleLabel: UILabel {
        content.hintLabel
    }

    override func setupViews() {
        super.setupViews()
        self.view.applyFloatingBGAndBorder()
        view.addSubview(content)
        content.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

    }

    override func bindViewModel() {
        super.bindViewModel()
        viewModel.floatingIcon
            .drive(shareImageView.rx.image)
            .disposed(by: disposeBag)

        viewModel.floatingTitle
            .drive(titleLabel.rx.text)
            .disposed(by: disposeBag)
    }

    override func viewDidFirstAppear(_ animated: Bool) {
        super.viewDidFirstAppear(animated)
        MeetingTracksV2.trackDisplayOnTheCallPage(true, isSharing: viewModel.context.meetingContent.isShareContent,
                                                  meeting: viewModel.meeting)
    }
}
