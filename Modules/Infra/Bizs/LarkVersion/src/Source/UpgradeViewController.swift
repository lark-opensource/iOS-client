//
//  UpgradeViewController.swift
//  LarkVersion
//
//  Created by aslan on 2023/7/18.
//

import Foundation
import LarkContainer
import LKCommonsLogging
import LarkUIKit

typealias UpgradeTransition = (CGFloat) -> Void

struct UpgradeViewModel {
    let title: String
    let note: String
    let showLater: Bool
    let laterButtonTitle: String?
    let upgradeButtonTitle: String?

    public init(title: String,
                note: String,
                showLater: Bool,
                laterButtonTitle: String? = nil,
                upgradeButtonTitle: String? = nil) {
        self.title = title
        self.note = note
        self.showLater = showLater
        self.laterButtonTitle = laterButtonTitle
        self.upgradeButtonTitle = upgradeButtonTitle
    }
}

class UpgradeViewController: UIViewController {

    static private var logger = Logger.log(UpgradeAlertView.self, category: "LarkVersion")

    private let upgradeViewModel: UpgradeViewModel

   internal lazy var upgradeView: UpgradeAlertView = {
        UpgradeAlertView(showLater: self.upgradeViewModel.showLater)
    }()

    private lazy var maskView: UIView = {
       let view = UIView()
        view.backgroundColor = UIColor.ud.bgMask
        return view
    }()

    private var alertSize: CGSize = .zero

    required init(upgradeViewModel: UpgradeViewModel) {
        self.upgradeViewModel = upgradeViewModel
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        Self.logger.info("new version: alert vc dealloc")
    }

    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        setUpLayout()
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if self.modalPresentationStyle == .overFullScreen {
            self.view.addSubview(self.maskView)
            self.maskView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        self.view.addSubview(self.upgradeView)

        upgradeView.setup(note: self.upgradeViewModel.note, customTitle: self.upgradeViewModel.title)
        if self.upgradeViewModel.showLater, let laterTitle = self.upgradeViewModel.laterButtonTitle {
            upgradeView.laterTitle = laterTitle
        }
        if let upgradeTitle = self.upgradeViewModel.upgradeButtonTitle {
            upgradeView.upgradeTitle = upgradeTitle
        }
    }

    func setUpLayout() {
        self.alertSize.width = self.getAlertWidth()
        upgradeView.snp.remakeConstraints { make in
            if (Self.isAlert(window: self.view.window)) {
                make.center.equalToSuperview()
            } else {
                make.bottom.equalToSuperview()
            }
            make.width.equalTo(self.alertSize.width)
            make.centerX.equalToSuperview()
        }
    }

    static func isAlert(window: UIWindow? = nil) -> Bool {
        if UIDevice.current.userInterfaceIdiom != .pad {
            return false
        }
        if let window = window {
            return window.traitCollection.horizontalSizeClass == .regular
        }
        return false
    }

    private func getAlertWidth() -> CGFloat {
        var width = self.view.frame.size.width
        if Self.isAlert(window: self.view.window) {
            if #available(iOS 13.0, *) {
                /// iPad 弹出时为了保持跟设置页宽度一致
                /// formsheet 弹出样式，后面的控制器会有往后缩小的问题
                width -= 20 * 2
            } else {
                /// iPad 12 及以下，单独适配，present 弹出需要自己加蒙层
                width = min(536, width)
            }
        }
        return width
    }
}
