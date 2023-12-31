//
//  MinutesDetailViewNavigationBar.swift
//  Minutes
//
//  Created by panzaofeng on 2021/1/11.
//

import Foundation
import MinutesFoundation
import MinutesNetwork
import UniverseDesignColor
import UniverseDesignIcon
import UIKit

protocol MinutesDetailViewNavigationBarDelegate: AnyObject {
    func navigationBack(_ view: MinutesDetailViewNavigationBar)
    func navigationMore(_ view: MinutesDetailViewNavigationBar)
    func navigationDone()

}

public final class MinutesDetailViewNavigationBar: UIView {

    weak var delegate: MinutesDetailViewNavigationBarDelegate?

    private let contentView = UIView()

    lazy var stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()

    private enum Layout {
        static let enlargeRegionInsets = UIEdgeInsets(top: 7,
                left: 7,
                bottom: 7,
                right: 7)
    }

    private lazy var backButton: EnlargeTouchButton = {
        let button: EnlargeTouchButton = EnlargeTouchButton(type: .custom)
        button.enlargeRegionInsets = Layout.enlargeRegionInsets
        button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.iconN1), for: .normal)
        button.addTarget(self, action: #selector(onClickBackButton(_:)), for: .touchUpInside)
        return button
    }()

    private(set) lazy var audioView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = BundleResources.Minutes.minutes_audio
        imageView.frame = CGRect(x: 0, y: 0, width: 24, height: 24)
        imageView.isHidden = true
        return imageView
    }()

    private(set) lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.boldSystemFont(ofSize: 17)
        titleLabel.textAlignment = .left
        titleLabel.numberOfLines = 1
        titleLabel.isHidden = true
        return titleLabel
    }()

    lazy var moreButton: EnlargeTouchButton = {
        let button: EnlargeTouchButton = EnlargeTouchButton(type: .custom)
        button.enlargeRegionInsets = Layout.enlargeRegionInsets
        button.setImage(UDIcon.getIconByKey(.moreOutlined, iconColor: UIColor.ud.iconN1), for: .normal)
        button.addTarget(self, action: #selector(onClickMoreButton(_:)), for: .touchUpInside)
        return button
    }()

    private lazy var doneButton: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setTitle(BundleI18n.Minutes.MMWeb_G_Done, for: .normal)
        btn.setTitleColor(UIColor.ud.primaryContentDefault, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 16)
        btn.addTarget(self, action: #selector(doneAction), for: .touchUpInside)
        btn.isHidden = true
        return btn
    }()

    lazy var subtitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12)
        l.textColor = UIColor.ud.textPlaceholder
        l.text = BundleI18n.Minutes.MMWeb_G_Saved
        l.isHidden = true
        return l
    }()

    private lazy var backView: UIView = {
        let v = UIView()
        v.backgroundColor = .clear
        v.addSubview(backButton)
        backButton.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        return v
    }()

    private lazy var textStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        stackView.distribution = .fill
        stackView.addArrangedSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.height.equalTo(22)
        }
        stackView.addArrangedSubview(subtitleLabel)
        subtitleLabel.snp.makeConstraints { (make) in
            make.height.equalTo(18)
        }
        titleLabel.isHidden = true
        return stackView
    }()

    var isEditing: Bool = false {
        didSet {
            backView.isHidden = isEditing
            moreButton.isHidden = isEditing
            doneButton.isHidden = !isEditing
            subtitleLabel.isHidden = !isEditing
            if isEditing {
                titleLabel.isHidden = false
                audioView.isHidden = true
            } else {
                titleLabel.isHidden = !isTitleShow
                audioView.isHidden = !isTitleShow
            }
        }
    }

    var isTitleShow: Bool = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UIColor.ud.bgBody
        addSubview(contentView)
        contentView.snp.makeConstraints { (maker) in
            maker.left.bottom.right.equalToSuperview()
            maker.height.equalTo(44)
        }

        contentView.addSubview(moreButton)
        moreButton.snp.makeConstraints { (maker) in
            maker.trailing.equalToSuperview().offset(-20)
            maker.bottom.equalToSuperview().offset(-12)
            maker.width.equalTo(24)
            maker.height.equalTo(24)
        }

        contentView.addSubview(doneButton)
        doneButton.snp.makeConstraints { make in
            make.right.equalTo(-15)
            make.centerY.equalToSuperview()
            make.height.equalTo(40)
            make.width.lessThanOrEqualTo(100)
        }

        contentView.addSubview(stackView)
        stackView.snp.makeConstraints { (maker) in
            maker.leading.equalToSuperview().offset(20)
            maker.height.equalTo(40)
            maker.bottom.equalToSuperview().offset(-5)
            maker.trailing.equalTo(moreButton.snp.leading).offset(-10)
        }

        stackView.insertArrangedSubview(textStackView, at: 0)
        textStackView.snp.makeConstraints { (maker) in
            maker.height.equalTo(40)
        }

        stackView.insertArrangedSubview(audioView, at: 0)
        audioView.isHidden = true
        audioView.snp.makeConstraints { (maker) in
            maker.width.equalTo(24)
            maker.height.equalTo(24)
        }
        stackView.setCustomSpacing(8, after: audioView)

        stackView.insertArrangedSubview(backView, at: 0)
        backView.snp.makeConstraints { (maker) in
            maker.width.equalTo(24)
            maker.height.equalTo(24)
        }
        stackView.setCustomSpacing(4, after: backView)

        NotificationCenter.default.addObserver(self, selector: #selector(updateSpeakerBegin), name: NSNotification.Name.EditSpeaker.updateSpeakerBegin, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateSpeakerSuccess), name: NSNotification.Name.EditSpeaker.updateSpeakerSuccess, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateSpeakerSuccess), name: NSNotification.Name.EditSpeaker.updateSpeakerFailed, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func config(with info: MinutesInfo) {
        guard let basicInfo = info.basicInfo else {
            return
        }
        if basicInfo.mediaType == .audio {
            audioView.image = BundleResources.Minutes.minutes_audio
        } else if basicInfo.mediaType == .text {
            audioView.image = BundleResources.Minutes.minutes_text
        }
    }

    func changeTitle(_ title: String) {
        titleLabel.text = title
    }

    func showTitle() {
        if isTitleShow {
            return
        }
        titleLabel.isHidden = false
        audioView.isHidden = isEditing
        isTitleShow = true
    }

    func hideTitle() {
        if isEditing || !isTitleShow {
            return
        }
        titleLabel.isHidden = true
        audioView.isHidden = true
        isTitleShow = false
    }
}

extension MinutesDetailViewNavigationBar {
    @objc
    func onClickBackButton(_ sender: UIButton) {
        self.delegate?.navigationBack(self)
    }

    @objc
    func onClickMoreButton(_ sender: UIButton) {
        self.delegate?.navigationMore(self)
    }

    @objc
    func doneAction() {
        delegate?.navigationDone()
    }

    @objc
    private func updateSpeakerBegin() {
        subtitleLabel.text = BundleI18n.Minutes.MMWeb_G_Saving
    }

    @objc
    private func updateSpeakerSuccess() {
        subtitleLabel.text = BundleI18n.Minutes.MMWeb_G_Saved
    }
}
