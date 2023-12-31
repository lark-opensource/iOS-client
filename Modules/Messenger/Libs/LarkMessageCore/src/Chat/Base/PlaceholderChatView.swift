//
//  PlaceholderChatView.swift
//  LarkChat
//
//  Created by 赵家琛 on 2020/11/11.
//

import Foundation
import UIKit
import LarkUIKit
import LarkMessengerInterface
import LarkContainer
import FigmaKit
import UniverseDesignColor

public protocol PlaceholderChatNavigationBarDelegate: AnyObject {
    func backButtonClicked()
}

final class PlaceholderChatNavigationBar: UIView {
    public weak var delegate: PlaceholderChatNavigationBarDelegate?

    private let isDark: Bool
    private let darkBackgroundColor: UIColor?
    private var itemsTintColor: UIColor {
        return isDark ? UIColor.ud.N00.alwaysLight : (UIColor.ud.N900 & UIColor.ud.N00.alwaysLight)
    }

    private var navBarBackgroundColor: UIColor {
        let normalColor = (UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.75) & UIColor.ud.staticBlack.withAlphaComponent(0.75))
        return isDark ? darkBackgroundColor ?? normalColor : normalColor
    }

    private lazy var backgroundBlurView: BackgroundBlurView = {
        let backgroundBlurView = BackgroundBlurView()
        backgroundBlurView.blurRadius = 25
        backgroundBlurView.backgroundColor = self.navBarBackgroundColor
        return backgroundBlurView
    }()

    public init(isDark: Bool, darkBackgroundColor: UIColor?) {
        self.isDark = isDark
        self.darkBackgroundColor = darkBackgroundColor
        super.init(frame: .zero)

        self.backgroundColor = UIColor.clear
        self.addSubview(self.backgroundBlurView)
        self.backgroundBlurView.snp.makeConstraints { $0.edges.equalToSuperview() }
        let container = UIView(frame: .zero)
        container.backgroundColor = UIColor.clear
        self.addSubview(container)
        container.snp.makeConstraints { (make) in
            make.top.equalTo(self.safeAreaLayoutGuide.snp.top)
            make.left.right.equalToSuperview()
            make.height.equalTo(44)
            make.bottom.equalToSuperview()
        }
        let backButton = UIButton(type: .custom)
        backButton.setImage(LarkUIKit.Resources.navigation_back_light.ud.withTintColor(itemsTintColor), for: .normal)
        backButton.addTarget(self, action: #selector(backButtonClicked), for: .touchUpInside)
        container.addSubview(backButton)
        backButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(12)
        }
    }

    @objc
    private func backButtonClicked() {
        self.delegate?.backButtonClicked()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class PlaceholderChatView: UIView {
    private let navigationBar: PlaceholderChatNavigationBar

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.font = UIFont.systemFont(ofSize: 16.0)
        titleLabel.textColor = UIColor.ud.N900
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.lineBreakMode = .byWordWrapping
        return titleLabel
    }()

    private lazy var subTitleLabel: UILabel = {
        let subTitleLabel = UILabel()
        subTitleLabel.font = UIFont.systemFont(ofSize: 14.0)
        subTitleLabel.textColor = UIColor.ud.N500
        subTitleLabel.textAlignment = .center
        subTitleLabel.numberOfLines = 0
        subTitleLabel.lineBreakMode = .byWordWrapping
        return subTitleLabel
    }()

    public init(isDark: Bool, title: String, subTitle: String, darkBackgroundColor: UIColor? = nil) {
        self.navigationBar = PlaceholderChatNavigationBar(isDark: isDark, darkBackgroundColor: darkBackgroundColor)
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBase

        self.addSubview(navigationBar)
        navigationBar.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
        }

        let imageView = UIImageView(image: Resources.no_access)
        self.addSubview(imageView)
        self.addSubview(self.titleLabel)
        self.addSubview(self.subTitleLabel)

        imageView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom).offset(210)
        }
        titleLabel.text = title
        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(28)
            make.top.equalTo(imageView.snp.bottom).offset(20)
        }
        subTitleLabel.text = subTitle
        subTitleLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview().inset(28)
            make.top.equalTo(titleLabel.snp.bottom).offset(4)
        }
    }

    public func setNavigationBarDelegate(_ delegate: PlaceholderChatNavigationBarDelegate) {
        self.navigationBar.delegate = delegate
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
