//
//  MoreAvatarView.swift
//  SKUIKit
//
//  Created by Weston Wu on 2023/1/11.
//

import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignLoading
import SnapKit

// 将 1pt 的外边距 + 1pt 的内边距 转换为 2pt 的内边距
public final class AvatarContainerView: UIControl {

    public private(set) lazy var avatar: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.backgroundColor = .clear
        return view
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        clipsToBounds = true
        layer.borderWidth = 2
        layer.ud.setBorderColor(UDColor.bgFloat)
        addSubview(avatar)
        avatar.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(1)
        }
    }
}

public final class AvatarLoadingView: UIView {

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        isUserInteractionEnabled = false
        clipsToBounds = true
        layer.borderWidth = 2
        layer.ud.setBorderColor(UDColor.bgFloat)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if frame.size != .zero {
            showUDSkeleton()
        }
    }
}


public final class MoreAvatarView: UIView {
    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.image = UDIcon.moreOutlined
        view.tintColor = UDColor.textCaption
        return view
    }()
    private lazy var numberLabel: UILabel = {
        let label = UILabel()
        label.textColor = UDColor.textCaption
        label.font = .systemFont(ofSize: 14, weight: .medium)
        return label
    }()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        isUserInteractionEnabled = false
        backgroundColor = UDColor.N200
        clipsToBounds = true
        layer.borderWidth = 2
        layer.ud.setBorderColor(UDColor.bgFloat)
        addSubview(numberLabel)
        numberLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(24)
        }
    }

    public func update(number: Int) {
        guard number > 0 else {
            assertionFailure()
            imageView.isHidden = false
            numberLabel.isHidden = true
            return
        }
        if number < 10 {
            imageView.isHidden = true
            numberLabel.text = "+\(number)"
            numberLabel.isHidden = false
            numberLabel.font = .systemFont(ofSize: 14, weight: .medium)
        } else if number < 100 {
            imageView.isHidden = true
            numberLabel.text = "+\(number)"
            numberLabel.isHidden = false
            numberLabel.font = .systemFont(ofSize: 12, weight: .medium)
        } else if number < 1000 {
            imageView.isHidden = true
            numberLabel.text = "+\(number)"
            numberLabel.isHidden = false
            numberLabel.font = .systemFont(ofSize: 11, weight: .medium)
        } else {
            imageView.isHidden = false
            numberLabel.isHidden = true
        }
    }
}
