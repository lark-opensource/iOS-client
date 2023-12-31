//
//  SetupMacTask.swift
//  LarkBaseService
//
//  Created by Yaoguoguo on 2023/7/13.
//

import Foundation
import LarkFoundation
import BootManager
import UniverseDesignColor
import SnapKit
import LarkReleaseConfig
import LKCommonsLogging
import LarkSetting

public class SetupMacTask: UserFlowBootTask, Identifiable {

    static let logger = Logger.log(SetupMacTask.self, category: "SetupMacTask")

    public static var identify = "SetupMacTask"

    public override var runOnlyOnceInUserScope: Bool { return false }

    public override func execute(_ context: BootContext) {
        Self.logger.info("execute")
        if #available(iOS 13.0, *) {
            let fg = try? self.userResolver.resolve(assert: FeatureGatingService.self)
            let fgValue = fg?.staticFeatureGatingValue(with: "core.mac.install_tips") ?? false
            Self.logger.info("fgValue: \(fgValue)")
            guard fgValue, let scene = context.window?.windowScene, Utils.isiOSAppOnMacSystem else {
                Self.logger.info("fgValue: \(fgValue), isiOSAppOnMacSystem: \(Utils.isiOSAppOnMacSystem)")
                return
            }
            scene.sizeRestrictions?.minimumSize = SoldOutAlertController.Cons.sceneContentSize

            /// 2s 后添加下线提示
            DispatchQueue.main.async {
                Self.logger.info("present Controller")
                let vc = SoldOutAlertController()
                vc.modalPresentationStyle = .formSheet
                vc.isModalInPresentation = true
                context.window?.rootViewController?.present(vc, animated: true, completion: nil)
            }
        } else {
            Self.logger.info("小于iOS 13")
        }
    }
}

class SoldOutAlertController: UIViewController {

    let titleLabel = UILabel()
    let contentView = UILabel()
    let clickButton = UIButton()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.preferredContentSize = Cons.preferredContentSize

        self.view.backgroundColor = UIColor.ud.bgBody

        self.view.addSubview(titleLabel)
        titleLabel.text = BundleI18n.Lark.Lark_Installer_M1OptimizedFeishuTitle()
        titleLabel.font = UIFont.ud.title1
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.snp.makeConstraints { maker in
            maker.left.equalTo(Cons.margin)
            maker.right.equalTo(-Cons.margin)
            maker.top.equalTo(Cons.topMargin)
        }

        self.view.addSubview(contentView)
        contentView.text = BundleI18n.Lark.Lark_Installer_M1OptimizedFeishuDesc()
        contentView.font = UIFont.ud.body0
        contentView.textColor = UIColor.ud.textCaption
        contentView.textAlignment = .left
        contentView.numberOfLines = 0
        contentView.snp.makeConstraints { maker in
            maker.left.equalTo(Cons.margin)
            maker.right.equalTo(-Cons.margin)
            maker.top.equalTo(titleLabel.snp.bottom).offset(Cons.contentTopMargin)
        }

        self.view.addSubview(clickButton)
        clickButton.setTitle(BundleI18n.Lark.Lark_Installer_M1OptimizedFeishuButton, for: .normal)
        clickButton.setTitleColor(UIColor.ud.primaryOnPrimaryFill, for: .normal)
        clickButton.titleLabel?.font = UIFont.ud.body0
        clickButton.layer.cornerRadius = Cons.cornerRadius
        clickButton.backgroundColor = UIColor.ud.primaryContentDefault
        clickButton.addTarget(self, action: #selector(clickDownload), for: .touchUpInside)
        clickButton.snp.makeConstraints { maker in
            maker.centerX.equalToSuperview()
            maker.left.equalTo(Cons.margin)
            maker.right.equalTo(-Cons.margin)
            maker.height.equalTo(Cons.clickButtonHeight)
            maker.bottom.equalTo(-Cons.margin)
        }
    }

    @objc
    func clickDownload() {
        let downloadString: String = DomainSettingManager.shared.currentSetting["ios_setup_mac_task"]?.first ?? ""

        if let url = URL(string: downloadString) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

extension SoldOutAlertController {
    enum Cons {
        static let sceneContentSize = CGSize(width: 1024, height: 768)
        static let preferredContentSize = CGSize(width: 375, height: 360)
        static let margin: CGFloat = 28
        static let contentTopMargin: CGFloat = 24
        static let topMargin: CGFloat = 40
        static let cornerRadius: CGFloat = 6
        static let clickButtonHeight: CGFloat = 48
    }
}
