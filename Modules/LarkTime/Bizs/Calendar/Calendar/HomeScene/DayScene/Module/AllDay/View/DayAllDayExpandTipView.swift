//
//  DayAllDayExpandTipView.swift
//  Calendar
//
//  Created by 张威 on 2020/8/25.
//

import UIKit
import LarkExtensions

/// DayScene - AllDay - TipView

final class DayAllDayExpandTipView: UIView {

    var onClick: (() -> Void)?

    var title: String? {
        didSet { titleLabel.text = title }
    }

    private let titleLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)

        titleLabel.font = UIFont.systemFont(ofSize: 12)
        titleLabel.textColor = UIColor.ud.textPlaceholder
        addSubview(titleLabel)

        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleClick)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.frame = bounds
    }

    @objc
    private func handleClick() {
        onClick?()
    }

}
