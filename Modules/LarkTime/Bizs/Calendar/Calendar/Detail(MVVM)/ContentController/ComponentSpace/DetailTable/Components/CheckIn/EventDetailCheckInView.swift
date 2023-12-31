//
//  EventDetailCheckInView.swift
//  Calendar
//
//  Created by huoyunjie on 2022/9/20.
//

import UIKit
import Foundation
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignColor

protocol EventDetailCheckInViewDateType {
    var title: String? { get }
    var subTitle: String { get }
    var titleHidden: Bool { get }
    var subTitleHidden: Bool { get }
    var arrowHidden: Bool { get }
    var titleActive: Bool { get }
    var subTitleActive: Bool { get }
    var arrowActive: Bool { get }
    var disableReason: String { get }
}

class EventDetailCheckInView: DetailCell {

    let goToButton: UIButton = UIButton()
    let titleLabel: UILabel = UILabel()
    let subTitleLabel: UILabel = UILabel()

    var viewData: EventDetailCheckInViewDateType? {
        didSet {
            guard let viewData = viewData else {
                self.isHidden = true
                self.superview?.isHidden = true
                return
            }

            self.isHidden = false
            self.superview?.isHidden = false
            self.titleLabel.isHidden = viewData.titleHidden
            self.goToButton.isHidden = viewData.arrowHidden
            self.subTitleLabel.isHidden = viewData.subTitleHidden

            self.titleLabel.text = viewData.title ?? ""
            self.subTitleLabel.text = viewData.subTitle

            self.titleLabel.textColor = viewData.titleActive ? UDColor.textTitle : UDColor.textPlaceholder
            self.subTitleLabel.textColor = viewData.subTitleActive ? UDColor.textTitle : UDColor.textPlaceholder

            let image = viewData.arrowActive ? UDIcon.rightOutlined.renderColor(with: .n2) : UDIcon.rightOutlined.renderColor(with: .n4)
            self.goToButton.setImage(image, for: .normal)

            self.titleLabel.text = viewData.title ?? ""
            self.subTitleLabel.text = viewData.subTitle

            if self.titleLabel.text.isEmpty {
                self.titleLabel.isHidden = true
            }
            if self.subTitleLabel.text.isEmpty {
                self.subTitleLabel.isHidden = true
            }
        }
    }

    var onClick: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setLeadingIcon(UDIcon.calendarDoneOutlined.renderColor(with: .n3))
        self.setupView()

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction))
        addGestureRecognizer(tap)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        titleLabel.numberOfLines = 0
        titleLabel.font = UDFont.body0
        titleLabel.textColor = UDColor.textTitle

        subTitleLabel.numberOfLines = 0
        subTitleLabel.font = UDFont.body2(.fixed)
        subTitleLabel.textColor = UDColor.textPlaceholder

        goToButton.setImage(UDIcon.rightOutlined.renderColor(with: .n2), for: .normal)
        goToButton.bounds = CGRect(x: 0, y: 0, width: 16, height: 16)

        let stackView = UIStackView(arrangedSubviews: [titleLabel, subTitleLabel])
        stackView.axis = .vertical
        stackView.spacing = 2

        let wrapper = UIStackView(arrangedSubviews: [stackView, goToButton])
        wrapper.axis = .horizontal
        wrapper.spacing = 4
        wrapper.alignment = .center

        goToButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview()
            make.width.height.equalTo(16)
        }

        let contentView = UIView()
        contentView.addSubview(wrapper)
        wrapper.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview()
        }

        self.addCustomView(contentView)
    }

    @objc
    private func tapAction() {
        if let data = viewData, !data.arrowHidden {
            onClick?()
        }
    }
}
