//
// Created by duanxiaochen.7 on 2021/7/15.
// Affiliated with SKBitable.
//
// Description:

import Foundation
import UIKit
import UniverseDesignFont
import UniverseDesignColor

final class BTTableTitleView: UIView {

    lazy var titleLabel = UILabel().construct { it in
        it.font = .systemFont(ofSize: 17, weight: .medium)
        it.textAlignment = .center
        it.textColor = UDColor.textTitle
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = UDColor.bgBody
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide.snp.top)
            make.height.equalTo(44)
            make.left.right.bottom.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setTitle(_ text: String) {
        titleLabel.text = text
    }
}
