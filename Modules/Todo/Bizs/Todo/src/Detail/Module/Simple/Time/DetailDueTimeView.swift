//
//  DetailDueTimeView.swift
//  Todo
//
//  Created by 白言韬 on 2020/11/19.
//

import CTFoundation
import UniverseDesignIcon
import UniverseDesignFont

struct DetailDueTimeViewData {
    var startTimeText: String?
    var dueTimeText: String?
    var preferQuick: Bool
    var hasReminder: Bool
    var hasRepeat: Bool
    var hasClearBtn: Bool
    var isClearBtnDisable: Bool
    var preferMaxLayoutWidth: CGFloat = 0
    var textColor: UIColor = UIColor.ud.textTitle
    var iconColor: UIColor = UIColor.ud.iconN1

    var isVisible: Bool {
        guard startTimeText == nil, dueTimeText == nil else {
            return true
        }
        return false
    }
}

final class DetailDueTimeView: BasicCellLikeView, ViewDataConvertible {

    var viewData: DetailDueTimeViewData? {
        didSet {
            guard let viewData = viewData else { return }
            if viewData.dueTimeText != nil || viewData.startTimeText != nil {
                content = .customView(contentView)
                var newViewData = viewData
                newViewData.preferMaxLayoutWidth = preferMaxLayoutWidth
                contentView.viewData = newViewData
                contentView.clickHandler = contentClickHandler
                contentView.clearButtonHandler = clearButtonHandler
            } else {
                if viewData.preferQuick {
                    content = .customView(quickSelectView)
                    quickSelectView.quickTodayHandler = quickTodayHandler
                    quickSelectView.quickTomorrowHandler = quickTomorrowHandler
                    quickSelectView.otherTimeHandler = fullPageHandler
                } else {
                    content = .customView(emptyView)
                    emptyView.text = I18N.Todo_Task_AddDueTime
                    emptyView.onTapHandler = emptyClickHandler
                }
            }
            invalidateIntrinsicContentSize()
            setNeedsUpdateConstraints()
        }
    }

    var emptyClickHandler: (() -> Void)?
    var contentClickHandler: (() -> Void)?

    var clearButtonHandler: (() -> Void)?
    var quickTodayHandler: (() -> Void)?
    var quickTomorrowHandler: (() -> Void)?
    var fullPageHandler: (() -> Void)?

    private lazy var emptyView = DetailEmptyView()
    private lazy var quickSelectView = DueTimeQuickSelectView()
    private lazy var contentView = DueTimeContentView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        let dueTime = UDIcon.getIconByKey(
            .calendarDateOutlined,
            renderingMode: .automatic,
            iconColor: nil,
            size: CGSize(width: 20, height: 20)
        )
        icon = .customImage(dueTime.ud.withTintColor(UIColor.ud.iconN3))
        iconAlignment = .topByOffset(16)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        let height = max(48.0, contentView.intrinsicContentSize.height + 12.0)
        return CGSize(width: Self.noIntrinsicMetric, height: height)
    }

}

final class DueTimeContentView: UIView, ViewDataConvertible {

    var clickHandler: (() -> Void)?

    var clearButtonHandler: (() -> Void)?

    var viewData: DetailDueTimeViewData? {
        didSet {
            guard let data = viewData else {
                isHidden = true
                return
            }
            isHidden = false
            if isMultiLine(with: data) {
                topSpaceView.isHidden = false
                firstLabel.isHidden = false
                firstLabel.text = "\(data.startTimeText ?? "") -"
                secondLabel.text = data.dueTimeText
            } else {
                // 用第二个label 显示
                topSpaceView.isHidden = true
                firstLabel.isHidden = true

                if let start = data.startTimeText, let due = data.dueTimeText {
                    secondLabel.text = "\(start) - \(due)"
                } else if let start = data.startTimeText {
                    secondLabel.text = start
                } else if let due = data.dueTimeText {
                    secondLabel.text = due
                }
            }
            firstLabel.textColor = data.textColor
            secondLabel.textColor = data.textColor
            repeatIcon.image = repeatIcon.image?.ud.withTintColor(data.iconColor)
            reminderIcon.image = reminderIcon.image?.ud.withTintColor(data.iconColor)
            reminderIcon.isHidden = !data.hasReminder
            repeatIcon.isHidden = !data.hasRepeat
            if data.hasClearBtn {
                clearButton.isHidden = data.isClearBtnDisable
                disableClearButton.isHidden = !data.isClearBtnDisable
            } else {
                clearButton.isHidden = true
                disableClearButton.isHidden = true
            }
        }
    }

    private(set) lazy var containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.backgroundColor = FeatureGating.boolValue(for: .startTime) ? .clear: UIColor.ud.bgBodyOverlay

        let tap = UITapGestureRecognizer(target: self, action: #selector(onBackgroundClick))
        view.addGestureRecognizer(tap)
        return view
    }()

    private lazy var dueStackView: UIStackView = {
        var stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = Config.Space
        return stackView
    }()

    private lazy var vStackView: UIStackView = {
        var stackView = UIStackView()
        stackView.axis = .vertical
        stackView.alignment = .leading
        return stackView

    }()

    private lazy var topSpaceView = UIView()

    private lazy var firstLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.systemFont(ofSize: 14)
        return label
    }()

    private lazy var secondLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.systemFont(ofSize: 14)
        return label
    }()

    private lazy var repeatIcon: UIImageView = {
        let view = UIImageView()
        let repeatIcon = UDIcon.getIconByKey(
            .repeatOutlined,
            iconColor: UIColor.ud.iconN1,
            size: CGSize(width: Config.IconSize, height: Config.IconSize)
        )
        view.image = repeatIcon
        return view
    }()

    private lazy var reminderIcon: UIImageView = {
        let view = UIImageView()
        let icon = UDIcon.bellOutlined.ud.resized(to: CGSize(width: Config.IconSize, height: Config.IconSize))
        view.image = icon.ud.withTintColor(UIColor.ud.iconN1)
        return view
    }()

    private lazy var clearButton: UIButton = {
        let button = UIButton()
        let icon = UDIcon.closeOutlined.ud.resized(to: CGSize(width: Config.IconSize, height: Config.IconSize))
        button.setImage(icon.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        button.hitTestEdgeInsets = UIEdgeInsets(top: -10, left: -10, bottom: -10, right: -10)
        button.addTarget(self, action: #selector(onClearButtonClick), for: .touchUpInside)
        return button
    }()

    private lazy var disableClearButton: UIImageView = {
        let view = UIImageView()
        let closeIcon = UDIcon.getIconByKey(
            .closeOutlined,
            renderingMode: .automatic,
            iconColor: UIColor.ud.iconDisabled,
            size: CGSize(width: Config.IconSize, height: Config.IconSize)
        )
        view.image = closeIcon
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(containerView)
        containerView.snp.makeConstraints {
            $0.left.centerY.equalToSuperview()
            $0.right.lessThanOrEqualToSuperview()
        }
        containerView.addSubview(vStackView)
        vStackView.snp.makeConstraints {
            $0.left.equalToSuperview().offset(Config.Padding)
            $0.right.equalToSuperview().offset(-Config.Padding)
            $0.top.bottom.equalToSuperview()
        }

        vStackView.addArrangedSubview(topSpaceView)
        topSpaceView.snp.makeConstraints { $0.height.width.equalTo(Config.Space) }
        topSpaceView.isHidden = true

        vStackView.addArrangedSubview(firstLabel)
        firstLabel.snp.makeConstraints { $0.height.equalTo(Config.TextHeight) }
        firstLabel.isHidden = true

        vStackView.addArrangedSubview(dueStackView)
        dueStackView.snp.makeConstraints {
            $0.height.equalTo(Config.Space * 2 + Config.TextHeight)
        }

        dueStackView.addArrangedSubview(secondLabel)
        secondLabel.snp.makeConstraints { $0.height.equalTo(Config.TextHeight) }

        dueStackView.addArrangedSubview(reminderIcon)
        reminderIcon.snp.makeConstraints { $0.width.height.equalTo(Config.IconSize) }
        reminderIcon.isHidden = true

        dueStackView.addArrangedSubview(repeatIcon)
        repeatIcon.snp.makeConstraints { $0.width.height.equalTo(Config.IconSize) }
        repeatIcon.isHidden = true

        dueStackView.addArrangedSubview(clearButton)
        clearButton.snp.makeConstraints { $0.width.height.equalTo(Config.IconSize) }
        clearButton.isHidden = true

        dueStackView.addArrangedSubview(disableClearButton)
        disableClearButton.snp.makeConstraints { $0.width.height.equalTo(Config.IconSize) }
        disableClearButton.isHidden = true

    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        var height = 0.0
        if !firstLabel.isHidden {
            height += Config.Space + Config.TextHeight
        }
        if !secondLabel.isHidden {
            height += Config.Space * 2 + Config.TextHeight
        }
        return CGSize(width: Self.noIntrinsicMetric, height: height)
    }

    var singleLineSize: CGSize {
        guard let viewData = viewData else { return .zero }
        var width = secondLabel.intrinsicContentSize.width + Config.Space * 2
        if viewData.hasReminder {
            width += reminderIcon.intrinsicContentSize.width + Config.Space
        }
        if viewData.hasRepeat {
            width += repeatIcon.intrinsicContentSize.width + Config.Space
        }
        if viewData.hasClearBtn {
            width += clearButton.intrinsicContentSize.width + Config.Space
        }
        return CGSize(width: width, height: Config.Space * 2 + Config.TextHeight)
    }

    @objc
    private func onBackgroundClick() {
        clickHandler?()
    }

    @objc
    private func onClearButtonClick() {
        clearButtonHandler?()
    }

    private func isMultiLine(with data: DetailDueTimeViewData) -> Bool {
        guard let startTime = data.startTimeText, let dueTime = data.dueTimeText else {
            return false
        }
        let text = "\(startTime) - \(dueTime)"
        secondLabel.text = text
        var width = Config.Space + ceil(secondLabel.intrinsicContentSize.width)
        if data.hasReminder {
            width += Config.Space + Config.IconSize
        }
        if data.hasRepeat {
            width += Config.Space + Config.IconSize
        }
        if data.hasClearBtn {
            width += Config.Space + Config.IconSize
        }
        if width > data.preferMaxLayoutWidth {
            return true
        }
        return false
    }

    struct Config {
        static let Padding = 10.0
        static let Space = 8.0
        static let TextHeight = 20.0
        static let IconSize = 14.0
    }
}
