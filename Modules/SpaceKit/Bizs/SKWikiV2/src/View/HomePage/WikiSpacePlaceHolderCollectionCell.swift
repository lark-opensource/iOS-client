//
//  WikiSpacePlaceHolderCollectionCell.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2019/10/30.
//  

import UIKit
import UniverseDesignColor

class WikiSpacePlaceHolderCollectionCell: UICollectionViewCell {

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        docs.addStandardLift()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        docs.addStandardLift()
    }

    private func setupUI() {
        contentView.backgroundColor = UIColor.ud.N50
        contentView.layer.ud.setBorderColor(UDColor.lineDividerDefault)
        contentView.layer.borderWidth = 1
        contentView.layer.cornerRadius = 8
        contentView.clipsToBounds = true

        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 10
        layer.ud.setShadowColor(UDColor.shadowDefaultLg)
        layer.shadowOpacity = 1
    }

    var shouldShowShadow: Bool = true {
        didSet {
            guard oldValue != shouldShowShadow else { return }
            layer.shadowOpacity = shouldShowShadow ? 1 : 0
        }
    }
}
