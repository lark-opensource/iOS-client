//
//  SKNavigationBarTitle+SecondTag.swift
//  SKUIKit
//
//  Created by guoqp on 2021/5/14.
//

import SKResource

extension SKNavigationBarTitle {

    public final class SecondTagLabel: UILabel {

        static private let accessId = "secondTagLabel"

        public override init(frame: CGRect) {
            super.init(frame: frame)
            commonInit()
        }

        public init() {
            super.init(frame: .zero)
            commonInit()
        }

        required init?(coder: NSCoder) {
            super.init(coder: coder)
            commonInit()
        }

        // Add leading and trailing paddings
        public override var intrinsicContentSize: CGSize {
            if text?.isEmpty == true {
                return super.intrinsicContentSize
            }
            return CGSize(width: super.intrinsicContentSize.width + 8, height: super.intrinsicContentSize.height)
        }

        private func commonInit() {
            font = UIFont.systemFont(ofSize: 12)
            textColor = UIColor.ud.N600
            textAlignment = .center
            text = BundleI18n.SKResource.CreationMobile_ECM_FileMigration_gen2_tag
            layer.cornerRadius = 3
            layer.backgroundColor = UIColor.ud.N900.withAlphaComponent(0.1).cgColor
            isHidden = true
            accessibilityIdentifier = SecondTagLabel.accessId
        }

    }

}
