//
//  LocationNavigateViewController.swift
//  LarkChat
//
//  Created by Fangzhou Liu on 2019/6/10.
//

import UIKit
import Foundation
import CoreLocation
import LarkUIKit
import LarkMessengerInterface
import LKCommonsLogging
import EENavigator
import RxSwift
import SnapKit
import LarkLocationPicker
import UniverseDesignToast
import UniverseDesignActionPanel
import LarkCoreLocation
import LarkSensitivityControl
import LarkContainer

final class LocationNavigateViewController: OpenLocationController, UserResolverWrapper {
    let userResolver: UserResolver
    private let viewModel: LocationNavigateViewModel
    private let disposeBag: DisposeBag = DisposeBag()
    private static let logger = Logger.log(LocationNavigateViewController.self, category: "LarkChat.LocationNavigateViewController")
    private var locationAuth: LocationAuthorization?
    private let sensitivityToken: Token

    init(
        userResolver: UserResolver,
        viewModel: LocationNavigateViewModel,
        forToken: Token = Token("LARK-PSDA-LocationNavigate-requestLocationAuthorization", type: .location),
        authorization: LocationAuthorization? = nil) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.sensitivityToken = forToken
        self.locationAuth = authorization
        let name =
        self.viewModel.content.location.name.isEmpty ?
        BundleI18n.LarkChat.Lark_Chat_MessageReplyStatusLocation("") :
        self.viewModel.content.location.name
        let setting = LocationSetting(
            name: name,
            description: self.viewModel.content.location.description_p,
            center: CLLocationCoordinate2D(
                latitude: NSString(string: self.viewModel.content.latitude).doubleValue,
                longitude: NSString(string: self.viewModel.content.longitude).doubleValue
            ),
            zoomLevel: Double(self.viewModel.content.zoomLevel),
            isCrypto: self.viewModel.isCrypto,
            isInternal: self.viewModel.content.isInternal,
            defaultAnnotation: true,
            needRightBtn: true
        )
        super.init(forToken: forToken, setting: setting, authorization: authorization)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func rightItemClicked(sender: UIControl) {
        showMoreItemsSheet(sender: sender)
        super.rightItemClicked(sender: sender)
    }

    override func navigateClicked() {
        ChatTracker.trackChatNavigationClick()
        super.navigateClicked()
    }
}

extension LocationNavigateViewController {
    /// Pop出收藏/转发的ActionSheet
    private func showMoreItemsSheet(sender: UIControl) {
        guard let buttonView = sender as? UIView else {
            return
        }
        let udActionSheet = UDActionSheet(
            config: UDActionSheetUIConfig(
                isShowTitle: false,
                popSource: UDActionSheetSource(
                    sourceView: buttonView,
                    sourceRect: CGRect(x: buttonView.bounds.width / 2, y: buttonView.bounds.height, width: 0, height: 0),
                    arrowDirection: .up)))
        /// 转发
        udActionSheet.addDefaultItem(text: BundleI18n.LarkChat.Lark_Legacy_MenuForward) { [weak self] in
            guard let `self` = self else { return }
            ChatTracker.trackChatShareClick()
            self.navigator.present(
                body: self.viewModel.createForwardBody(),
                from: self,
                prepare: { $0.modalPresentationStyle = .fullScreen })
        }

        switch viewModel.source {
        case .common:
            /// 收藏
            udActionSheet.addDefaultItem(text: BundleI18n.LarkChat.Lark_Legacy_AddToFavorite) { [weak self] in
                guard let `self` = self else { return }
                ChatTracker.trackChatShareClick()
                let hud = UDToast.showLoading(with: BundleI18n.LarkChat.Lark_Legacy_BaseUiLoading, on: self.view, disableUserInteraction: true)
                self.viewModel.createObservableFavorites()
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { [weak self] _ in
                        if let self = self {
                            hud.showSuccess(with: BundleI18n.LarkChat.Lark_Legacy_ChatViewFavorites, on: self.view)
                        }
                    }, onError: { [weak self] error in
                        if let self = self {
                            hud.showFailure(
                                with: BundleI18n.LarkChat.Lark_Legacy_SaveFavoriteFail,
                                on: self.view,
                                error: error
                            )
                        }
                    }).disposed(by: self.disposeBag)
            }
        case .favorite:
            /// 取消收藏
            udActionSheet.addDefaultItem(text: BundleI18n.LarkChat.Lark_Legacy_Remove) { [weak self] in
                guard let `self` = self else { return }
                ChatTracker.trackChatShareClick()
                let hud = UDToast.showLoading(on: self.view, disableUserInteraction: true)
                self.viewModel.deleteObservableFavorites()
                    .observeOn(MainScheduler.instance)
                    .subscribe(onNext: { (_) in
                        hud.remove()
                        self.navigationController?.popViewController(animated: true)
                    }, onError: { [weak self] (error) in
                        Self.logger.error("delete favorite failed", error: error)
                        if let view = self?.view {
                            hud.showFailure(with: BundleI18n.LarkChat.Lark_Legacy_SaveBoxDeleteFail, on: view, error: error)
                        }
                    })
                    .disposed(by: self.disposeBag)
            }
        }
        /// 取消
        udActionSheet.setCancelItem(text: BundleI18n.LarkChat.Lark_Legacy_Cancel)
        self.present(udActionSheet, animated: true, completion: nil)
    }
}
