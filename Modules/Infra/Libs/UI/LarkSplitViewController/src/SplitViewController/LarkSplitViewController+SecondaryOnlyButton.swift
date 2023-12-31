//
//  LarkSplitViewController+SecondaryOnlyButton.swift
//  LarkSplitViewController
//
//  Created by Yaoguoguo on 2022/8/30.
//

import UIKit
import Foundation

// 只是展示全屏按钮的view
// 将它添加在页面上，有相应点击事件，点击后会变化样式。
// 当displayMode变化后，vc会收到通知，调用updateIcon或setupIcon方法，从而改变图标
public final class SecondaryOnlyButton: UIView {

    private let iconButton: UIButton = UIButton()
    private weak var vc: UIViewController?

    public init(vc: UIViewController) {
        self.vc = vc
        super.init(frame: CGRect.zero)
        self.addSubview(iconButton)
        iconButton.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        iconButton.addTarget(self, action: #selector(iconcClick), for: .touchUpInside)
        updateIcon()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // 按钮状态
    public enum State {
        case off
        case on
    }

    private var state: State = .off {
        didSet {
            let icon: UIImage
            switch state {
            case .off:
                icon = Resources.enterFullScreen
            case .on:
                icon = Resources.leaveFullScreen
            }
            iconButton.setImage(icon, for: .normal)
        }
    }

    // 更新displayMode后，需要更新按钮状态和样式
    // 调用任意一个
    public func setupIcon(newState: State) {
        state = newState
    }

    // 调用任意一个
    public func updateIcon() {
        if let split = vc?.larkSplitViewController {
            if split.splitMode == .secondaryOnly {
                setupIcon(newState: .on)
            } else {
                setupIcon(newState: .off)
            }
        }
    }

    @objc
    func iconcClick() {
        if let split = vc?.larkSplitViewController {
            switch state {
            case .off:
                split.updateSplitMode(.secondaryOnly, animated: true)
            case .on:
                split.updateSplitMode(.twoBesideSecondary, animated: true)
            }
        }
    }
}

// 全屏展开关闭 item
public final class SecondaryOnlyButtonItem: UIBarButtonItem {

    // 当前页面状态
    enum State {
        case off
        case on
    }

    public static var tintColorEnable: Bool = false
    public static var iconTintColor: UIColor?

    public var tintColorEnable: Bool = SecondaryOnlyButtonItem.tintColorEnable {
        didSet {
            self.updateIcon()
        }
    }
    public var iconTintColor: UIColor? = SecondaryOnlyButtonItem.iconTintColor {
        didSet {
            self.updateIcon()
        }
    }

    weak var controller: UIViewController?

    var state: State = .off {
        didSet {
            self.updateIcon()
            if self.contentView.window != nil {
                self.sendShowTrack()
            }
        }
    }

    public var enterFullScreenIcon: UIImage = Resources.enterFullScreen {
        didSet {
            self.updateIcon()
        }
    }
    public var leaveFullScreenIcon: UIImage = Resources.leaveFullScreen {
        didSet {
            self.updateIcon()
        }
    }

    private var contentView: ItemContentView = ItemContentView()
    private var stateBtn: UIButton = UIButton()

    init(vc: UIViewController) {
        self.controller = vc
        super.init()
        self.customView = self.contentView
        self.contentView.addSubview(self.stateBtn)
        stateBtn.snp.makeConstraints { (maker) in
            maker.height.width.equalTo(24)
            maker.edges.equalToSuperview()
        }
        self.stateBtn.addTarget(self, action: #selector(switchFullScreen), for: .touchUpInside)
        self.updateIcon()
        self.contentView.moveToWindowCallBack = { [weak self] in
            self?.sendShowTrack()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func switchFullScreen() {
        guard UIDevice.current.userInterfaceIdiom != .phone,
              let split = self.controller?.larkSplitViewController else {
            return
        }
        let scene = self.controller?.fullScreenSceneBlock?()
        if split.splitMode == .secondaryOnly {
            split.updateSplitMode(.twoBesideSecondary, animated: true)
            Tracker.trackFullScreenItemClick(scene: scene, isFold: false)
        } else {
            split.updateSplitMode(.secondaryOnly, animated: true)
            Tracker.trackFullScreenItemClick(scene: scene, isFold: true)
        }

        updateSplitState()
    }

    func updateSplitState() {
        if let split = self.controller?.larkSplitViewController {
            self.state = split.splitMode == .secondaryOnly ? .on : .off
        }
    }

    private func updateIcon() {
        let icon: UIImage
        switch self.state {
        case .off:
            icon = self.enterFullScreenIcon
        case .on:
            icon = self.leaveFullScreenIcon
        }

        if self.tintColorEnable,
            let iconTintColor = self.iconTintColor {
            self.stateBtn.setImage(icon.ud.withTintColor(iconTintColor), for: .normal)
        } else {
            self.stateBtn.setImage(icon.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        }
    }

    private func sendShowTrack() {
        let scene = self.controller?.fullScreenSceneBlock?()
        if self.state == .on {
            Tracker.trackFullScreenItemShow(scene: scene, isFold: false)
        } else {
            Tracker.trackFullScreenItemShow(scene: scene, isFold: true)
        }
    }
}

public final class AutoBackBarButtonItem: UIBarButtonItem {

    public static var tintColorEnable: Bool = false
    public static var iconTintColor: UIColor?

    public var tintColorEnable: Bool = SecondaryOnlyButtonItem.tintColorEnable {
        didSet {
            self.updateIcon()
        }
    }
    public var iconTintColor: UIColor? = SecondaryOnlyButtonItem.iconTintColor {
        didSet {
            self.updateIcon()
        }
    }

    weak var controller: UIViewController?
    public var backIcon: UIImage = Resources.back {
        didSet {
            updateIcon()
        }
    }
    private var contentView: UIView = UIView()
    private var stateBtn: UIButton = UIButton()

    init(vc: UIViewController) {
        self.controller = vc
        super.init()
        self.customView = self.contentView
        self.contentView.addSubview(self.stateBtn)
        stateBtn.snp.makeConstraints { (maker) in
            maker.height.width.equalTo(24)
            maker.edges.equalToSuperview()
        }
        self.stateBtn.addTarget(self, action: #selector(goBack), for: .touchUpInside)
        self.updateIcon()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func goBack() {
        self.controller?.navigationController?.popViewController(animated: true)
    }

    func updateIcon() {
        if self.tintColorEnable,
            let iconTintColor = self.iconTintColor {
            self.stateBtn.setImage(self.backIcon.ud.withTintColor(iconTintColor), for: .normal)
        } else {
            self.stateBtn.setImage(self.backIcon.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        }
    }
}

final class ItemContentView: UIView {

    var moveToWindowCallBack: (() -> Void)?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        moveToWindowCallBack?()
    }
}
