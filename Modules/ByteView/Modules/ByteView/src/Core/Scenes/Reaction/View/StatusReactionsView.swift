//
//  StatusReactionsView.swift
//  ByteView
//
//  Created by ByteDance on 2022/8/9.
//

import Foundation
import UIKit
import ByteViewUI
import ByteViewTracker
import ByteViewSetting

protocol StatusReactionsViewDelegate: AnyObject {
    func didSelectRaiseHand(isChangeSkin: Bool)
    func didSelectQuickLeave()
}

final class StatusReactionsView: UIView {
    weak var delegate: StatusReactionsViewDelegate?

    enum Status {
        case none
        case raiseHand
        case quickLeave
    }

    private enum Layout {
        static let iconTextDistance: CGFloat = 6  // 预期icon为宽高22，间距为6，但实际宽为32，故间距调为1
        static let verticalOffset: CGFloat = 11
        static let cornerRadius: CGFloat = 8.0
        static let emojiDist: CGFloat = 12
        static let containerInset = 12
    }

    var status: Status = .none {
        didSet {
            // nolint-next-line: magic number
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
                self?.updateStatus(oldValue: oldValue)
            }
        }
    }


    var selectedHandsUpEmojiKey: String

    let handsUpEmojiKeys: [String] = [
        "MediumLightHandsUp",
        "LightHandsUp",
        "HandsUp",
        "MediumHandsUp",
        "MediumDarkHandsUp",
        "DarkHandsUp"
    ]

    private var pickerManager: FloatPickerManager?

    private func updateStatus(oldValue: Status) {
        Util.runInMainThread {
            switch self.status {
            case .none:
                self.raiseHandBtn.isSelected = false
                self.quickLeaveBtn.isSelected = false
                if oldValue == .raiseHand {
                    VCTracker.post(name: .vc_meeting_reaction_status, params: [
                        "reaction_name": "hands_up",
                        "status": "end"
                    ])
                } else if oldValue == .quickLeave {
                    VCTracker.post(name: .vc_meeting_reaction_status, params: [
                        "reaction_name": "leave",
                        "status": "end"
                    ])
                }
            case .raiseHand:
                self.raiseHandBtn.isSelected = true
                self.quickLeaveBtn.isSelected = false
                if oldValue != .raiseHand {
                    VCTracker.post(name: .vc_meeting_reaction_status, params: [
                        "reaction_name": "hands_up",
                        "status": "start"
                    ])
                    if oldValue == .quickLeave {
                        VCTracker.post(name: .vc_meeting_reaction_status, params: [
                            "reaction_name": "leave",
                            "status": "end"
                        ])
                    }
                }
            case .quickLeave:
                self.raiseHandBtn.isSelected = false
                self.quickLeaveBtn.isSelected = true
                if oldValue != .quickLeave {
                    VCTracker.post(name: .vc_meeting_reaction_status, params: [
                        "reaction_name": "leave",
                        "status": "start"
                    ])
                    if oldValue == .raiseHand {
                        VCTracker.post(name: .vc_meeting_reaction_status, params: [
                            "reaction_name": "leave",
                            "status": "end"
                        ])
                    }
                }
            }
            self.updateBtnTitle()
        }
    }

    private lazy var raiseHandBtn: UIButton = {
        let button = button(with: EmojiResources.getEmojiSkin(by: selectedHandsUpEmojiKey), title: I18n.View_G_RaiseHand_Button)
        button.addTarget(self, action: #selector(didSelectRaiseHand), for: .touchUpInside)
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        longPressGesture.minimumPressDuration = 0.4
        button.addGestureRecognizer(longPressGesture)
        return button
    }()

    private lazy var quickLeaveBtn: UIButton = {
        let button = button(with: EmojiResources.emoji_quickleave, title: I18n.View_G_QuickLeave_Button)
        button.addTarget(self, action: #selector(didSelectQuickLeave), for: .touchUpInside)
        return button
    }()

    let setting: MeetingSettingManager
    init(setting: MeetingSettingManager) {
        self.setting = setting
        self.selectedHandsUpEmojiKey = setting.handsUpEmojiKey
        super.init(frame: .zero)
        setupViews()
        configFloatPicker()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupViews() {
        addSubview(quickLeaveBtn)
        quickLeaveBtn.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().inset(Layout.containerInset)
        }
        addSubview(raiseHandBtn)
        raiseHandBtn.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.right.equalToSuperview().inset(Layout.containerInset)
            make.left.equalTo(quickLeaveBtn.snp.right).offset(Layout.emojiDist)
            make.width.equalTo(quickLeaveBtn.snp.width)
        }
    }

    func updateHandsUpSkin(key: String) {
        selectedHandsUpEmojiKey = key
        pickerManager?.config.selectedItemIdx = handsUpEmojiKeys.firstIndex(of: selectedHandsUpEmojiKey) ?? 2
        let image = EmojiResources.getEmojiSkin(by: key)
        setButtonImage(image, for: .normal)
    }

    private func configFloatPicker() {
        var config = FloatPickerConfig(itemCount: handsUpEmojiKeys.count,
                                       selectedItemIdx: handsUpEmojiKeys.firstIndex(of: selectedHandsUpEmojiKey) ?? 2,
                                       viewSize: CGSize(width: 272, height: 52),
                                       itemViewSize: CGSize(width: 44, height: 44),
                                       sourceView: raiseHandBtn.imageView)
        config.contentInset = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 4)
        config.mode = .tapAndSlide
        self.pickerManager = FloatPickerManager(config: config, delegate: self)
    }

    private func updateBtnTitle() {
        let leaveTitle = status == .quickLeave ? I18n.View_G_ImBack_Button : I18n.View_G_QuickLeave_Button
        let handsUpTitle = status == .raiseHand ? I18n.View_G_HandDown_Button : I18n.View_G_RaiseHand_Button
        quickLeaveBtn.setTitle(leaveTitle, for: .normal)
        raiseHandBtn.setTitle(handsUpTitle, for: .normal)
    }

    private func button(with image: UIImage, title: String) -> UIButton {
        let layoutGuide = UILayoutGuide()
        let btn = VisualButton()
        btn.addLayoutGuide(layoutGuide)
        btn.edgeInsetStyle = .left
        btn.contentEdgeInsets = .init(top: 0, left: 5, bottom: 0, right: 5)
        btn.titleLabel?.numberOfLines = 1
        btn.titleLabel?.lineBreakMode = .byTruncatingTail
        btn.layer.cornerRadius = Layout.cornerRadius
        btn.clipsToBounds = true
        btn.adjustsImageWhenDisabled = false
        btn.adjustsImageWhenHighlighted = false
        btn.setImage(image, for: .normal)
        btn.setTitle(title, for: .normal)
        btn.imageView?.contentMode = .scaleAspectFit
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        btn.setTitleColor(UIColor.ud.textCaption, for: .normal)
        btn.setTitleColor(UIColor.ud.primaryContentDefault, for: .selected)
        btn.vc.setBackgroundColor(UIColor.ud.bgFloatOverlay, for: .normal)
        btn.vc.setBackgroundColor(UIColor.ud.udtokenBtnTextBgNeutralPressed, for: .highlighted)
        btn.vc.setBackgroundColor(UIColor.ud.udtokenBtnTextBgPriFocus, for: .selected)
        btn.vc.setBackgroundColor(UIColor.ud.udtokenBtnTextBgPriPressed, for: [.selected, .highlighted])
        btn.addInteraction(type: .highlight)

        if let imageView = btn.imageView, let titleLabel = btn.titleLabel {
            imageView.snp.makeConstraints { make in
                make.size.equalTo(18)
                make.right.equalTo(titleLabel.snp.left).offset(-Layout.iconTextDistance)
            }
        }

        return btn
    }

    private func setButtonImage(_ image: UIImage, for state: UIButton.State) {
        Util.runInMainThread {
            self.raiseHandBtn.setImage(image, for: state)
        }
    }

    @objc
    private func didSelectRaiseHand() {
        delegate?.didSelectRaiseHand(isChangeSkin: false)
    }

    @objc
    private func didSelectQuickLeave() {
        delegate?.didSelectQuickLeave()
    }

    @objc
    private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        pickerManager?.onLongPress(gesture: gesture)
    }
}

extension StatusReactionsView: FloatPickerManagerDelegate {
    func cellForItem(at index: Int) -> UIImage? {
        guard index < handsUpEmojiKeys.count else {
            return nil
        }
        return EmojiResources.getEmojiSkin(by: handsUpEmojiKeys[index])
    }

    func didPickOutItem(at index: Int, selectMode: SelectMode) {
        selectedHandsUpEmojiKey = handsUpEmojiKeys[index]
        pickerManager?.config.selectedItemIdx = index
        let image = EmojiResources.getEmojiSkin(by: handsUpEmojiKeys[index])
        setButtonImage(image, for: .normal)
        setting.updateSettings({ $0.handsUpEmojiKey = selectedHandsUpEmojiKey })
        delegate?.didSelectRaiseHand(isChangeSkin: true)
    }
}
