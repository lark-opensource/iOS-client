//
//  CameraCell.swift
//  UniverseDesignImageList
//
//  Created by 郭怡然 on 2022/9/22.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignTheme

class CameraCell: UICollectionViewCell {
    static let reuseIdentifier: String = "CameraCell"
    let iconSize: CGFloat = 24
    var backgroudColor: UIColor = UIColor.ud.primaryOnPrimaryFill
    let cameraIcon = UIImageView(image: UDIcon.cameraFilled.withColor(UIColor.ud.iconN3))


    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    func setupSubviews() {
        addSubview(cameraIcon)
    }

    func setupConstraints() {
        cameraIcon.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(iconSize)
        }
    }

    func setupAppearance() {
        self.backgroundColor = backgroundColor
        self.layer.cornerRadius = 8
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.ud.lineBorderCard.cgColor
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupAppearance()
    }
}
