//
//  SKNavigationBarTitle+ExternalLabel.swift
//  SpaceKit
//
//  Created by 边俊林 on 2020/2/27.
//
import SKResource

extension SKNavigationBarTitle {

    public final class ExternalLabel: UILabel {

        static private let accessId = "externalLabel"

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
            font = UIFont.systemFont(ofSize: 11)
            textColor = UIColor.ud.B600
            textAlignment = .center
            text = BundleI18n.SKResource.Doc_Widget_External
            layer.cornerRadius = 4
            backgroundColor = UIColor.ud.B100
            isHidden = true
            accessibilityIdentifier = ExternalLabel.accessId
        }

    }

}
