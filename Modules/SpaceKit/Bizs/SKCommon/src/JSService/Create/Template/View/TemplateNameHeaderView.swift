//
//  TemplateNameHeaderView.swift
//  SKCommon
//
//  Created by 邱沛 on 2020/9/17.
//

import UIKit
import SKUIKit
import SKFoundation
import UniverseDesignColor

class TemplateNameHeaderView: UICollectionReusableView {
    static let cellID = "TemplateNameHeaderView"
    static let suggestHeight: CGFloat = 40
    let tipLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(tipLabel)
        tipLabel.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.bottom.equalToSuperview().inset(12)
            make.height.equalTo(20)
            make.right.equalToSuperview().inset(16)
        }
        tipLabel.font = .systemFont(ofSize: 16, weight: .medium)
        tipLabel.textColor = UDColor.textTitle
        self.backgroundColor = UDColor.bgBody
    }

    func updateLabelLeftOffest(offest: CGFloat) {
        guard self.superview != nil else { return }
        tipLabel.snp.updateConstraints { (make) in
            make.left.equalTo(offest)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
