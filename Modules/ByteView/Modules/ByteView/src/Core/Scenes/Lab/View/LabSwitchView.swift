//
//  LabSwitchView.swift
//  ByteView
//
//  Created by ZhangJi on 2022/4/29.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignSwitch

class LabSwitchViewModel: NSObject {
    let title: String
    let isDefaultOn: Bool
    let isSwitchEnabled: Bool
    let switchAction: (Bool) -> Void

    init(title: String,
         isDefaultOn: Bool = false,
         isSwitchEnabled: Bool = true,
         switchAction: @escaping (Bool) -> Void) {
        self.title = title
        self.isDefaultOn = isDefaultOn
        self.isSwitchEnabled = isSwitchEnabled
        self.switchAction = switchAction
    }

}

class LabSwitchView: UIView {
    private var model: LabSwitchViewModel

    var isOn: Bool {
        return self.switchView.isOn
    }

    private lazy var switchView: UDSwitch = {
        let switchView = UDSwitch()
        return switchView
    }()

    private lazy var titleLabe: UILabel = {
        let label = UILabel()
        label.lineBreakMode = .byTruncatingTail
        label.font = .systemFont(ofSize: 16)
        label.textColor = UIColor.ud.textTitle
        label.numberOfLines = 1
        label.textAlignment = .left
        return label
    }()

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    init(frame: CGRect, model: LabSwitchViewModel) {
        self.model = model
        super.init(frame: frame)
        setupViews()
        config(with: model)
    }

    func updateTitleColor(isLandscapeMode: Bool) {
        let shadow = NSShadow()
        shadow.shadowColor = UIColor.ud.staticBlack.withAlphaComponent(0.5)
        shadow.shadowOffset = CGSize(width: 0, height: 0.5)
        shadow.shadowBlurRadius = 2

        if isLandscapeMode {
            titleLabe.attributedText = NSAttributedString(string: model.title, attributes: [.shadow: shadow, .font: UIFont.systemFont(ofSize: 16), .foregroundColor: UIColor.ud.primaryOnPrimaryFill])
        } else {
            titleLabe.attributedText = NSAttributedString(string: model.title, attributes: [.font: UIFont.systemFont(ofSize: 16), .foregroundColor: UIColor.ud.textTitle])
        }
    }

    private func config(with model: LabSwitchViewModel) {
        titleLabe.text = model.title
        switchView.setOn(model.isDefaultOn, animated: false)
        switchView.valueChanged = model.switchAction
    }

    private func setupViews() {
        self.addSubview(titleLabe)
        self.addSubview(switchView)

        switchView.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 48, height: 28))
            make.right.equalToSuperview().inset(Display.pad ? 28 : 16)
        }

        titleLabe.snp.remakeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().inset(Display.pad ? 28 : 16)
        }
    }

    func layoutForLandscape(isLandscape: Bool) {
        if isLandscape {
            titleLabe.textAlignment = .right
            titleLabe.snp.remakeConstraints { make in
                make.left.greaterThanOrEqualTo(self)
                make.centerY.equalToSuperview()
                make.right.equalTo(self.switchView.snp.left).offset(-12)
            }
        } else {
            titleLabe.textAlignment = .left
            titleLabe.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.left.equalToSuperview().inset(Display.pad ? 28 : 16)
            }
        }
    }
}
