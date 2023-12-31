//
//  QRLoginViewModel.swift
//  LarkAccount
//
//  Created by Miaoqi Wang on 2021/1/18.
//

import Foundation
import RxSwift
import RxCocoa
import LarkEnv
import LarkContainer

/// 新账号模型二维码轮询状态
enum QRLoginStatus: Int, Codable {
    case enterPolling = 0
    case notScanned = 1         // 扫码端未扫码
    case notConfirmed = 2       // 扫码端扫码后，未确认
    case cancelled = 3          // 扫码端扫码后，取消
    case failed = 4             // 扫码端扫码错误，通知被扫端
    case tokenExpired = 5       // token 过期
}

enum QRImageType {
    case scan(content: String, needRefresh: Bool = false)
    case confirm(content: String, avatarUrl: String)
}

class QRLoginViewModel: V3ViewModel {

    let registEnable: Bool

    var state: QRLoginStatus = .enterPolling

    private let token: String
    @Provider var api: LoginAPI
    let disposeBag: DisposeBag = DisposeBag()
    private weak var latestPollingRequest: LoginRequest<V3.Step>?
    var qrCodeString: String {
        qrCodeString(token: token)
    }

    var needKeepLoginTip: Bool {
        return PassportSwitch.shared.value(.keepLoginOption)
    }

    var needUpdateImage: BehaviorRelay<QRImageType> = .init(value: .scan(content: ""))
    var needRefreshQRCode: BehaviorRelay<Void> = .init(value: ())

    init(token: String, registEnable: Bool, context: UniContextProtocol) {
        self.token = token
        self.registEnable = registEnable
        super.init(step: "", stepInfo: PlaceholderServerInfo(), context: context)
    }

    func verifyPolling(startEnterApp: @escaping () -> Void) -> Observable<Void> {
        return Observable
            .create { [weak self] (observer) -> Disposable in
                guard let self = self else { return Disposables.create() }
                self.pollingWork(observer: observer, startEnterApp: startEnterApp)
                return Disposables.create()
            }
            .do(onError: { [weak self] _ in
                guard let self = self else { return }
                self.needRefreshQRCode.accept(())
            })
                }
    
    private func handleQRLoginStatus(_ status: QRLoginStatus, user: V4ResponseUser?, observer: AnyObserver<Void>, startEnterApp: @escaping () -> Void) {
        state = status
        switch status {
        case .notScanned:
            self.pollingWork(observer: observer, startEnterApp: startEnterApp)
        case .cancelled, .tokenExpired:
            self.needRefreshQRCode.accept(())
        case .notConfirmed:
            self.pollingWork(observer: observer, startEnterApp: startEnterApp)
            guard let user = user else {
                Self.logger.error("notConfirmed: no user to confirm")
                observer.onError(V3LoginError.badServerData)
                return
            }
            self.needUpdateImage.accept(.confirm(content: self.qrCodeString, avatarUrl: user.avatarURL))
        case .failed:
            Self.logger.error("failed: no user to confirm")
            self.needRefreshQRCode.accept(())
        case .enterPolling:
            Self.logger.error("should not have this status")
        }
    }
    
    private func pollingWork(observer: AnyObserver<Void>, startEnterApp: @escaping () -> Void) {
        let (observable, request) = api.qrLoginPolling()
        latestPollingRequest = request
        observable
            .subscribe(onNext: { [weak self] result in
                guard let self = self else { return }
                let step = result.stepData.stepInfo
                guard let data = try? JSONSerialization.data(withJSONObject: step, options: .prettyPrinted) else {
                    Self.logger.error("PassportStep: can not get pageInfo from none jsonDic)")
                    return
                }
                
                if let info = try? JSONDecoder().decode(QRCodeLoginInfo.self, from: data) {
                    self.handleQRLoginStatus(info.status, user: info.user, observer: observer, startEnterApp: startEnterApp)
                    return
                }
                if let info = try? JSONDecoder().decode(V4EnterAppInfo.self, from: data) {
                    startEnterApp()
                    
                    var context = UniContextCreator.create(.authorization)
                    
                    self.service.enterAppDidCall(
                        enterAppInfo: info,
                        sceneInfo: [:],
                        success: {
                            observer.onCompleted()
                        },
                        error: { error in
                            observer.onError(error)
                        }, context: context
                    )
                    return
                }
                
                Self.logger.error("PassportStep: can not get pageInfo from none jsonDic)")
                
            }, onError: { (error) in
                observer.onError(error)
            })
            .disposed(by: self.disposeBag)
    }

    func refreshCode(success: @escaping () -> Void, onError: @escaping (Error) -> Void) {
        api.qrLoginInit().subscribe { [weak self] result in
            guard let self = self else { return }
            let step = result.stepData.stepInfo
            guard let data = try? JSONSerialization.data(withJSONObject: step, options: .prettyPrinted),
                  let info = try? JSONDecoder().decode(QRCodeLoginInfo.self, from: data) else {
                Self.logger.error("PassportStep: can not get pageInfo from none jsonDic)")
                return
            }
            self.needUpdateImage.accept(.scan(content: self.qrCodeString(token: info.token)))
            success()
        } onError: { (error) in
            onError(error)
        }.disposed(by: disposeBag)
    }

    func fetchPrepareTenantInfo() -> Observable<Void> {
        Self.logger.info("do prepare tenant")
        return api.fetchPrepareTenantInfo(context: context).post(context: context)
    }

    func qrCodeString(token: String) -> String {
        let contentDict = [
            "qrlogin": [
                "token": token
            ]
        ]
        return contentDict.jsonString()
    }

    func cancelPollingRequest() {
        latestPollingRequest?.cancelTask()
        latestPollingRequest = nil
    }
}
