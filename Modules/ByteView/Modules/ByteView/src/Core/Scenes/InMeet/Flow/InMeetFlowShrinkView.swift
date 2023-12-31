//
//  InMeetFlowShrinkView.swift
//  ByteView
//
//  Created by kiri on 2021/3/25.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import UIKit
import ByteViewCommon
import ByteViewTracker
import UniverseDesignIcon

protocol InMeetFlowShrinkViewDelegate: AnyObject {
    func shrinkViewDidChangeShrink(_ shrinkView: InMeetFlowShrinkView, alongsideAnimation: @escaping () -> Void,
                                   completion: @escaping (Bool) -> Void)
}

class InMeetFlowShrinkView: UIView {
    private var hintLabel: UILabel?
    private let speakerLabel = UILabel()
    private let expandView = UIView()
    private let collapsedView = UIView()
    let backgroundView = UIView()

    private let expandImageView: UIImageView = {
        let img = UDIcon.getIconByKey(.vcToolbarUpFilled, iconColor: .ud.iconN3, size: CGSize(width: 20, height: 20))
        return UIImageView(image: img)
    }()

    private let collapsedImageView: UIImageView = {
        let img = UDIcon.getIconByKey(.vcToolbarDownFilled, iconColor: .ud.iconN3, size: CGSize(width: 20, height: 20))
        return UIImageView(image: img)
    }()

    private lazy var heightConstraint = NSLayoutConstraint(item: self, attribute: .height, relatedBy: .equal,
                                                           toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 24)
    private lazy var tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))

    private(set) lazy var isShrunken = service.storage.bool(forKey: .isFlowShrunken) {
        didSet {
            if oldValue != isShrunken {
                service.storage.set(isShrunken, forKey: .isFlowShrunken)
            }
        }
    }
    weak var delegate: InMeetFlowShrinkViewDelegate?
    weak var swipeGestureRecognizer: UISwipeGestureRecognizer? {
        didSet {
            if let swipe = swipeGestureRecognizer, oldValue != swipe {
                swipe.direction = isShrunken ? .down : .up
                if isPhoneLandscape {
                    swipe.isEnabled = false
                } else {
                    swipe.isEnabled = alpha > 0
                }
                swipe.addTarget(self, action: #selector(didSwipe(_:)))
            }
        }
    }

    var meetingLayoutStyle: MeetingLayoutStyle?

    let service: MeetingBasicService
    init(service: MeetingBasicService) {
        self.service = service
        super.init(frame: .zero)
        setupViews()
        setupConstraints()
        updateShrinkBar()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setSpeakerUserName(_ name: String?) {
        speakerLabel.text = I18n.View_VM_SpeakingColonName(name ?? I18n.View_G_NoOneSpeaking)
    }

    func setFocusingUserName(_ name: String) {
        speakerLabel.text = I18n.View_MV_FocusVideoName_Icon(name)
    }

    func didChangeWhiteboardOperateStatus(isOpaque: Bool) {
        DispatchQueue.main.async {
            // disable-lint: magic number
            let alpha: CGFloat = isOpaque ? 1 : 0.3
            UIView.animate(withDuration: 0.25, animations: {
                self.alpha = alpha
            })
        }
        // enable-lint: magic number
    }

    func show() {
        alpha = 1
        if isPhoneLandscape {
            swipeGestureRecognizer?.isEnabled = false
        } else {
            swipeGestureRecognizer?.isEnabled = true
        }
    }

    func hide() {
        alpha = 0
        swipeGestureRecognizer?.isEnabled = false
    }

    private func setupViews() {
        backgroundView.backgroundColor = .clear
        expandView.isUserInteractionEnabled = false
        collapsedView.isUserInteractionEnabled = false
        speakerLabel.textColor = UIColor.ud.textTitle
        addGestureRecognizer(tapGestureRecognizer)

        addSubview(backgroundView)
        addSubview(expandView)
        addSubview(collapsedView)
        expandView.addSubview(expandImageView)

        collapsedView.addSubview(collapsedImageView)
        collapsedView.addSubview(speakerLabel)
        if service.shouldShowGuide(.shrinkerGuideKey) {
            let textLabel = UILabel()
            textLabel.text = I18n.View_G_TapOrSwipeToHideThumbnails
            textLabel.textColor = UIColor.ud.textPlaceholder
            textLabel.font = .systemFont(ofSize: 10)
            expandView.addSubview(textLabel)
            self.hintLabel = textLabel
        }
    }

    private func setupConstraints() {
        heightConstraint.constant = 24
        heightConstraint.priority = .defaultHigh
        heightConstraint.isActive = true
        backgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        expandView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.bottom.equalToSuperview()
        }
        collapsedView.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.bottom.equalToSuperview()
            maker.width.lessThanOrEqualToSuperview().inset(12)
        }
    }

    private func updateShrinkBar() {
        if isPhoneLandscape {
            swipeGestureRecognizer?.isEnabled = false
            tapGestureRecognizer.isEnabled = false
            collapsedImageView.alpha = 0
            collapsedView.alpha = 1
            expandView.alpha = 0
            speakerLabel.font = .systemFont(ofSize: 10)
            speakerLabel.snp.remakeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
            heightConstraint.constant = 15
        } else {
            collapsedImageView.alpha = 1
            speakerLabel.font = .systemFont(ofSize: 12)
            swipeGestureRecognizer?.isEnabled = true
            tapGestureRecognizer.isEnabled = true
            if isShrunken {
                collapsedView.alpha = 1
                expandView.alpha = 0
                swipeGestureRecognizer?.direction = .down
                collapsedImageView.snp.remakeConstraints { (maker) in
                    maker.width.height.equalTo(20)
                    maker.left.centerY.equalToSuperview()
                }
                speakerLabel.snp.remakeConstraints { (maker) in
                    maker.centerY.equalTo(collapsedImageView)
                    maker.left.equalTo(collapsedImageView.snp.right).offset(12)
                    maker.right.equalToSuperview()
                }
                heightConstraint.constant = 32
            } else {
                collapsedView.alpha = 0
                expandView.alpha = 1
                swipeGestureRecognizer?.direction = .up
                expandImageView.snp.remakeConstraints { (maker) in
                    maker.width.height.equalTo(20)
                    maker.left.centerY.equalToSuperview()
                    maker.centerY.equalToSuperview()
                    if hintLabel == nil {
                        maker.right.equalToSuperview()
                    }
                }
                hintLabel?.snp.remakeConstraints({ (maker) in
                    maker.centerY.equalTo(expandImageView)
                    maker.left.equalTo(expandImageView.snp.right).offset(5)
                    maker.right.equalToSuperview()
                })
                heightConstraint.constant = 24
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateShrinkBar()
    }

    func updateShrunken(_ isShrunken: Bool) {
        guard self.isShrunken != isShrunken else {
            return
        }
        toggleShrunken()
    }

    private func toggleShrunken() {
        self.isShrunken = !isShrunken
        VCTracker.post(name: .vc_meeting_page_onthecall, params: [.action_name: isShrunken ? "click_fold" : "click_unfold"])
        if let obj = delegate {
            obj.shrinkViewDidChangeShrink(self, alongsideAnimation: {
                self.updateShrinkBar()
            }, completion: { (_) in
                self.removeHintIfNeeded()
            })
        } else {
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.2, animations: {
                self.updateShrinkBar()
                self.layoutIfNeeded()
            }, completion: { (_) in
                self.removeHintIfNeeded()
            })
        }
    }

    private func removeHintIfNeeded() {
        if isShrunken && hintLabel?.superview != nil {
            service.didShowGuide(.shrinkerGuideKey)
            hintLabel?.removeFromSuperview()
            hintLabel = nil
        }
    }

    @objc private func didSwipe(_ gr: UISwipeGestureRecognizer) {
        toggleShrunken()
    }

    @objc private func didTap(_ gr: UITapGestureRecognizer) {
        toggleShrunken()
    }
}
