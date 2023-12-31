//
//  OPDebugWindowController.swift
//  EEMicroAppSDK
//
//  Created by 尹清正 on 2021/2/3.
//

import UIKit
import SnapKit
import OPSDK

class OPDebugWindowController: UIViewController {

    /// 用于布局的工具类
    var layout: OPDebugWindowLayout?

    // MARK: - 代理

    weak var displayTypeDelegate: OPDebugCommandWindowDisplayTypeDelegate?
    weak var moveDelegate: OPDebugCommandWindowMoveDelegate?

    // MARK: - 系统属性

    override var shouldAutorotate: Bool { BDPDeviceHelper.isPadDevice() }

    // MARK: - subview variables：子View变量
    /// 最小化窗口的View
    private lazy var minimizedWindowView: UIView = {
        let view = OPDebugWindowMinimizedWindowView(frame: .zero)
        view.moveDelegate = moveDelegate
        view.displayTypeDelegate = displayTypeDelegate
        return view
    }()

    /// 小程序的容器Controller，只有满足FG之后才会创建调试小程序界面
    private lazy var gadgetController: OPDebugWindowGadgetController? = {
        if OPDebugFeatureGating.debugAvailable() {
            return OPDebugWindowGadgetController()
        }
        return nil
    }()

    /// 最大化窗口的view
    private lazy var maximizedWindowView: UIView = UIView()

    /// 用于装载小程序的controller是无法自主释放的，需要外部帮助释放
    deinit {
        gadgetController?.container?.destroy(monitorCode: OPSDKMonitorCode.cancel)
    }

    // MARK: - life cycle methods: 生命周期方法

    override func viewDidLoad() {
        title = "调试"

        navigationItem.rightBarButtonItems = [
            .init(title: "收起", style: .plain, target: self, action: #selector(minimizeWindowView)),
            .init(title: "关闭", style: .plain, target: self, action: #selector(closeWindow))
        ]

        view.layer.masksToBounds = true
        view.layer.cornerRadius = OPDebugWindowLayout.windowRadius

        view.addSubview(minimizedWindowView)
        minimizedWindowView.snp.makeConstraints { maker in
            maker.bottom.top.left.right.equalToSuperview()
        }

        view.addSubview(maximizedWindowView)
        maximizedWindowView.snp.makeConstraints { maker in
            maker.bottom.left.right.equalToSuperview()
            maker.top.equalTo(view.safeAreaLayoutGuide.snp.top)
        }

        if let gadgetController = gadgetController {
            addChild(gadgetController)
            maximizedWindowView.addSubview(gadgetController.view)
            gadgetController.didMove(toParent: self)
            gadgetController.view.snp.makeConstraints { maker in
                maker.leading.top.bottom.equalToSuperview()
                maker.width.equalTo(layout?.maximizedViewSize.width ?? maximizedWindowView.snp.width)
            }
        }
    }

    @objc func minimizeWindowView() {
        displayTypeDelegate?.minimize()
    }

    @objc func closeWindow() {
        displayTypeDelegate?.close()
    }

    // MARK: - public method: 对外公开的API方法
    
    /// 显示最小化窗口的view
    func showMinimizedView() {
        navigationController?.setNavigationBarHidden(true, animated: false)
        view.bringSubviewToFront(minimizedWindowView)
        minimizedWindowView.alpha = 1
        maximizedWindowView.alpha = 0
    }

    /// 显示正常调试窗口的view
    func showMaximizedView() {
        // 显示调试小程序界面需要满足FG开启条件
        guard OPDebugFeatureGating.debugAvailable() else {
            return
        }

        navigationController?.setNavigationBarHidden(false, animated: false)
        view.bringSubviewToFront(maximizedWindowView)
        minimizedWindowView.alpha = 0
        maximizedWindowView.alpha = 1
    }
}
