//
//  OncallViewCollectionCell.swift
//  LarkContact
//
//  Created by 姚启灏 on 2018/11/11.
//

import UIKit
import Foundation
import LarkModel
import LarkUIKit
import LarkTag
import LarkSDKInterface

protocol OnCallTagDelegate: AnyObject {
    func select(tagId: String)
}

final class OnCallTagView: UIView {
    weak var delegate: OnCallTagDelegate?

    var onCallTag = OnCallTag()

    lazy var label: PaddingUILabel = {
        let label = PaddingUILabel()
        label.textColor = UIColor.ud.N600
        label.color = UIColor.ud.N600.withAlphaComponent(0.14)
        label.textAlignment = .center
        label.layer.cornerRadius = 14
        label.layer.masksToBounds = true
        label.paddingLeft = 12
        label.paddingRight = 12
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        self.addSubview(label)
        self.lu.addTapGestureRecognizer(action: #selector(selectCell))
        label.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    @objc
    func selectCell() {
        self.delegate?.select(tagId: self.onCallTag.id)
        self.label.textColor = UIColor.ud.primaryOnPrimaryFill
        self.label.color = UIColor.ud.colorfulBlue
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        label.sizeToFit()
        return label.bounds.size
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setContent(onCallTag: OnCallTag, delegate: OnCallTagDelegate?) {
        label.text = onCallTag.name
        self.onCallTag = onCallTag
        self.delegate = delegate
    }

    func clearStatus() {
        self.label.textColor = UIColor.ud.N600
        self.label.color = UIColor.ud.N600.withAlphaComponent(0.14)
    }
}
