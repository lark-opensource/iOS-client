//
//  SubscribeLables.swift
//  Calendar
//
//  Created by heng zhu on 2019/1/11.
//  Copyright © 2019 EE. All rights reserved.
//

import Foundation
import CalendarFoundation
import UIKit
import SnapKit

final class SubscribeLables: UIView {

    private(set) lazy var titleLabel = UILabel.cd.textLabel()
    private(set) var externalTag = TagViewProvider.externalNormal
    private let middleTitleLabel: UILabel = UILabel.cd.textLabel()
    private let subTitleLabel: UILabel = UILabel.cd.subTitleLabel()

    init() {
        super.init(frame: .zero)
        let firstLine = UIStackView(arrangedSubviews: [titleLabel, externalTag])
        firstLine.spacing = 8
        let stackWrapper = UIStackView()
        stackWrapper.axis = .vertical
        stackWrapper.alignment = .leading
        stackWrapper.addArrangedSubview(firstLine)
        stackWrapper.addArrangedSubview(subTitleLabel)
        stackWrapper.spacing = 4
        addSubview(stackWrapper)
        stackWrapper.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateWith(_ title: String, subTitle: String) {
        subTitleLabel.isHidden = subTitle.isEmpty
        titleLabel.text = title
        subTitleLabel.text = subTitle
    }
}
