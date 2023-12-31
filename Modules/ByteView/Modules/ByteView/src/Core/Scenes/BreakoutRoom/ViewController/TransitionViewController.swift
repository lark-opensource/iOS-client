//
//  TransitionViewController.swift
//  ByteView
//
//  Created by wulv on 2021/3/8.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxCocoa
import RxSwift
import UniverseDesignIcon
import ByteViewUI

final class TransitionViewController: VMViewController<TransitionViewModel> {

    // MARK: UI
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var contentLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textCaption
        return label
    }()

    lazy var backButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(
            UDIcon.getIconByKey(.leftOutlined, iconColor: .ud.iconN1, size: CGSize(width: 24, height: 24)),
            for: .normal)
        button.addTarget(
            self,
            action: #selector(backToFloating),
            for: .touchUpInside
        )
        return button
    }()

    lazy var leaveButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(I18n.View_M_LeaveMeetingButton, for: .normal)
        button.setTitleColor(UIColor.ud.functionDangerContentDefault, for: .normal)
        button.setTitleColor(UIColor.ud.functionDangerContentDefault, for: .highlighted)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.vc.setBackgroundColor(UIColor.ud.udtokenComponentOutlinedBg, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenBtnSeBgDangerHover, for: .highlighted)
        button.layer.ud.setBorderColor(UIColor.ud.functionDangerContentDefault)
        button.layer.borderWidth = 1.0
        button.layer.cornerRadius = 4.0
        button.layer.masksToBounds = true
        button.contentEdgeInsets = .init(top: 0, left: 16, bottom: 0, right: 16)
        button.addTarget(self, action: #selector(leaveButtonAction), for: .touchUpInside)
        return button
    }()

    private let topSpacer = UILayoutGuide()
    private let botSpacer = UILayoutGuide()


    override func setupViews() {
        view.addSubview(backButton)
        view.addSubview(titleLabel)
        view.addSubview(contentLabel)
        view.addSubview(leaveButton)
        view.addLayoutGuide(topSpacer)
        view.addLayoutGuide(botSpacer)
        leaveButton.isHidden = true
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(10)) { [weak self] in
            self?.leaveButton.isHidden = false
        }
        makeSubViewsConstrants()
    }

    // MARK: bindViewModel
    override func bindViewModel() {
        viewModel.titleDriver
            .map { (title: String?) -> NSAttributedString? in
                guard let title = title else { return nil }
                return NSAttributedString(string: title, config: .h4, alignment: .center)
            }
            .drive(titleLabel.rx.attributedText)
            .disposed(by: rx.disposeBag)

        viewModel.contentDriver
            .map { (content: String?) -> NSAttributedString? in
                guard let content = content else { return nil }
                return NSAttributedString(string: content, config: .bodyAssist, alignment: .center)
            }
            .drive(contentLabel.rx.attributedText)
            .disposed(by: rx.disposeBag)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.updateMediaStatus(.muteAll)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.updateMediaStatus(.normal)
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        self.remakeSubViewsConstrants()
    }

    @objc private func leaveButtonAction() {
        BreakoutRoomTracks.transitionLeaveMeeting()
        BreakoutRoomTracksV2.transitionLeaveMeeting(viewModel.meeting)
        viewModel.leaveMeeting()
    }

    @objc private func backToFloating() {
        viewModel.meeting.router.setWindowFloating(true)
    }
}

// MARK: - Layout
extension TransitionViewController {

    private enum Layout {
        static var HorizontalGap: CGFloat {
            if VCScene.rootTraitCollection?.horizontalSizeClass == .regular {
                return 200
            } else {
                return 16
            }
        }
        static var MarginRight: CGFloat {
            VCScene.safeAreaInsets.right + HorizontalGap
        }
        static var MarginLeft: CGFloat {
            VCScene.safeAreaInsets.left + HorizontalGap
        }
        static let IconOffCenter: CGFloat = -50
        static let VerticalGap: CGFloat = 12
    }

    var backTop: CGFloat {
        currentLayoutContext.layoutType.isPhoneLandscape ? 10 : (VCScene.safeAreaInsets.top + 22)
    }

    var backLeft: CGFloat {
        currentLayoutContext.layoutType.isPhoneLandscape ? (Display.iPhoneXSeries ? 58 : 14) : 12
    }

    func makeSubViewsConstrants() {
        remakeSubViewsConstrants()

        leaveButton.snp.makeConstraints { (maker) in
            maker.top.equalTo(contentLabel.snp.bottom).offset(24)
            maker.top.equalTo(titleLabel.snp.bottom).offset(24).priority(.low)
            maker.height.equalTo(36)
            maker.width.greaterThanOrEqualTo(156)
            maker.centerX.equalToSuperview()
        }
    }

    // disable-lint: duplicated code
    private func remakeSubViewsConstrants() {

        backButton.snp.remakeConstraints { (maker) in
            maker.left.equalToSuperview().offset(backLeft)
            maker.top.equalToSuperview().offset(backTop)
        }

        topSpacer.snp.remakeConstraints { maker in
            maker.top.equalToSuperview()
        }

        titleLabel.snp.remakeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalTo(topSpacer.snp.bottom)
            maker.left.equalToSuperview().inset(Layout.MarginLeft)
            maker.right.equalToSuperview().inset(Layout.MarginRight)
        }

        contentLabel.snp.remakeConstraints { (maker) in
            maker.centerX.left.right.equalTo(titleLabel)
            maker.top.equalTo(titleLabel.snp.bottom).offset(Layout.VerticalGap)
        }

        botSpacer.snp.remakeConstraints { maker in
            maker.top.equalTo(contentLabel.snp.bottom)
            maker.bottom.equalToSuperview()
            maker.height.equalTo(topSpacer)
        }
    }
    // enable-lint: duplicated code
}
