//
//  PushTokenUploadRequest.swift
//  LarkPushTokenUploader
//
//  Created by aslan on 2023/11/2.
//

import Foundation
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import Swinject
import RxSwift
import RustPB
import LarkSetting
import LarkReleaseConfig
import LarkAccountInterface
import LarkStorage
import LarkTracker

final class PushTokenUploadRequest: NSObject {

    fileprivate let scheduler = SerialDispatchQueueScheduler(internalSerialQueueName: "token.uploader.scheduler")

    fileprivate let disposeBag = DisposeBag()

    let logger = Logger.log(PushTokenUploadRequest.self, category: "LarkPushTokenUploader")

    deinit {
        self.logger.info("request deinit")
    }

    func uploadApnsToken(_ apnsToken: String?, userResolver: UserResolver, completion: (() -> Void)? = nil) {
        guard let rustService = try? userResolver.resolve(type: RustService.self) else {
            self.logger.error("resolve rustService failed. userId: \(userResolver.userID)")
            completion?()
            return
        }
        guard let apnsToken = apnsToken else {
            self.logger.error("apnsToken is nil")
            completion?()
            return
        }
        self.logger.info("begin upload push apnsToken \(apnsToken.suffix(6))")
        var request = RustPB.Device_V1_SetPushTokenRequest()
        request.apnsToken = apnsToken
        request.channel = ReleaseConfig.pushChannel

        rustService.sendAsyncRequest(request)
            .observeOn(scheduler)
            .subscribe(onNext: { [weak self] _ in
                guard let `self` = self else { return }
                self.logger.info("end upload push token and succeed. userId: \(userResolver.userID)")
                completion?()
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                self.logger.error("end upload push token but failed. userId: \(userResolver.userID)", error: error)
                completion?()
            })
        .disposed(by: self.disposeBag)
    }

    func uploadVoipToken(_ voipToken: String?, userResolver: UserResolver) {
        guard let rustService = try? userResolver.resolve(type: RustService.self) else {
            self.logger.error("resolve rustService failed. userId: \(userResolver.userID)")
            return
        }
        guard let voipToken = voipToken else {
            self.logger.error("voipToken is nil")
            return
        }
        self.logger.info("begin upload push voipToken \(voipToken.suffix(6)) ")
        var request = RustPB.Device_V1_SetPushTokenRequest()
        request.voipToken = voipToken
        request.channel = ReleaseConfig.pushChannel

        rustService.sendAsyncRequest(request)
            .observeOn(scheduler)
            .subscribe(onNext: { [weak self] _ in
                self?.logger.debug("end upload push token and succeed")
            }, onError: { [weak self] (error) in
                self?.logger.error("end upload push token and failed", error: error)
            })
        .disposed(by: self.disposeBag)
    }

    func uploadToken2TTpush(_ apnsToken: String?, userResolver: UserResolver) {
        guard let deviceService = try? userResolver.resolve(type: DeviceService.self) else {
            self.logger.error("resolve deviceService failed. userId: \(userResolver.userID)")
            return
        }
        guard let apnsToken = apnsToken else {
            self.logger.error("apnsToken is nil")
            return
        }
        self.logger.info("Receive new apns token upload ttpush")
        let newDeviceLoginId = deviceService.deviceLoginId
        guard newDeviceLoginId != "" else {
            self.logger.info("newDeviceLoginId: \(newDeviceLoginId)")
            return
        }
        guard let domainService = try? userResolver.resolve(type: UserDomainService.self) else {
            self.logger.info("resolve domainService failed. \(userResolver.userID)")
            return
        }
        let host = domainService.getDomainSetting()[.ttpush]?.first ?? ""
        self.logger.info("start upload apns token to ttpush")
        let appName = (Bundle.main.infoDictionary?["CFBundleName"] as? String) ?? ""
        let appId = ReleaseConfig.appId
        let cParam = TTChannelRequestParam()

        cParam.channel = ReleaseConfig.channelName
        cParam.appName = appName
        cParam.aId = appId
        cParam.appName = appName
        cParam.installId = deviceService.installId
        cParam.deviceId = deviceService.deviceId
        cParam.deviceLoginId = newDeviceLoginId
        cParam.package = Bundle.main.bundleIdentifier
        cParam.osVersion = UIDevice.current.systemVersion
        // 1 代表用户手动开启推送，因为我们有自己的接口负责开关消息推送，因此此处始终为1
        cParam.notice = "1"
        cParam.host = host

        let noerror = NSError(domain: "noerror", code: -1, userInfo: nil)

        TouTiaoPushSDK.sendRequest(with: cParam) { [weak self] (respon) in
            if respon?.success == true {
                self?.logger.info("TouTiaoPushSDK.sendRequestA success")
            } else {
                self?.logger.info("TouTiaoPushSDK.sendRequestA:\(respon?.error ?? noerror)")
            }
        }

        let param = TTUploadTokenRequestParam()
        param.token = apnsToken
        param.aId = appId
        param.appName = appName
        param.installId = deviceService.installId
        param.deviceId = deviceService.deviceId
        param.deviceLoginId = newDeviceLoginId
        param.host = host

        TouTiaoPushSDK.sendRequest(with: param) { [weak self] (respon) in
            if respon?.success == true {
                self?.logger.info("TouTiaoPushSDK.sendRequestB success")
            } else {
                self?.logger.info("TouTiaoPushSDK.sendRequestB:\(respon?.error ?? noerror)")
            }
        }
    }
}
