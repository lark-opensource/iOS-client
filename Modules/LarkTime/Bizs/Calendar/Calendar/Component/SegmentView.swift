//
//  SegmentView.swift
//  Calendar
//
//  Created by zc on 2018/6/22.
//  Copyright © 2018年 EE. All rights reserved.
//

import UIKit
import Foundation
import CalendarFoundation
import SnapKit

final class SegmentView: UIControl {
    private let itemCount: Int
    init(items: [String]) {
        self.itemCount = items.count
        let defaultHeight: CGFloat = 40.0
        // 外部使用 autolayout 布局 无需此处提供宽度
        super.init(frame: CGRect(x: 0, y: 0, width: 0, height: defaultHeight))
        let count = items.count
        for i in 0..<count {
            let button = self.button(with: items[i])
            self.addSubview(button)
            button.snp.makeConstraints { (make) in
                make.height.equalToSuperview()
                make.top.equalToSuperview()
                make.width.equalToSuperview().multipliedBy(1.0 / Float(count))
                make.centerX.equalToSuperview().multipliedBy((1.0 + Float(i) * 2.0) / Float(count) )
            }
            button.tag = i
            button.isSelected = i == 0
        }
        self.addBottomBorder(lineHeight: 1.0)
        self.backgroundColor = UIColor.ud.bgBody
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var selectedIndex: Int {
        return self.selectedButton()?.tag ?? 0
    }

    func updateSlidingProgress(_ progress: CGFloat) {
        let width = self.bounds.size.width
        let itemWidth = width / CGFloat(self.itemCount)
        assertLog(width > 0)
        var center: CGPoint = .zero
        center.y = self.bounds.height - (self.slidingView.bounds.height) / 2.0
        center.x = itemWidth / 2.0 + (width - itemWidth) * progress
        self.slidingView.center = center
    }

    func setSelectedIndex(_ index: Int, animated: Bool) {
        if index == self.selectedIndex { return }
        self.selectedButton()?.isSelected = false
        guard let desButton = self.buttons().first(where: { $0.tag == index }) else {
            assertionFailureLog()
            return
        }
        desButton.isSelected = true
    }

    lazy var slidingView: UIView = {
        let sliding = UIView(frame: CGRect(x: 0, y: self.bounds.height - 2, width: self.bounds.width / CGFloat(self.itemCount), height: 2))
        self.addSubview(sliding)
        sliding.backgroundColor = UIColor.ud.primaryContentDefault
        sliding.autoresizingMask = [.flexibleTopMargin]
        return sliding
    }()

    private func buttons() -> [UIButton] {
        return self.subviews.compactMap({ $0 as? UIButton })
    }

    private func selectedButton() -> UIButton? {
        return self.buttons().first(where: { $0.isSelected })
    }

    private func button(with title: String) -> UIButton {
        let button = UIButton.cd.button(type: .custom)
        button.setTitle(title, for: .normal)
        button.setTitle(title, for: .selected)
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: .selected)
        button.setTitleColor(UIColor.ud.N600, for: .normal)
        button.titleLabel?.font = UIFont.cd.mediumFont(ofSize: 14)
        button.addTarget(self, action: #selector(buttonAction(sender:)), for: .allTouchEvents)
        button.adjustsImageWhenHighlighted = false
        return button
    }

    @objc
    private func buttonAction(sender: UIButton) {
        sender.isHighlighted = false
        if sender.tag == self.selectedIndex { return }
        self.setSelectedIndex(sender.tag, animated: true)
        self.sendActions(for: .valueChanged)
    }
}
