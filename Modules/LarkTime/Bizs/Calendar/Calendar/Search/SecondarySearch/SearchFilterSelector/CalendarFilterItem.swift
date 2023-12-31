//
//  File.swift
//  CalendarInChat
//
//  Created by zoujiayi on 2019/8/9.
//

import UIKit
import Foundation

public final class CalendarFilterItem: SearchFilterSelectorCellContext {
    private let originalLabelText: String
    private let view = UIView()
    private let label = UILabel()
    private let clickCallBack: () -> Void

    func getView() -> UIView {
        view.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.left.right.equalToSuperview().inset(10)
            make.top.bottom.equalToSuperview().inset(6)
            make.width.lessThanOrEqualTo(self.getMaxWidth())
        }
        label.backgroundColor = UIColor.clear
        label.font = UIFont.cd.regularFont(ofSize: 14)
        view.layer.cornerRadius = 4
        view.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        return view
    }

    func reset() {
        label.text = originalLabelText
        isActive = false
    }

    func getMaxWidth() -> CGFloat {
        return 200
    }

    func setText(_ text: String) {
        label.text = text
    }

    func set(avatars: [Avatar]) {
        // do nothing
        assertionFailure()
    }

    @objc
    private func onClick() {
        clickCallBack()
    }

    var isActive: Bool {
        didSet {
            if isActive {
                label.textColor = UIColor.ud.primaryOnPrimaryFill
                view.backgroundColor = UIColor.ud.primaryContentDefault
                view.layer.borderWidth = 0
            } else {
                label.textColor = UIColor.ud.textTitle
                view.backgroundColor = UIColor.ud.bgBody
                view.layer.borderWidth = 1
            }
        }
    }

    init(originalLabelText: String, clickCallBack: @escaping () -> Void) {
        self.originalLabelText = originalLabelText
        self.clickCallBack = clickCallBack
        self.isActive = false
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onClick))
        label.addGestureRecognizer(tapGesture)
        label.isUserInteractionEnabled = true
        label.text = originalLabelText
    }
}
