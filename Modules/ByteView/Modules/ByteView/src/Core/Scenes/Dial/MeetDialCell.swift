//
//  MeetDialCell.swift
//  ByteView
//
//  Created by wangpeiran on 2021/7/14.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RxSwift
import RxCocoa
import UniverseDesignColor

class MeetDialCell: UICollectionViewCell {
    struct Layout {
        static let cellWidth: CGFloat = 72
    }

    lazy var button: UIButton = {
        let button = UIButton(type: .custom)
        button.layer.cornerRadius = Layout.cellWidth / 2
        button.layer.masksToBounds = true
        button.titleLabel?.font = UIFont.systemFont(ofSize: 30, weight: .semibold)
        button.setTitleColor(UIColor.ud.textTitle, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.bgFloatOverlay, for: .normal)
        button.vc.setBackgroundColor(UIColor.ud.udtokenTagNeutralBgNormalPressed, for: .highlighted)
        button.addTarget(self, action: #selector(tapAction), for: .touchUpInside)
        return button
    }()

    var model: (String, CGFloat, UIEdgeInsets?)?

    var tapBlock: ((String) -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(button)
        button.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func bindData(model: (String, CGFloat, UIEdgeInsets?)) {
        self.model = model
        button.setTitle(model.0, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: model.1, weight: .semibold)

        if let titleEdgeInsets = model.2 {
            button.titleEdgeInsets = titleEdgeInsets
        }
    }

    @objc
    private func tapAction() {
        if let number = self.model?.0 {
            self.tapBlock?(number)
        }
    }
}
