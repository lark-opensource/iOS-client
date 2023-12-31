//
//  SceneDetailScetionHeader.swift
//  LarkAI
//
//  Created by Zigeng on 2023/10/8.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignColor

class SceneDetailScetionHeader: UIView {
    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = .ud.textCaption
        label.font = .systemFont(ofSize: 14)
        return label
    }()

    private lazy var asterisk: UILabel = {
        let label = UILabel()
        label.text = "*"
        label.textColor = .ud.functionDanger500
        return label
    }()

    init() {
        super.init(frame: .zero)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(4)
            make.top.equalToSuperview().offset(20)
        }
        addSubview(asterisk)
        asterisk.snp.makeConstraints { make in
            make.left.equalTo(titleLabel.snp.right)
            make.top.equalToSuperview().offset(20)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setHeader(text: String, isRequired: Bool) {
        titleLabel.text = text
        asterisk.isHidden = !isRequired
    }
}
