//
//  AttendeeFilterItem.swift
//  Calendar
//
//  Created by zoujiayi on 2019/8/27.
//

import UIKit
import Foundation
import SnapKit
import LarkBizAvatar

public final class AttendeeFilterItem: SearchFilterSelectorCellContext {

    private let stackViewWrapper = UIView()
    private let label = UILabel()
    private let clickCallBack: () -> Void
    private lazy var filterView: UIView = {
        let view = UIView()
        let stackView = UIStackView()
        stackView.axis = .horizontal
        view.addSubview(stackView)
        label.text = BundleI18n.Calendar.Calendar_EventSearch_Guest
        label.backgroundColor = UIColor.clear
        label.font = UIFont.cd.regularFont(ofSize: 14)
        stackView.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(10)
            make.top.bottom.equalToSuperview().inset(6)
        }
        stackView.spacing = 10
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(stackViewWrapper)
        view.layer.cornerRadius = 4
        view.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        return view
    }()

    @objc
    private func onClick() {
        clickCallBack()
    }

    internal init(clickCallBack: @escaping () -> Void) {
        self.clickCallBack = clickCallBack
        stackViewWrapper.isHidden = true
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClick))
        filterView.addGestureRecognizer(tapGesture)
        filterView.isUserInteractionEnabled = true
    }

    func getView() -> UIView {
        return filterView
    }

    func getMaxWidth() -> CGFloat {
        return 200
    }

    func setText(_ text: String) {
        // DO Nothing
    }

    func reset() {
        isActive = false
        stackViewWrapper.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        stackViewWrapper.isHidden = true
    }

    func set(avatars: [Avatar]) {
        stackViewWrapper.subviews.forEach { (view) in
            view.removeFromSuperview()
        }
        if avatars.isEmpty {
            stackViewWrapper.isHidden = true
            return
        }
        stackViewWrapper.isHidden = false
        let stackView = RoundAvatarStackView()
        stackViewWrapper.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        stackView.set(avatars)
        filterView.layoutIfNeeded()
    }

    var isActive: Bool = false {
        didSet {
            if isActive {
                label.textColor = UIColor.ud.primaryOnPrimaryFill
                filterView.backgroundColor = UIColor.ud.primaryContentDefault
                filterView.layer.borderWidth = 0
            } else {
                label.textColor = UIColor.ud.textTitle
                filterView.backgroundColor = UIColor.ud.bgBody
                filterView.layer.borderWidth = 1
            }
        }
    }
}

final class RoundAvatarStackView: UIView {

    private let overlappingWidth: CGFloat = 9
    private(set) var avatars: [Avatar] = []

    private var widthConstraint: Constraint?

    init() {
        super.init(frame: .zero)

        snp.makeConstraints { (make) in
            widthConstraint = make.width.equalTo(0).constraint
            make.height.equalTo(20)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(_ avatars: [Avatar]) {
        guard let widthConstraint = widthConstraint else {
            return
        }
        self.avatars = avatars
        subviews.forEach { $0.removeFromSuperview() }

        if avatars.isEmpty {
            widthConstraint.update(offset: 0)
        } else {
            var startOffset: CGFloat = 0

            let avatarViews = avatars.map { (avatar) -> AvatarView in
                let view = AvatarView()
                view.setAvatar(avatar, with: 20)
                return view
            }
            avatarViews
                .prefix(3)
                .forEach { (avatarView) in
                    addSubview(avatarView)
                    sendSubviewToBack(avatarView)
                    avatarView.snp.makeConstraints({ (make) in
                        make.centerY.equalToSuperview()
                        make.left.equalTo(startOffset)
                        make.size.equalTo(CGSize(width: 20, height: 20))
                    })
                    startOffset += 20 - overlappingWidth
                }
            widthConstraint.update(offset: startOffset + overlappingWidth)
        }
    }
}
