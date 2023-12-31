//
//  ReactionHeaderView.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/6/8.
//

import UIKit

class ReactionHeaderView: UICollectionReusableView {
    private var currentIcon = ""
    private let contentView = UIView()
    private let iconView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textCaption
        label.font = UIFont.systemFont(ofSize: 12)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(icon: String, title: String) {
        currentIcon = icon
        iconView.isHidden = true
        titleLabel.snp.remakeConstraints { make in
            make.left.equalToSuperview()
            make.top.bottom.right.equalToSuperview()
        }

        if !icon.isEmpty {
            iconView.vc.setEmojiSectionIcon(icon, placeholder: nil, completion: { [weak self] result in
                guard let self = self, case .success = result, self.currentIcon == icon else { return }
                self.iconView.isHidden = false
                self.titleLabel.snp.remakeConstraints { make in
                    make.left.equalTo(self.iconView.snp.right).offset(6)
                    make.top.bottom.right.equalToSuperview()
                }
            })
        }

        titleLabel.attributedText = NSAttributedString(string: title, config: .tinyAssist)
    }

    private func setupSubviews() {
        addSubview(contentView)
        contentView.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(16)
            make.bottom.right.equalToSuperview()
            make.height.equalTo(18)
        }

        contentView.addSubview(iconView)
        iconView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.size.equalTo(16)
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(6)
            make.top.bottom.right.equalToSuperview()
        }
    }
}
