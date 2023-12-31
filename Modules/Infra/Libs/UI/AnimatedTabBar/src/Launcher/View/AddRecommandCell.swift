//
//  AddRecommandCell.swift
//  AnimatedTabBar
//
//  Created by phoenix on 2023/11/2.
//

import UIKit
import UniverseDesignIcon
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignTheme

final class AddRecommandCell: UICollectionViewCell {

    private lazy var addRecommandView: AddRecommandView = {
        let addView = AddRecommandView(frame: .zero)
        return addView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.addSubview(addRecommandView)
        addRecommandView.snp.makeConstraints { make in
            make.leading.top.trailing.equalToSuperview()
            make.height.equalTo(44)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(event: (() -> Void)? = nil) {
        self.addRecommandView.addEvent = event
    }
}
