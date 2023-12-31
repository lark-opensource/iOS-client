//
//  NoPermissionAuthViewModel.swift
//  LarkSecurityCompliance
//
//  Created by qingchun on 2022/4/14.
//

import Foundation
import LarkContainer
import RxSwift
import RxCocoa
import LarkAccountInterface
import EENavigator
import WebBrowser
import LarkFoundation
import LarkSecurityComplianceInfra

final class NoPermissionAuthViewModel: BaseViewModel, UserResolverWrapper {

    enum TextLink: String {
        case privacy
        case service
    }

    struct Model {
        let scheme: String
        let userID: String
        let webID: String
    }

    @ScopedProvider private var service: NoPermissionService?
    @ScopedProvider private var agreementService: AccountServiceAgreement? // Global
    private let bag = DisposeBag()
    private let http = DeviceManagerAPI()
    let model: Model
    let userResolver: LarkContainer.UserResolver

    var backClicked: Binder<Void> {
        return Binder(self) { [weak self] _, _ in
            self?.dismissVC.accept(())
        }
    }

    var checkboxClicked: Binder<Bool> {
        return Binder(self) { [weak self] _, result in
            self?.checkbox.accept(!result)
            Logger.info("click checkbox: \(result)")
        }
    }

    let checkbox = BehaviorRelay<Bool>(value: false)
    let textLinkClicked = PublishRelay<TextLink>()
    let denyButtonClicked = PublishRelay<Void>()
    let agreeClicked = PublishRelay<Void>()
    let showAgreeAlert = PublishRelay<Void>()
    let dismissVC = PublishRelay<Void>()

    init(resolver: UserResolver, scheme: String, webId: String, userId: String) throws {
        self.model = Model(scheme: scheme, userID: userId, webID: webId)
        self.userResolver = resolver
        super.init()
        setupServices()
    }

    // MARK: - Private

    private func setupServices() {
        textLinkClicked
            .subscribe { [weak self] textLink in
                self?.gotoPage(withType: textLink)
            }
            .disposed(by: bag)
        denyButtonClicked
            .bind { [weak self] in
                guard let `self` = self else { return }
                self.dismissVC.accept(())
                guard let schemeUrl = URL(string: self.model.scheme) else { return }
                UIApplication.shared.open(schemeUrl) { [weak self] success in
                    SCMonitor.info(business: .no_permission,
                                   eventName: "browser_redirect",
                                   category: ["scheme": self?.model.scheme ?? "",
                                              "status": success ? 0 : 1])
                }
            }
            .disposed(by: bag)
        agreeClicked
            .filter({ [weak self] in (self?.checkbox.value).isTrue })
            .flatMapLatest { [weak self] () -> Observable<BaseResponse<BindDeviceWebResp>?>  in
                guard let `self` = self else { return .just(nil) }
                return self.http.bindDeviceWeb(self.model.webID)
                    .map { $0 as BaseResponse<BindDeviceWebResp>? }
                    .catchErrorJustReturn(nil)
            }
            .observeOn(MainScheduler.instance)
            .bind { [weak self] _ in
                guard let `self` = self else { return }
                self.dismissVC.accept(())
                guard let schemeUrl = URL(string: self.model.scheme) else { return }
                UIApplication.shared.open(schemeUrl) { [weak self] success in
                    SCMonitor.info(business: .no_permission,
                                   eventName: "browser_redirect",
                                   category: ["scheme": self?.model.scheme ?? "",
                                              "status": success ? 0 : 1])
                }
            }
            .disposed(by: bag)
        agreeClicked
            .filter({ [weak self] in (self?.checkbox.value).isFalse })
            .bind(to: showAgreeAlert)
            .disposed(by: bag)
    }

    private func gotoPage(withType link: TextLink) {
        let url: URL?
        switch link {
        case .privacy:
            url = self.agreementService?.getAgreementURLWithPackageDomain(type: .privacy)
        case .service:
            url = self.agreementService?.getAgreementURLWithPackageDomain(type: .term)
        }
        guard let aURL = url, let from = coordinator else { return }
        let body = WebBody(url: aURL, webAppInfo: nil, hideShowMore: true)
        navigator.push(body: body, from: from)
    }
}
