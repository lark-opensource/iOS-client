//
//  FocusDetailView.swift
//  ExpandableTable
//
//  Created by Hayden Wang on 2021/8/25.
//

import Foundation
import UIKit
import SnapKit
import LarkInteraction
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignActionPanel
import UniverseDesignDatePicker
import LarkContainer
import LarkSDKInterface

final class FocusDetailView: UIView, UserResolverWrapper {

    @ScopedInjectedLazy
    var userSettings: UserGeneralSettings?
    /// 当前是否为 24 小时制
    var is24Hour: Bool {
        return userSettings?.is24HourTime.value ?? false
    }


    var selectionState: FocusModeCellState = .closed {
        didSet {
            if oldValue != selectionState {
                changeSelectionState()
            }
        }
    }

    func setPeriods(list: [FocusPeriod], selected: FocusPeriod?) {
        timeTagView.removeAllTags()
        timeTagView.addTags(list.map({ $0.name(is24Hour: is24Hour) }))
        for (index, period) in list.enumerated() where period.rawValue == selected?.rawValue {
            timeTagView.tagViews[index].isSelected = true
            // UGLY
            timeTagView.tagViews[index].setTitle(selected?.name(is24Hour: is24Hour), for: UIControl.State())
        }
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textCaption
        return label
    }()

    lazy var timeTagView: TagListView = {
        let view = TagListView()
        view.marginY = 12
        view.marginX = 12
        view.tagCornerRadius = 6
        view.textFont = UIFont.systemFont(ofSize: 14)
        view.paddingX = 10
        view.paddingY = 9
        view.textColor = UIColor.ud.textTitle
        view.selectedTextColor = UIColor.ud.primaryOnPrimaryFill
        view.tagBackgroundColor = Cons.tagColor
        view.tagSelectedBackgroundColor = Cons.tagSelectColor
        return view
    }()

    private lazy var separator: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        return line
    }()

    lazy var settingButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        return button
    }()

    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubviews() {
        addSubview(titleLabel)
        addSubview(timeTagView)
        addSubview(separator)
        addSubview(settingButton)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapBackgroundView)))
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(14)
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
        }
        timeTagView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.trailing.equalToSuperview().offset(-16)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
        }
        separator.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalTo(timeTagView.snp.bottom).offset(18)
            make.height.equalTo(0.5)
        }
        settingButton.snp.makeConstraints { make in
            make.top.equalTo(separator.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().priority(749)
            make.height.equalTo(48)
        }
    }

    private func setupAppearance() {
        backgroundColor = Cons.backgroundColor
        titleLabel.text = BundleI18n.LarkFocus.Lark_Profile_LastTime
        settingButton.setTitle(BundleI18n.LarkFocus.Lark_Profile_MoreSettings, for: .normal)
        settingButton.setTitleColor(UIColor.ud.textCaption, for: .normal)
        if #available(iOS 13.4, *) {
            let action = PointerInteraction(style: PointerStyle(effect: .hover()))
            settingButton.addLKInteraction(action)
        }
    }

    @objc
    private func didTapBackgroundView() {
        // nothing
    }

    private func changeSelectionState() {
        switch selectionState {
        case .closing, .reopening:
            for tagView in timeTagView.tagViews {
                tagView.selectedBackgroundColor = UIColor.ud.B300.nonDynamic
            }
        case .opened:
            for tagView in timeTagView.tagViews {
                tagView.selectedBackgroundColor = UIColor.ud.B400.nonDynamic
            }
        case .closed, .opening:
            break
        }
    }
}

extension FocusDetailView {

    enum Cons {
        static var backgroundColor: UIColor {
            UIColor.ud.N100 & UIColor.ud.rgb(0x1A1A1A)
        }

        static var tagColor: UIColor {
            UIColor.ud.N1000.withAlphaComponent(0.07)
        }

        static var tagSelectColor: UIColor {
            UIColor.ud.primaryContentDefault
        }
    }
}
