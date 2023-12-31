//
//  TranslateMoreActionCell.swift
//  LarkMessageCore
//
//  Created by Patrick on 3/8/2022.
//

import Foundation
import UIKit

public final class TranslateMoreActionCell: UITableViewCell {
    enum LocationType {
        case first
        case middle
        case last
    }
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var container: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        return view
    }()

    private lazy var divider: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.lineDividerDefault.withAlphaComponent(0.15)
        view.isHidden = true
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private func setupView() {
        backgroundColor = .ud.bgFloatBase
        container.backgroundColor = .ud.bgFloat
        addSubview(container)
        container.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(16)
        }
        container.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(16)
        }
        container.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(12)
            make.centerY.equalToSuperview()
        }
        container.addSubview(divider)
        divider.snp.makeConstraints { make in
            make.left.equalTo(titleLabel)
            make.right.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }

    func set(withAction action: TranslateMoreActionModel, locationType: LocationType) {
        iconView.image = action.icon
        titleLabel.text = action.title

        switch locationType {
        case .first:
            container.clipsToBounds = true
            container.roundCorners(corners: [.topLeft, .topRight], radius: 6.0)
            divider.isHidden = false
        case .middle:
            container.clipsToBounds = false
            container.layer.maskedCorners = []
            divider.isHidden = false
        case .last:
            container.clipsToBounds = true
            container.roundCorners(corners: [.bottomLeft, .bottomRight], radius: 6.0)
            divider.isHidden = true
        }
    }
}

extension UIView {
    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
        clipsToBounds = true
        layer.cornerRadius = radius
        layer.maskedCorners = CACornerMask(rawValue: corners.rawValue)
    }
}
