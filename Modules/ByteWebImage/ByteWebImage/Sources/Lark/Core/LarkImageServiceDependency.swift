//
//  LarkImageServiceDependency.swift
//  ByteWebImage
//
//  Created by xiongmin on 2021/5/12.
//

import Foundation
import RxSwift
import RustPB

public struct RustImageResultWrapper {
    public var contextID: String?
    public var url: URL?
    public var rustCost: [String: UInt64]?
    public var error: Error?
    public var fromNet: Bool = false
    // 数据是否被加密
    public var isCrypto: Bool = false
    public init() { }
}

public enum FetchCryptoLogicError: Int {
    case imagePathNotUTF8 = -45_000_001
    case dataConvertFail = -45_000_002
}

public enum FetchCryptoError: Error {
    case rustError(UInt32)
    case logicError(FetchCryptoLogicError)

    var code: Int {
        switch self {
        case .rustError(let code):
            return Int(code)
        case .logicError(let error):
            return error.rawValue
        }
    }

    var description: String {
        switch self {
        case .rustError(let code):
            return "FetchCryptoError rustError \(code)"
        case .logicError(let error):
            return "FetchCryptoError logicError \(error.rawValue)"
        }
    }
}

public protocol LarkImageServiceDependency {

    var progressValue: Observable<(String, Progress)>? { get }

    var avatarConfig: AvatarImageConfig { get }

    var stickerSetDownloadPath: String { get }

    var modifier: ((URLRequest) -> URLRequest)? { get }

    var currentAccountID: String { get }

    var accountChangeBlock: (() -> Void)? { get set }

    var imageSetting: ImageSetting { get }

    var imageDisplayStrategySetting: ImageDisplayStrategySetting { get }

    var imageUploadComponentConfig: ImageUploadComponentConfig { get }

    var imageExportConfig: ImageExportConfig { get }

    /// set is only used as internal debug
    var imagePreloadConfig: ImagePreloadConfig { get set }

    var avatarDownloadHeic: Bool { get set }

    var imageUploadWebP: Bool { get set }

    // 获取普通图片
    func fetchResource(resource: LarkImageResource,
                       passThrough: ImagePassThrough?,
                       path: String?,
                       onlyLocalData: Bool) -> Observable<RustImageResultWrapper>
    // 获取头像
    func fetchAvatar(entityID: Int64,
                             key: String,
                             size: Int32,
                             dpr: Float,
                             format: String) -> Observable<Data?>

    func fetchCryptoResource(path: String) -> Result<Data, FetchCryptoError>
    func steamRequest(req: RustPB.Tool_V1_SendSteamLogsRequest) -> Observable<Tool_V1_SendSteamLogsResponse>
}
