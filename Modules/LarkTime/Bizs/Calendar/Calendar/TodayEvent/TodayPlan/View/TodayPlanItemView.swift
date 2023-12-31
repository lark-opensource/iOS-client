//
//  TodayPlanItemView.swift
//  Calendar
//
//  Created by chaishenghua on 2023/8/2.
//

import LarkUIKit
import UniverseDesignColor
import UniverseDesignFont
import UniverseDesignIcon

class TodayPlanItemView: UIView {
    private let margin = 8
    private let logoWidth = 14
    private let subTtileHeight = 18

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UDFont.body1
        label.textColor = UDColor.functionInfo700
        return label
    }()

    private lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.font = UDFont.caption1
        label.textColor = UDColor.functionInfo700
        label.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        return label
    }()

    // 需求变更，今日安排不显示会议室
//    private lazy var locationLabel: UILabel = {
//        let label = UILabel()
//        label.font = UDFont.caption1
//        label.textColor = UDColor.functionInfo700
//        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
//        return label
//    }()

//    private lazy var divideView: UIView = {
//        let view = UIView()
//        view.backgroundColor = UDColor.functionInfo700
//        return view
//    }()

    private lazy var logo = UIImageView()

    init() {
        super.init(frame: .zero)
        self.layer.cornerRadius = 6
        self.backgroundColor = UDColor.functionInfo100
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        self.addSubview(titleLabel)
        self.addSubview(timeLabel)
        // self.addSubview(locationLabel)
        // self.addSubview(divideView)
        self.addSubview(logo)

        titleLabel.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(margin)
            make.height.equalTo(20)
            make.top.equalToSuperview().inset(margin)
            make.trailing.equalTo(logo.snp.leading).offset(-margin)
            make.bottom.equalTo(timeLabel.snp.top)
        }
        logo.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(margin)
            make.top.equalToSuperview().inset(11)
            make.width.height.equalTo(logoWidth)
        }
        timeLabel.snp.remakeConstraints { make in
            make.leading.equalToSuperview().inset(margin)
            make.trailing.lessThanOrEqualToSuperview().inset(margin)
            make.bottom.equalToSuperview().inset(margin)
            make.height.equalTo(subTtileHeight)
        }
        // 产品需求变更，后续可能会用到，暂时注释
//        divideView.snp.makeConstraints { make in
//            make.leading.equalTo(timeLabel.snp.trailing).offset(4)
//            make.trailing.equalTo(locationLabel.snp.leading).offset(-4)
//            make.height.equalTo(12)
//            make.width.equalTo(1)
//            make.centerY.equalTo(timeLabel)
//        }
//        locationLabel.snp.makeConstraints { make in
//            make.trailing.bottom.equalToSuperview().inset(margin)
//            make.height.equalTo(subTtileHeight)
//        }
    }

    func setModel(model: TodayPlanModel) {
        self.titleLabel.text = model.baseModel.summary
        switch model.calendarType {
        case .google:
            self.logo.isHidden = false
            self.logo.image = UDIcon.getIconByKey(UDIconType.googleFilled).colorImage(UDColor.primaryFillTransparent03)
        case .exchange:
            self.logo.isHidden = false
            self.logo.image = UDIcon.getIconByKey(UDIconType.exchangeFilled).colorImage(UDColor.primaryFillTransparent03)
        default:
            self.logo.isHidden = true
        }

        logo.snp.updateConstraints { make in
            make.width.equalTo(logo.isHidden ? 0: logoWidth)
        }

        let timeHiddne = model.baseModel.rangeTime.isEmpty
        timeLabel.isHidden = timeHiddne
        timeLabel.text = model.baseModel.rangeTime
        timeLabel.snp.updateConstraints { make in
            make.height.equalTo(timeHiddne ? 0: subTtileHeight)
        }
        // 产品需求变更，后续可能会用到，暂时注释
//        let locationHidden = model.baseModel.location.isEmpty
//        locationLabel.isHidden = locationHidden
//        locationLabel.text = model.baseModel.location
//        locationLabel.snp.updateConstraints { make in
//            make.height.equalTo(locationHidden ? 0: subTtileHeight)
//        }

//        if !timeHiddne && !locationHidden {
//            divideView.isHidden = false
//            divideView.snp.updateConstraints { make in
//                make.leading.equalTo(timeLabel.snp.trailing).offset(4)
//                make.trailing.equalTo(locationLabel.snp.leading).offset(-4)
//                make.height.equalTo(12)
//                make.width.equalTo(1)
//            }
//        } else {
//            divideView.isHidden = true
//            divideView.snp.updateConstraints { make in
//                make.leading.equalTo(timeLabel.snp.trailing)
//                make.trailing.equalTo(locationLabel.snp.leading)
//                make.height.equalTo(0)
//                make.width.equalTo(0)
//            }
//        }
    }
}
