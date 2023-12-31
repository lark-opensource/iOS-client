//
//  BTCardListFooterView.swift
//  SKBitable
//
//  Created by zoujie on 2023/12/1.
//  

import Foundation
import UniverseDesignColor

final class BTCardListFooterView: UICollectionReusableView {
    private lazy var textLabel = UILabel().construct { it in
        it.font = .systemFont(ofSize: 14)
        it.textColor = UDColor.textCaption
        it.numberOfLines = 0
        it.textAlignment = .center
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(textLabel)
        textLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.left.right.equalToSuperview().inset(16)
            make.bottom.lessThanOrEqualToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setText(_ text: String) {
        textLabel.text = text
    }
}
