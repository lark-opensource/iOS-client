//
//  QuickCreateDueTimePickView.swift
//  Todo
//
//  Created by wangwanxin on 2021/3/23.
//

import CTFoundation
import LarkContainer
import UniverseDesignIcon
import UniverseDesignFont

/// DueTime Pick : today + tomorrow + other days
protocol QuickCreateDueTimePickViewDataType {
    var isVisible: Bool { get }
}

class QuickCreateDueTimePickView: UIView, ViewDataConvertible {

    var viewData: QuickCreateDueTimePickViewDataType? {
        didSet {
            guard let viewData = viewData, viewData.isVisible else {
                isHidden = true
                return
            }
            isHidden = false
            invalidateIntrinsicContentSize()
        }
    }

    var onTodaySelect: (() -> Void)? {
        didSet { todayItem.didTapItem = onTodaySelect }
    }

    var onTomorrowSelect: (() -> Void)? {
        didSet { tomorrowItem.didTapItem = onTomorrowSelect }
    }

    var onOtherSelect: (() -> Void)? {
        didSet { othetItem.didTapItem = onOtherSelect }
    }

    private lazy var todayItem: PickDueTimeItemView = {
        let icon = UDIcon.getIconByKey(
            UDIconType.calendarDateOutlined(timeZone: .current),
            renderingMode: .automatic,
            iconColor: UIColor.ud.colorfulBlue,
            size: CGSize(width: 20, height: 20)
        )
        let item = PickDueTimeItemView(icon, title: I18N.Todo_Common_Today)
        return item
    }()
    private lazy var tomorrowItem: PickDueTimeItemView = {
        let icon = UDIcon.getIconByKey(
            .calendarTomorrowOutlined,
            renderingMode: .automatic,
            iconColor: UIColor.ud.T600,
            size: CGSize(width: 20, height: 20)
        )
        let item = PickDueTimeItemView(icon, title: I18N.Todo_Common_Tomorrow)
        item.didTapItem = onTomorrowSelect
        return item
    }()
    private lazy var othetItem: PickDueTimeItemView = {
        let icon = UDIcon.calendarDateOutlined.ud.resized(to: CGSize(width: 20, height: 20))
        let item = PickDueTimeItemView(icon.ud.withTintColor(UIColor.ud.iconN3), title: I18N.Todo_Common_OtherTime)
        item.didTapItem = onOtherSelect
        return item
    }()

    override init(frame: CGRect) {
        super.init(frame: .zero)

        addSubview(todayItem)
        addSubview(tomorrowItem)
        addSubview(othetItem)

        todayItem.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
        }
        tomorrowItem.snp.makeConstraints { (make) in
            make.left.equalTo(todayItem.snp.right).offset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
        }
        othetItem.snp.makeConstraints { (make) in
            make.left.equalTo(tomorrowItem.snp.right).offset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(36)
        }
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: todayItem.systemLayoutSizeFitting(.zero).width +
                        32 +
                        tomorrowItem.systemLayoutSizeFitting(.zero).width +
                        othetItem.systemLayoutSizeFitting(.zero).width,
                      height: 36)
    }

}

private class PickDueTimeItemView: UIView {

    var didTapItem: (() -> Void)?
    var icon: UIImage
    var title: String

    private let iconView = UIImageView()
    private lazy var control: UIControl = {
        let control = UIControl()
        control.addTarget(self, action: #selector(clickItem), for: .touchUpInside)
        return control
    }()
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        label.sizeToFit()
        return label
    }()

    init(_ icon: UIImage, title: String) {
        self.icon = icon
        self.title = title
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBodyOverlay
        layer.cornerRadius = 8
        layer.masksToBounds = true

        addSubview(iconView)
        addSubview(titleLabel)
        addSubview(control)

        iconView.image = icon
        titleLabel.text = title

        iconView.snp.makeConstraints {
            $0.left.top.bottom.equalToSuperview()
                .inset(UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 0))
            $0.width.height.equalTo(20)
        }
        titleLabel.snp.makeConstraints {
            $0.centerY.equalTo(iconView)
            $0.left.equalTo(iconView.snp.right).offset(4)
            $0.right.equalToSuperview().offset(-16)
        }
        control.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func clickItem() {
        didTapItem?()
    }
}
