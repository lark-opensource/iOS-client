//
//  SelectMoreCell.swift
//  LarkAssetsBrowser
//
//  Created by xiongmin on 2021/6/16.
//

import UIKit
import Foundation

final class SelectMoreCell: UICollectionViewCell {

    static let identifier = "kSelectMoreCellIdentifier"

    private lazy var addImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = Resources.add_icon
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.ud.N200
        addSubview(addImageView)
        addImageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
