//
//  PasswordInputViewController.swift
//  SpaceKit
//
//  Created by liweiye on 2020/4/13.
//

import UIKit
import SnapKit
import RxCocoa
import RxSwift
import RxRelay
import SKResource
import SKFoundation
import SKUIKit
import UniverseDesignToast
import RoundedHUD
import SwiftyJSON
import SpaceInterface
import SKInfra

public final class PasswordInputViewController: UIViewController {
    private var inputPasswordForShareFolderRequest: DocsRequest<JSON>?
    private let disposeBag = DisposeBag()
    private let token: String
    private let type: DocsType
    private let isFolderV2: Bool
    private var passwordRequest: DocsRequest<JSON>?

    // Output
    public let unlockStateRelay = PublishRelay<Bool>()

    private(set) lazy var passwordView: PasswordHintView = {
        let view = PasswordHintView()
        view.configUI(promptLabelText: BundleI18n.SKResource.Doc_Permission_PleaseEnterPasswordAccess)
        return view
    }()

    deinit {
        DocsLogger.info("PasswordInputViewController -- deinit")
    }
    override public func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    public init(token: String,
                type: DocsType,
                isFolderV2: Bool = false) {
        self.token = token
        self.type = type
        self.isFolderV2 = isFolderV2
        super.init(nibName: nil, bundle: nil)
        setupPasswordViewHandler()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        view.addSubview(passwordView)
        passwordView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func setupPasswordViewHandler() {
        passwordView.passwordHandler = { [weak self] password in
            guard let self = self else { return }
            if self.isFolderV2 {
                self.inputPasswordForShareFolder(password: password)
            } else {
                self.submitPassword(with: password) { [weak self] unlockResult in
                    guard let self = self else { return }
                    switch unlockResult {
                    case .success(let isUnlock):
                        self.unlockStateRelay.accept(isUnlock)
                        if !isUnlock {
                            // 显示密码错误的UI
                            self.passwordView.showPasswordError()
                        }
                    case .failure(let error):
                        self.handleError(error)
                    }
                }
            }
        }
    }

    private func handleError(_ error: Error) {
        guard let erroeCode = (error as? DocsNetworkError)?.code else {
            DocsLogger.error("unkonw error, error: \(error)")
            showFailure(content: BundleI18n.SKResource.Doc_Facade_OperateFailed)
            return
        }
        switch erroeCode {
        case .errorReachedLimit:
            // 密码错误次数已达上限
            showFailure(content: BundleI18n.SKResource.Doc_Permission_PasswordErrorLimitTips)
        default:
            // 网络错误
            showFailure(content: BundleI18n.SKResource.Doc_Doc_NetException)
            DocsLogger.error("handleError: \(error)")
        }
    }

    private func showFailure(content: String) {
        guard let window = view.window else { return }
        UDToast.showFailure(with: content, on: window)
    }
    
    private func inputPasswordForShareFolder(password: String) {
        let token = self.token
        let type = self.type.rawValue
        inputPasswordForShareFolderRequest = PermissionManager.inputPasswordForShareFolder(
            token: token,
            type: type,
            password: password) { [weak self] (success, code, error) in
            guard let self = self else { return }
            if success {
                self.unlockStateRelay.accept(true)
            } else {
                // 密码错误
                if code == DocsNetworkError.Code.wrongPassword.rawValue {
                    self.passwordView.showPasswordError()
                } else {
                    if let error = error {
                        self.handleError(error)
                    } else {
                        self.showFailure(content: BundleI18n.SKResource.Doc_Facade_OperateFailed)
                    }
                }
            }
        }
    }
    
    private func submitPassword(with password: String, completionHandler: @escaping (Result<Bool, Error>) -> Void) {
        passwordRequest?.cancel()
        let params: [String: Any] = ["token": token,
                                     "type": type.rawValue,
                                     "password": password]
        passwordRequest = DocsRequest<JSON>(path: OpenAPI.APIPath.suitePermissionPasswordInput, params: params)
            .set(method: .POST)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)
            .start(result: { json, error in
                if let error = error {
                    DocsLogger.error("submitPassword failed!", extraInfo: nil, error: error, component: nil)
                    guard (error as? URLError)?.errorCode != NSURLErrorCancelled else { return }
                    completionHandler(.failure(error))
                    return
                }
                guard let json = json,
                    let code = json["code"].int else {
                        completionHandler(.failure(DocsNetworkError.invalidData))
                        DocsLogger.error("submitPassword invalidData!", extraInfo: nil, error: error, component: nil)
                        return
                }
                if code == 0 {
                    completionHandler(.success(true))
                    return
                } else {
                    /// 密码错误
                    if code == DocsNetworkError.Code.wrongPassword.rawValue {
                        completionHandler(.success(false))
                        return
                    }
                    var error: Error
                    if let networkError = DocsNetworkError(code) {
                        error = networkError
                    } else {
                        error = PasswordSettingNetworkError.submitFailed
                    }
                    completionHandler(.failure(error))
                }
        })
    }
}
