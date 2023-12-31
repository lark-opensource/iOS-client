//
//  NewMedalStackView.swift
//  LarkProfile
//
//  Created by Yuri on 2022/8/26.
//

import UIKit
import Foundation
import ByteWebImage

final class NewMedalStackView: MedalStackView {
    
    override func setConstraints() {
        self.medalStackView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(8)
        }
        
        self.textLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.moreImageView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(3)
            make.right.equalToSuperview().offset(-3)
        }
        
    }

    override func layoutViews() {
        self.titleLabel.snp.remakeConstraints { make in
            if medalStackView.isHidden {
                make.left.equalToSuperview().offset(11)
            } else {
                make.left.equalTo(medalStackView.snp.right).offset(4)
                make.width.lessThanOrEqualTo(82)
            }
            make.top.bottom.equalToSuperview()
        }
        pushView.snp.remakeConstraints { make in
            if self.titleLabel.isHidden {
                make.left.equalTo(self.medalStackView.snp.right)
            } else {
                make.left.equalTo(self.titleLabel.snp.right)
            }
            make.width.height.equalTo(12)
            make.right.equalToSuperview().offset(-6)
            make.centerY.equalToSuperview()
        }
    }
    
    // swiftlint:disable empty_count
    override func setMedals(_ medals: [LarkUserProfilMedal], count: Int) {
        if count == 0, medals.isEmpty {
            self.isHidden = true
        } else {
            self.isHidden = false

            self.titleLabel.isHidden = medals.count != 1
            if let first = medals.first {
                self.titleLabel.text = first.i18NName.getString()
            }
            medalStackView.arrangedSubviews.forEach {
                medalStackView.removeArrangedSubview($0)
                $0.removeFromSuperview()
            }
            sendSubviewToBack(medalStackView)
            
            self.medalStackView.isHidden = false

            for value in medals {
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFit

                var passThrough = ImagePassThrough()
                passThrough.key = value.image.key
                passThrough.fsUnit = value.image.fsUnit

                imageView.bt.setLarkImage(with: .default(key: value.image.key),
                                          passThrough: passThrough)

                self.medalStackView.addArrangedSubview(imageView)
                imageView.snp.makeConstraints { make in
                    make.width.height.equalTo(16)
                    make.centerY.equalToSuperview()
                }
            }

            if count > 3 {
                let textCount = count - 3
                if textCount > 9 {
                    self.textLabel.isHidden = true
                    self.moreImageView.isHidden = false
                } else {
                    self.textLabel.isHidden = false
                    self.moreImageView.isHidden = true
                    self.textLabel.text = "+\(textCount)"
                }

                wrapperView.removeFromSuperview()
                self.medalStackView.addArrangedSubview(wrapperView)

                wrapperView.snp.remakeConstraints { make in
                    make.centerY.equalToSuperview()
                    make.width.height.equalTo(16)
                }
            }
        }

        layoutViews()
    }
}
