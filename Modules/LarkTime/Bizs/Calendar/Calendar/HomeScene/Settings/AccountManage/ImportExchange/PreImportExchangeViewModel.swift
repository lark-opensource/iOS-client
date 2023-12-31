//
//  PreImportExchangeViewModel.swift
//  Calendar
//
//  Created by tuwenbo on 2022/8/9.
//

import Foundation
import RxRelay
import RxSwift
import ServerPB
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import CalendarFoundation

final class PreImportExchangeViewModel: UserResolverWrapper {

    typealias DiscoveryExchangeAccountResult = (Result<Void, Never>) -> Void

    @ScopedInjectedLazy var rustService: RustService?

    let userResolver: UserResolver

    let emailAddress: BehaviorRelay<String>
    let nextEnabled: Observable<Bool>
    let nextLoading = BehaviorRelay(value: false)
    let discoveryResult = PublishSubject<Result<DiscoveryExchangeAccountSuccess, DiscoveryExchangeAccountError>>()

    let resultCallback: DiscoveryExchangeAccountResult?

    private let disposeBag = DisposeBag()
    private let logger = Logger.log(PreImportExchangeViewModel.self, category: "calendar.PreImportExchangeViewModel")

    init(userResolver: UserResolver, defaultEmail: String = "", resultCallback: DiscoveryExchangeAccountResult?) {
        self.userResolver = userResolver
        self.emailAddress = BehaviorRelay(value: defaultEmail)
        self.nextEnabled = emailAddress.map {
            !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
        self.resultCallback = resultCallback
    }

    func goNext() {
        self.nextLoading.accept(true)
        _goNext()
            .do(onNext: {[weak self] _ in
                self?.nextLoading.accept(false)
            }).subscribe(onNext: { [weak self] next in
                self?.discoveryResult.onNext(next)
            }).disposed(by: disposeBag)
    }

    private func _goNext() -> Observable<Result<DiscoveryExchangeAccountSuccess, DiscoveryExchangeAccountError>> {
        let email = self.emailAddress.value
        guard email.isEmailAddress() else {
            return .just(.failure(.emailInvalid))
        }
        return discoverExchangeAccount(email: email)
    }
}

extension PreImportExchangeViewModel {
    private func discoverExchangeAccount(email: String) -> Observable<Result<DiscoveryExchangeAccountSuccess, DiscoveryExchangeAccountError>> {
        return Observable.create {[weak self] (observer) -> Disposable in
            guard let `self` = self, let rustService = self.rustService else { return Disposables.create() }
            var request = ServerPB_Calendar_external_DiscoveryExchangeAccountTypeRequest()
            request.exchangeAccount = email.trimmingCharacters(in: .whitespacesAndNewlines)
            return rustService.sendPassThroughAsyncRequest(request,
                                                           serCommand: .discoveryExchangeAccountType)
                .subscribe(onNext: { (response: ServerPB_Calendar_external_DiscoveryExchangeAccountTypeResponse) in
                    if response.mayHaveOauth && !response.exchangeAuthURL.isEmpty {
                        observer.onNext(.success(.mayHaveOAuth(response.exchangeAuthURL)))
                    } else {
                        observer.onNext(.success(.noOAuth))
                    }
                    observer.onCompleted()
                }, onError: { _ in
                    observer.onNext(.failure(.unknown))
                    observer.onCompleted()
                })
        }
    }
}

extension PreImportExchangeViewModel {
    enum DiscoveryExchangeAccountSuccess {
        case mayHaveOAuth(String) // 可能支持 OAuth，跳转到浏览器打开 OAuth 授权页面, 参数是 exchangeAuthUrl
        case noOAuth  // 不支持 OAuth，应跳转输密码页面
    }

    enum DiscoveryExchangeAccountError: Error {
        case unknown
        case emailInvalid
    }
}
