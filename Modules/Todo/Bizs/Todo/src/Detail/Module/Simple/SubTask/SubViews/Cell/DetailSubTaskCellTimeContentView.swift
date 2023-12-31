//
//  DetailSubTaskCellTimeContentView.swift
//  Todo
//
//  Created by baiyantao on 2022/8/1.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignFont

struct DetailSubTaskCellTimeContentViewData {
    var timeText: String?
    var hasReminder: Bool = false
    var hasRepeat: Bool = false
    var hasClearBtn: Bool = false
}

final class DetailSubTaskCellTimeContentView: UIView {

    var viewData: DetailSubTaskCellTimeContentViewData? {
        didSet {
            guard let data = viewData else { return }
            timeLabel.text = data.timeText
            reminderIcon.isHidden = !data.hasReminder
            repeatIcon.isHidden = !data.hasRepeat
            clearBtn.isHidden = !data.hasClearBtn
        }
    }

    var detailClickHandler: (() -> Void)?
    var clearBtnClickHandler: (() -> Void)?

    private lazy var stackView = getStackView()
    private lazy var timeLabel = getTimeLabel()
    private lazy var reminderIcon = getReminderIcon()
    private lazy var repeatIcon = getRepeatIcon()
    private lazy var clearBtn = getClearBtn()

    init() {
        super.init(frame: .zero)

        addSubview(stackView)
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        stackView.addArrangedSubview(timeLabel)
        timeLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)

        stackView.addArrangedSubview(reminderIcon)
        reminderIcon.isHidden = true
        stackView.addArrangedSubview((repeatIcon))
        repeatIcon.isHidden = true
        stackView.addArrangedSubview(clearBtn)
        clearBtn.isHidden = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func getStackView() -> UIStackView {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        let tap = UITapGestureRecognizer(target: self, action: #selector(onDetailClick))
        stackView.addGestureRecognizer(tap)
        return stackView
    }

    private func getTimeLabel() -> UILabel {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.textAlignment = .left
        label.lineBreakMode = .byTruncatingTail
        label.numberOfLines = 1
        label.font = UDFont.systemFont(ofSize: 14)
        return label
    }

    private func getReminderIcon() -> UIImageView {
        let view = UIImageView()
        view.image = UDIcon.bellOutlined
            .ud.resized(to: CGSize(width: 14.0, height: 14.0))
            .ud.withTintColor(UIColor.ud.iconN2)
        return view
    }

    private func getRepeatIcon() -> UIImageView {
        let view = UIImageView()
        view.image = UDIcon.repeatOutlined
            .ud.resized(to: CGSize(width: 14.0, height: 14.0))
            .ud.withTintColor(UIColor.ud.iconN2)
        return view
    }

    private func getClearBtn() -> UIButton {
        let button = UIButton()
        let icon = UDIcon.closeOutlined
            .ud.resized(to: CGSize(width: 14.0, height: 14.0))
            .ud.withTintColor(UIColor.ud.iconN2)
        button.setImage(icon, for: .normal)
        button.setImage(icon, for: .highlighted)
        button.hitTestEdgeInsets = UIEdgeInsets(top: -12, left: -12, bottom: -12, right: -12)
        button.addTarget(self, action: #selector(onClearBtnClick), for: .touchUpInside)
        return button
    }

    @objc
    private func onDetailClick() {
        detailClickHandler?()
    }

    @objc
    private func onClearBtnClick() {
        clearBtnClickHandler?()
    }
}
