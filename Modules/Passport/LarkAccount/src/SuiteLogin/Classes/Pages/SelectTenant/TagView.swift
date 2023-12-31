//
//  TagView.swift
//  LarkAccount
//
//  Created by Nix Wang on 2022/7/28.
//

import Foundation
import UIKit
import UniverseDesignColor

class TagView: UIView {
    enum Style {
        case green
    }

    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 4
        stackView.alignment = .center
        return stackView
    }()
    let iconView = UIImageView()
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        return label
    }()

    init(icon: UIImage?, title: String?, style: TagView.Style = .green) {
        assert(icon != nil || title != nil)

        if let icon = icon {
            iconView.image = icon
            stackView.addArrangedSubview(iconView)
        }

        if let title = title {
            titleLabel.text = title
            stackView.addArrangedSubview(titleLabel)
        }

        super.init(frame: .zero)

        addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.height.equalTo(18)
            make.edges.equalToSuperview().inset(UIEdgeInsets(horizontal: 4, vertical: 0))
        }

        layer.cornerRadius = 4
        layer.masksToBounds = true
        if style == .green {
            backgroundColor = UIColor.ud.udtokenTagBgGreen
            titleLabel.textColor = UIColor.ud.udtokenTagTextSGreen
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
