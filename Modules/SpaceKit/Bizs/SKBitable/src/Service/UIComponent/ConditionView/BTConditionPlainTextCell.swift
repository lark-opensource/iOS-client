//
//  BTConditionPlainTextCell.swift
//  SKBitable
//
//  Created by X-MAN on 2023/4/26.
//

import Foundation
import SKResource
import UniverseDesignColor

final class BTConditionPlainTextCell: UICollectionViewCell {
    
    private lazy var label = UILabel().construct { it in
        it.text = BundleI18n.SKResource.Bitable_BTModule_Equal
        it.font = .systemFont(ofSize: 16)
        it.textColor = UDColor.textTitle
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setUpView()
    }

    private func setUpView() {
        self.backgroundColor = .clear
        self.clipsToBounds = true

        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.centerY.left.right.equalToSuperview()
        }
    }

    func updateText(text: String) {
        label.text = text
    }

    func getCellWidth(height: CGFloat) -> CGFloat {
        let textWidth = label.sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude, height: height)).width
        return textWidth
    }
}
