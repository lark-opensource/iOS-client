//
//  TopAlignView.swift
//  Calendar
//
//  Created by zhuchao on 2019/3/26.
//

import UIKit
import Foundation
import CalendarFoundation

final class TopAlignView: UIView {
    let label = UILabel.cd.textLabel()
    let tailingWrapperView = UIView()
    init(tailingView: UIView, spacing: CGFloat = 6.0, topOffset: CGFloat = 4.0) {
        // 外部 autolayout 布局 frame 无意义
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: 40))
        layout(label: label,
               tailingWrapper: tailingWrapperView,
               tailingView: tailingView,
               spacing: spacing,
               topOffset: topOffset)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func layout(label: UILabel,
                        tailingWrapper: UIView,
                        tailingView: UIView,
                        spacing: CGFloat,
                        topOffset: CGFloat) {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .top
        stackView.spacing = spacing
        self.addSubview(stackView)
        stackView.snp.makeConstraints { (make) in
            make.top.left.bottom.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        label.setContentCompressionResistancePriority(.required - 1, for: .horizontal)
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(tailingWrapper)

        tailingWrapper.addSubview(tailingView)
        tailingView.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        tailingView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalToSuperview().offset(topOffset)
        }
    }

    func showTailingView(_ isShow: Bool) {
        tailingWrapperView.isHidden = !isShow
    }
}
