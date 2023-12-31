//
//  PrelobbyHeaderView.swift
//  ByteView
//
//  Created by kiri on 2022/5/21.
//

import Foundation
import UIKit
import Lottie

/// 会前等候室头部区域，title | loading
final class PrelobbyHeaderView: PreviewChildView {

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.attributedText = NSAttributedString(string: I18n.View_G_WaitForOrganizer, config: .h1, alignment: .center, lineBreakMode: .byTruncatingTail, textColor: UIColor.ud.textTitle)
        label.numberOfLines = 0
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
