//
//  DateFilerItemView.swift
//  LarkSearch
//
//  Created by SuPeng on 4/18/19.
//

import UIKit
import Foundation
import UniverseDesignFont

enum DateFilerItemViewSyle {
    case left
    case right
}

protocol DateFilerItemViewDelegate: AnyObject {
    func itemViewDidClick(_ itemView: DateFilerItemView)
}

final class DateFilerItemView: UIView {
    weak var delegate: DateFilerItemViewDelegate?
    private(set) var selected: Bool = false

    private let contentView = UIView()
    private let topLabel = UILabel()
    private let bottomLabel = UILabel()
    private let triangleView = DateFilterTriangleView()

    init(style: DateFilerItemViewSyle) {
        super.init(frame: .zero)

        contentView.lu.addTapGestureRecognizer(action: #selector(contentViewDidClick), target: self)
        addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.width.equalToSuperview().offset(-40)
        }

        triangleView.style = style
        addSubview(triangleView)
        triangleView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.width.equalTo(40)
        }

        switch style {
        case .left:
            contentView.snp.makeConstraints { (make) in
                make.left.equalToSuperview()
            }
            triangleView.snp.makeConstraints { (make) in
                make.right.equalToSuperview()
            }
            topLabel.text = BundleI18n.Calendar.Lark_Search_SearchStartingTimeFilter
        case .right:
            contentView.snp.makeConstraints { (make) in
                make.right.equalToSuperview()
            }
            triangleView.snp.makeConstraints { (make) in
                make.left.equalToSuperview()
            }
            topLabel.text = BundleI18n.Calendar.Lark_Search_SearchEndingTimeFilter
        }

        let contentLayoutGuide = UILayoutGuide()
        addLayoutGuide(contentLayoutGuide)
        contentLayoutGuide.snp.makeConstraints { (make) in
            make.centerY.equalTo(contentView)
            make.left.equalTo(contentView.snp.left).offset(15)
            make.width.equalTo(0)
        }

        topLabel.font = UDFont.systemFont(ofSize: 14)
        addSubview(topLabel)
        topLabel.snp.makeConstraints { (make) in
            make.top.left.equalTo(contentLayoutGuide)
        }

        bottomLabel.font = UDFont.systemFont(ofSize: 17)
        addSubview(bottomLabel)
        bottomLabel.snp.makeConstraints { (make) in
            make.top.equalTo(topLabel.snp.bottom).offset(5)
            make.left.bottom.equalTo(contentLayoutGuide)
        }

        set(selected: selected)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func contentViewDidClick() {
        delegate?.itemViewDidClick(self)
    }

    func set(selected: Bool) {
        self.selected = selected
        if selected {
            topLabel.textColor = UIColor.ud.primaryOnPrimaryFill
            bottomLabel.textColor = UIColor.ud.primaryOnPrimaryFill
            contentView.backgroundColor = UIColor.ud.primaryContentDefault
            triangleView.color = UIColor.ud.primaryContentDefault
        } else {
            topLabel.textColor = UIColor.ud.textPlaceholder
            bottomLabel.textColor = UIColor.ud.textTitle
            contentView.backgroundColor = UIColor.ud.N50
            triangleView.color = UIColor.ud.N50
        }
    }

    func set(title: String) {
        bottomLabel.text = title
    }
}
