//
//  ZoomHostNavigationTitleView.swift
//  Calendar
//
//  Created by pluto on 2022/11/1.
//

import UIKit
import Foundation
import LarkUIKit
import RxSwift
import UniverseDesignIcon

final class ZoomHostNavigationTitleView: UIView {

    private lazy var contentStatckView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 2
        stackView.alignment = .center
        stackView.distribution = .fill
        return stackView
    }()

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.textAlignment = .center
        return titleLabel
    }()

    private lazy var subTitleLabel: UILabel = {
        let subTitleLabel = UILabel()
        subTitleLabel.font = UIFont.systemFont(ofSize: 11)
        subTitleLabel.textColor = UIColor.ud.textCaption
        subTitleLabel.adjustsFontSizeToFitWidth = true
        subTitleLabel.minimumScaleFactor = 0.8
        return subTitleLabel
    }()

    init(title: String) {
        super.init(frame: .zero)
        self.titleLabel.text = title
        self.addSubview(contentStatckView)
        contentStatckView.snp.makeConstraints { $0.edges.equalToSuperview() }
        contentStatckView.addArrangedSubview(titleLabel)
        contentStatckView.addArrangedSubview(subTitleLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configNum(number: Int) {
        subTitleLabel.isHidden = (number == 0)
        subTitleLabel.text = I18n.Calendar_Edit_Email(num: number)
    }

}
