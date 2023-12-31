//
//  ImportExchangeViewModel.swift
//  Calendar
//
//  Created by Rico on 2021/3/9.
//

import Foundation
import RxRelay
import RxSwift
import ServerPB
import LarkContainer
import LarkRustClient
import LKCommonsLogging

final class ImportExchangeViewModel: UserResolverWrapper {

    typealias BindExchangeReslut = (Result<Void, Never>) -> Void

    let userResolver: UserResolver
    @ScopedInjectedLazy var rustService: RustService?

    let emailAddress: BehaviorRelay<String>
    let password = BehaviorRelay(value: "")
    let serverUrl = BehaviorRelay(value: "")
    let loginLoading = BehaviorRelay(value: false)
    let loginResult = PublishSubject<Result<LoginSuccess, LoginError>>()
    let loginEnabled: Observable<Bool>
    let resultCallback: BindExchangeReslut?
    private let disposeBag = DisposeBag()
    private let logger = Logger.log(ImportExchangeViewModel.self, category: "calendar.ImportExchangeViewModel")
    private(set) var helpUrl: URL?

    init(userResolver: UserResolver, defaultEmail: String = "", resultCallback: BindExchangeReslut?) {
        self.userResolver = userResolver
        self.emailAddress = BehaviorRelay(value: defaultEmail)
        loginEnabled = Observable
            .combineLatest(emailAddress, password)
            .map { !$0.isEmpty && !$1.isEmpty }
        self.resultCallback = resultCallback
    }

    // MARK: - Public
    func login() {
        self.loginLoading.accept(true)

        _login()
            .do(onNext: { [weak self] _ in
            self?.loginLoading.accept(false)
        }).subscribe(onNext: {[weak self] next in
            self?.loginResult.onNext(next)
        }).disposed(by: disposeBag)
    }

    // MARK: - Private

    private func _login() -> Observable<Result<LoginSuccess, LoginError>> {
        let email = self.emailAddress.value
        let password = self.password.value
        let serverUrl = self.serverUrl.value

        guard email.isEmailAddress() else {
            return .just(.failure(.emailInvalid))
        }

        return bindExchangeAccount(email: email, password: password, serverUrl: serverUrl)
    }
}

extension ImportExchangeViewModel {
    private func bindExchangeAccount(email: String, password: String, serverUrl: String? = nil) -> Observable<Result<LoginSuccess, LoginError>> {

        guard let base64Pwd = password.data(using: .utf8)?.base64EncodedString(),
              let rustService = self.rustService else {
            assertionFailure("exchange password base64 encode failed")
            logger.error("exchange password base64 encode failed")
            return .just(.failure(.unknown))
        }
        var request = ServerPB_Calendars_BindingExchangeAccountRequest()
        request.exchangeAccount = email
        request.exchangePassword = base64Pwd
        if let serverUrl = serverUrl, !serverUrl.isEmpty { request.serverURL = serverUrl }
        guard let rustService = self.rustService else { return .empty() }
        return Observable.create { (observer) -> Disposable in
            return rustService
                .sendPassThroughAsyncRequest(request, serCommand: .bindingExchangeAccount, transform: { (response: ServerPB_Calendars_BindingExchangeAccountResponse) -> ServerPB_Calendars_BindingExchangeAccountResponse.State in
                    self.logger.info("respState: \(response.respState)")
                    return response.respState
                }).subscribe { (state) in
                    switch state {
                    case .bindingSuccess: observer.onNext(.success(.bindSuccess))
                    case .unauthorized: observer.onNext(.failure(.userNotAuthorized))
                    case .communicationFailed: observer.onNext(.failure(.serverUrlNotConnectable))
                    case .needServerURL:
                        observer.onNext(.failure(.serverUrlNotExist))
                        self.helpUrl = URL(string: SettingService.shared().settingExtension.exchangeHelperUrl)
                    case .unknownError: observer.onNext(.failure(.unknown))
                    case .forbiddentError:
                        observer.onNext(.failure(.forbidden))
                        self.helpUrl = URL(string: SettingService.shared().settingExtension.outlookHelperUrl)
                    case .alreadyBindingSelf: observer.onNext(.success(.alreadyBinded))
                    @unknown default:
                        break
                    }
                    observer.onCompleted()
                } onError: { error in
                    self.logger.error("bindExchangeAccount error: \(error)")
                    observer.onNext(.failure(.unknown))
                    observer.onCompleted()
                }
        }
    }
}

extension ImportExchangeViewModel {

    enum LoginSuccess {
        case bindSuccess
        case alreadyBinded
    }

    enum LoginError: Error {
        case unknown
        case serverUrlNotExist
        case serverUrlNotConnectable
        case userNotAuthorized
        case emailInvalid
        case forbidden
    }
}
