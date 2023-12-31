//
//  EmotionShopDetailCollectionCell.swift
//  LarkMessageCore
//
//  Created by huangjianming on 2019/8/21.
//

import Foundation
import UIKit
import SnapKit

final class EmotionShopDetailCollectionCell: UICollectionViewCell {
    public lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    required override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        self.contentView.addSubview(self.imageView)
        self.imageView.snp.makeConstraints { (make) in
            make.left.right.bottom.top.equalToSuperview()
        }
    }
}
