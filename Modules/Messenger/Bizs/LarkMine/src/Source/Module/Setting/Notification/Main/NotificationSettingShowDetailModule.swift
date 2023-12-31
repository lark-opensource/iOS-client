//
//  NotificationSettingShowDetailModule.swift
//  LarkMine
//
//  Created by panbinghua on 2022/6/27.
//

import UIKit
import Foundation
import EENavigator
import LarkContainer
import LarkMessengerInterface
import Swinject
import LarkSDKInterface
import RustPB
import RxSwift
import RxCocoa
import UniverseDesignToast
import UniverseDesignDialog
import LarkOpenSetting
import LarkStorage
import LarkSettingUI

final class NotificationSettingShowDetailModule: BaseModule {

    private var userGeneralSettings: UserGeneralSettings?

    static let userStore = \NotificationSettingShowDetailModule._userStore

    @KVBinding(to: userStore, key: KVKeys.SettingStore.Notification.showMessageDetail)
    private var showMessageDetail: Bool

    @KVBinding(to: userStore, key: KVKeys.SettingStore.Notification.adminCloseShowDetail)
    private var adminCloseShowDetail: Bool

    override init(userResolver: UserResolver) {
        super.init(userResolver: userResolver)

        self.userGeneralSettings = try? self.userResolver.resolve(assert: UserGeneralSettings.self)

        self.onRegisterDequeueViews = { tableView in
            tableView.register(Footer.self, forHeaderFooterViewReuseIdentifier: Footer.identifier)
        }
        self.fetchRemoteNotificationDetailSettings()
    }

    private func fetchRemoteNotificationDetailSettings() {
        self.userGeneralSettings?.fetchRemoteSettingFromServer { [weak self] (isShowDetail, _, adminCloseShowDetail) in
            guard let `self` = self else { return }
            SettingLoggerService.logger(.module(self.key)).info("api/get/res: ok, isShowDetail: \(isShowDetail)")
            if self.showMessageDetail != isShowDetail || self.adminCloseShowDetail != adminCloseShowDetail {
                self.showMessageDetail = isShowDetail
                self.adminCloseShowDetail = adminCloseShowDetail
                self.context?.reload()
            }
        }
    }

    override func createSectionProp(_ key: String) -> SectionProp? {
        let detail: String? = self.adminCloseShowDetail ? BundleI18n.LarkMine.Lark_NotificationPreviewSettings_AdminDisabledPreviewDesc : nil
        let item = SwitchNormalCellProp(
            title: BundleI18n.LarkMine.Lark_NewSettings_BannerNotificationMessageDetailMobile,
            detail: detail,
            isOn: self.showMessageDetail && !self.adminCloseShowDetail,
            isEnabled: !self.adminCloseShowDetail) { [weak self] _, isOn in
                self?.updateRemoteNotificationDetailSettings(isShowDetail: isOn)
        }
        return SectionProp(items: [item], footer: .prop(Footer.Prop(showMessageDetail: showMessageDetail && !adminCloseShowDetail)))
    }

    /// 设置通知栏显示消息详情
    private func updateRemoteNotificationDetailSettings(isShowDetail: Bool) {
        self.showMessageDetail = isShowDetail
        self.context?.reload()
        let logger = SettingLoggerService.logger(.module(self.key))
        self.userGeneralSettings?
            .updateRemoteSetting(isShowDetail: isShowDetail, success: {
                logger.info("api/set/req: isShowDetail: \(isShowDetail); res: ok")
            }, failure: { [weak self] (error) in
                guard let self = self, let vc = self.context?.vc else { return }
                let alertController = UDDialog()
                alertController.setTitle(text: BundleI18n.LarkMine.Lark_Legacy_Hint)
                alertController.setContent(text: BundleI18n.LarkMine.Lark_Legacy_MineMessageSettingSetupFailed)
                alertController.addPrimaryButton(text: BundleI18n.LarkMine.Lark_Legacy_Sure)
                self.userResolver.navigator.present(alertController, from: vc)
                self.showMessageDetail = isShowDetail // 回滚
                self.context?.reload()
                logger.error("api/set/req: isShowDetail: \(isShowDetail); res: error: \(error)")
            })
    }

    final class Footer: BaseHeaderFooterView {

        static let identifier = "NotificationSettingShowDetailModule.Footer"

        final class Prop: HeaderFooterProp {
            var showMessageDetail: Bool
            init(showMessageDetail: Bool) {
                self.showMessageDetail = showMessageDetail
                super.init(identifier: Footer.identifier)
            }
        }

        let previewDetail = UILabel()
        let detailLabel: UILabel = UILabel()
        override func update(_ info: HeaderFooterProp) {
            super.update(info)
            guard let info = info as? Prop else { return }
            detailLabel.text = info.showMessageDetail ?
                BundleI18n.LarkMine.Lark_NewSettings_BannerNotificationPreviewOnDescriptionMobile :
                BundleI18n.LarkMine.Lark_NewSettings_BannerNotificationPreviewOffDescriptionMobile
            previewDetail.text = info.showMessageDetail ?
                BundleI18n.LarkMine.Lark_Settings_Badgestylepicturepreviewg :
                BundleI18n.LarkMine.Lark_Legacy_NewMessage
        }

        override init(reuseIdentifier: String?) {
            super.init(reuseIdentifier: reuseIdentifier)
            let previewBGView = UIView()
            previewBGView.layer.cornerRadius = 5
            previewBGView.ud.setLayerBorderColor(UIColor.ud.lineBorderCard)
            previewBGView.layer.borderWidth = 0.5
            previewBGView.backgroundColor = UIColor.ud.bgFloat
            previewBGView.layer.shadowColor = UIColor.ud.staticBlack.withAlphaComponent(0.06).cgColor
            previewBGView.layer.shadowOpacity = 1
            previewBGView.layer.shadowRadius = 5
            contentView.addSubview(previewBGView)
            previewBGView.snp.makeConstraints { (make) in
                make.width.equalTo(138)
                make.top.equalTo(8)
                make.right.equalToSuperview()
                make.bottom.equalTo(-4)
            }

            let previewIcon = UIImageView(image: Resources.ios_icon)
            previewIcon.layer.minificationFilter = .trilinear
            previewBGView.addSubview(previewIcon)
            previewIcon.snp.makeConstraints { (make) in
                make.width.height.equalTo(14)
                make.left.equalTo(10)
                make.top.equalTo(5)
            }
            let previewTitle = UILabel()
            previewTitle.numberOfLines = 1
            previewTitle.text = BundleI18n.bundleDisplayName
            previewTitle.font = UIFont.systemFont(ofSize: 11)
            previewTitle.textColor = UIColor.ud.textPlaceholder
            previewBGView.addSubview(previewTitle)
            previewTitle.snp.makeConstraints { (make) in
                make.centerY.equalTo(previewIcon.snp.centerY)
                make.left.equalTo(30)
                make.right.equalTo(-10)
            }
            let previewLine = UIView()
            previewLine.backgroundColor = UIColor.ud.lineDividerDefault
            previewBGView.addSubview(previewLine)
            previewLine.snp.makeConstraints { (make) in
                make.height.equalTo(0.5)
                make.top.equalTo(previewIcon.snp.bottom).offset(5)
                make.left.right.equalToSuperview()
            }

            previewDetail.numberOfLines = 0
            previewDetail.font = UIFont.systemFont(ofSize: 12)
            previewDetail.textColor = UIColor.ud.textPlaceholder
            previewBGView.addSubview(previewDetail)
            previewDetail.snp.makeConstraints { (make) in
                make.left.equalTo(8)
                make.right.bottom.equalTo(-8)
                make.top.equalTo(previewLine.snp.bottom).offset(8)
            }

            detailLabel.textColor = UIColor.ud.textPlaceholder
            detailLabel.font = UIFont.systemFont(ofSize: 14)
            detailLabel.numberOfLines = 0
            contentView.addSubview(detailLabel)
            detailLabel.snp.makeConstraints { (make) in
                make.left.equalTo(16)
                make.top.equalTo(4)
                make.bottom.lessThanOrEqualTo(-4)
                make.right.equalTo(previewBGView.snp.left).offset(-12)
            }
        }

        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
}
