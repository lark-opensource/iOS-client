//
//  DetailCell.swift
//  Calendar
//
//  Created by zhu chao on 2018/11/6.
//  Copyright © 2018 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation

class DetailCell: UIView {
    private let leadingIcon = UIImageView()

    private let customView = UIView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.layoutLeadingIcon(leadingIcon)
        self.layoutCustomView(customView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setLeadingIcon(_ icon: UIImage?) {
        leadingIcon.image = icon
    }

    func addCustomView(_ view: UIView, edgeInset: UIEdgeInsets = .zero) {
        customView.addSubview(view)
        view.snp.makeConstraints { (make) in
            make.edges.equalToSuperview().inset(edgeInset)
        }
    }

    private func layoutLeadingIcon(_ icon: UIImageView) {
        self.addSubview(icon)
        icon.contentMode = .scaleAspectFit
        icon.snp.makeConstraints { (make) in
            make.centerY.equalTo(16 + 5)
            make.centerX.equalTo(16 + 8)
            make.width.height.equalTo(16)
        }
    }

    private func layoutCustomView(_ view: UIView) {
        self.addSubview(view)
        // 上下 padding 各 10
        view.snp.makeConstraints { (make) in
            make.top.equalToSuperview().offset(10)
            make.left.equalToSuperview().offset(48)
            make.bottom.equalToSuperview().offset(-10).priority(.medium)
            make.right.equalToSuperview().offset(-16)
        }
    }

    static func normalTextLabel() -> UILabel {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.ud.body0(.fixed)
        return label
    }
}

class DetailSingleLineCell: UIView {
    private let leadingIcon = UIImageView()

    let label = DetailCell.normalTextLabel()

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 42))  // 内容 22， 上下 10+10
        self.layoutLeadingIcon(leadingIcon)
        self.layoutLabel(label)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setLeadingIcon(_ icon: UIImage?) {
        leadingIcon.image = icon
    }

    func layoutLabel(_ label: UILabel) {
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(48)
            make.right.lessThanOrEqualToSuperview().offset(-16)
        }
    }

    func setText(_ text: String) {
        label.text = text
    }

    private func layoutLeadingIcon(_ icon: UIImageView) {
        self.addSubview(icon)
        icon.contentMode = .scaleAspectFit
        icon.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
            make.width.height.equalTo(16)
        }
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = 42.0
        return size
    }
}
