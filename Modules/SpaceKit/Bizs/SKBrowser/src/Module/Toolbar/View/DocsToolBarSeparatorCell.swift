//
//  DocsToolBarSeparatorCell.swift
//  DocsSDK
//
//  Created by Gill on 2020/6/7.
//

import UIKit
import SnapKit

class DocsToolBarSeparatorCell: UICollectionViewCell {
    private(set) lazy var separator: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.N300
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(separator)
        separator.snp.makeConstraints { (make) in
            make.center.equalToSuperview()
            make.height.equalTo(24)
            make.width.equalTo(1)
        }
    }

    func set(orientation: ToolbarOrientation) {
        if orientation == .vertical {
            separator.snp.remakeConstraints { (make) in
                make.center.equalToSuperview()
                make.height.equalTo(24)
                make.width.equalTo(1)
            }
        } else {
            separator.snp.remakeConstraints { (make) in
                make.center.width.equalToSuperview()
                make.width.equalToSuperview()
                make.height.equalTo(0.5)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
