//
//  MeetingRoomFilterView.swift
//  Calendar
//
//  Created by zhuheng on 2021/2/3.
//

import UniverseDesignIcon
import Foundation
import UIKit
import SnapKit

protocol MeetingRoomFilterViewDataType {
    var equipment: String? { get }
    var capacity: String? { get }
    var showAvailableRooms: Bool? { get }
}

final class MeetingRoomFilterView: UIView, ViewDataConvertible {
    var viewData: MeetingRoomFilterViewDataType? {
        didSet {
            filterStackView.arrangedSubviews.forEach { (view) in
                view.removeFromSuperview()
                filterStackView.removeArrangedSubview(view)
            }
            if let info = viewData?.equipment {
                if info.isEmpty {
                    equipmentItem.viewData = .initial
                } else {
                    equipmentItem.viewData = .info(info)
                }
                filterStackView.addArrangedSubview(equipmentItem)
            }

            if let info = viewData?.capacity, !info.isEmpty {
                capacityItem.viewData = .infoWithIcon(info)
            } else {
                capacityItem.viewData = .initial
            }

            filterStackView.addArrangedSubview(capacityItem)

            if let onlyAvailableShowed = viewData?.showAvailableRooms {
                if onlyAvailableShowed {
                    availableRoomsItem.viewData = .info(BundleI18n.Calendar.Calendar_Edit_AvaliableRooms)
                } else {
                    availableRoomsItem.viewData = .initial
                }
                filterStackView.addArrangedSubview(availableRoomsItem)
            }
            // 筛选项 nil --> 该筛选项不参与 resetItem disable 变化 --> 在 && 运算中 true pass
            if (viewData?.capacity?.isEmpty ?? true) &&
                (viewData?.equipment?.isEmpty ?? true) &&
                (!(viewData?.showAvailableRooms ?? false)) {
                resetItem.viewData = .disable
            } else {
                resetItem.viewData = .enable
            }
        }
    }

    var equipmentTapped: (() -> Void)? {
        didSet {
            equipmentItem.itemTapped = equipmentTapped
        }
    }

    var capacityTapped: (() -> Void)? {
        didSet {
            capacityItem.itemTapped = capacityTapped
        }
    }

    var availableRoomsTapped: (() -> Void)? {
        didSet {
            availableRoomsItem.itemTapped = availableRoomsTapped
        }
    }

    var resetTapped: (() -> Void)? {
        didSet {
            resetItem.itemTapped = resetTapped
        }
    }

    private let equipmentItem: Item = {
        let item = Item(defaultInfo: BundleI18n.Calendar.Calendar_Edit_Device)
        return item
    }()

    private let capacityItem: Item = {
        let item = Item(defaultInfo: BundleI18n.Calendar.Calendar_Edit_CapacityMobile, iconImage: UDIcon.getIconByKeyNoLimitSize(.groupOutlined).renderColor(with: .primaryPri500))
        return item
    }()

    private let availableRoomsItem: Item = {
        let item = Item(defaultInfo: BundleI18n.Calendar.Calendar_Edit_AvaliableRooms, iconImage: UDIcon.getIconByKeyNoLimitSize(.groupOutlined).renderColor(with: .primaryOnPrimaryFill))
        return item
    }()

    private let resetItem: Item = {
        let item = Item(defaultInfo: BundleI18n.Calendar.Calendar_EventSearch_Reset)
        return item
    }()

    private let scrollview = UIScrollView()

    private lazy var filterStackView: UIStackView = {
        let view = UIStackView()
        view.axis = .horizontal
        view.spacing = 8
        view.distribution = .fill
        view.alignment = .fill
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)
        setupViews()
        backgroundColor = UIColor.ud.bgBody
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(resetItem)
        addSubview(scrollview)
        scrollview.showsHorizontalScrollIndicator = false
        scrollview.showsVerticalScrollIndicator = false
        scrollview.snp.makeConstraints {
            $0.left.equalToSuperview().offset(15)
            $0.right.equalTo(resetItem.snp.left)
            $0.top.bottom.equalToSuperview()
        }

        scrollview.addSubview(filterStackView)
        filterStackView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.equalToSuperview().inset(14)
        }

        filterStackView.addArrangedSubview(equipmentItem)
        filterStackView.addArrangedSubview(capacityItem)

        resetItem.snp.makeConstraints {
            $0.centerY.equalTo(filterStackView)
            $0.right.equalToSuperview().offset(-6)
        }
    }
}

extension MeetingRoomFilterView {
    final class Item: UIView {
        enum State {
            case initial
            case enable
            case disable
            case info(String)
            case infoWithIcon(String)
        }
        var viewData: State {
            didSet {
                switch viewData {
                case .initial:
                    label.text = defaultInfo
                    label.textColor = UIColor.ud.textTitle
                    backgroundColor = UIColor.ud.bgFiller
                    iconView?.isHidden = true
                case .info(let string):
                    label.text = string
                    label.textColor = UIColor.ud.primaryPri500
                    backgroundColor = UIColor.ud.fillActive
                    iconView?.isHidden = true
                case .infoWithIcon(let string):
                    iconView?.isHidden = false
                    label.text = string
                    label.textColor = UIColor.ud.primaryPri500
                    backgroundColor = UIColor.ud.fillActive
                case .enable:
                    label.textColor = UIColor.ud.primaryPri500
                    isUserInteractionEnabled = true
                case .disable:
                    label.textColor = UIColor.ud.primaryContentLoading
                    isUserInteractionEnabled = false
                }
            }
        }
        private let defaultInfo: String
        fileprivate let label = UILabel()
        private var iconView: UIImageView?

        var itemTapped: (() -> Void)?

        init(defaultInfo: String,
             textColor: UIColor = UIColor.ud.textTitle,
             iconImage: UIImage? = nil
        ) {
            self.defaultInfo = defaultInfo
            self.viewData = .initial
            super.init(frame: .zero)
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClick))
            addGestureRecognizer(tapGesture)

            let stackView = UIStackView()
            stackView.axis = .horizontal
            stackView.spacing = 8
            stackView.distribution = .equalSpacing
            addSubview(stackView)

            stackView.snp.makeConstraints { make in
                make.leading.trailing.equalToSuperview().inset(10)
                make.centerY.equalToSuperview()
            }

            if let icon = iconImage {
                let iconView = UIImageView(image: icon)
                addSubview(iconView)
                iconView.snp.makeConstraints {
                    $0.centerY.equalToSuperview()
                    $0.width.height.equalTo(16)
                    $0.left.equalToSuperview().offset(10)
                }
                iconView.isHidden = true
                self.iconView = iconView
                stackView.addArrangedSubview(iconView)
            }

            label.textAlignment = .center
            label.textColor = textColor
            label.text = defaultInfo
            label.lineBreakMode = .byTruncatingTail
            label.font = UIFont.cd.regularFont(ofSize: 14)
            layer.cornerRadius = 6

            label.snp.makeConstraints { make in
                make.width.lessThanOrEqualTo(180)
            }
            stackView.addArrangedSubview(label)

            snp.makeConstraints {
                $0.height.equalTo(32)
            }

        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc
        private func onClick() {
            itemTapped?()
        }

    }
}
