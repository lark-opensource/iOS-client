//
//  QuickTabBarEmptyView.swift
//  AnimatedTabBar
//
//  Created by bytedance on 2020/12/3.
//

import Foundation
import UIKit
import UniverseDesignEmpty

final class QuickTabBarEmptyView: UIView {

    private enum Cons {
        static var imageSize: CGSize { CGSize(width: 120, height: 120) }
        static var textFont: UIFont { .systemFont(ofSize: 14) }
        static var ImageTextSpacing: CGFloat { 16 }
    }

    private lazy var container = UIView()

    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.image = UDEmptyType.imAddApplication.defaultImage()
        view.backgroundColor = .clear
        return view
    }()

    private lazy var textLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.AnimatedTabBar.Lark_Legacy_Navigation
        label.font = Cons.textFont
        label.textColor = UIColor.ud.textPlaceholder
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
    }

    private func setupSubviews() {
        container.backgroundColor = .clear
        addSubview(container)
        container.addSubview(imageView)
        container.addSubview(textLabel)
    }

    private func setupConstraints() {
        container.snp.makeConstraints { (make) in
            make.width.lessThanOrEqualToSuperview()
            make.center.equalToSuperview()
        }
        imageView.snp.makeConstraints { (make) in
            make.size.equalTo(Cons.imageSize)
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        textLabel.snp.makeConstraints { (make) in
            make.top.equalTo(imageView.snp.bottom).offset(Cons.ImageTextSpacing)
            make.bottom.equalToSuperview()
            make.leading.equalToSuperview().offset(10)
            make.trailing.equalToSuperview().offset(-10)
        }
    }
}
