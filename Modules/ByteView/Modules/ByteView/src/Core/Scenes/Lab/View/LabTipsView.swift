//
//  LabTipsView.swift
//  ByteView
//
//  Created by Tobb Huang on 2020/12/2.
//  Copyright © 2020 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon

class LabTipsView: UIView {

    private let tipsText: String
    private let tipsStyle: VCFontConfig = VCFontConfig.tinyAssist

    lazy var tipsLabel: UILabel = {
        var label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 10)
        return label
    }()

    init(frame: CGRect, tipsText: String) {
        self.tipsText = tipsText
        super.init(frame: frame)
        self.tipsLabel.text = tipsText
        setupViews()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        addSubview(tipsLabel)
        tipsLabel.snp.makeConstraints { maker in
            maker.top.left.right.equalToSuperview()
            maker.bottom.lessThanOrEqualToSuperview()
        }
    }
}
