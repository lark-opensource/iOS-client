//
//  SyncMessageToolbar.swift
//  Lark
//
//  Created by ChalrieSu on 2018/6/1.
//  Copyright © 2018 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import LarkMessengerInterface
import SnapKit
import Swinject
import LarkGuide
import UniverseDesignCheckBox

final class SyncMessageToolbar: PickerToolBar {

    static var guideService: (() -> GuideService?)?

    private let originCheckbox = UDCheckBox(boxType: .multiple)
    private let originPhotoLabel = UILabel.lu.labelWith(fontSize: 15,
                                                        textColor: UIColor.ud.colorfulBlue,
                                                        text: BundleI18n.LarkContact.Lark_Legacy_CreateGroupChatSyncChatRecord)
    /// checkBox + text StackView
    lazy var checkBoxAndTextStackView: UIStackView = {

        // CheckBox + Text
        let checkBoxAndTextStackView = UIStackView()
        checkBoxAndTextStackView.spacing = 5
        checkBoxAndTextStackView.alignment = .leading
        checkBoxAndTextStackView.lu.addTapGestureRecognizer(action: #selector(didTapSyncButton), target: self)

        originCheckbox.isUserInteractionEnabled = false
        originCheckbox.isSelected = true
        checkBoxAndTextStackView.addArrangedSubview(originCheckbox)
        originCheckbox.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.size.equalTo(LKCheckbox.Layout.iconLargeSize)
        }

        checkBoxAndTextStackView.addArrangedSubview(originPhotoLabel)
        originPhotoLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
        }

        checkBoxAndTextStackView.sizeToFit()
        return checkBoxAndTextStackView
    }()

    lazy var syncButtonItem: UIBarButtonItem = {
        return UIBarButtonItem(customView: self.checkBoxAndTextStackView)
    }()

    override func toolbarItems() -> [UIBarButtonItem] {
        let fixedSpaceBarItem = UIBarButtonItem(barButtonSystemItem: .fixedSpace, target: nil, action: nil)
        fixedSpaceBarItem.width = 5
        let flexibleSpaceBarItem = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        DispatchQueue.main.async {
            self.checkShowSyncRecordHint()
        }
        return [syncButtonItem, flexibleSpaceBarItem, flexibleSpaceBarItem, fixedSpaceBarItem]
    }

    var syncRecord: Bool = true
    @objc
    private func didTapSyncButton() {
        syncRecord = !syncRecord
        originCheckbox.isSelected = syncRecord
    }

    var hintBubbleView: EasyhintBubbleView?
    func checkShowSyncRecordHint() {
        guard let guideManager = Self.guideService?() else { return }

        guard let superview = self.superview else {
            assertionFailure()
            return
        }

        let key = "mobile_sync_message"
        if !guideManager.needShowGuide(key: key) {
            return
        }
        guideManager.didShowGuide(key: key)

        self.clipsToBounds = false

        var preferences = EasyhintBubbleView.globalPreferences
        preferences.drawing.arrowPosition = .bottom
        preferences.drawing.textColor = UIColor.ud.primaryOnPrimaryFill
        preferences.drawing.font = UIFont.systemFont(ofSize: 14)
        preferences.drawing.backgroundColor = UIColor.ud.colorfulBlue
        preferences.positioning.maxWidth = 240
        let hintbubbleView = EasyhintBubbleView(text: BundleI18n.LarkContact.Lark_Legacy_GuideSyncRecordHint, preferences: preferences)
        self.hintBubbleView = hintbubbleView
        hintbubbleView.show(forView: originCheckbox, withinSuperview: superview)
        hintbubbleView.center = CGPoint(x: hintbubbleView.center.x + 16, y: hintbubbleView.center.y - 15)
        hintbubbleView.clickBlock = { [weak self] in
            guard let `self` = self else { return }
            self.hintBubbleView?.removeFromSuperview()
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let hintBubbleView = self.hintBubbleView {
            let frame = convert(hintBubbleView.bounds, from: hintBubbleView)
            if frame.contains(point) {
                hintBubbleView.clickBlock?()
            }
        }
        return super.hitTest(point, with: event)
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        if let hintBubbleView = self.hintBubbleView {
            let frame = convert(hintBubbleView.bounds, from: hintBubbleView)
            if frame.contains(point) {
                hintBubbleView.clickBlock?()
            }
        }
        return super.point(inside: point, with: event)
    }
}
