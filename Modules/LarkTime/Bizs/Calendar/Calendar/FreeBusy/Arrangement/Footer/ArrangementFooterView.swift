//
//  ArrangementFooterView.swift
//  Calendar
//
//  Created by harry zou on 2019/3/20.
//

import UIKit
import SnapKit
import CalendarFoundation
import UniverseDesignIcon

protocol ArrangementFooterViewDelegate: AnyObject {
    func arrangementFooterViewTimeConfirmed()
}

protocol ArrangementFooterViewInterface {
    var timeText: String { get }
    var subTitleAttributedText: NSAttributedString { get }
}

final class ArrangementFooterView: UIView, Shadowable {
    weak var delegate: ArrangementFooterViewDelegate?
    private let hasConfirmButton: Bool

    private let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.cd.mediumFont(ofSize: 17)
        label.numberOfLines = 0
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    // 暂时取一个较小值375代替屏幕宽度
    static let labelMaxWidth: CGFloat = 375 - 118
    static let labelMaxWidthNoConfirmButton: CGFloat = 375 - 36
    private let situationLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.cd.regularFont(ofSize: 14)
        label.numberOfLines = 0
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let confirmButton: UIButton = {
        let button = UIButton()
        let yesIcon = UDIcon.getIconByKey(.yesOutlined, renderingMode: .alwaysOriginal,
                                          iconColor: UIColor.ud.primaryContentDefault,
                                          size: CGSize(width: 32, height: 32))
        button.setImage(yesIcon, for: .normal)
        return button
    }()

    @objc
    private func confirmButtonPressed() {
        delegate?.arrangementFooterViewTimeConfirmed()
    }

    func updateContent(content: ArrangementFooterViewInterface) {
        timeLabel.text = content.timeText
        situationLabel.attributedText = content.subTitleAttributedText
    }

    convenience init() {
        self.init(hasConfirmButton: true)
    }

    init(hasConfirmButton: Bool) {
        self.hasConfirmButton = hasConfirmButton
        super.init(frame: .zero)
        confirmButton.addTarget(self, action: #selector(confirmButtonPressed), for: .touchUpInside)
        if hasConfirmButton {
            layout(confirmButton: confirmButton)
        }
        layoutLabels(stackView: UIStackView(),
                     timeLabel: timeLabel,
                     situationLabel: situationLabel)
        backgroundColor = UIColor.ud.bgFloat
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        setupTopShadows()
    }

    private func layoutLabels(stackView: UIStackView, timeLabel: UILabel, situationLabel: UILabel) {
        addSubview(stackView)
        stackView.axis = .vertical
        stackView.spacing = 4
        let leftEdge = hasConfirmButton ? confirmButton.snp.left : self.snp.right
        stackView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(28)
            make.top.bottom.equalToSuperview().inset(16)
            make.right.lessThanOrEqualTo(leftEdge)
        }
        stackView.addArrangedSubview(timeLabel)
        stackView.addArrangedSubview(situationLabel)
    }

    private func layout(confirmButton: UIButton) {
        addSubview(confirmButton)
        confirmButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(32)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-28)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
