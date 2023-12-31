//
//  SpaceVerticalGridEmptyTipsCell.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/21.
//

import UIKit
import SnapKit
import UniverseDesignColor
import SKResource

class SpaceVerticalGridEmptyTipsCell: UICollectionViewCell {

    private lazy var tipLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UDColor.textPlaceholder
        label.text = BundleI18n.SKResource.Doc_List_Pin_Empty_Tips
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        contentView.addSubview(tipLabel)
        tipLabel.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.centerY.equalToSuperview()
        }
    }

    func update(placeHolder: String) {
        tipLabel.text = placeHolder
    }
}
