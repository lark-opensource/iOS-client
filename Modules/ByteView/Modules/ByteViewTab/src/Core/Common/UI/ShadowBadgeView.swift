//
//  ShadowBadgeView.swift
//  ByteViewTab
//
//  Created by fakegourmet on 2022/6/9.
//

import Foundation
import UIKit

class ShadowBadgeView: UIView {

    var showLabel: Bool = false {
        didSet {
            descLabel.isHidden = !showLabel
        }
    }

    var showIcon: Bool = true {
        didSet {
            iconView.isHidden = !showIcon
        }
    }

    var text: String = "" {
        didSet {
            descLabel.attributedText = .init(string: text,
                                             config: .tiniestAssist,
                                             alignment: .center,
                                             textColor: UIColor.ud.primaryOnPrimaryFill)
        }
    }

    var iconView = UIImageView()
    private var descLabel = UILabel()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [iconView, descLabel])
        stackView.axis = .horizontal
        stackView.spacing = 2.0
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupSubviews() {
        backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.3)
        layer.cornerRadius = 4.0
        clipsToBounds = true

        descLabel.isHidden = true

        addSubview(stackView)

        stackView.snp.makeConstraints {
            $0.center.equalToSuperview()
            $0.edges.equalToSuperview().inset(2.0)
        }

        iconView.snp.makeConstraints {
            $0.width.height.equalTo(12.0)
        }
    }

}
