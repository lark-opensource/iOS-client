//
//  SpaceListFilterStateView.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/3.
//

import UIKit
import UniverseDesignColor
import UniverseDesignIcon

public final class SpaceListFilterStateView: UIControl {

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var activatedBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.udtokenBtnTextBgPriHover
        view.layer.cornerRadius = 4
        view.isUserInteractionEnabled = false
        return view
    }()

    private var isActive = false

    public override var isEnabled: Bool {
        didSet {
            guard oldValue != isEnabled else { return }
            if isEnabled {
                transformToEnabledState()
            } else {
                transformToDisabledState()
            }
        }
    }

    public init(iconKey: UDIconType = .filterOutlined, iconColor: UIColor = UDColor.iconN2) {
        super.init(frame: .zero)
        setupUI()
        imageView.image = UDIcon.getIconByKey(iconKey, renderingMode: .alwaysTemplate)
        imageView.tintColor = iconColor
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        clipsToBounds = false
        addSubview(activatedBackgroundView)
        activatedBackgroundView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(-2)
        }
        activatedBackgroundView.alpha = 0

        addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(18)
        }

        docs.addHighlight(with: UIEdgeInsets(top: -6, left: -8, bottom: -6, right: -8),
                          radius: 8)
    }

    public func update(isActive: Bool) {
        guard self.isActive != isActive else { return }
        if isActive {
            transformToActivatedState()
        } else {
            transformToDeactivatedState()
        }
        self.isActive = isActive
    }

    private func transformToActivatedState() {
        UIView.animate(withDuration: 0.3) { [self] in
            activatedBackgroundView.alpha = 1
            imageView.tintColor = UDColor.primaryContentDefault
        }
    }

    private func transformToDeactivatedState() {
        UIView.animate(withDuration: 0.3) { [self] in
            imageView.tintColor = UDColor.iconN2
            activatedBackgroundView.alpha = 0
        }
    }

    // 响应 isEnabled = false 的变化
    private func transformToDisabledState() {
        if isActive {
            UIView.animate(withDuration: 0.3) { [self] in
                imageView.tintColor = UDColor.iconDisabled
                activatedBackgroundView.backgroundColor = UDColor.udtokenBtnTextBgNeutralHover
            }
        } else {
            UIView.animate(withDuration: 0.3) { [self] in
                imageView.tintColor = UDColor.iconDisabled
            }
        }
    }

    // 响应 isEnabled = true 的变化
    private func transformToEnabledState() {
        if isActive {
            UIView.animate(withDuration: 0.3) { [self] in
                imageView.tintColor = UDColor.primaryContentDefault
                activatedBackgroundView.backgroundColor = UDColor.udtokenBtnTextBgPriHover
            }
        } else {
            UIView.animate(withDuration: 0.3) { [self] in
                imageView.tintColor = UDColor.iconN2
            }
        }
    }
}
