//
//  BitableHomeBottomTabBarItemView.swift
//  SKBitable
//
//  Created by 刘焱龙 on 2023/10/29.
//

import Foundation
import UniverseDesignIcon
import UniverseDesignColor
import Lottie
import SKUIKit
import SKResource

struct BitableHomeBottomTabBarItem {
    let unselectKey: UDIconType
    let selectKey: UDIconType
    let scene: BitableHomeScene
}

final class BitableHomeBottomTabBarItemView: UIView {
    private static let imageSize = CGSize(width: 22, height: 22)

    private lazy var button: UIControl = {
        let btn = UIControl()
        btn.addTarget(self, action: #selector(onClick), for: .touchUpInside)
        return btn
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.axis = .vertical
        view.alignment = .center
        view.distribution = .fill
        view.spacing = 6
        view.isUserInteractionEnabled = false
        return view
    }()

    private lazy var imageView: UIImageView = {
        let view = UIImageView()
        view.isUserInteractionEnabled = false
        view.contentMode = .scaleAspectFit
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 10, weight: .medium)
        label.textColor = .ud.textCaption
        label.textAlignment = .center
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    private var currentClickAnimationView: LOTAnimationView?

    let scene: BitableHomeScene
    private let clickAction: (_ scene: BitableHomeScene) -> Void

    private var isSelect: Bool = false

    init(scene: BitableHomeScene, clickAction: @escaping (_ scene: BitableHomeScene) -> Void) {
        self.scene = scene
        self.clickAction = clickAction
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupSubviews() {
        addSubview(button)
        button.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        stackView.addArrangedSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.size.equalTo(Self.imageSize)
        }
        titleLabel.text = scene.title
        stackView.addArrangedSubview(titleLabel)
        button.addSubview(stackView)
        stackView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        updateSelect(isSelect: false, animated: false)
    }

    private func fetchClickAnimationView() -> LOTAnimationView {
        let animation = scene.animationView
        animation.backgroundColor = .ud.bgBody
        animation.loopAnimation = false
        animation.autoReverseAnimation = false
        animation.contentMode = .scaleAspectFill
        return animation
    }

    private func showClickAnimation() {
        clearAnimation()
        let animationView = fetchClickAnimationView()
        addSubview(animationView)
        animationView.snp.makeConstraints { make in
            make.edges.equalTo(imageView)
        }
        currentClickAnimationView = animationView
        animationView.play { [weak self] _ in
            guard let self = self else {
                return
            }
            updateTextColor()
            clearAnimation()
        }
    }

    private func showUnclickAnimation() {
        clearAnimation()
        let animationView = fetchClickAnimationView()
        addSubview(animationView)
        animationView.snp.makeConstraints { make in
            make.edges.equalTo(imageView)
        }
        currentClickAnimationView = animationView
        // lottie 倒放的时候可能会闪第一帧，所以需要设置一下 progress
        animationView.animationProgress = 1.0
        animationView.play(fromProgress: 1, toProgress: 0) { [weak self] _ in
            guard let self = self else {
                return
            }
            updateTextColor()
            clearAnimation()
        }
    }

    private func updateTextColor() {
        let currentColor: UIColor = isSelect ? .ud.textTitle : .ud.textCaption
        titleLabel.textColor = currentColor
    }

    private func clearAnimation() {
        currentClickAnimationView?.stop()
        currentClickAnimationView?.removeFromSuperview()
        currentClickAnimationView = nil
    }

    @objc
    private func onClick() {
        clickAction(scene)
    }

    func updateSelect(isSelect: Bool, animated: Bool) {
        let showAnimation = (self.isSelect != isSelect)
        self.isSelect = isSelect
        self.isUserInteractionEnabled = !isSelect

        let iconKey = isSelect ? scene.selectKey : scene.unselectKey
        var image = UDIcon.getIconByKey(iconKey, size: Self.imageSize)
        let font: UIFont = isSelect ? .systemFont(ofSize: 10, weight: .medium) : .systemFont(ofSize: 10, weight: .regular)
        titleLabel.font = font
        if !isSelect {
            image = image.ud.withTintColor(.ud.iconN2)
        }

        if showAnimation, animated {
            imageView.image = image
            isSelect ? showClickAnimation() : showUnclickAnimation()
        } else {
            imageView.image = image
        }
    }
}

fileprivate extension BitableHomeScene {
    var animationView: LOTAnimationView {
        switch self {
        case .homepage:
            return AnimationViews.bitableHomeTabHomePageAnimation
        case .recommend:
            return AnimationViews.bitableHomeTabRecommendAnimation
        case .new:
            return AnimationViews.bitableHomeTabNewAnimation
        }
    }

    var title: String {
        switch self {
        case .homepage:
            return BundleI18n.SKResource.Bitable_HomeDashboard_Homepage_Tab
        case .recommend:
            return BundleI18n.SKResource.Bitable_HomeDashboard_Discover_Tab
        case .new:
            return BundleI18n.SKResource.Bitable_HomeDashboard_Create_Tab
        }
    }

    var selectKey: UDIconType {
        switch self {
        case .homepage:
            return .baseHomeColorful
        case .recommend:
            return .baseDiscoverColorful
        case .new:
            return .baseAddColorful
        }
    }

    var unselectKey: UDIconType {
        switch self {
        case .homepage:
            return .baseHomeOutlined
        case .recommend:
            return .baseDiscoverOutlined
        case .new:
            return .baseAddOutlined
        }
    }
}
