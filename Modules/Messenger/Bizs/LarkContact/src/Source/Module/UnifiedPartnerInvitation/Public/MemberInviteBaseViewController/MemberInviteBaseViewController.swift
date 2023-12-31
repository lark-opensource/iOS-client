//
//  MemberInviteBaseViewController.swift
//  LarkContact
//
//  Created by shizhengyu on 2021/4/7.
//

import Foundation
import LarkUIKit
import LarkSnsShare
import LarkContainer
import LarkMessengerInterface
import RustPB
import RxSwift
import UniverseDesignToast
import UniverseDesignTheme
import QRCode
import LarkAccountInterface
import ByteWebImage
import UIKit

class MemberInviteBaseViewController: BaseUIViewController, UserResolverWrapper {
    @ScopedProvider var inAppShareService: InAppShareService?
    @ScopedProvider var snsShareService: LarkShareService?
    private(set) var inviteInfo: InviteAggregationInfo?
    var userResolver: LarkContainer.UserResolver
    private lazy var memberAPI: MemberInviteAPI = {
        return MemberInviteAPI(resolver: self.userResolver)
    }()
    private lazy var currentUserId: String = {
        return self.userResolver.userID
    }()
    private var templateConfig: TemplateConfiguration {
        var imageOptions = Contact_V1_ImageOptions()
        imageOptions.resolutionType = .highDefinition
        var isDarkMode = false
        if #available(iOS 13.0, *) {
            isDarkMode = UDThemeManager.getRealUserInterfaceStyle() == .dark
        }
        return TemplateConfiguration(
            bizScenario: isDarkMode ? .teamQrcardDark : .teamQrcardLight,
            imageOptions: imageOptions
        )
    }
    private lazy var exporter: DynamicRenderingTemplateExporter = {
        return DynamicRenderingTemplateExporter(
            templateConfiguration: templateConfig,
            extraOverlayViews: [:],
            resolver: userResolver
        )
    }()
    private var extraOverlayViews: [OverlayViewType: UIView]? {
        didSet {
            exporter.updateExtraOverlayViews(self.extraOverlayViews ?? [:])
        }
    }
    var exportDisposable: Disposable?
    let disposeBag = DisposeBag()

    init(resolver: UserResolver) {
        self.userResolver = resolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func fetchInviteLinkInfo(forceRefresh: Bool = false, departments: [String] = []) -> Observable<InviteAggregationInfo> {
        let hud = UDToast.showLoading(on: view)
        return memberAPI
            .fetchInviteAggregationInfo(forceRefresh: forceRefresh, departments: departments)
            .timeout(.seconds(5), scheduler: MainScheduler.instance)
            .do(onNext: { [weak self] (inviteInfo) in
                self?.inviteInfo = inviteInfo
                self?.genConstantOverlayViews(by: inviteInfo)
                self?.updateTemplateConfig(with: inviteInfo)
                hud.remove()
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                if forceRefresh {
                    guard let err = error as? MemberInviteAPI.WrapError else { return }
                    switch err {
                    case .buzError(let displayMsg):
                        UDToast.showTips(with: displayMsg, on: self.view)
                    default: break
                    }
                } else {
                    self.retryLoadingView.isHidden = false
                }
                hud.remove()
            }, onDispose: {
                hud.remove()
            })
    }

    func downloadRendedImageIfNeeded() -> Observable<UIImage> {
        guard extraOverlayViews != nil else { return .error(DynamicResourceExportError.unknownError(logMsg: "extraOverlayView is empty")) }
        exportDisposable?.dispose()

        let hud = UDToast.showLoading(on: view)
        return exporter.export()
            .observeOn(MainScheduler.instance)
            .timeout(.seconds(10), scheduler: MainScheduler.instance)
            .do(onNext: { _ in
                hud.remove()
            }, onError: { (_) in
                hud.remove()
            })
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if let inviteInfo = inviteInfo {
            updateTemplateConfig(with: inviteInfo)
        }
    }
}

private extension MemberInviteBaseViewController {
    func genConstantOverlayViews(by info: InviteAggregationInfo) {
        guard let memberExtraInfo = info.memberExtraInfo else { return }

        let userAvatarContentSize = CGSize(width: 100, height: 100)
        let qrcodeContentSize = CGSize(width: 200, height: 200)
        let teamAvatarContentSize = CGSize(width: 100, height: 100)

        // 个人头像
        let avatarView = UIImageView()
        avatarView.contentMode = .scaleAspectFill
        avatarView.frame = CGRect(x: 0, y: 0, width: userAvatarContentSize.width, height: userAvatarContentSize.height)
        /// 这里先读取小头像作为占位图，防止保存时出现空白区域
        avatarView.bt.setLarkImage(with: .avatar(key: info.avatarKey, entityID: currentUserId),
         trackStart: {
             TrackInfo(scene: .Profile, fromType: .avatar)
         },
         completion: { [weak avatarView, weak self] _ in
            guard let `self` = self else { return }
            avatarView?.bt.setLarkImage(with: .avatar(key: info.avatarKey, entityID: self.currentUserId, params: .defaultBig),
             trackStart: {
                 TrackInfo(scene: .Profile, fromType: .avatar)
             })
         })

        // 团队头像
        let teamLogoView = UIImageView()
        teamLogoView.frame = CGRect(x: 0, y: 0, width: teamAvatarContentSize.width, height: teamAvatarContentSize.height)
        teamLogoView.contentMode = .scaleAspectFill
        teamLogoView.bt.setLarkImage(with: .default(key: memberExtraInfo.teamLogoURL))

        // 二维码视图
        let qrcodeView = UIImageView()
        qrcodeView.frame = CGRect(x: 0, y: 0, width: qrcodeContentSize.width, height: qrcodeContentSize.height)
        qrcodeView.contentMode = .scaleAspectFill
        qrcodeView.image = QRCodeTool.createQRImg(str: memberExtraInfo.urlForQRCode, size: qrcodeContentSize.width)

        extraOverlayViews = [OverlayViewType.userAvatar: avatarView,
                             OverlayViewType.teamCodeQr: qrcodeView,
                             OverlayViewType.tenantAvatar: teamLogoView]
    }

    func updateTemplateConfig(with info: InviteAggregationInfo) {
        guard let teamcode = info.memberExtraInfo?.teamCode else {
            return
        }

        let expireDate = BundleI18n.LarkContact.Lark_AdminUpdate_Subtitle_MobileQRCodeExpire(info.memberExtraInfo?.expireDateDesc ?? "")
        let replacer = [
            "{{USER_NAME}}": info.name,
            "{{TENANT_NAME}}": info.tenantName,
            "{{TEAM_CODE}}": teamcode,
            "{{EXPIRE_DATE}}": expireDate
        ]
        var new = templateConfig
        new.textContentReplacer = replacer
        exporter.updateTemplateConfiguration(new)
    }
}
