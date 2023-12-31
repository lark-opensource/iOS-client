//
//  MessageVisibleView.swift
//  LarkTeam
//
//  Created by xiaruzhen on 2023/2/15.
//

import UIKit
import Foundation
import LarkUIKit

final class MessageVisibleView: UIView {
    private let titleLabel = UILabel()
    private let descLabel = UILabel()
    private let chooseImageView = UIImageView()
    private let bottomLineView = UIView()

    var selectedCallback: (() -> Void)?

    init() {
        super.init(frame: .zero)
        self.setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        self.backgroundColor = UIColor.ud.bgBody

        self.addSubview(titleLabel)
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.top.equalToSuperview().offset(16)
        }

        self.addSubview(descLabel)
        descLabel.textColor = UIColor.ud.textPlaceholder
        descLabel.font = UIFont.systemFont(ofSize: 14)
        descLabel.snp.makeConstraints { (make) in
            make.leading.equalToSuperview().offset(16)
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.bottom.equalToSuperview().offset(-16)
        }

        chooseImageView.image = Resources.checkmark
        self.addSubview(chooseImageView)
        chooseImageView.snp.makeConstraints { (make) in
            make.trailing.equalToSuperview().offset(-16)
            make.centerY.equalToSuperview()
        }

        bottomLineView.backgroundColor = UIColor.ud.lineDividerDefault
        self.addSubview(bottomLineView)
        setBottomLineShowState(true)
        let lineHeight = 1 / UIScreen.main.scale
        bottomLineView.snp.makeConstraints { (make) in
            make.bottom.trailing.equalToSuperview()
            make.leading.equalTo(titleLabel)
            make.height.equalTo(lineHeight)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        addGestureRecognizer(tap)
    }

    func setTitle(_ text: String) {
        self.titleLabel.text = text
    }

    func setDesc(_ text: String) {
        self.descLabel.text = text
    }

    func setSelectedState(_ selected: Bool) {
        self.chooseImageView.isHidden = !selected
    }

    func setUnavailableState(_ available: Bool) {
        self.titleLabel.textColor = available ? UIColor.ud.textTitle : UIColor.ud.textDisabled
        self.descLabel.textColor = available ? UIColor.ud.textPlaceholder : UIColor.ud.textDisabled
    }

    func setBottomLineShowState(_ show: Bool) {
        self.bottomLineView.isHidden = !show
    }

    @objc
    private func tapped() {
        selectedCallback?()
    }
}
