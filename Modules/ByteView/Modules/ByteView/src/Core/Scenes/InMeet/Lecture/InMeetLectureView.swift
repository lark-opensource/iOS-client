//
//  InMeetLectureView.swift
//  ByteView
//
//  Created by fakegourmet on 2022/8/9.
//

import UIKit
import RxSwift
import UniverseDesignIcon
import UniverseDesignColor
import ByteViewUI

protocol InMeetLecturerViewDelegate: AnyObject {
    func didTabExitLecturer()
}

/// 演讲者视图
final class InMeetLecturerView: UIView {
    private let speakingView = SpeakingView()

    private lazy var exitButton: VisualButton = {
        let exitButton = VisualButton()
        exitButton.setImage(UDIcon.getIconByKey(.topbarOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 20, height: 20)), for: .normal)
        exitButton.vc.setBackgroundColor(UIColor.ud.vcTokenMeetingBgFloat, for: .normal)
        exitButton.vc.setBackgroundColor(UIColor.ud.udtokenBtnTextBgNeutralPressed, for: .highlighted)
        exitButton.addTarget(self, action: #selector(didTapExitButton), for: .touchUpInside)
        return exitButton
    }()

    private let lineView = UIView()

    private let disposeBag = DisposeBag()

    weak var delegate: InMeetLecturerViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)

        backgroundColor = UIColor.ud.vcTokenMeetingBgFloat
        lineView.backgroundColor = UIColor.ud.lineDividerDefault

        addSubview(speakingView)
        addSubview(lineView)
        addSubview(exitButton)

        speakingView.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview().inset(12)
        }
        lineView.snp.makeConstraints {
            $0.left.equalTo(speakingView.snp.right).offset(8)
            $0.width.equalTo(0.5)
            $0.top.bottom.equalToSuperview()
        }
        exitButton.snp.makeConstraints {
            $0.top.bottom.right.equalToSuperview()
            $0.left.equalTo(lineView.snp.right)
            $0.width.equalTo(44)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        exitButton.layer.cornerRadius = 10
        exitButton.layer.maskedCorners = [.layerMaxXMinYCorner, .layerMaxXMaxYCorner]
    }

    func setSpeakerUserName(_ name: String) {
        speakingView.speakingTitleLabel.text = I18n.View_VM_SpeakingColonName("")
        speakingView.speakingLabel.text = name
    }

    func setFocusingUserName(_ name: String) {
        speakingView.speakingTitleLabel.text = I18n.View_MV_FocusVideoName_Icon("")
        speakingView.speakingLabel.text = name
    }

    func bindViewModel(_ viewModel: InMeetGridViewModel) {
        viewModel.shrinkViewSpeakingUser
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] name, showFocusPrefix in
                guard let self = self else { return }
                guard let name = name else {
                    self.setSpeakerUserName("")
                    return
                }
                if showFocusPrefix {
                    self.setFocusingUserName(name)
                } else {
                    self.setSpeakerUserName(name)
                }
            }).disposed(by: rx.disposeBag)
    }

    @objc func didTapExitButton() {
        delegate?.didTabExitLecturer()
    }
}

final class SpeakingView: UIView {
    let speakingLabel = UILabel()
    let speakingTitleLabel = UILabel()
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false

        speakingTitleLabel.textColor = UIColor.ud.textCaption
        speakingTitleLabel.font = .systemFont(ofSize: 14)
        speakingTitleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        speakingTitleLabel.setContentHuggingPriority(.required, for: .horizontal)
        speakingTitleLabel.text = I18n.View_VM_SpeakingColonName("")
        speakingLabel.textColor = UIColor.ud.textTitle
        speakingLabel.font = speakingTitleLabel.font

        addSubview(speakingTitleLabel)
        addSubview(speakingLabel)
        speakingTitleLabel.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview()
            maker.centerY.equalToSuperview()
            maker.height.equalTo(20)
        }
        speakingLabel.snp.makeConstraints { (maker) in
            maker.leading.equalTo(speakingTitleLabel.snp.trailing)
            maker.trailing.equalToSuperview()
            maker.centerY.equalToSuperview()
            maker.height.equalTo(speakingTitleLabel)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
