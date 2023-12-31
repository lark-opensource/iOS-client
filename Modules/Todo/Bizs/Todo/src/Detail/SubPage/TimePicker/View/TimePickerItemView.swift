//
//  TimePickerItemView.swift
//  Todo
//
//  Created by wangwanxin on 2023/5/24.
//

import Foundation
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignFont

final class TimePickerItemView: UIView {

    var clickHandler: (() -> Void)?
    var closeHandler: (() -> Void)?

    enum RightIconStatus {
        case indicator(transform: Bool)
        case close
    }
    var rightIconStatus: RightIconStatus = .indicator(transform: false) {
        didSet {
            rightBtn.isHidden = disabled
            switch rightIconStatus {
            case .indicator(let transform):
                rightBtn.setImage(indicator, for: .normal)
                rightBtn.transform = transform ? CGAffineTransform.identity.rotated(by: -.pi / 2) : .identity
            case .close:
                rightBtn.setImage(closeIcon, for: .normal)
            }
        }
    }

    var title: String? {
        didSet {
            titleLabel.textColor = disabled ? UIColor.ud.textDisabled : UIColor.ud.textTitle
            titleLabel.text = title
            leftImageView.image = leftImageView.image?.ud.withTintColor(disabled ? UIColor.ud.iconDisabled : UIColor.ud.iconN3)
        }
    }

    var disabled: Bool = false {
        didSet {
            titleLabel.textColor = disabled ? UIColor.ud.textDisabled : UIColor.ud.textTitle
            rightBtn.isHidden = disabled
            leftImageView.image = leftImageView.image?.ud.withTintColor(disabled ? UIColor.ud.iconDisabled : UIColor.ud.iconN3)
        }
    }

    private lazy var leftImageView = UIImageView()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UDFont.systemFont(ofSize: Config.TitleFont)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var closeIcon = UDIcon.getIconByKey(.closeOutlined, iconColor: UIColor.ud.iconN3, size: Config.RightIconSize)
    private lazy var indicator = UDIcon.getIconByKey(.rightOutlined, iconColor: UIColor.ud.iconN3, size: Config.RightIconSize)
    private lazy var rightBtn = UIButton()

    init(leftIconKey: UniverseDesignIcon.UDIconType, title: String) {
        super.init(frame: .zero)
        self.leftImageView.image = UDIcon.getIconByKey(leftIconKey, size: Config.LeftIconSize)
        self.titleLabel.text = title
        backgroundColor = UIColor.ud.bgBody
        addSubview(leftImageView)
        addSubview(titleLabel)
        addSubview(rightBtn)
        rightBtn.setImage(indicator, for: .normal)
        rightBtn.hitTestEdgeInsets = UIEdgeInsets(top: -12, left: -12, bottom: -12, right: -12)

        leftImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(Config.hSpace)
            make.size.equalTo(Config.LeftIconSize)
            make.centerY.equalToSuperview()
        }

        rightBtn.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-Config.hSpace)
            make.size.equalTo(Config.RightIconSize)
            make.centerY.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.equalTo(leftImageView.snp.right).offset(Config.IconTextSpace)
            make.right.equalTo(rightBtn.snp.left).offset(-Config.IconTextSpace)
        }

        rightBtn.addTarget(self, action: #selector(clickClose), for: .touchUpInside)
        let tap = UITapGestureRecognizer(target: self, action: #selector(onTap))
        self.addGestureRecognizer(tap)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        return CGSize(width: Self.noIntrinsicMetric, height: Config.Height)
    }

    @objc
    private func onTap() {
        guard !disabled else { return }
        clickHandler?()
    }

    @objc
    private func clickClose() {
        guard !disabled else { return }
        if case .close = rightIconStatus {
            closeHandler?()
        } else {
            clickHandler?()
        }
    }

}

extension TimePickerItemView {
    struct Config {
        static let TitleFont = 16.0
        static let LeftIconSize = CGSize(width: 20.0, height: 20.0)
        static let RightIconSize = CGSize(width: 16.0, height: 16.0)
        static let Height = 58.0
        static let hSpace = 16.0
        static let IconTextSpace = 12.0
    }
}

final class TimePickerEmptyView: UIView {

    override var intrinsicContentSize: CGSize {
        return CGSize(width: Self.noIntrinsicMetric, height: Config.Height)
    }

    struct Config {
        static let Height = 16.0
    }
}
