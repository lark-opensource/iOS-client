//
//  WaterMarkDataSource.swift
//  LarkWaterMark
//
//  Created by 李晨 on 2021/4/22.
//

import Foundation
import RustPB
import LarkRustClient
import RxSwift
import RxCocoa
import LarkStorage
import LarkContainer
import LarkTimeFormatUtils
import LKCommonsLogging
import LarkExtensions
import SwiftyJSON

protocol WaterMarkDataSource {
    func updateWatermarkInfo()
    func setupWaterMarkByDefault()
    func needShowObviousWaterMark() -> Bool

    var watermarkStrSignal: Observable<String> { get }
    var watermarkURLSignal: Observable<String> { get }
    var obviousWatermarkEnableSignal: Observable<Bool> { get }
    var imageWatermarkEnableSignal: Observable<Bool> { get }
    var watermarkCustomPatternSignal: Observable<ObviousWaterMarkPatternConfig> { get }
    var defaultWatermarkStrSignal: Observable<String> { get }
}

/// old watermark data source
final class WaterMarkOriginDataSource: WaterMarkDataSource {
    let userID: String

    var watermarkStrSignal: Observable<String> {
        return watermarkStrSubject.asObservable()
    }
    var watermarkURLSignal: Observable<String> {
        return watermarkURLSubject.asObservable()
    }
    var obviousWatermarkEnableSignal: Observable<Bool> {
        return obviousWatermarkEnable.asObservable()
    }
    var imageWatermarkEnableSignal: Observable<Bool> {
        return imageWatermarkEnable.asObservable()
    }
    var watermarkCustomPatternSignal: Observable<ObviousWaterMarkPatternConfig> {
        return watermarkCustomPatternSubject.asObservable()
    }
    var defaultWatermarkStrSignal: Observable<String> {
        return watermarkStrSubject.asObservable()
    }

    private var watermarkStrSubject: ReplaySubject<String> = ReplaySubject<String>.create(bufferSize: 1)
    private var watermarkURLSubject: ReplaySubject<String> = ReplaySubject<String>.create(bufferSize: 1)
    private var obviousWatermarkEnable: ReplaySubject<Bool> = ReplaySubject<Bool>.create(bufferSize: 1)
    private var imageWatermarkEnable: ReplaySubject<Bool> = ReplaySubject<Bool>.create(bufferSize: 1)
    private let watermarkCustomPatternSubject = ReplaySubject<ObviousWaterMarkPatternConfig>.create(bufferSize: 1)

    private let client: RustService
    private let phoneSuffixLength: Int = 4

    private let disposeBag = DisposeBag()

    private let contactKey = KVKey<String?>("origin.contactKey")
    private let userNameKey = KVKey<String?>("origin.userNameKey")
    private let needShowWaterKey = KVKey<Bool?>("origin.needShowWaterKey")
    private lazy var userKV = KVStores.udkv(space: .user(id: userID), domain: Domain.biz.core.child("WaterMark"))

    init(userID: String, client: RustService) {
        self.userID = userID
        self.client = client
        setupWaterMarkByDefault()
    }

    func needShowObviousWaterMark() -> Bool {
        return self.userKV.value(forKey: self.needShowWaterKey) ?? false
    }

    func setupWaterMarkByDefault() {
        updateWaterMarkContent()
    }

    func updateWatermarkInfo() {
        WaterMarkNewDataSource.logger.info("origin datasource update info")
        self.fetchUserName()
            .flatMap({ [weak self] (name) -> Observable<String> in
                guard let `self` = self else { return .just("") }
                self.userKV.set(name, forKey: self.userNameKey)
                return self.fetchWaterMarkSuffix()
            })
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (str) in
                guard let `self` = self else { return }
                WaterMarkNewDataSource.logger.info("origin datasource fetch user name succeeded")
                self.userKV.set(str, forKey: self.contactKey)
                self.updateWaterMarkContent()
            }, onError: { [weak self] (_) in
                guard let `self` = self else { return }
                WaterMarkNewDataSource.logger.error("origin datasource fetch user name error")
                self.updateWaterMarkContent()
            }).disposed(by: self.disposeBag)
    }

    @objc
    private func updateWaterMarkContent() {
        let str = self.userKV.value(forKey: self.contactKey)
        let name = self.userKV.value(forKey: self.userNameKey)
        let waterMarkStr = self.combine(userName: name ?? "", suffix: str)
        self.watermarkStrSubject.onNext(waterMarkStr)
    }

    // MARK: rust API
    private func fetchUserName() -> Observable<String> {
        let userId = self.userID
        var request = RustPB.Contact_V1_MGetChattersRequest()
        request.chatterIds = [userId]
        return client.sendAsyncRequest(
            request,
            transform: { (response: RustPB.Contact_V1_MGetChattersResponse) -> String in
                return response.entity.chatters[userId]?.localizedName ?? ""
            })
    }

    private func fetchWaterMarkSuffix() -> Observable<String> {
        return self.fetchUserMoiblePhonenumber()
            .flatMap { [weak self] (mobilePhoneNumber, hasPermission) -> Observable<String> in
                guard let `self` = self else {
                    return .just("")
                }
                if mobilePhoneNumber.count > self.phoneSuffixLength, hasPermission {
                    return .just(self.phoneNumberSuffix(number: mobilePhoneNumber))
                }
                return self.fetchUserEmail()
                    .map({ (email) -> String in
                        return email.components(separatedBy: "@").first ?? ""
                    })
            }
            .observeOn(MainScheduler.instance)
            .delaySubscription(.milliseconds(100), scheduler: MainScheduler.instance)
    }

    private func fetchUserMoiblePhonenumber() -> Observable<(mobilePhoneNumber: String, hasPermission: Bool)> {
        var request = RustPB.Contact_V1_GetChatterMobileRequest()
        request.chatterID = userID
        return self.client.sendAsyncRequest(
            request,
            transform: { (response: Contact_V1_GetChatterMobileResponse) -> (mobilePhoneNumber: String,
                                                                             hasPermission: Bool) in
                (response.mobile, !response.noPermission)
            })
    }

    private func fetchUserEmail() -> Observable<String> {
        var request = RustPB.Contact_V1_GetUserProfileRequest()
        request.userID = userID
        return self.client.sendAsyncRequest(
            request,
            transform: { (response: Contact_V1_GetUserProfileResponse) -> String in
                return response.personal.email
            })
    }

    // MARK: util
    private func phoneNumberSuffix(number: String) -> String {
        assert(number.count > self.phoneSuffixLength)
        return String(number[number.index(number.endIndex, offsetBy: -self.phoneSuffixLength)...])
    }

    private func combine(userName: String, suffix: String?) -> String {
        guard let suffix = suffix else {
            return userName
        }
        return "\(userName) \(suffix)"
    }
}

extension ObviousWaterMarkPatternConfig: KVNonOptional {}

// MARK: new data source
final class WaterMarkNewDataSource: WaterMarkDataSource {
    static var logger = Logger.log(WaterMarkNewDataSource.self, category: "WaterMark")
    static let monitor = WaterMarkMonitor()

    let userID: String

    var watermarkStrSignal: Observable<String> {
        return watermarkStrSubject.map({ (content) -> String in
            return Self.addTimestampIfNeeded(content: content) 
        }).asObservable()
    }
    
    var defaultWatermarkStrSignal: Observable<String> {
        return defaultWatermarkStrSubject.map({ (content) -> String in
            return Self.addTimestampIfNeeded(content: content) 
        }).asObservable()
    }
    
    var watermarkCustomPatternSignal: Observable<ObviousWaterMarkPatternConfig> {
        return watermarkCustomPatternSubject.asObservable()
    }
    var watermarkURLSignal: Observable<String> {
        return watermarkURLSubject.asObservable()
    }
    var obviousWatermarkEnableSignal: Observable<Bool> {
        return obviousWatermarkEnable.asObservable()
    }
    var imageWatermarkEnableSignal: Observable<Bool> {
        return imageWatermarkEnable.asObservable()
    }
    
    private var watermarkStrSubject: ReplaySubject<String> = ReplaySubject<String>.create(bufferSize: 1)
    private var defaultWatermarkStrSubject: ReplaySubject<String> = ReplaySubject<String>.create(bufferSize: 1)
    private let watermarkCustomPatternSubject = ReplaySubject<ObviousWaterMarkPatternConfig>.create(bufferSize: 1)
    private var watermarkURLSubject: ReplaySubject<String> = ReplaySubject<String>.create(bufferSize: 1)
    private var obviousWatermarkEnable: ReplaySubject<Bool> = ReplaySubject<Bool>.create(bufferSize: 1)
    private var imageWatermarkEnable: ReplaySubject<Bool> = ReplaySubject<Bool>.create(bufferSize: 1)

    private var waterMarkContent: String = "" {
        didSet {
            if waterMarkContent != oldValue {
                observeTimeChangeIfNeeded()
            }
        }
    }
    
    private var waterMarkDefaultContent: String = ""
    
    private var waterMarkURL: String = ""
    private var isRemote = false

    private let client: RustService

    private let disposeBag = DisposeBag()
    private var timer: Timer?

    private let contentKey = KVKey<String?>("contentKey")
    private let contentURLKey = KVKey<String?>("contentURLKey")
    private let needShowWaterKey = KVKey<Bool?>("needShowWaterKey")
    private let needShowImageWaterKey = KVKey<Bool?>("needShowImageWaterKey")
    private let customPatternKey = KVKey<ObviousWaterMarkPatternConfig?>("customPattern")
    private let defaultContentKey = KVKey<String?>("defaultContentKey")

    private lazy var userKV = KVStores.udkv(space: .user(id: userID), domain: Domain.biz.core.child("WaterMark"))

    private let timestampTemplet = "{{.timestamp}}"

    // swiftlint:disable:next superfluous_disable_command
    private var pushCenter: PushNotificationCenter? = implicitResolver?.pushCenter
    init(
        userID: String,
        client: RustService
    ) {
        self.userID = userID
        self.client = client

        setupWaterMarkByDefault()
        // setup push observe
        handleWaterMarkPush()
        observeTimeFormatChange()
    }

    func updateWatermarkInfo() {
        WaterMarkNewDataSource.logger.info("update watermark info userID \(userID)")
        self.setupWaterMarkByDefault()
        self.updateCustomWaterMarkConfig()
        self.updateDefaultWaterMarkConfig()
        self.updateWaterMarkImageUrl()
    }

    func needShowObviousWaterMark() -> Bool {
        return self.userKV.value(forKey: self.needShowWaterKey) ?? false
    }

    func setupWaterMarkByDefault() {
        let needShowWater = self.userKV.value(forKey: self.needShowWaterKey) ?? false
        let needShowImageWater = self.userKV.value(forKey: self.needShowImageWaterKey) ?? false
        let content = self.userKV.value(forKey: self.contentKey) ?? ""
        let defaultContent = self.userKV.value(forKey: self.defaultContentKey) ?? ""
        let urlContent = self.userKV.value(forKey: self.contentURLKey) ?? ""
        let previousCustomPattern = self.userKV.value(forKey: self.customPatternKey) ?? ObviousWaterMarkPatternConfig()
        let logStr = """
            setup watermark userID:\(self.userID)
            obviousEnabled:\(needShowWater)
            hiddenEnabled:\(needShowImageWater)
            contentLength:\(content.count)
            defaultContentLength: \(content.count)
            urlLength:\(urlContent.count)
            """
        WaterMarkNewDataSource.logger.info(logStr)
        self.obviousWatermarkEnable.onNext(needShowWater)
        self.imageWatermarkEnable.onNext(needShowImageWater)
        self.waterMarkContent = content
        self.watermarkStrSubject.onNext(content)
        self.waterMarkURL = urlContent
        self.watermarkURLSubject.onNext(urlContent)
        self.watermarkCustomPatternSubject.onNext(previousCustomPattern)
        self.waterMarkDefaultContent = defaultContent
        self.defaultWatermarkStrSubject.onNext(defaultContent)
    }
    
    private func updateDefaultWaterMarkConfig() {
        self.fetchWaterMarkConfig(useDefault: true)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                guard let `self` = self else { return }
                let logStr = """
                    fetch default watermark info success userID:\(self.userID)
                    contentLength:\(response.content.count)
                    """
                WaterMarkNewDataSource.logger.info(logStr)
                Self.monitor.monitorWaterMarkFetchResult("fetch_default_watermark",
                                                         status: 0,
                                                         extra: [
                                                            "userId": self.userID,
                                                            "useDefault": true,
                                                            "defaultTextLength": response.content.count
                ])
                
                self.userKV.set(response.content, forKey: self.defaultContentKey)
                self.waterMarkDefaultContent = response.content
                self.defaultWatermarkStrSubject.onNext(response.content)
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                WaterMarkNewDataSource.logger.info("fetch default watermark info userID \(self.userID) error \(error)")
                Self.monitor.monitorWaterMarkFetchResult("fetch_default_watermark",
                                                         status: 1,
                                                         extra: [
                                                            "userId": self.userID,
                                                            "useDefault": true
                ])
                
                let defaultContent = self.userKV.value(forKey: self.defaultContentKey) ?? ""
                self.waterMarkDefaultContent = defaultContent
                self.defaultWatermarkStrSubject.onNext(defaultContent)
            }).disposed(by: self.disposeBag)
    }
    
    private func updateCustomWaterMarkConfig() {
        self.fetchWaterMarkConfig()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                guard let `self` = self else { return }
                let logStr = """
                    fetch watermark info success userID:\(self.userID)
                    obviousEnabled:\(response.obviousEnabled)
                    hiddenEnabled:\(response.hiddenEnabled)
                    contentLength:\(response.content.count)
                    obviousStyle:\(response.clearStyle_p)
                    """
                WaterMarkNewDataSource.logger.info(logStr)
                Self.monitor.monitorWaterMarkFetchResult("fetch_obvious_watermark_config",
                                                         status: 0,
                                                         extra: [
                                                            "userId": self.userID,
                                                            "useDefault": false,
                                                            "obviousEnabled": response.obviousEnabled,
                                                            "textLength": response.content.count,
                                                            "hiddenEnabled": response.hiddenEnabled
                ])
                
                self.userKV.set(response.obviousEnabled, forKey: self.needShowWaterKey)
                self.userKV.set(response.hiddenEnabled, forKey: self.needShowImageWaterKey)
                self.obviousWatermarkEnable.onNext(response.obviousEnabled)
                self.imageWatermarkEnable.onNext(response.hiddenEnabled)
                self.userKV.set(response.content, forKey: self.contentKey)
                self.waterMarkContent = response.content
                self.watermarkStrSubject.onNext(response.content)
                let watermarkPatternConfig = self.getObviousWaterMarkCustomPatternFromDict(styleDict: response.clearStyle_p)
                self.userKV.set(watermarkPatternConfig, forKey: self.customPatternKey)
                self.watermarkCustomPatternSubject.onNext(watermarkPatternConfig)
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                WaterMarkNewDataSource.logger.info("fetch watermark info userID \(self.userID) error \(error)")
                Self.monitor.monitorWaterMarkFetchResult("fetch_obvious_watermark_config",
                                                         status: 1,
                                                         extra: [
                                                            "userId": self.userID,
                                                            "useDefault": false
                ])
                
                self.obviousWatermarkEnable.onNext(self.userKV.value(forKey: self.needShowWaterKey) ?? false)
                self.imageWatermarkEnable.onNext(self.userKV.value(forKey: self.needShowImageWaterKey) ?? false)
                let content = self.userKV.value(forKey: self.contentKey) ?? ""
                self.waterMarkContent = content
                self.watermarkStrSubject.onNext(content)
                let prevWatermarkPatternConfig = self.userKV.value(forKey: self.customPatternKey) ?? ObviousWaterMarkPatternConfig()
                self.watermarkCustomPatternSubject.onNext(prevWatermarkPatternConfig)
            }).disposed(by: self.disposeBag)
    }
    
    private func getObviousWaterMarkCustomPatternFromDict(styleDict: [String: String]) -> ObviousWaterMarkPatternConfig {
        if styleDict.isEmpty {
            return ObviousWaterMarkPatternConfig()
        }
        let jsonStyleDict = JSON(styleDict)
        let density: ObviousWaterMarkDensity = {
            switch jsonStyleDict["density"].intValue {
            case 1:
                return .normal
            case 0:
                return .sparse
            default:
                return .dense
            }
        }()
        
        let patternConfig = ObviousWaterMarkPatternConfig(
            opacity: jsonStyleDict["opacity"].floatValue > 0 ? jsonStyleDict["opacity"].floatValue : 0.12,
            darkOpacity: jsonStyleDict["dark_opacity"].floatValue > 0 ? jsonStyleDict["dark_opacity"].floatValue : 0.08,
            fontSize: jsonStyleDict["font_size"].floatValue > 0 ? jsonStyleDict["font_size"].floatValue : 14,
            rotateAngle: jsonStyleDict["rotate_angle"].floatValue,
            density: density
        )
        return patternConfig
    }

    private func updateWaterMarkImageUrl() {
        self.isRemote = false

        self.getImageWaterMarkURL()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (url) in
                guard let `self` = self, !self.isRemote else { return }
                WaterMarkNewDataSource.logger.info("fetch watermark url success userID \(self.userID) url count \(url.count), Local")
                self.userKV.set(url, forKey: self.contentURLKey)
                self.waterMarkURL = url
                self.watermarkURLSubject.onNext(url)
            }).disposed(by: self.disposeBag)

        self.fetchImageWaterMarkURL()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (url) in
                guard let `self` = self else { return }
                WaterMarkNewDataSource.logger.info("fetch watermark url success userID \(self.userID) url count \(url.count), Server")
                Self.monitor.monitorWaterMarkFetchResult("fetch_hidden_watermark_url",
                                                         status: 0,
                                                         extra: [
                                                            "userId": self.userID,
                                                            "urlCount": url.count
                ])
                self.userKV.set(url, forKey: self.contentURLKey)
                self.waterMarkURL = url
                self.watermarkURLSubject.onNext(url)
                self.isRemote = true
            }, onError: { [weak self] (error) in
                guard let `self` = self else { return }
                WaterMarkNewDataSource.logger.info("fetch watermark url userID \(self.userID) error \(error)")
                Self.monitor.monitorWaterMarkFetchResult("fetch_hidden_watermark_url",
                                                         status: 1,
                                                         extra: [
                                                            "userId": self.userID
                ])
                let url = self.userKV.value(forKey: self.contentURLKey) ?? ""
                self.waterMarkURL = url
                self.watermarkURLSubject.onNext(url)
            }).disposed(by: self.disposeBag)
    }

    // MARK: timestamp
    private func updateContentWithTimestamp() {
        if checkNeedAddTimestamp(content: self.waterMarkContent) {
            self.watermarkStrSubject.onNext(self.waterMarkContent)
        }
    }
    
    private func updateDefaultContentWithTimestamp() {
        if checkNeedAddTimestamp(content: self.waterMarkDefaultContent) {
            self.defaultWatermarkStrSubject.onNext(self.waterMarkDefaultContent)
        }
    }

    static func addTimestampIfNeeded(content: String) -> String {
        let date = Date()
        let options = Options(is12HourStyle: false, timeFormatType: .long, timePrecisionType: .minute, datePrecisionType: .day, dateStatusType: .absolute, shouldRemoveTrailingZeros: false)
        let timeStr = TimeFormatUtils.formatDateTime(from: date, with: options)
        return content.replacingOccurrences(of: "{{.timestamp}}", with: timeStr)
    }

    private func checkNeedAddTimestamp(content: String) -> Bool {
        return content.contains(timestampTemplet)
    }

    private func observeTimeChangeIfNeeded() {
        self.timer?.invalidate()
        if checkNeedAddTimestamp(content: self.waterMarkContent) {
            self.timer = Timer.scheduledTimer(withTimeInterval: 20, repeats: true, block: { [weak self] (_) in
                self?.updateContentWithTimestamp()
            })
        }
    }

    // MARK: Observe
    private func observeTimeFormatChange() {
        pushCenter?.observable(for: RustPB.Settings_V1_PushUserSetting.self)
            .map { $0.timeFormat.timeFormat.is24HourTime }
            .distinctUntilChanged()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (_) in
                self?.updateContentWithTimestamp()
                self?.updateDefaultContentWithTimestamp()
            }).disposed(by: self.disposeBag)
    }
    
    private func handleWaterMarkPush() {
        pushCenter?
            .driver(for: WaterMarkPushModel.self)
            .drive(onNext: { [weak self] (model) in
                guard let self = self else { return }
                let logStr = """
                    receive watermark info push userID:\(self.userID)
                    obviousEnabled:\(model.obviousEnabled)
                    hiddenEnabled:\(model.hiddenEnabled)
                    contentLength:\(model.userContent.count)
                    obviousStyle:\(model.clearStyle)
                    """
                WaterMarkNewDataSource.logger.info(logStr)
                Self.monitor.monitorWaterMarkPush(extra: [
                    "obviousEnabled": model.obviousEnabled,
                    "hiddenEnabled": model.hiddenEnabled,
                    "textLength": model.userContent.count
                ])
                
                self.userKV.set(model.obviousEnabled, forKey: self.needShowWaterKey)
                self.userKV.set(model.hiddenEnabled, forKey: self.needShowImageWaterKey)
                self.obviousWatermarkEnable.onNext(model.obviousEnabled)
                self.imageWatermarkEnable.onNext(model.hiddenEnabled)
                self.userKV.set(model.userContent, forKey: self.contentKey)
                self.waterMarkContent = model.userContent
                self.watermarkStrSubject.onNext(model.userContent)
                let pushObviousWaterMarkPatternConfig = self.getObviousWaterMarkCustomPatternFromDict(styleDict: model.clearStyle)
                self.userKV.set(pushObviousWaterMarkPatternConfig, forKey: self.customPatternKey)
                self.watermarkCustomPatternSubject.onNext(pushObviousWaterMarkPatternConfig)
            }).disposed(by: self.disposeBag)
    }

    // MARK: rust API
    private func fetchWaterMarkConfig(useDefault: Bool = false) -> Observable<Passport_V1_GetWaterMarkConfigResponse> {
        var request = RustPB.Passport_V1_GetWaterMarkConfigRequest()
        request.defaultConfig = useDefault
        return self.client.sendAsyncRequest(request)
    }

    private func getImageWaterMarkURL() -> Observable<String> {
        var request = RustPB.Passport_V1_GetHiddenWaterMarkImageRequest()
        request.alphaFlag = 1
        request.colorRgba8 = UInt32("ffffff08", radix: 16) ?? 0 // 255 255 255 8
        request.sizeOption = .size192192
        request.syncDataStrategy = .local
        return self.client.sendAsyncRequest(
            request,
            transform: { (response: Passport_V1_GetHiddenWaterMarkImageResponse) -> String in
                return response.waterMarkURL
            })
    }

    private func fetchImageWaterMarkURL() -> Observable<String> {
        var request = RustPB.Passport_V1_GetHiddenWaterMarkImageRequest()
        request.alphaFlag = 1
        request.colorRgba8 = UInt32("ffffff08", radix: 16) ?? 0 // 255 255 255 8
        request.sizeOption = .size192192
        request.syncDataStrategy = .forceServer
        return self.client.sendAsyncRequest(
            request,
            transform: { (response: Passport_V1_GetHiddenWaterMarkImageResponse) -> String in
                return response.waterMarkURL
            })
    }
}

extension RustPB.Settings_V1_PushUserSetting: PushMessage {}

extension RustPB.Settings_V1_TimeFormatSetting.TimeFormat {
    var is24HourTime: Bool {
        if case .twentyFourHour = self {
            return true
        }
        return false
    }
}
