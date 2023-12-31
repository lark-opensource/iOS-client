//
//  LKAssetsCollectionHeader.swift
//  LarkAssetsBrowser
//
//  Created by 王元洵 on 2021/5/25.
//

import Foundation
import UIKit

final class LKAssetsCollectionHeader: UICollectionReusableView {
    private let label: UILabel = {
        let label = UILabel(frame: .zero)
        label.font = UIFont.ud.body2(.fixed)
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
