//
//  TimePickerSubTitleCell.swift
//  Todo
//
//  Created by 白言韬 on 2021/7/8.
//

import Foundation
import UniverseDesignIcon
import UIKit
import UniverseDesignFont

final class TimePickerSubTitleCell: UIView {

    var clickHandler: (() -> Void)?

    var subTitle: String? {
        didSet {
            subTitleLabel.text = subTitle
        }
    }

    var subTitleColor = UIColor.ud.textPlaceholder {
        didSet {
            subTitleLabel.textColor = subTitleColor
        }
    }

    var indicatorColor = UIColor.ud.iconN3 {
        didSet {
            indicatorView.image = indicatorView.image?.ud.withTintColor(indicatorColor)
        }
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UDFont.systemFont(ofSize: 16)
        label.numberOfLines = 1
        return label
    }()

    private lazy var subTitleLabel: UILabel = {
        let label = UILabel()
        label.textColor = subTitleColor
        label.font = UDFont.systemFont(ofSize: 16)
        label.numberOfLines = 1
        return label
    }()

    private lazy var indicatorView: UIImageView = {
        let icon = UDIcon.getIconByKey(
            .rightOutlined,
            renderingMode: .automatic,
            iconColor: UIColor.ud.iconN3,
            size: CGSize(width: 16, height: 16)
        )
        return UIImageView(image: icon)
    }()

    init(title: String, hasIndicator: Bool = false) {
        super.init(frame: .zero)
        backgroundColor = UIColor.ud.bgBody

        titleLabel.text = title
        addSubview(titleLabel)
        addSubview(subTitleLabel)
        if hasIndicator {
            addSubview(indicatorView)
        }

        if hasIndicator {
            indicatorView.snp.makeConstraints {
                $0.centerY.equalToSuperview()
                $0.height.equalTo(16)
                $0.width.equalTo(16)
                $0.right.equalToSuperview().inset(16)
            }
            subTitleLabel.snp.makeConstraints {
                $0.centerY.equalToSuperview()
                $0.right.equalTo(indicatorView.snp.left).offset(-4)
            }
        } else {
            subTitleLabel.snp.makeConstraints {
                $0.centerY.equalToSuperview()
                $0.right.equalToSuperview().offset(-16)
            }
        }
        titleLabel.snp.makeConstraints {
            $0.centerY.equalToSuperview()
            $0.left.equalToSuperview().offset(16)
            $0.right.lessThanOrEqualTo(subTitleLabel.snp.left).offset(-16)
        }

        let bottomLineView = UIView()
        bottomLineView.backgroundColor = UIColor.ud.lineDividerDefault
        addSubview(bottomLineView)
        bottomLineView.snp.makeConstraints {
            $0.left.equalTo(titleLabel.snp.left)
            $0.right.bottom.equalToSuperview()
            $0.height.equalTo(CGFloat(1.0 / UIScreen.main.scale))
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        self.addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func onTap() {
        clickHandler?()
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: Self.noIntrinsicMetric, height: 60)
    }

}
