//
//  Privacy.swift
//  ByteView
//
//  Created by 李凌峰 on 2018/7/24.
//

import Foundation
import RxSwift
import RxRelay
import AVFoundation
import ByteViewUI

enum AccessStatus {
    case accessOfAsk
    case deniedOfAsk
    case access
    case denied
}

enum AlertError: Error {
    case denied
}

extension AVAuthorizationStatus {
    var isAuthorized: Bool {
        return self == .authorized
    }
}

final class Privacy {

    static private var _cameraAccess: BehaviorRelay<AVAuthorizationStatus> = {
        return BehaviorRelay(value: AVCaptureDevice.authorizationStatus(for: .video))
    }()

    static private var _micAccess: BehaviorRelay<AVAuthorizationStatus> = {
        return BehaviorRelay(value: AVCaptureDevice.authorizationStatus(for: .audio))
    }()

    static var cameraAccess: BehaviorRelay<AVAuthorizationStatus> {
        let newVal = AVCaptureDevice.authorizationStatus(for: .video)
        if _cameraAccess.value != newVal {
            _cameraAccess.accept(newVal)
        }
        return _cameraAccess
    }

    static var micAccess: BehaviorRelay<AVAuthorizationStatus> {
        let newVal = AVCaptureDevice.authorizationStatus(for: .audio)
        if _micAccess.value != newVal {
            _micAccess.accept(newVal)
        }
        return _micAccess
    }

    static var videoAuthorized: Bool {
        return AVCaptureDevice.authorizationStatus(for: .video) == .authorized
    }

    /// 相机icon样式判断使用
    static var videoDenied: Bool {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
        return authStatus != .authorized
    }

    static var audioAuthorized: Bool {
        return AVCaptureDevice.authorizationStatus(for: .audio) == .authorized
    }

    /// 麦克风icon样式判断使用
    static var audioDenied: Bool {
        let authStatus = AVCaptureDevice.authorizationStatus(for: .audio)
        return authStatus != .authorized
    }

    static func requestCameraAccess(completion: ((AccessStatus) -> Void)?) {
        Util.runInMainThread {
            let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
            switch authStatus {
            case .notDetermined:
                CameraSncWrapper.requestAccessCamera { hasPermission, isSuccess  in
                    Util.runInMainThread {
                        self._cameraAccess.accept(hasPermission ? .authorized : .denied)
                        completion?(hasPermission ? .accessOfAsk : isSuccess ? .deniedOfAsk : .denied)
                    }
                }
            case .restricted, .denied:
                self._cameraAccess.accept(.denied)
                completion?(.denied)
            default:
                self._cameraAccess.accept(.authorized)
                completion?(.access)
            }
        }
    }


    static func requestCameraAccess() -> Single<AccessStatus> {
        return Single<AccessStatus>.create(subscribe: { single -> Disposable in
            let authStatus = AVCaptureDevice.authorizationStatus(for: .video)
            if authStatus == .notDetermined {
                CameraSncWrapper.requestAccessCamera { hasPermission, isSuccess in
                    Util.runInMainThread {
                        self._cameraAccess.accept(hasPermission ? .authorized : .denied)
                        single(.success(hasPermission ? .accessOfAsk : isSuccess ? .deniedOfAsk : .denied))
                    }
                }
            } else {
                self._cameraAccess.accept(videoDenied ? .denied : .authorized)
                single(.success(videoDenied ? .denied : .access))
            }

            return Disposables.create()
        }).subscribeOn(MainScheduler.asyncInstance).observeOn(MainScheduler.instance)
    }

    static func requestMicrophoneAccess(completion: @escaping (AccessStatus) -> Void) {
        let permission = AVCaptureDevice.authorizationStatus(for: .audio)
        self._micAccess.accept(permission)
        if permission == .notDetermined {
            MicrophoneSncWrapper.requestAccessAudio { hasPermission, isSuccess  in
                Util.runInMainThread {
                    self._micAccess.accept(hasPermission ? .authorized : .denied)
                    completion(hasPermission ? .accessOfAsk : isSuccess ? .deniedOfAsk : .denied)
                }
            }
        } else {
            Util.runInMainThread {
                self._micAccess.accept(audioDenied ? .denied : .authorized)
                completion(audioDenied ? .denied : .access)
            }
        }
    }

    static func requestCameraAccessAlert(cancelHandler: ((ByteViewDialog) -> Void)? = nil,
                                         sureHandler: ((ByteViewDialog) -> Void)? = nil) -> Completable {
        return Completable.create(subscribe: { completable -> Disposable in
            let disposeCameraAccess = requestCameraAccess().subscribe(onSuccess: { accessStatus in
                switch accessStatus {
                case .denied:
                    showCameraAlert(cancelHandler: cancelHandler, sureHandler: sureHandler)
                    completable(.error(AlertError.denied))
                case .deniedOfAsk:
                    completable(.error(AlertError.denied))
                case .access, .accessOfAsk:
                    completable(.completed)
                }
            })

            return Disposables.create([disposeCameraAccess])
        }).subscribeOn(MainScheduler.instance)
    }

    static func requestCameraAccessAlert(cancelHandler: ((ByteViewDialog) -> Void)? = nil,
                                         sureHandler: ((ByteViewDialog) -> Void)? = nil,
                                         completion: @escaping (Result<Void, Error>) -> Void) {
        requestCameraAccess { accessStatus in
            switch accessStatus {
            case .denied:
                showCameraAlert(cancelHandler: cancelHandler, sureHandler: sureHandler)
                completion(.failure(AlertError.denied))
            case .deniedOfAsk:
                completion(.failure(AlertError.denied))
            case .access, .accessOfAsk:
                completion(.success(()))
            }
        }
    }

    static func requestMicrophoneAccessAlert(cancelHandler: ((ByteViewDialog) -> Void)? = nil,
                                             sureHandler: ((ByteViewDialog) -> Void)? = nil,
                                             completion: @escaping (Result<Void, Error>) -> Void) {
        requestMicrophoneAccess { accessStatus in
            switch accessStatus {
            case .denied:
                Logger.ui.error("requestMicrophoneAccess failed!")
                showMicrophoneAlert(cancelHandler: cancelHandler, sureHandler: sureHandler)
                completion(.failure(AlertError.denied))
            case .deniedOfAsk:
                Logger.ui.error("requestMicrophoneAccess failed, deniedOfAsk!")
                completion(.failure(AlertError.denied))
            case .accessOfAsk:
                Logger.ui.info("requestMicrophoneAccess succeed, accessOfAsk.")
                completion(.success(()))
            case .access:
                completion(.success(()))
            }
        }
    }

    static func showMicrophoneAlert(cancelHandler: ((ByteViewDialog) -> Void)? = nil,
                                    sureHandler: ((ByteViewDialog) -> Void)? = nil) {
        Util.runInMainThread {
            ByteViewDialog.Builder()
                .id(.microphone)
                .title(I18n.View_VM_AccessToMicDenied)
                .message(I18n.View_G_NeedsMicAppNameBraces(Util.appName))
                .leftTitle(I18n.View_G_CancelButton)
                .leftHandler(cancelHandler)
                .rightTitle(I18n.View_G_Settings)
                .rightHandler({ action in
                    UIApplication.openSettings()
                    sureHandler?(action)
                })
                .show()
        }
    }

    static func showCameraAlert(cancelHandler: ((ByteViewDialog) -> Void)? = nil,
                                sureHandler: ((ByteViewDialog) -> Void)? = nil) {
        Util.runInMainThread {
            ByteViewDialog.Builder()
                .id(.camera)
                .title(I18n.View_VM_AccessToCameraDenied)
                .message(I18n.View_VM_NeedsCameraAppNameBraces(Util.appName))
                .leftTitle(I18n.View_G_CancelButton)
                .leftHandler(cancelHandler)
                .rightTitle(I18n.View_G_Settings)
                .rightHandler({ action in
                    UIApplication.openSettings()
                    sureHandler?(action)
                })
                .show()
        }
    }
}

private extension UIApplication {
    static func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}
