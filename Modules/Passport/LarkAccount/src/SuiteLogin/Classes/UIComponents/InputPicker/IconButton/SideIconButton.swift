//
//  SideIconButton.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2019/9/22.
//

import UIKit

class SideIconButton: UIControl {
    struct Layout {
        static let space: CGFloat = 4.0
        static let arrowWidth: CGFloat = 7.0
        static let imageSize: CGFloat = 15.0
        static let fontSize: CGFloat = 16.0
    }

    private let titleLabel: UILabel

    init(leftIcon: UIImage, title: String, rightIcon: UIImage) {
        self.titleLabel = UILabel(frame: .zero)
        super.init(frame: .zero)
        let leftIconImageView = UIImageView(image: leftIcon)
        leftIconImageView.contentMode = .scaleAspectFit

        titleLabel.text = title
        titleLabel.textColor = UIColor.ud.textCaption
        titleLabel.font = UIFont.systemFont(ofSize: Layout.fontSize)

        let rightIconImageView = UIImageView(image: rightIcon)
        rightIconImageView.contentMode = .scaleAspectFit

        addSubview(leftIconImageView)
        addSubview(titleLabel)
        addSubview(rightIconImageView)

        leftIconImageView.snp.makeConstraints { (make) in
            make.left.centerY.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.width.equalTo(Layout.imageSize)
        }

        titleLabel.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.top.bottom.equalToSuperview()
            make.left.equalTo(leftIconImageView.snp.right).offset(Layout.space)
        }

        rightIconImageView.snp.makeConstraints { (make) in
            make.right.centerY.equalToSuperview()
            make.width.equalTo(Layout.arrowWidth)
            make.top.bottom.equalToSuperview()
            make.left.equalTo(titleLabel.snp.right).offset(Layout.space)
        }
    }

    func setTitle(_ title: String) {
        titleLabel.text = title
    }

    func resetFont() {
        titleLabel.font = UIFont.systemFont(ofSize: Layout.fontSize)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
