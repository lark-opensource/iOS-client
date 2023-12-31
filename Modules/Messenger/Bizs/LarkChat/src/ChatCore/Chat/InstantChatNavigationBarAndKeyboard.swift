//
//  InstantChatNavigationBarAndKeyboard.swift
//  LarkChat
//
//  Created by zc09v on 2020/2/18.
//

import Foundation
import UIKit
import AnimatedTabBar
import LarkExtensions
import LarkUIKit
import LarkMessageCore

public protocol InstantChatNavigationBarDelegate: AnyObject {
    func backButtonClicked()
}

public final class InstantChatNavigationBar: UIView {
    public weak var delegate: InstantChatNavigationBarDelegate?

    private let isDark: Bool
    private var itemsTintColor: UIColor {
        return isDark ? UIColor.ud.N00 : UIColor.ud.N900
    }
    public var navBarBackgroundColor: UIColor = UIColor.ud.bgBody {
        didSet {
            self.backgroundColor = navBarBackgroundColor
        }
    }
    private var contentAlpha: CGFloat {
        return isDark ? 0.5 : 1
    }
    private var contentColors: [UIColor] {
        return isDark ? [UIColor.ud.N200.withAlphaComponent(0.6), UIColor.ud.N200] : [UIColor.ud.N200]
    }
    public init(isDark: Bool, leftStyle: Bool = false) {
        self.isDark = isDark
        super.init(frame: .zero)
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
        backButton.setImage(LarkUIKit.Resources.navigation_back_light
            .lu.colorize(color: itemsTintColor), for: .normal)
        backButton.addTarget(self, action: #selector(backButtonClicked), for: .touchUpInside)
        container.addSubview(backButton)
        backButton.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(12)
        }

        let fakeTitle = GradientView()
        fakeTitle.colors = contentColors
        fakeTitle.direction = .horizontal
        fakeTitle.layer.masksToBounds = true
        fakeTitle.layer.cornerRadius = 2
        fakeTitle.locations = [0.0, 1.0]
        fakeTitle.alpha = contentAlpha
        container.addSubview(fakeTitle)
        if leftStyle {
            fakeTitle.snp.makeConstraints { (make) in
                make.centerY.equalToSuperview()
                make.left.equalTo(backButton.snp.right).offset(16)
                make.width.equalTo(90)
                make.height.equalTo(16)
            }
        } else {
            fakeTitle.snp.makeConstraints { (make) in
                make.center.equalToSuperview()
                make.width.equalTo(90)
                make.height.equalTo(16)
            }
        }

        let fakeIcon1 = GradientView()
        fakeIcon1.colors = contentColors
        fakeIcon1.direction = .horizontal
        fakeIcon1.layer.masksToBounds = true
        fakeIcon1.layer.cornerRadius = 12
        fakeIcon1.locations = [0.0, 1.0]
        fakeIcon1.alpha = contentAlpha
        container.addSubview(fakeIcon1)
        fakeIcon1.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }

        let fakeIcon2 = GradientView()
        fakeIcon2.colors = contentColors
        fakeIcon2.direction = .horizontal
        fakeIcon2.layer.masksToBounds = true
        fakeIcon2.layer.cornerRadius = 12
        fakeIcon2.locations = [0.0, 1.0]
        fakeIcon2.alpha = contentAlpha
        container.addSubview(fakeIcon2)
        fakeIcon2.snp.makeConstraints { (make) in
            make.left.equalTo(fakeIcon1.snp.right).offset(20)
            make.right.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
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

public class InstantChatKeyboard: UIView {
}

public final class NormalInstantChatKeyboard: InstantChatKeyboard {
    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBody
        self.layer.ud.setShadowColor(UIColor.ud.staticBlack)
        self.layer.shadowOpacity = 0.05
        self.layer.shadowOffset = CGSize(width: 0, height: -0.5)
        let fakeInputView = UIView(frame: .zero)
        fakeInputView.backgroundColor = UIColor.ud.N200
        fakeInputView.layer.masksToBounds = true
        fakeInputView.layer.cornerRadius = 2
        self.addSubview(fakeInputView)
        fakeInputView.snp.makeConstraints { (make) in
            make.width.equalTo(120)
            make.height.equalTo(16)
            make.top.equalToSuperview().offset(14.5)
            make.left.equalToSuperview().offset(20)
        }

        let fakeButton = UIView(frame: .zero)
        fakeButton.backgroundColor = UIColor.ud.N200
        fakeButton.layer.masksToBounds = true
        fakeButton.layer.cornerRadius = 12
        self.addSubview(fakeButton)
        fakeButton.snp.makeConstraints { (make) in
            make.width.height.equalTo(24)
            make.top.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-20)
        }
        let buttonNum = 5
        let buttonStack = UIStackView(frame: .zero)
        buttonStack.backgroundColor = UIColor.ud.bgBody
        buttonStack.axis = .horizontal
        buttonStack.distribution = .equalSpacing
        buttonStack.alignment = .center
        self.addSubview(buttonStack)
        buttonStack.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-20)
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(fakeInputView.snp.bottom).offset(15.5)
            make.height.equalTo(24)
        }
        for _ in 0 ..< buttonNum {
            let fakeButton = UIView(frame: .zero)
            fakeButton.backgroundColor = UIColor.ud.N200
            fakeButton.layer.masksToBounds = true
            fakeButton.layer.cornerRadius = 12
            self.addSubview(fakeInputView)
            fakeButton.snp.makeConstraints { (make) in
                make.width.height.equalTo(24)
            }
            buttonStack.addArrangedSubview(fakeButton)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

public final class CryptoInstantChatKeyboard: InstantChatKeyboard {
    init() {
        super.init(frame: .zero)
        self.backgroundColor = UIColor.ud.bgBody
        self.layer.ud.setShadowColor(UIColor.ud.staticBlack)
        self.layer.shadowOpacity = 0.05
        self.layer.shadowOffset = CGSize(width: 0, height: -0.5)
        let fakeInputView = UIView(frame: .zero)
        fakeInputView.backgroundColor = UIColor.ud.N200
        fakeInputView.layer.masksToBounds = true
        fakeInputView.layer.cornerRadius = 2
        self.addSubview(fakeInputView)
        fakeInputView.snp.makeConstraints { (make) in
            make.width.equalTo(120)
            make.height.equalTo(16)
            make.top.equalToSuperview().offset(14.5)
            make.left.equalToSuperview().offset(20)
        }

        let buttonNum = 6
        let buttonStack = UIStackView(frame: .zero)
        buttonStack.backgroundColor = UIColor.ud.bgBody
        buttonStack.axis = .horizontal
        buttonStack.distribution = .equalSpacing
        buttonStack.alignment = .center
        self.addSubview(buttonStack)
        buttonStack.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-20)
            make.left.equalToSuperview().offset(20)
            make.top.equalTo(fakeInputView.snp.bottom).offset(15.5)
            make.height.equalTo(24)
        }
        for _ in 0 ..< buttonNum {
            let fakeButton = UIView(frame: .zero)
            fakeButton.backgroundColor = UIColor.ud.N200
            fakeButton.layer.masksToBounds = true
            fakeButton.layer.cornerRadius = 12
            self.addSubview(fakeInputView)
            fakeButton.snp.makeConstraints { (make) in
                make.width.height.equalTo(24)
            }
            buttonStack.addArrangedSubview(fakeButton)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
