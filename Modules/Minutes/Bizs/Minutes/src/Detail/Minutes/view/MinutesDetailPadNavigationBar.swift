//
//  MinutesDetailPadNavigationBar.swift
//  Minutes
//
//  Created by 陈乐辉 on 2023/8/28.
//

import Foundation
import MinutesFoundation
import MinutesNetwork
import UniverseDesignColor
import UniverseDesignIcon
import SnapKit

final class MinutesDetailPadNavigationBar: UIView {

    private lazy var contentView: UIView = {
        let cv = UIView()
        cv.backgroundColor = .ud.bgBody
        cv.addSubview(backButton)
        backButton.snp.makeConstraints { make in
            make.width.height.equalTo(28)
            make.left.centerY.equalToSuperview()
        }

        cv.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.edges.equalTo(backButton)
        }

        cv.addSubview(titleView)
        titleView.snp.makeConstraints { make in
            make.left.equalTo(backButton.snp.right)
            make.centerY.equalTo(backButton)
            make.right.equalTo(-42)
            make.height.equalTo(44)
        }

        cv.addSubview(clipView)
        clipView.snp.makeConstraints { make in
            make.edges.equalTo(titleView)
        }

        cv.addSubview(moreButton)
        moreButton.snp.makeConstraints { make in
            make.width.height.equalTo(28)
            make.centerY.right.equalToSuperview()
        }
        return cv
    }()

    lazy var backButton: EnlargeTouchButton = {
        let button: EnlargeTouchButton = EnlargeTouchButton(type: .custom)
        button.enlargeRegionInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.iconN1), for: .normal)
        return button
    }()

    lazy var moreButton: EnlargeTouchButton = {
        let button: EnlargeTouchButton = EnlargeTouchButton(type: .custom)
        button.enlargeRegionInsets = UIEdgeInsets(top: 7, left: 7, bottom: 7, right: 7)
        button.setImage(UDIcon.getIconByKey(.moreOutlined, iconColor: UIColor.ud.iconN1), for: .normal)
        return button
    }()

    lazy var titleView: MinutesDetailTitleView = {
        let v = MinutesDetailTitleView()
        return v
    }()

    lazy var clipView: ClipNavigationView = {
        let v = ClipNavigationView()
        v.subtitleView.delegate = self
        v.isHidden = true
        return v
    }()

    private lazy var editSpeakerContentView: UIView = {
        let v = UIView()
        v.isHidden = true

        v.addSubview(doneButton)
        doneButton.snp.makeConstraints { make in
            make.right.centerY.equalToSuperview()
            make.height.equalTo(40)
        }

        v.addSubview(editTitleLabel)
        editTitleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalTo(8)
            make.height.equalTo(24)
            make.right.equalTo(doneButton.snp.left).offset(-16)
        }

        v.addSubview(editSubtitleLabel)
        editSubtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(editTitleLabel.snp.bottom).offset(2)
            make.left.right.equalTo(editTitleLabel)
            make.height.equalTo(18)
        }
        return v
    }()

    private lazy var editTitleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 1
        return titleLabel
    }()

    private lazy var editSubtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = UIColor.ud.textPlaceholder
        l.text = BundleI18n.Minutes.MMWeb_G_Saved
        return l
    }()

    lazy var doneButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle(BundleI18n.Minutes.MMWeb_G_Done, for: .normal)
        btn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        btn.setContentHuggingPriority(.required, for: .horizontal)
        btn.setContentCompressionResistancePriority(.required, for: .horizontal)
        return btn
    }()

    lazy var closeButton: UIButton = {
        let button: UIButton = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.closeOutlined, iconColor: UIColor.ud.iconN1), for: .normal)
        button.isHidden = true
        return button
    }()

    var isEditSpeaker: Bool = false {
        didSet {
            contentView.isHidden = isEditSpeaker
            editSpeakerContentView.isHidden = !isEditSpeaker
        }
    }

    var clipLinkBlock: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .ud.bgBody

        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(14)
            make.bottom.equalToSuperview()
            make.height.equalTo(60)
        }

        addSubview(editSpeakerContentView)
        editSpeakerContentView.snp.makeConstraints { make in
            make.edges.equalTo(contentView)
        }

        NotificationCenter.default.addObserver(self, selector: #selector(updateSpeakerBegin), name: NSNotification.Name.EditSpeaker.updateSpeakerBegin, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateSpeakerSuccess), name: NSNotification.Name.EditSpeaker.updateSpeakerSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateSpeakerSuccess), name: NSNotification.Name.EditSpeaker.updateSpeakerFailed, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
    }

    func config(with minutes: Minutes) {
        if minutes.info.status == .audioRecording {
            clipView.isHidden = true
            titleView.config(with: minutes.info)
            if minutes.basicInfo?.isRecordingDevice == true {
                moreButton.isHidden = false
            } else {
                moreButton.isHidden = true
            }
        } else {
            if minutes.isClip {
                clipView.config(with: minutes.info.basicInfo)
                moreButton.isHidden = minutes.info.basicInfo?.mediaType == .audio
            } else {
                titleView.config(with: minutes.info)
                editTitleLabel.text = minutes.info.basicInfo?.topic
            }
            clipView.isHidden = !(minutes.isClip)
            titleView.isHidden = minutes.isClip
        }
    }

    func hideTitle() {
        titleView.isHidden = true
        moreButton.isHidden = true
        clipView.isHidden = true
    }

    @objc
    private func updateSpeakerBegin() {
        editSubtitleLabel.text = BundleI18n.Minutes.MMWeb_G_Saving
    }

    @objc
    private func updateSpeakerSuccess() {
        editSubtitleLabel.text = BundleI18n.Minutes.MMWeb_G_Saved
    }
}

extension MinutesDetailPadNavigationBar: MinutesClipSubTitleInnerViewDelegate {
    func tapLinkClosure() {
        clipLinkBlock?()
    }
}

final class ClipNavigationView: UIView {

    private lazy var titleLabel: UILabel = {
        let label: UILabel = UILabel(frame: CGRect.zero)
        label.textAlignment = .left
        label.textColor = UIColor.ud.textTitle
        label.font = .systemFont(ofSize: 17)
        label.numberOfLines = 1
        return label
    }()

    private lazy var titleTag: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 10, weight: .medium)
        l.textColor = UIColor.ud.udtokenTagTextSPurple
        l.backgroundColor = UIColor.ud.udtokenTagBgPurple.withAlphaComponent(0.2)
        l.layer.cornerRadius = 4
        l.clipsToBounds = true
        l.setContentHuggingPriority(.required, for: .horizontal)
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        l.text = " \(BundleI18n.Minutes.MMWeb_G_Clip) "
        return l
    }()

    lazy var subtitleView: MinutesClipSubTitleInnerView = {
        let l = MinutesClipSubTitleInnerView()
        return l
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.top.equalToSuperview()
            make.height.equalTo(24)
        }

        addSubview(titleTag)
        titleTag.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right).offset(6)
            make.centerY.equalTo(titleLabel)
            make.right.lessThanOrEqualToSuperview().offset(-16)
            make.height.equalTo(16)
        }

        addSubview(subtitleView)
        subtitleView.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(16)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.height.equalTo(18)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func timeString(from duration: Int) -> String {
        var timeStr: String = ""
        let hours: Int = duration / 3600

        let minutes = duration % 3600 / 60

        let seconds = duration % 3600 % 60

        if hours == 0 && minutes == 0 {
            return BundleI18n.Minutes.MMWeb_MV_SecondUnit(seconds)
        } else if hours == 0 {
            return BundleI18n.Minutes.MMWeb_MV_MinuteSecondUnit(minutes, seconds)
        } else {
            return BundleI18n.Minutes.MMWeb_MV_HourMinuteSecondUnit(hours, minutes, seconds)
        }
    }

    func config(with info: BasicInfo?) {
        var w = frame.width
        titleLabel.text = info?.topic ?? ""
        if let time = info?.duration {
            subtitleView.preferredMaxLayoutWidth = w
            subtitleView.update(duration: timeString(from: time / 1000), isContinue: info?.clipInfo?.continuous ?? false)
        }
    }
}
