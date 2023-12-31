//
//  AtSettingItemView.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2021/10/12.
//

import UIKit
import Foundation
import UniverseDesignCheckBox

final class AtSettingItemView: UIView {
    private let checkBox = UDCheckBox(boxType: .multiple)
    private let label = UILabel()
    private let bottomLineView = UIView()

    var selectedCallback: (() -> Void)?

    private var model: AtSettingItemModel?

    init() {
        super.init(frame: .zero)
        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        self.backgroundColor = UIColor.ud.bgBody

        self.addSubview(checkBox)
        checkBox.isUserInteractionEnabled = false
        checkBox.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(14)
            make.bottom.equalToSuperview().offset(-14)
            make.size.equalTo(20)
        }

        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.leading.equalTo(checkBox.snp.trailing).offset(12)
            make.centerY.trailing.equalToSuperview()
        }

        bottomLineView.backgroundColor = UIColor.ud.lineDividerDefault
        self.addSubview(bottomLineView)
        setBottomLineShowState(true)
        let lineHeight = 1 / UIScreen.main.scale
        bottomLineView.snp.makeConstraints { (make) in
            make.bottom.trailing.equalToSuperview()
            make.leading.equalToSuperview().offset(30)
            make.height.equalTo(lineHeight)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
    }

    @objc
    private func tapped() {
        selectedCallback?()
    }

    func setModel(_ model: AtSettingItemModel) {
        self.model = model
        self.label.text = model.title
        self.checkBox.isEnabled = model.isEnabled
        self.checkBox.isSelected = model.selected
    }

    func setBottomLineShowState(_ show: Bool) {
        self.bottomLineView.isHidden = !show
    }
}
