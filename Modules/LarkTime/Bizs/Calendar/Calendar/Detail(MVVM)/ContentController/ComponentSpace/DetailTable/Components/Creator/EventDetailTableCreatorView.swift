//
//  EventDetailTableCreatorView.swift
//  Calendar
//
//  Created by Rico on 2021/4/22.
//

import UIKit
import SnapKit
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignFont

protocol EventDetailTableCreatorViewDataType {
    var creatorInfo: String { get }
}

final class EventDetailTableCreatorView: UIView, ViewDataConvertible {
    var viewData: EventDetailTableCreatorViewDataType? {
        didSet {
            guard let viewData = viewData else { return }
            titleLabel.text = viewData.creatorInfo
            titleLabel.tryFitFoFigmaLineHeight()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        layoutUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layoutUI() {
        addSubview(icon)
        addSubview(titleLabel)

        icon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.leading.equalTo(16)
            make.size.equalTo(CGSize(width: 16, height: 16))
        }

        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalTo(icon.snp.trailing).offset(16)
            make.centerY.equalToSuperview()
            make.trailing.equalTo(-16)
        }
    }

    private lazy var icon: UIImageView = {
        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.image = UDIcon.getIconByKeyNoLimitSize(.infoOutlined).renderColor(with: .n3).withRenderingMode(.alwaysOriginal)
        return icon
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = UDColor.textTitle
        label.font = UDFont.body0(.fixed)
        return label
    }()

}
