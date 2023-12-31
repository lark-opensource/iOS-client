//
//  EventDetailTableRemindView.swift
//  Calendar
//
//  Created by Rico on 2021/4/7.
//

import UIKit
import SnapKit
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignFont

protocol EventDetailTableRemindViewDataType {
    var remind: String { get }
}

final class EventDetailTableRemindView: UIView, ViewDataConvertible {
    var viewData: EventDetailTableRemindViewDataType? {
        didSet {
            guard let viewData = viewData else { return }
            titleLabel.text = viewData.remind
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

        titleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview().inset(10)
            make.left.equalToSuperview().offset(48)
            make.right.equalToSuperview().inset(10)
        }

        icon.snp.makeConstraints { (make) in
            make.leading.equalTo(16)
            make.size.equalTo(CGSize(width: 16, height: 16))
            make.top.equalToSuperview().offset(13)
        }
    }

    private lazy var icon: UIImageView = {
        let icon = UIImageView()
        icon.contentMode = .scaleAspectFit
        icon.image = UDIcon.getIconByKeyNoLimitSize(.bellOutlined).renderColor(with: .n3)
        return icon
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textTitle
        label.font = UDFont.body0(.fixed)
        label.numberOfLines = 0
        return label
    }()

}
