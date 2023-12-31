//
//  MeetingRoomHomeFilterView.swift
//  Calendar
//
//  Created by 王仕杰 on 2021/5/6.
//

import UniverseDesignIcon
import UIKit

protocol MeetingRoomHomeFilterViewData {
    var building: String? { get }
    var equipment: String? { get }
    var capacity: String? { get }
}

final class MeetingRoomHomeFilterView: UIView, ViewDataConvertible {

    private let maskWidth: CGFloat = 64

    private lazy var gradientMaskLayer: CAGradientLayer = {
        let gradientMaskLayer = CAGradientLayer()
        gradientMaskLayer.locations = [0.0, 0.875]
        gradientMaskLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientMaskLayer.endPoint = CGPoint(x: 1, y: 0.5)
        return gradientMaskLayer
    }()

    private lazy var gradientMaskView: UIView = {
        let gradientMaskView = UIView()
        gradientMaskView.isUserInteractionEnabled = false
        gradientMaskView.layer.insertSublayer(gradientMaskLayer, at: 0)
        return gradientMaskView
    }()

    var viewData: MeetingRoomHomeFilterViewData? {
        didSet {
            filterStackView.arrangedSubviews.forEach { (view) in
                view.removeFromSuperview()
                filterStackView.removeArrangedSubview(view)
            }

            guard let viewData = viewData else {
                return
            }

            if let building = viewData.building, !building.isEmpty {
                buildingItem.viewData = .info(building)
            } else {
                buildingItem.viewData = .initial
            }
            filterStackView.addArrangedSubview(buildingItem)
            buildingItem.snp.makeConstraints { make in
                make.width.lessThanOrEqualTo(self).dividedBy(2)
            }
            buildingItem.label.lineBreakMode = .byTruncatingTail

            if let info = viewData.equipment {
                if !info.isEmpty {
                    equipmentItem.viewData = .info(info)
                } else {
                    equipmentItem.viewData = .initial
                }
                filterStackView.addArrangedSubview(equipmentItem)
            }

            if let info = viewData.capacity, !info.isEmpty {
                capacityItem.viewData = .infoWithIcon(info)
            } else {
                capacityItem.viewData = .initial
            }

            filterStackView.addArrangedSubview(capacityItem)

            DispatchQueue.main.async {
                self.scrollViewDidScroll(self.scrollview)
            }
        }
    }

    var buildingTapped: (() -> Void)? {
        didSet {
            buildingItem.itemTapped = buildingTapped
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

    var refreshTapped: (() -> Void)?

    let buildingItem = Item(defaultInfo: BundleI18n.Calendar.Calendar_MeetingRoom_BuildingAndFloor)

    private(set) var equipmentItem = Item(defaultInfo: BundleI18n.Calendar.Calendar_Edit_Device)

    private let capacityItem = Item(defaultInfo: BundleI18n.Calendar.Calendar_Edit_CapacityMobile, iconImage: UDIcon.getIconByKeyNoLimitSize(.groupOutlined).ud.resized(to: CGSize(width: 20, height: 20)).renderColor(with: .primaryOnPrimaryFill))

    private let refreshView: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKeyNoLimitSize(.refreshOutlined).ud.resized(to: CGSize(width: 20, height: 20)).renderColor(with: .n2), for: .normal)
        button.addTarget(self, action: #selector(refresh), for: .touchUpInside)
        return button
    }()

    @objc func refresh() {
        refreshTapped?()
    }

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
        addSubview(refreshView)
        addBottomSepratorLine()

        addSubview(scrollview)
        scrollview.showsHorizontalScrollIndicator = false
        scrollview.showsVerticalScrollIndicator = false
        scrollview.snp.makeConstraints {
            $0.left.equalToSuperview().offset(15)
            $0.right.equalTo(refreshView.snp.left)
            $0.top.bottom.equalToSuperview()
        }
        scrollview.delegate = self

        scrollview.addSubview(filterStackView)
        filterStackView.snp.makeConstraints {
            $0.left.right.equalToSuperview()
            $0.top.bottom.equalToSuperview().inset(14)
        }

        filterStackView.addArrangedSubview(buildingItem)
        filterStackView.addArrangedSubview(equipmentItem)
        filterStackView.addArrangedSubview(capacityItem)

        refreshView.snp.makeConstraints {
            $0.top.bottom.equalToSuperview()
            $0.right.equalToSuperview()
            $0.width.equalTo(refreshView.snp.height)
        }

        addSubview(gradientMaskView)
        gradientMaskView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview().inset(1)
            make.trailing.equalTo(scrollview)
            make.width.equalTo(maskWidth)
        }
        gradientMaskLayer.frame = CGRect(x: 0, y: 0, width: maskWidth, height: 59)
        gradientMaskLayer.ud.setColors([UIColor.ud.bgBody.withAlphaComponent(0), UIColor.ud.bgBody])
    }

}

extension MeetingRoomHomeFilterView: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        gradientMaskView.isHidden = scrollView.contentOffset.x + scrollView.frame.width >= scrollView.contentSize.width
    }
}

extension MeetingRoomHomeFilterView {
    final class Item: UIView {
        enum State {
            case initial
            case info(String)
            case infoWithIcon(String)
        }
        var viewData: State {
            didSet {
                switch viewData {
                case .initial:
                    label.text = defaultInfo
                    label.textColor = UIColor.ud.textTitle
                    backgroundColor = UIColor.ud.bgBody
                    iconView?.isHidden = true
                    layer.ud.setBorderColor(borderColor)
                case .info(let string):
                    label.text = string
                    label.textColor = UIColor.ud.primaryOnPrimaryFill
                    backgroundColor = UIColor.ud.functionInfoContentDefault
                    layer.ud.setBorderColor(UIColor.clear)
                    iconView?.isHidden = true
                case .infoWithIcon(let string):
                    iconView?.isHidden = false
                    label.text = string
                    label.textColor = UIColor.ud.primaryOnPrimaryFill
                    backgroundColor = UIColor.ud.functionInfoContentDefault
                    layer.ud.setBorderColor(UIColor.clear)
                }
            }
        }
        private let defaultInfo: String
        fileprivate let label = UILabel()
        private var iconView: UIImageView?
        private let borderColor: UIColor

        var itemTapped: (() -> Void)?

        init(defaultInfo: String,
             borderColor: UIColor = UIColor.ud.lineBorderComponent,
             textColor: UIColor = UIColor.ud.textTitle,
             iconImage: UIImage? = nil
             ) {
            self.defaultInfo = defaultInfo
            self.borderColor = borderColor
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
            label.lineBreakMode = .byClipping
            label.font = UIFont.cd.regularFont(ofSize: 14)
            layer.cornerRadius = 4
            layer.borderWidth = 1

            layer.borderColor = borderColor.cgColor
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
