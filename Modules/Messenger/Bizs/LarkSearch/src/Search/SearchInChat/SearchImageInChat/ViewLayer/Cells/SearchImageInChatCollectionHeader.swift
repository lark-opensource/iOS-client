//
//  SearchImageInChatCollectionHeader.swift
//  LarkSearch
//
//  Created by zc09v on 2018/9/11.
//

import UIKit
import Foundation

final class SearchImageInChatCollectionHeader: UICollectionReusableView {
    private lazy var label: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.bgBody
        self.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview()
        }
    }

    func set(text: String) {
        self.label.text = text
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
