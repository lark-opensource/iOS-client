//
//  FaceToFaceCreateGroupViewModel.swift
//  LarkContact
//
//  Created by 赵家琛 on 2021/1/8.
//

import UIKit
import Foundation
import LarkModel
import LarkSDKInterface
import RxSwift
import RxCocoa
import LarkContainer
import CoreLocation
import LKCommonsLogging
import RustPB
import LKCommonsTracker
import Homeric
import LarkCoreLocation
import LarkSetting
import LarkSensitivityControl

enum FaceToFaceProcessType {
    case locationAccessDenied // 无定位权限
    case verifySuccess([RustPB.Im_V1_FaceToFaceApplicant]) // 验证码验证成功
    case hasNewApplicants([RustPB.Im_V1_FaceToFaceApplicant]) // PUSH 新成员
    case requestFailure(String) // 请求失败
    case enableKeyboard(Bool) // 是否禁用键盘
    case hudStatusChanged(FaceToFaceHudStatus) // UDToast 展示
}

enum FaceToFaceHudStatus {
    case initHud
    case loadingHud
    case removeHud
    case showFailure(String)
}

final class FaceToFaceCreateGroupViewModel: NSObject, UserResolverWrapper {

    static let logger = Logger.log(FaceToFaceCreateGroupViewModel.self, category: "Module.Contact.FaceToFaceCreateGroupViewModel")
    var userResolver: LarkContainer.UserResolver
    private static let pattern = "^(\\d)\\1{3}|2580|0123|1234|2345|3456|4567|5678|6789|9876|8765|7654|6543|5432|4321|3210$"
    private static let regex = try? NSRegularExpression(pattern: pattern)

    struct FaceToFaceUserLocation {
        let latitude: String
        let longitude: String
    }

    let codeNumberLimit = 4
    private lazy var systemLocationFG: Bool = {
        return userResolver.fg.staticFeatureGatingValue(with: "messenger.location.force_original_system_location")
    }()

    /// 请求定位权限 PSDA管控Token
    private let locationAuthorizationToken: Token = Token("LARK-PSDA-FaceToFaceCreateGroup-requestLocationAuthorization", type: .location)
    /// 开始定位 PSDA管控Token
    private let startLocatingToken: Token = Token("LARK-PSDA-FaceToFaceCreateGroup-startUpdateLocation", type: .location)
    // VC 监听
    var processDriver: Driver<FaceToFaceProcessType> {
        return processPublish.asDriver(onErrorRecover: { _ in return .empty() })
    }
    private let processPublish: PublishSubject<FaceToFaceProcessType> = PublishSubject<FaceToFaceProcessType>()

    // Header View 监听
    var statusDriver: Driver<FaceToFaceHeadStatus> {
        return headStatus.asDriver(onErrorJustReturn: .showNumbers([]))
    }
    private let headStatus: BehaviorRelay<FaceToFaceHeadStatus> = BehaviorRelay<FaceToFaceHeadStatus>(value: .showNumbers([]))

    @ScopedInjectedLazy private var chatAPI: ChatAPI?
    private let disposeBag = DisposeBag()
    private lazy var locationManager: CLLocationManager = {
       var manager = CLLocationManager()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        return manager
    }()
    private var currentLocation: FaceToFaceUserLocation?
    private let locationPublish: PublishSubject<FaceToFaceUserLocation> = PublishSubject<FaceToFaceUserLocation>()
    // 验证码
    private var codeArray: [Int] = []
    // 入群 token
    private var token: String?
    // 验证申请 ID
    private var applicationId: String?
    // 监听 PUSH
    private let pushFaceToFaceApplicants: Observable<PushFaceToFaceApplicants>
    // 对 PUSH 过来的数据去重
    private var applicantSet: Set<Int> = []
    private let locationAuth: LocationAuthorization
    private let locationTask: SingleLocationTask
    init(pushFaceToFaceApplicants: Observable<PushFaceToFaceApplicants>, authorization: LocationAuthorization, locationTask: SingleLocationTask, resolver: UserResolver) {
        self.pushFaceToFaceApplicants = pushFaceToFaceApplicants
        self.locationAuth = authorization
        self.locationTask = locationTask
        self.userResolver = resolver
        super.init()

        locationTask.locationCompleteCallback = { [weak self] (task, result) in
            guard let `self` = self else { return }
            self.didUpdateCompleteLocations(task: task, result: result)
        }
        if !systemLocationFG {
            observeOnBecomeActive()
        }
    }

    private func observeOnBecomeActive() {
        NotificationCenter.default.rx.notification(UIApplication.didBecomeActiveNotification)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                if self.currentLocation == nil {
                    self.startUpdatingLocation()
                }
            })
            .disposed(by: disposeBag)
    }

    func startUpdatingLocation() {
        if systemLocationFG {
            Self.logger.info("FaceToFace,Start UseSystemLocation")
            useSystemRequestLocationAuthorization(manager: locationManager)
            useSystemStartUpdatingLocation(manager: locationManager)
        } else {
            do {
                Self.logger.info("FaceToFace,Start UseLocationModule")
                //开启请求定位
                locationAuth.requestWhenInUseAuthorization(forToken: locationAuthorizationToken, complete: didChangeAuthorization)
                try locationTask.resume(forToken: startLocatingToken)
            } catch {
                let msg = "FaceToFace,SingleLocationTask taskID: \(locationTask.taskID) resume failed, error is \(error)"
                Self.logger.info(msg)
            }
        }
    }

    private func useSystemRequestLocationAuthorization(manager: CLLocationManager) {
        do {
            try LocationEntry.requestWhenInUseAuthorization(forToken: locationAuthorizationToken, manager: manager)
        } catch let error {
            if let checkError = error as? CheckError {
                Self.logger.info("requestLocationAuthorization for locationEntry error \(checkError.description)")
            }
        }
    }

    private func useSystemStartUpdatingLocation(manager: CLLocationManager) {
        do {
            try LocationEntry.startUpdatingLocation(forToken: startLocatingToken, manager: manager)
        } catch let error {
            if let checkError = error as? CheckError {
                Self.logger.info("startUpdatingLocation for locationEntry error \(checkError.description)")
            }
        }
    }

    // 处理键盘点击事件
    func handleKeyboardAction(_ action: FaceToFaceKeyboardItemType) {
        switch action {
        case .delete:
            if !self.codeArray.isEmpty {
                self.codeArray.removeLast()
                self.headStatus.accept(.showNumbers(self.codeArray))
            }
        case .number(let code):
            if self.codeArray.count >= self.codeNumberLimit { return }
            self.codeArray.append(code)
            self.headStatus.accept(.showNumbers(self.codeArray))

            if self.codeArray.count == self.codeNumberLimit {
                // 开始验证
                if !self.verifyCodes(self.codeArray) {
                    self.codeArray = []
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        self.headStatus.accept(.showError(BundleI18n.LarkContact.Lark_NearbyGroup_ErrorTooSimple))
                    }
                    return
                }

                self.createApplication()
            }
        case .placeholder:
            assertionFailure()
        }
    }

    /// 验证码校验
    private func verifyCodes(_ codes: [Int]) -> Bool {
        var numberStr = ""
        codes.forEach { numberStr += "\($0)" }

        return Self.regex?.matches(numberStr).isEmpty ?? false
    }

    private func createLocationObservable() -> Observable<FaceToFaceUserLocation> {
        if let location = self.currentLocation {
            return Observable.create { (observer) -> Disposable in
                observer.onNext(FaceToFaceUserLocation(latitude: location.latitude, longitude: location.longitude))
                observer.onCompleted()
                return Disposables.create()
            }
        }
        return self.locationPublish.asObservable()
    }

    private func createApplication() {
        self.processPublish.onNext(.enableKeyboard(false))
        self.processPublish.onNext(.hudStatusChanged(.initHud))
        // 延迟 300 ms 展示 loading
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + .milliseconds(300)) {
            self.processPublish.onNext(.hudStatusChanged(.loadingHud))
        }
        /// 兜底逻辑， 防止不能及时获取位置信息，等待 5 秒
        self.createLocationObservable()
            .timeout(.seconds(5), scheduler: MainScheduler.instance)
            .subscribeOn(MainScheduler.instance)
            .do(onError: { [weak self] _ in
                guard let self = self else { return }
                self.processPublish.onNext(.locationAccessDenied)
            })
            .flatMap({ [weak self] (location) -> Observable<RustPB.Im_V1_CreateFaceToFaceApplicationResponse> in
                guard let self = self, let chatAPI = self.chatAPI else { return .empty() }
                var matchCode = 0
                self.codeArray.forEach { matchCode = matchCode * 10 + $0 }
                Self.logger.info("create application begin",
                                 additionalData: ["matchCode": "\(matchCode)",
                                                  "latitude": location.latitude,
                                                  "longitude": location.longitude]
                )
                return chatAPI
                    .createFaceToFaceApplication(
                        latitude: location.latitude,
                        longitude: location.longitude,
                        matchCode: Int32(matchCode)
                    )
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] response in
                guard let self = self else { return }
                self.token = response.token
                self.applicationId = response.applicationID
                let applicants = response.applicants.sorted(by: { $0.rank < $1.rank })
                self.applicantSet = Set(applicants.map { Int($0.userID) })

                self.headStatus.accept(.hideTips)
                self.processPublish.onNext(.verifySuccess(applicants))
                self.processPublish.onNext(.hudStatusChanged(.removeHud))
                self.observePush()
            }, onError: { [weak self] error in
                guard let self = self else { return }

                Self.logger.error("create application error: [verify code] \(self.codeArray)")
                self.codeArray = []
                self.headStatus.accept(.showNumbers(self.codeArray))
                self.processPublish.onNext(.enableKeyboard(true))

                if let apiError = error.underlyingError as? APIError {
                    switch apiError.type {
                    case .chatMemberHadFullForPay(message: let message), .chatMemberHadFullForCertificationTenant(message: let message):
                        self.headStatus.accept(.showError(message))
                        self.processPublish.onNext(.hudStatusChanged(.removeHud))
                    case .chatMemberHadFull(message: let message):
                        self.headStatus.accept(.showError(message))
                        self.processPublish.onNext(.hudStatusChanged(.removeHud))
                        Tracker.post(TeaEvent(Homeric.IM_CHAT_MEMBER_TOPLIMIT_VIEW, params: [
                            "text_type": "nearby"
                        ]))
                    case .externalCoordinateCtl(message: let message):
                        self.processPublish.onNext(.hudStatusChanged(.showFailure(message)))
                    default:
                        self.processPublish.onNext(.hudStatusChanged(.showFailure(BundleI18n.LarkContact.Lark_Legacy_ErrorMessageTip)))
                    }
                } else {
                    self.processPublish.onNext(.hudStatusChanged(.showFailure(BundleI18n.LarkContact.Lark_Legacy_ErrorMessageTip)))
                }
            }, onCompleted: { [weak self] in
                self?.processPublish.onNext(.hudStatusChanged(.removeHud))
            }, onDisposed: { [weak self] in
                self?.processPublish.onNext(.hudStatusChanged(.removeHud))
            }).disposed(by: disposeBag)
    }

    private func observePush() {
        self.pushFaceToFaceApplicants
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] push in
                guard let self = self, self.applicationId == push.applicationId, !push.applicants.isEmpty else { return }

                var newApplicants: [RustPB.Im_V1_FaceToFaceApplicant] = []
                push.applicants.forEach {
                    if !self.applicantSet.contains(Int($0.userID)) {
                        newApplicants.append($0)
                        self.applicantSet.insert(Int($0.userID))
                    }
                }
                if !newApplicants.isEmpty { self.processPublish.onNext(.hasNewApplicants(newApplicants)) }
            }).disposed(by: disposeBag)
    }

    func joinChat(success: @escaping (Chat) -> Void) {
        guard let token = self.token, let chatAPI = self.chatAPI else {
            Self.logger.error(
                "join chat error token is empty",
                additionalData: ["applicationId": self.applicationId ?? "",
                                 "applicants count": "\(self.applicantSet.count)"]
            )
            return
        }
        self.processPublish.onNext(.hudStatusChanged(.initHud))
        self.processPublish.onNext(.hudStatusChanged(.loadingHud))
        chatAPI
            .joinFaceToFaceChat(token: token)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] chatInfo in
                let chat = chatInfo.0
                let isCreateChat = chatInfo.1
                self?.processPublish.onNext(.hudStatusChanged(.removeHud))
                success(chat)
                if isCreateChat { Tracer.faceToFaceNewCreateChat(chatId: chat.id) }
            }, onError: { [weak self] error in
                guard let self = self else { return }
                Self.logger.error(
                    "join chat error",
                    additionalData: ["token": token,
                                     "applicationId": self.applicationId ?? "",
                                     "applicants count": "\(self.applicantSet.count)"]
                )
                if let apiError = error.underlyingError as? APIError {
                    switch apiError.type {
                    case .requestOverFrequency(message: let message):
                        self.processPublish.onNext(.requestFailure(message))
                        self.processPublish.onNext(.hudStatusChanged(.removeHud))
                    case .invalidFaceToFaceToken(message: let message):
                        self.processPublish.onNext(.requestFailure(message))
                        self.processPublish.onNext(.hudStatusChanged(.removeHud))
                    case .chatMemberHadFullForPay(message: let message), .chatMemberHadFullForCertificationTenant(message: let message):
                        self.processPublish.onNext(.requestFailure(message))
                        self.processPublish.onNext(.hudStatusChanged(.removeHud))
                    default:
                        self.processPublish.onNext(.hudStatusChanged(.showFailure(BundleI18n.LarkContact.Lark_Legacy_ErrorMessageTip)))
                    }
                } else {
                    self.processPublish.onNext(.hudStatusChanged(.showFailure(BundleI18n.LarkContact.Lark_Legacy_ErrorMessageTip)))
                }
            }).disposed(by: disposeBag)
    }
}

extension FaceToFaceCreateGroupViewModel {
    public func didChangeAuthorization(error: LocationAuthorizationError?) {
        guard let error = error else {
            return
        }

        switch error {
        case .denied:
            self.processPublish.onNext(.locationAccessDenied)
        case .notDetermined:
            locationAuth.requestWhenInUseAuthorization(forToken: locationAuthorizationToken, complete: didChangeAuthorization)
        default: break
        }
    }

    public func didUpdateCompleteLocations(task: SingleLocationTask, result: LocationTaskResult) {
        Self.logger.info("FaceToFace,Complete,UseLocationModule")
        switch result {
        case .success(let location):
            Self.logger.info("FaceToFace,CompleteSuccess,UseLocationModule")
            let userLocation = FaceToFaceUserLocation(latitude: "\(location.location.coordinate.latitude)", longitude: "\(location.location.coordinate.longitude)")
            self.currentLocation = userLocation
            self.locationTask.cancel()
            self.locationPublish.onNext(userLocation)
            self.locationPublish.onCompleted()
        case .failure(let error): break
            Self.logger.info("FaceToFace,CompleteError,UseLocationModule")
        }
    }
}

extension FaceToFaceCreateGroupViewModel: CLLocationManagerDelegate {

    @available(iOS 14, *)
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        locationManager(manager, didChangeAuthorization: manager.authorizationStatus)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if case .denied = status {
            self.processPublish.onNext(.locationAccessDenied)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let currentLocation = locations.last {
            Self.logger.info("FaceToFace,UpdateLocations,UseSystemLocation")
            let location = FaceToFaceUserLocation(latitude: "\(currentLocation.coordinate.latitude)", longitude: "\(currentLocation.coordinate.longitude)")
            self.currentLocation = location
            self.locationManager.stopUpdatingLocation()
            self.locationPublish.onNext(location)
            self.locationPublish.onCompleted()
        }
    }
}
