//
//  IMMentionErrorView.swift
//  LarkIMMention
//
//  Created by ByteDance on 2022/8/9.
//

import UIKit
import Foundation

class IMMentionErrorView: UIView {
    
    private var label = UILabel()
    var errorString: String? {
        didSet {
            label.text = errorString
        }
    }
    init() {
        super.init(frame: .zero)
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 16)
        label.numberOfLines = 2
        label.text = BundleI18n.LarkIMMention.Lark_IM_SearchForMembersOrDocs_NoResultsFoundTryAnotherWord_Text
        addSubview(label)
        label.snp.makeConstraints {
            $0.top.equalToSuperview().offset(80)
            $0.centerX.equalToSuperview()
            $0.left.greaterThanOrEqualToSuperview().offset(16)
            $0.right.lessThanOrEqualToSuperview().inset(16)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
