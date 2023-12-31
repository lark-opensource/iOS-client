//
//  MeetingInterpretationView.swift
//  ByteView
//
//  Created by Tobb Huang on 2020/10/28.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import SnapKit

class MeetingStatusView: BaseInMeetStatusView {

    struct Layout {
        static let normalSpacing: CGFloat = 2.0
        static let shrinkSpacing: CGFloat = 2.0
    }

    let languageImageView: UIImageView = {
        var imageView = UIImageView()
        return imageView
    }()

    let languageLabel: UILabel = {
        var label = UILabel()
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 10)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        addSubview(languageImageView)
        addSubview(languageLabel)
        updateLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func updateLayout() {
        if shouldHiddenForOmit {
            languageLabel.isHidden = true
            languageImageView.snp.remakeConstraints { (maker) in
                maker.size.equalTo(12)
                maker.edges.equalToSuperview()
            }
        } else {
            languageLabel.isHidden = false
            languageImageView.snp.remakeConstraints { (maker) in
                maker.size.equalTo(12)
                maker.centerY.equalToSuperview()
                maker.left.equalToSuperview()
            }
            languageLabel.snp.remakeConstraints { (maker) in
                maker.centerY.equalToSuperview()
                maker.left.equalTo(languageImageView.snp.right).offset(Layout.normalSpacing)
                maker.right.equalToSuperview()
            }
        }
    }

    func setLabel(_ text: String) {
        languageLabel.text = text
    }

    func setIcon(_ icon: UIImage?) {
        guard let image = icon else { return }
        languageImageView.image = image
    }

    func hidden(isHidden: Bool) {
        languageImageView.isHidden = isHidden
        languageLabel.isHidden = isHidden
    }
}
