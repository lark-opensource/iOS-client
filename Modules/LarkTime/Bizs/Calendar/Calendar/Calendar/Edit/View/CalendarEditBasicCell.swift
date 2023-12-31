//
//  CalendarEditBasicCell.swift
//  Calendar
//
//  Created by Hongbin Liang on 3/10/23.
//

import Foundation
import UIKit
import UniverseDesignIcon

enum CalendarCellContent {
    case subTitle(text: String)
    case sampleView(view: UIView, size: CGSize)
}

protocol CalendarCellDataType {
    var title: String { get }
    var content: CalendarCellContent { get }
    var clickNeedBlock: Bool { get }
}

class CalendarEditBasicCell: EventBasicCellLikeView.BackgroundView, ViewDataConvertible {

    var onClick: ((_ needBlock: Bool) -> Void)?

    var viewData: CalendarCellDataType? {
        didSet {
            guard let viewData = viewData else { return }
            authorityMask.isHidden = !viewData.clickNeedBlock
            titleLabel.text = viewData.title
            switch viewData.content {
            case .subTitle(let text):
                descLabel.text = text
                descLabel.isHidden = false
            case .sampleView(let view, let size):
                descriptionView.addSubview(view)
                view.snp.makeConstraints {
                    $0.size.equalTo(size)
                    $0.top.bottom.trailing.equalToSuperview()
                    $0.leading.greaterThanOrEqualToSuperview()
                }
                descLabel.isHidden = true
            }
            let highLightColor = viewData.clickNeedBlock ? UIColor.ud.panelBgColor : UIColor.ud.fillPressed
            backgroundColors = (UIColor.ud.panelBgColor, highLightColor)
        }
    }

    private let authorityMask = UIView()
    private let titleLabel = UILabel.cd.textLabel()
    private let descLabel = UILabel.cd.subTitleLabel()
    private let descriptionView = UIView()
    private let arrowIcon = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColors = (UIColor.ud.panelBgColor, UIColor.ud.fillPressed)
        let gesture = UITapGestureRecognizer(target: self, action: #selector(cellTapped))
        addGestureRecognizer(gesture)

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().inset(16)
            $0.centerY.equalToSuperview()
        }

        addSubview(descriptionView)
        descriptionView.snp.makeConstraints {
            $0.leading.equalTo(titleLabel.snp.trailing).offset(12)
            $0.top.bottom.equalToSuperview().inset(12)
        }

        descLabel.textAlignment = .right
        descLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        descriptionView.addSubview(descLabel)
        descLabel.snp.makeConstraints {
            $0.centerY.trailing.equalToSuperview()
            $0.top.greaterThanOrEqualToSuperview()
            $0.bottom.lessThanOrEqualToSuperview()
            $0.leading.greaterThanOrEqualToSuperview()
            $0.height.equalTo(24)
        }

        arrowIcon.image = UDIcon.getIconByKey(.rightBoldOutlined, size: CGSize(width: 12, height: 12)).renderColor(with: .n3)
        addSubview(arrowIcon)
        arrowIcon.snp.makeConstraints {
            $0.trailing.equalToSuperview().inset(16)
            $0.leading.equalTo(descriptionView.snp.trailing).offset(12)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(CGSize(width: 12, height: 12))
        }

        authorityMask.alpha = 0.5
        authorityMask.isHidden = true
        authorityMask.backgroundColor = .ud.panelBgColor
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(authorityMaskTapped))
        authorityMask.addGestureRecognizer(tapGesture)
        addSubview(authorityMask)
        authorityMask.snp.makeConstraints { $0.edges.equalToSuperview() }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func cellTapped() {
        onClick?(false)
    }

    @objc
    private func authorityMaskTapped() {
        onClick?(true)
    }
}
