//
//  DetailEmptyView.swift
//  Todo
//
//  Created by baiyantao on 2022/9/21.
//

import Foundation
import UniverseDesignFont

final class DetailEmptyView: UIView {

    var text: String? {
        didSet {
            titleLabel.text = text
        }
    }

    var onTapHandler: (() -> Void)?

    private(set) lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.numberOfLines = 2
        label.font = UDFont.systemFont(ofSize: 14)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.left.bottom.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func onTap() {
        onTapHandler?()
    }

}
