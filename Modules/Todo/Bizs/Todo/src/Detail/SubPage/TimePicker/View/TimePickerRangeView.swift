//
//  TimePickerRangeView.swift
//  Todo
//
//  Created by wangwanxin on 2023/5/22.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignFont

struct TimePickRangeData {
    enum RangeType {
        case start
        case due
    }
    var startDateStr: String?
    var startTimeStr: String?
    var startPlaceholder: String {
        return I18N.Todo_TaskStartTime_Button
    }
    var dueDateStr: String?
    var dueTimeStr: String?
    var duePlaceholder: String {
        return I18N.Todo_Task_DueAt
    }
    var selected: RangeType = .due

}

final class TimePickerRangeView: UIView {

    var viewData: TimePickRangeData? {
        didSet {
            guard let data = viewData else { return }
            let start = RangeViewData(
                isSelected: data.selected == .start,
                placeholder: (data.startDateStr == nil && data.startTimeStr == nil) ? data.startPlaceholder : nil,
                title: data.startDateStr,
                subTitle: data.startTimeStr
            )
            let due = RangeViewData(
                isSelected: data.selected == .due,
                placeholder: (data.dueDateStr == nil && data.dueDateStr == nil) ? data.duePlaceholder : nil,
                title: data.dueDateStr,
                subTitle: data.dueTimeStr
            )
            startView.viewData = start
            dueView.viewData = due
            switch data.selected {
            case .start:
                arrowView.fillColor = UIColor.ud.primaryContentDefault
            case .due:
                arrowView.fillColor = UIColor.ud.bgBody
            }
        }
    }

    var onSwitchRangeHandler: ((TimePickRangeData.RangeType) -> Void)?
    var onCloseHander: ((TimePickRangeData.RangeType) -> Void)?

    private lazy var arrowView = ArrowView()
    private lazy var startView = PickerRangeView()
    private lazy var dueView = PickerRangeView()

    override init(frame: CGRect) {
        super.init(frame: .zero)

        addSubview(startView)
        addSubview(dueView)
        addSubview(arrowView)

        startView.snp.makeConstraints {
            $0.top.bottom.left.equalToSuperview()
            $0.right.equalTo(self.snp.centerX).offset(-Config.StartToCenterOffSet)
        }

        dueView.snp.makeConstraints {
            $0.top.bottom.right.equalToSuperview()
            $0.left.equalTo(startView.snp.right)
        }

        arrowView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.width.equalTo(Config.ArrowWidth)
            make.height.equalTo(Config.Height)
            make.centerX.equalToSuperview()
        }

        startView.onSwitchRangeHandler = { [weak self] in
            self?.onSwitchRangeHandler?(.start)
        }
        startView.onCloseHander = { [weak self] in
            self?.onCloseHander?(.start)
        }

        dueView.onSwitchRangeHandler = { [weak self] in
            self?.onSwitchRangeHandler?(.due)
        }
        dueView.onCloseHander = { [weak self] in
            self?.onCloseHander?(.due)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: Self.noIntrinsicMetric, height: Config.Height)
    }

}

extension TimePickerRangeView {

    struct RangeViewData {
        var isSelected: Bool
        var placeholder: String?
        var title: String?
        var subTitle: String?
    }

    final class PickerRangeView: UIView {

        var onSwitchRangeHandler: (() -> Void)?
        var onCloseHander: (() -> Void)?

        var viewData: RangeViewData? {
            didSet {
                guard let viewData = viewData else { return }
                if let placeholder = viewData.placeholder {
                    placeholderLabel.isHidden = false
                    addImageView.isHidden = false
                    closeBtn.isHidden = true
                    placeholderLabel.text = placeholder
                } else {
                    closeBtn.isHidden = false
                    addImageView.isHidden = true
                    placeholderLabel.isHidden = true
                }
                if let title = viewData.title {
                    titleLabel.isHidden = false
                    titleLabel.text = title
                } else {
                    titleLabel.isHidden = true
                }
                if let subTitle = viewData.subTitle {
                    subTitleLabel.isHidden = false
                    subTitleLabel.text = subTitle
                } else {
                    subTitleLabel.isHidden = true
                }
                if viewData.isSelected {
                    let color = UIColor.ud.staticWhite
                    backgroundColor = UIColor.ud.primaryContentDefault
                    titleLabel.textColor = color
                    subTitleLabel.textColor = color
                    placeholderLabel.textColor = color
                    addImageView.image = addIcon.ud.withTintColor(color)
                    closeBtn.setImage(closeIcon.ud.withTintColor(color), for: .normal)
                } else {
                    backgroundColor = UIColor.ud.bgBody
                    titleLabel.textColor = UIColor.ud.textTitle
                    subTitleLabel.textColor = UIColor.ud.textTitle
                    placeholderLabel.textColor = UIColor.ud.textPlaceholder
                    addImageView.image = addIcon.ud.withTintColor(UIColor.ud.iconN3)
                    closeBtn.setImage(closeIcon.ud.withTintColor(UIColor.ud.iconN3), for: .normal)
                }
            }
        }

        private lazy var addIcon = UDIcon.getIconByKey(.addOutlined, size: Config.AddIconSize)

        private lazy var addImageView = UIImageView(image: addIcon)

        private lazy var placeholderLabel: UILabel = {
            let label = UILabel()
            label.font = UDFont.systemFont(ofSize: Config.SubTitleFont)
            return label
        }()

        private lazy var contentView: UIStackView = {
            let stack = UIStackView()
            stack.axis = .vertical
            stack.spacing = Config.StackSpace
            stack.alignment = .center
            return stack
        }()

        private lazy var titleLabel: UILabel = {
            let label = UILabel()
            label.font = UDFont.systemFont(ofSize: Config.TitleFont, weight: .medium)
            return label
        }()

        private lazy var subTitleLabel: UILabel = {
            let label = UILabel()
            label.font = UDFont.systemFont(ofSize: Config.SubTitleFont, weight: .regular)
            return label
        }()

        private lazy var closeIcon = UDIcon.getIconByKey(.closeOutlined, size: Config.CloseIconSize)

        private lazy var closeBtn: UIButton = {
            let btn = UIButton()
            btn.setImage(closeIcon, for: .normal)
            return btn
        }()


        override init(frame: CGRect) {
            super.init(frame: .zero)
            addSubview(addImageView)
            addSubview(placeholderLabel)
            addSubview(contentView)
            contentView.addArrangedSubview(titleLabel)
            contentView.addArrangedSubview(subTitleLabel)
            addSubview(closeBtn)

            closeBtn.addTarget(self, action: #selector(clickClose), for: .touchUpInside)
            let tap = UITapGestureRecognizer(target: self, action: #selector(tapView))
            addGestureRecognizer(tap)

            addImageView.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(50)
                make.size.equalTo(Config.AddIconSize)
                make.centerY.equalToSuperview()
            }

            placeholderLabel.snp.makeConstraints { make in
                make.left.equalTo(addImageView.snp.right).offset(10)
                make.right.equalToSuperview()
                make.centerY.equalToSuperview()
            }

            closeBtn.snp.makeConstraints { make in
                make.top.bottom.equalToSuperview()
                make.size.equalTo(Config.CloseIconSize)
                make.right.equalToSuperview().offset(-16)
            }

            titleLabel.snp.makeConstraints { make in
                make.height.equalTo(Config.TitleHeight)
            }

            subTitleLabel.snp.makeConstraints { make in
                make.height.equalTo(Config.SubTitleFont)
            }

            contentView.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(40)
                make.top.equalToSuperview().offset(10)
                make.bottom.equalToSuperview().offset(-9)
                make.right.equalTo(closeBtn.snp.left)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        @objc
        private func tapView() {
            onSwitchRangeHandler?()
        }

        @objc
        private func clickClose() {
            onCloseHander?()
        }

    }

    final class ArrowView: UIView {
        var fillColor: UIColor {
            didSet { setNeedsDisplay() }
        }

        init(fillColor: UIColor = UIColor.ud.staticWhite) {
            self.fillColor = fillColor
            super.init(frame: .zero)
            backgroundColor = .clear
        }

        required public init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override public func draw(_ rect: CGRect) {
            let path = UIBezierPath()
            path.move(to: bounds.centerRight)
            path.addLine(to: bounds.bottomLeft)
            path.addLine(to: bounds.topLeft)
            fillColor.setFill()
            path.close()
            path.fill()
        }
    }

    struct Config {
        static let AddIconSize = CGSize(width: 16.0, height: 16.0)
        static let TitleFont = 16.0
        static let SubTitleFont = 14.0
        static let CloseIconSize = CGSize(width: 14.0, height: 14.0)
        static let StackSpace = 2.0
        static let TitleHeight = 22.0
        static let SubTitleHeight = 17.0

        static let ArrowWidth = 12.0
        static let StartToCenterOffSet = 6.0

        static let Height = 60.0
    }

}

