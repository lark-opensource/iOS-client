//
//  DefaultImageServiceDependencyIMP.swift
//  ByteWebImage
//
//  Created by xiongmin on 2021/11/15.
//

import Foundation
import LarkAccountInterface
import LarkContainer
import LarkRustClient
import LarkSetting
import LKCommonsLogging
import LKCommonsTracker
import RxSwift
import RustPB
import RustSDK
import CookieManager

extension FeatureGatingManager.Key {
    /// 头像加载使用 HEIC
    static let avatarDownloadHeic: Self = "messenger.avatar.download.heic"
    /// 使用自研HEIF解码库
    static let useLibttheif: Self = "core.bytewebimage.libttheif"
    /// 会话网络图片渲染失败上报Steam
    static let sendSteamFG: Self = "lark-file.download.image_trace"
    /// 发送图片使用 webp 格式
    static let uploadConvertWebPFG: Self = "messenger.convert.webp"
}

class DefaultImageServiceDependencyIMP: LarkImageServiceDependency {

    static let logger = Logger.log(DefaultImageServiceDependencyIMP.self, category: "LarkImageServiceDependency")

    @Provider private var accountService: AccountService
    @Provider private var rustService: RustService

    var avatarConfig: AvatarImageConfig = AvatarImageConfig()
    var stickerSetDownloadPath: String = NSHomeDirectory() + "/Documents/stickerSet/"
    /// 为空时值为 "placeholder.user.id"
    var currentAccountID: String = "placeholder.user.id" // 原 account 空值
    var imageSetting: ImageSetting = ImageSetting()
    var imageDisplayStrategySetting: ImageDisplayStrategySetting = ImageDisplayStrategySetting()
    var imageUploadComponentConfig: ImageUploadComponentConfig = ImageUploadComponentConfig()
    var imageExportConfig: ImageExportConfig = ImageExportConfig()
    var imagePreloadConfig: ImagePreloadConfig = ImagePreloadConfig()
    var avatarUploadWebP: Bool = false
    var avatarDownloadHeic: Bool = false
    var imageUploadWebP: Bool = false
    var progressValue: Observable<(String, Progress)>?
    var accountChangeBlock: (() -> Void)?
    var disposeBag = DisposeBag()

    var modifier: ((URLRequest) -> URLRequest)? {
        return { request in
            return LarkCookieManager.shared.processRequest(request)
        }
    }

    public init() {
        // config
        self.fetchNewConfig()
        self.setABExperiments()
        // setup
        let progressHandler = ImageResourceProgressHandler()
        SimpleRustClient.global.registerPushHandler(factories: [.pushResourceProgress: { progressHandler }])
        self.progressValue = progressHandler.observable
        Self.setupLogger()
        // account change
        accountService.accountChangedObservable.subscribe { [weak self] (_) in
            self?.fetchNewConfig()
            self?.accountChangeBlock?()
        }.disposed(by: disposeBag)
    }

    // MARK: - config

    private func fetchNewConfig() {
        self.avatarConfig = Self.getAvatarConfig()
        setImageFeatureGating()
        self.imageSetting = Self.getImageSetting()
        self.imageDisplayStrategySetting = Self.getImageDisplayStrategySetting()
        self.imageUploadComponentConfig = Self.getImageUploadComponentConfig()
        self.imageExportConfig = Self.getImageExportConfig()
        self.currentAccountID = self.accountService.foregroundUser?.userID ?? "placeholder.user.id" // 原 account 空值
    }

    private static func getAvatarConfig() -> AvatarImageConfig {
        do {
            let dprConfig = try SettingManager.shared.setting(with: AvatarImageConfig.sizeConfigKey)
            let keyAndIdConfig = try SettingManager.shared.setting(with: AvatarImageConfig.avatarConfigKey)
            let avatarConfig = AvatarImageConfig(dprConfig: dprConfig, keyAndIdConfig: keyAndIdConfig)
            return avatarConfig
        } catch let error {
            Self.logger.error("get avatar config error use default config",
                              tag: "LarkImageServiceDependency",
                              additionalData: [:], error: error)
            let defaultConfig = AvatarImageConfig()
            return defaultConfig
        }
    }

    private func setImageFeatureGating() {
    }

    private static func getImageSetting() -> ImageSetting {
        do {
            let config = try SettingManager.shared.setting(with: ImageSetting.key)
            return ImageSetting(with: config)
        } catch let error {
            Self.logger.error("get image config error use default config",
                              tag: "LarkImageServiceDependency",
                              additionalData: [:],
                              error: error)
            return ImageSetting()
        }
    }

    private static func getImageDisplayStrategySetting() -> ImageDisplayStrategySetting {
        do {
            let config = try SettingManager.shared.setting(with: ImageDisplayStrategySetting.key)
            return ImageDisplayStrategySetting(with: config)
        } catch let error {
            Self.logger.error("get image display strategy config failed", error: error)
            return ImageDisplayStrategySetting()
        }
    }

    private static func getImageUploadComponentConfig() -> ImageUploadComponentConfig {
        do {
            let config = try SettingManager.shared.setting(with: ImageUploadComponentConfig.key)
            return ImageUploadComponentConfig(with: config)
        } catch let error {
            Self.logger.error("get image upload component config failed", error: error)
            return ImageUploadComponentConfig()
        }
    }

    private static func getImageExportConfig() -> ImageExportConfig {
        do {
            let config = try SettingManager.shared.setting(with: ImageExportConfig.key)
            return ImageExportConfig(with: config)
        } catch {
            Self.logger.error("get image export config failed", error: error)
            return ImageExportConfig()
        }
    }

    // 取 AB 实验的值必须在此方法中取,图片库初始化时机过早,不能直接取
    private func setABExperiments() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: Tracker.LKExperimentDataDidRegister),
                                               object: nil,
                                               queue: nil) { [weak self] _ in
            // Avatar download HEIC
            let avatarDownloadFG = FeatureGatingManager.shared.featureGatingValue(with: .avatarDownloadHeic)
            var avatarDownloadAB: Bool?
            if avatarDownloadFG {
                avatarDownloadAB = Tracker.experimentValue(key: "messenger_avatar_download_heic", shouldExposure: true) as? Bool
                let avatarDownloadHeic = avatarDownloadAB == true
                self?.avatarDownloadHeic = avatarDownloadHeic
            } else {
                self?.avatarDownloadHeic = false
            }
            Self.logger.info("[Image][AB] messenger_avatar_download_heic fg: \(avatarDownloadFG), ab: \(String(describing: avatarDownloadAB))")

            // upload image convert to webp
            let uploadConvertWebPFG = FeatureGatingManager.shared.featureGatingValue(with: .uploadConvertWebPFG)
            var convertToWebPAB: Int?
            if uploadConvertWebPFG {
                convertToWebPAB = Tracker.experimentValue(key: "convert_to_webp", shouldExposure: true) as? Int
                let imageUploadWebP = convertToWebPAB == 1
                self?.imageUploadWebP = imageUploadWebP
            } else {
                self?.imageUploadWebP = false
            }
            Self.logger.info("[Image][AB] image_upload_webP fg: \(uploadConvertWebPFG), ab: \(String(describing: convertToWebPAB))")

            // Use libttheif
            var useLibttheif = FeatureGatingManager.shared.featureGatingValue(with: .useLibttheif)
            if useLibttheif {
                let useLibttheifAB = Tracker.experimentValue(key: "core_bytewebimage_libttheif", shouldExposure: true) as? Bool ?? false
                useLibttheif = useLibttheifAB
            }
            if useLibttheif {
                ImageDecoderFactory.register(.heic, HEIC.TTDecoder.self)
                ImageDecoderFactory.register(.heif, HEIF.TTDecoder.self)
            } else {
                ImageDecoderFactory.register(.heic, HEIC.Decoder.self)
                ImageDecoderFactory.register(.heif, HEIF.Decoder.self)
            }
            Self.logger.info("[Image][AB] byte_web_image_libttheif \(useLibttheif)")

            // image preload
            do {
                let configJSON = try SettingManager.shared.setting(with: ImagePreloadConfig.key)
                var config = ImagePreloadConfig(with: configJSON)
                if config.preloadEnable, // Setting && AB
                   let abEnable = Tracker.experimentValue(key: "image_preload_enable", shouldExposure: true) as? Bool {
                    config.preloadEnable = abEnable
                }
                self?.imagePreloadConfig = config
                Self.logger.info("[Image][Setting] image_preload config: \(config)")
            } catch {
                self?.imagePreloadConfig = ImagePreloadConfig()
                Self.logger.error("get image preload config failed", error: error)
            }
        }
    }

    // MARK: - setup

    private static func setupLogger() {
        Log.handler = { level, desc, file, function, line in
            switch level {
            case .fatal, .error:
                Self.logger.error(desc, file: file, function: function, line: line)
            case .warning:
                Self.logger.warn(desc, file: file, function: function, line: line)
            case .info:
                Self.logger.info(desc, file: file, function: function, line: line)
            case .debug:
                Self.logger.debug(desc, file: file, function: function, line: line)
            case .trace:
                Self.logger.trace(desc, file: file, function: function, line: line)
            case .off, .all:
                assertionFailure("should not print log at .off or .all levels")
                Self.logger.info(desc, file: file, function: function, line: line)
            }
        }
    }

    // MARK: - fetch

    func fetchCryptoResource(path: String) -> Result<Data, FetchCryptoError> {
        guard let imagePath = path.cString(using: .utf8)?.dropLast() else {
            return .failure(.logicError(.imagePathNotUTF8))
        }
        let lengthPointer = UnsafeMutablePointer<Int>.allocate(capacity: 1)
        let dataPointerPointer = UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>.allocate(capacity: 1)
        let freePointer = {
            lengthPointer.deallocate()
            dataPointerPointer.deallocate()
        }
        let result = lark_sdk_resource_encrypt_with_sdkkey_read_all(unsafeBitCast(Array(imagePath), to: [UInt8].self),
                                                                    imagePath.count,
                                                                    dataPointerPointer,
                                                                    lengthPointer)
        let length = lengthPointer.pointee
        if result.rawValue == 0 {
            if let dataPointer = UnsafeRawPointer(dataPointerPointer.pointee) {
                let data = Data(bytes: dataPointer, count: length)
                lark_sdk_resource_encrypt_free_buf(dataPointerPointer.pointee, Int(lengthPointer.pointee))
                freePointer()
                return .success(data)
            } else {
                freePointer()
                return .failure(.logicError(.dataConvertFail))
            }
        } else {
            freePointer()
            return .failure(.rustError(result.rawValue))
        }
    }

    func fetchResource(resource: LarkImageResource, passThrough: ImagePassThrough?, path: String?, onlyLocalData: Bool) -> Observable<RustImageResultWrapper> {
        var set = RustPB.Media_V1_MGetResourcesRequest.Set()
        if let path = path {
            set.path = path
        }
        var request = RustPB.Media_V1_MGetResourcesRequest()
        switch resource {
        case let .default(key):
            set.key = key
        case .avatar:
            assertionFailure("avatar should not call this function")
            break
        case let .reaction(key, isEmojis):
            set.key = key
            request.isReaction = true
            request.isEmojis = isEmojis
        case let .sticker(key, stickerSetID, downloadDirectory):
            set.key = key
            if let downloadDirectory = downloadDirectory {
                let path = downloadDirectory + (downloadDirectory.hasSuffix("/") ? stickerSetID : "/\(stickerSetID)")
                set.path = path
            }
        case let .rustImage(key, fsUnit, crypto):
            set.key = key
            if let fsUnit {
                set.fsUnit = fsUnit
            }
            if let crypto {
                set.imageCrypto = crypto
            }
        }
        request.sets = [set]
        request.scene = .chat
        request.fromLocal = onlyLocalData
        if let pass = passThrough {
            request.imageSetPassThrough = [Basic_V1_ImageSetPassThrough.transform(pass: pass)]
        }
        var packet = RequestPacket(message: request)
        packet.collectTrace = true
        return rustService.async(packet).flatMap { (packet: ResponsePacket<RustPB.Media_V1_MGetResourcesResponse>) throws -> Observable<RustImageResultWrapper> in
            let contextID = packet.contextID
            let result = packet.result
            var rustResult = RustImageResultWrapper()
            rustResult.contextID = contextID
            let observable = Observable<RustImageResultWrapper>.create { (observer) -> Disposable in
                switch result {
                case let .success(response):
                    var rustCost: [String: UInt64] = [:]
                    for span in response.trace.spans {
                        rustCost[span.name] = span.durationMillis
                        if span.name == "network_time_cost" && span.durationMillis > 0 {
                            rustResult.fromNet = true
                        }
                    }
                    rustResult.rustCost = rustCost
                    if let res = response.resources.first?.value {
                        rustResult.url = URL(fileURLWithPath: res.path)
                        rustResult.isCrypto = res.isEncrypted
                        observer.onNext(rustResult)
                    } else {
                        let error = ImageError(ByteWebImageErrorBadImageData,
                                                      userInfo: [NSLocalizedDescriptionKey: "bad image data"])
                        rustResult.error = error
                        observer.onNext(rustResult)
                    }
                case let .failure(error):
                    rustResult.error = error
                    observer.onNext(rustResult)
                }
                observer.onCompleted()
                return Disposables.create()
            }
            return observable
        }
    }

    func fetchAvatar(entityID: Int64, key: String, size: Int32, dpr: Float, format: String) -> Observable<Data?> {
        return Observable.create { observer -> Disposable in
            guard let keyPointer = (key as NSString).utf8String,
                  let formatPointer = (format as NSString).utf8String else {
                let error = ImageError(ByteWebImageErrorInternalError,
                                              userInfo: [NSLocalizedDescriptionKey: "convert string to pointer error"])
                observer.onError(error)
                observer.onCompleted()
                return Disposables.create()
            }
            let lengthPointer = UnsafeMutablePointer<Int>.allocate(capacity: 1)
            let dataPointerPointer = UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>.allocate(capacity: 1)
            let errorCode = get_avatar(entityID, keyPointer, size, dpr,
                                       formatPointer, lengthPointer, dataPointerPointer)
            let length = lengthPointer.pointee
            if errorCode != 0 {
                let error = ImageError(ByteWebImageErrorCode(errorCode),
                                              userInfo: [NSLocalizedDescriptionKey: "sdk error"])
                observer.onError(error)
                observer.onCompleted()
            } else {
                if let dataPointer = UnsafeRawPointer(dataPointerPointer.pointee) {
                    let data = Data(bytes: dataPointer, count: length)
                    observer.onNext(data)
                    observer.onCompleted()
                }
            }
            free_rust(dataPointerPointer.pointee, UInt32(length))
            lengthPointer.deallocate()
            dataPointerPointer.deallocate()
            return Disposables.create()
        }
    }

    // MARK: - Steam
    func steamRequest(req: RustPB.Tool_V1_SendSteamLogsRequest) -> Observable<Tool_V1_SendSteamLogsResponse> {
        rustService.sendAsyncRequest(req)
    }
}
