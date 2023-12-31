//
//  KeyboardSubmitView.swift
//  LarkMessageCore
//
//  Created by bytedance on 6/21/22.
//

import UIKit
import FigmaKit
import LarkSDKInterface
import LarkMessageBase
import UniverseDesignIcon
import UniverseDesignColor

public final class KeyboardSubmitView: UIView, KeyboardPanelRightContainerViewProtocol {
    public func layoutWith(superView: UIView) {
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalTo(108)
        }
    }
    private lazy var commitButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UDIcon.getIconByKey(.listCheckBoldOutlined, size: .init(width: 18, height: 18)).ud.withTintColor(.ud.primaryOnPrimaryFill), for: .normal)
        button.setBackgroundImage(UIImage.ud.fromPureColor(.ud.primaryFillDefault), for: .normal)
        button.setBackgroundImage(UIImage.ud.fromPureColor(.ud.primaryFillPressed), for: .highlighted)
        button.setBackgroundImage(UIImage.ud.fromPureColor(.ud.textDisabled), for: .disabled)

        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(onCommit), for: .touchUpInside)
        return button
    }()
    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UDIcon.getIconByKey(.closeSmallOutlined, size: .init(width: 18, height: 18)), for: .normal)
        button.tintColor = .ud.iconN1
        button.backgroundColor = .ud.udtokenComponentOutlinedBg
        button.layer.borderWidth = 1
        button.layer.ud.setBorderColor(UIColor.ud.lineBorderComponent)
        button.layer.cornerRadius = 6
        button.clipsToBounds = true
        button.addTarget(self, action: #selector(onClose), for: .touchUpInside)
        return button
    }()
    public var onCommitCallback: (() -> Void)?
    public var onCloseCallback: (() -> Void)?

    /// 在闭包里配置 commitButton 的样式
    /// - NOTE: 更好的方法是改造 KeyboardSubmitView，接收 Configuration 对象，提供灵活的定制能力
    /// - NOTE: 这里为了快速实现需求，且完全不影响其他点位，使用了 Configuration 闭包的形式
    public var commitButtonConfigurator: ((UIButton) -> Void)? {
        didSet {
            commitButtonConfigurator?(commitButton)
        }
    }

    public init(commitButtonEnable: Bool) {
        super.init(frame: .zero)
        addSubview(commitButton)
        commitButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-8)
            make.width.equalTo(44)
            make.height.equalTo(32)
        }
        addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
            make.width.equalTo(44)
            make.height.equalTo(32)
        }
        setCommitButtonEnable(commitButtonEnable)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    private func onCommit() {
        onCommitCallback?()
    }

    @objc
    private func onClose() {
        onCloseCallback?()
    }

    private func setCommitButtonEnable(_ value: Bool) {
        commitButton.isEnabled = value
    }

    public func updateFor(_ scene: MessengerKeyboardPanel.Scene) {
        switch scene {
        case .submitView(let enable), .scheduleMsgEdit(let enable, _, _, _):
            setCommitButtonEnable(enable)
        case .sendQuickAction(let enable):
            setCommitButtonEnable(enable)
        default:
            break
        }
    }

    public override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if #available(iOS 13.0, *), traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            commitButtonConfigurator?(commitButton)
        }
    }
}
