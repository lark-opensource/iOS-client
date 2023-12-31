//
//  MedalStackView.swift
//  LarkProfile
//
//  Created by 姚启灏 on 2021/9/15.
//

import Foundation
import UniverseDesignIcon
import ByteWebImage
import UIKit
import LarkAttachmentUploader

public class MedalStackView: UIView {

    public var tapCallback: (() -> Void)?

    lazy var medalStackView: UIStackView = {
        let medalStackView = UIStackView()
        medalStackView.spacing = 4
        medalStackView.axis = .horizontal
        medalStackView.alignment = .center
        return medalStackView
    }()

    lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.ud.primaryOnPrimaryFill
        titleLabel.font = UIFont.systemFont(ofSize: 14)
        titleLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentHuggingPriority(.required, for: .horizontal)
        return titleLabel
    }()

    lazy var textLabel: UILabel = {
        let textLabel = UILabel()
        textLabel.textAlignment = .center
        textLabel.textColor = UIColor.ud.iconN2
        textLabel.font = UIFont.systemFont(ofSize: 10)
        textLabel.backgroundColor = UIColor.ud.bgBodyOverlay
        textLabel.layer.cornerRadius = 8
        textLabel.layer.masksToBounds = true
        textLabel.clipsToBounds = true
        return textLabel
    }()

    lazy var moreImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    lazy var wrapperView: UIView = {
        let wrapperView = UIView()
        wrapperView.backgroundColor = UIColor.ud.bgBodyOverlay
        wrapperView.layer.cornerRadius = 8
        wrapperView.layer.masksToBounds = true
        wrapperView.clipsToBounds = true
        return wrapperView
    }()

    lazy var pushView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()

    private var medalTapGesture: UITapGestureRecognizer?

    public override init(frame: CGRect) {
        super.init(frame: frame)

        self.backgroundColor = UIColor.ud.rgb(0x2B2F36).withAlphaComponent(0.5)
        self.isUserInteractionEnabled = true

        let medalTapGesture = UITapGestureRecognizer(target: self, action: #selector(medalViewTapped))
        self.medalTapGesture = medalTapGesture
        self.addGestureRecognizer(medalTapGesture)

        self.addSubview(medalStackView)
        self.addSubview(titleLabel)
        self.addSubview(pushView)

        wrapperView.addSubview(textLabel)
        wrapperView.addSubview(moreImageView)
        setConstraints()
        layoutViews()
    }

    public required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func layoutViews() {

        self.medalStackView.snp.remakeConstraints { make in
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(8)
        }

        self.titleLabel.snp.remakeConstraints { make in
            if medalStackView.isHidden {
                make.left.equalToSuperview().offset(11)
            } else {
                make.left.equalTo(medalStackView.snp.right).offset(4)
                make.width.lessThanOrEqualTo(82)
            }
            make.top.bottom.equalToSuperview()
        }

        self.pushView.snp.remakeConstraints { make in
            if self.titleLabel.isHidden {
                make.left.equalTo(self.medalStackView.snp.right)
            } else {
                make.left.equalTo(self.titleLabel.snp.right)
            }
            make.width.height.equalTo(12)
            make.right.equalToSuperview().offset(-6)
            make.centerY.equalToSuperview()
        }

        self.textLabel.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }

        self.moreImageView.snp.remakeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalToSuperview().offset(3)
            make.right.equalToSuperview().offset(-3)
        }
    }
    
    func setConstraints() {}

    public override func layoutSubviews() {
        super.layoutSubviews()

        self.layer.cornerRadius = self.bounds.height / 2
    }

    public func setTitle(_ title: String) {
        self.isHidden = false
        self.titleLabel.text = title
        self.medalStackView.isHidden = true
        layoutViews()
    }

    // swiftlint:disable empty_count
    // nolint: duplicated_code - 本次需求没有QA，为了避免产生问题，会在后期FG下线技术需求统一处理
    public func setMedals(_ medals: [LarkUserProfilMedal], count: Int) {
        if count == 0, medals.isEmpty {
            self.isHidden = true
        } else {
            self.isHidden = false

            self.titleLabel.isHidden = medals.count != 1
            if let first = medals.first {
                self.titleLabel.text = first.i18NName.getString()
            }

            self.medalStackView.removeFromSuperview()
            let medalStackView = UIStackView()
            medalStackView.spacing = 4
            medalStackView.axis = .horizontal
            medalStackView.alignment = .center
            self.medalStackView = medalStackView
            self.addSubview(medalStackView)

            for value in medals {
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFit

                var passThrough = ImagePassThrough()
                passThrough.key = value.image.key
                passThrough.fsUnit = value.image.fsUnit

                imageView.bt.setLarkImage(with: .default(key: value.image.key),
                                          passThrough: passThrough)

                self.medalStackView.addArrangedSubview(imageView)
                imageView.snp.remakeConstraints { make in
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
    // swiftlint:enable empty_count

    @objc func medalViewTapped() {
        self.tapCallback?()
    }
}
