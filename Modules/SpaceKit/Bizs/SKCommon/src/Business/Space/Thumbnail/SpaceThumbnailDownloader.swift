//
//  SpaceThumbnailDownloader.swift
//  SpaceKit
//
//  Created by wuwenjian.weston on 2020/5/13.
//  

import UIKit
import RxSwift
import SwiftyJSON
import SKFoundation
import SpaceInterface
import SKInfra

extension SpaceThumbnailDownloader {
    public struct Request {
        let url: URL
        let encryptType: EncryptType
        var etag: String?

        public init(url: URL, encryptType: SpaceThumbnailDownloader.EncryptType, etag: String?) {
            self.url = url
            self.encryptType = encryptType
            self.etag = etag
        }
    }

    public enum Response<T> {
        // 304
        case resourceNotModified
        // 9009
        case fileIsEmpty
        // code:9010 or statusCode:404
        case fileDeleted
        // statusCode:202 and code:90002004
        case generating
        // statusCode:202 and code:90002005
        case coverUnavailable
        // statusCode:202 and code:90002006
        case coverNotExist
        /// 特殊占位图：空白、无权限、后台生成失败、已经删除等情况。
        /// 2020-11-17，3.39及后续版本使用此方案应对: https://bytedance.feishu.cn/docs/doccnRYFxWIBlWXrGAlafZbFZvw#
        case specialPlaceHolder(result: T, etag: String?)

        case success(result: T, etag: String?)

        func convert<R>(convertion: (T) throws -> R) rethrows -> Response<R> {
            switch self {
            case .resourceNotModified:
                return .resourceNotModified
            case .fileIsEmpty:
                return .fileIsEmpty
            case .fileDeleted:
                return .fileDeleted
            case .generating:
                return .generating
            case .coverUnavailable:
                return .coverUnavailable
            case .coverNotExist:
                return .coverNotExist
            case let .specialPlaceHolder(result, etag):
                return .specialPlaceHolder(result: try convertion(result), etag: etag)
            case let .success(result, etag):
                return .success(result: try convertion(result), etag: etag)
            }
        }
    }
}

public final class SpaceThumbnailDownloader {

    public typealias Info = SpaceThumbnailInfo
    public typealias EncryptInfo = Info.ExtraInfo
    public typealias EncryptType = EncryptInfo.EncryptType

    private struct SpecialResponse: Codable {
        let code: Int
    }

    public enum DownloadError: LocalizedError {
        case decryptionFailed(error: Error)
        case unknownStatusCode(code: Int)
        case unknownBusinessCode(code: Int)
        case parseDataFailed

        public var errorDescription: String? {
            switch self {
            case let .decryptionFailed(error):
                return "decryption failed with error: \(error)"
            case let .unknownStatusCode(code):
                return "unknown http status code: \(code)"
            case let .unknownBusinessCode(code):
                return "unknown business code: \(code)"
            case .parseDataFailed:
                return "failed to parse data"
            }
        }
    }

    private let downloadQueue = DispatchQueue(label: "space.thumbnail.download", attributes: [.concurrent])

    /// 下载数据、解密并生成缩略图
    public func download(request: Request) -> Single<Response<UIImage>> {
        return download(url: request.url, etag: request.etag)
            // 解密图片数据
            .map { response -> Response<Data> in
                switch response {
                case let .success(encryptedData, etag):
                    let decrypter = Self.decrypter(for: request.encryptType)
                    do {

                        let data = try decrypter.decrypt(encryptedData: encryptedData)
                        return .success(result: data, etag: etag)
                    } catch {
                        throw DownloadError.decryptionFailed(error: error)
                    }
                case let .specialPlaceHolder(encryptedData, etag):
                    let decrypter = Self.decrypter(for: request.encryptType)
                    do {
                        let data = try decrypter.decrypt(encryptedData: encryptedData)
                        return .specialPlaceHolder(result: data, etag: etag)
                    } catch {
                        throw DownloadError.decryptionFailed(error: error)
                    }
                default:
                    return response
                }
            }
            // 转换成图片
            .map { dataResponse -> Response<UIImage> in
                return try dataResponse.convert { (data) -> UIImage in
                    guard let image = UIImage(data: data) else {
                        DocsLogger.error("space.thumbnail.downloader --- failed to convert data to image object")
                        // 数据转图片失败，可能是解密参数不匹配的问题，目前后端在 explorer 接口拉取其他 unit 上的缩略图时，存在解密参数不匹配的问题，属于解密失败
                        throw DownloadError.decryptionFailed(error: SpaceThumbnailDecryptError.invalidImageData)
                    }
                    return image
                }
            }
    }

    // swiftlint:disable:next cyclomatic_complexity
    // nolint: magic number
    private func download(url: URL, etag: String?) -> Single<Response<Data>> {
        var request = DocsRequest<JSON>(url: url.absoluteString, params: nil)
            .set(method: .GET)
            .set(cachePolicy: .reloadIgnoringLocalCacheData)

        var headers: [String: String] = [:]
        if let etag = etag {
            headers["If-None-Match"] = etag
        }
        let localeIdentifier = DocsSDK.currentLanguage.localeIdentifier
        headers["locale"] = localeIdentifier
        headers["use-new-default-thumbnail"] = "true"
        request = request.set(headers: headers)

        let requestID = request.requestID

        return request.rxData()
            .observeOn(ConcurrentDispatchQueueScheduler(queue: downloadQueue)) // 派发数据解析处理到下载线程
            .map { (data, response) -> Response<Data> in
                DocsLogger.info("space.thumbnail.downloader --- start parsing download thumbnail response", extraInfo: ["requestID": requestID, "header": headers])
                guard let httpResponse = response as? HTTPURLResponse else {
                    DocsLogger.error("space.thumbnail.downloader --- response is not a http response", extraInfo: ["requestID": requestID])
                    throw DownloadError.parseDataFailed
                }
                let statusCode = httpResponse.statusCode
                if statusCode == 304 {
                    DocsLogger.info("space.thumbnail.downloader --- 304 resource not modified", extraInfo: ["requestID": requestID])
                    return .resourceNotModified
                } else if statusCode == 404 {
                    return .fileDeleted
                } else if statusCode == 202 {
                    let specialCode = try Self.handleSpecialCode(data: data, requestID: requestID)
                    switch specialCode {
                    case 90002004:
                        return .generating
                    case 90002005:
                        return .coverUnavailable
                    case 90002006:
                        return .coverNotExist
                    default:
                        DocsLogger.error("space.thumbnail.downloader --- Unknown business response code", extraInfo: ["statusCode": statusCode, "code": specialCode, "requestID": requestID])
                        throw DownloadError.unknownBusinessCode(code: specialCode)
                    }
                }
                guard statusCode == 200 else {
                    DocsLogger.error("space.thumbnail.downloader --- Unknown http status code", extraInfo: ["statusCode": statusCode, "requestID": requestID])
                    throw DownloadError.unknownStatusCode(code: statusCode)
                }
                guard let contentType = httpResponse.headerString(field: "Content-Type") else {
                    DocsLogger.error("space.thumbnail.downloader --- failed to read content-type header value", extraInfo: ["requestID": requestID])
                    throw DownloadError.parseDataFailed
                }
                guard let data = data else {
                    DocsLogger.error("space.thumbnail.downloader --- failed to get data from response", extraInfo: ["requestID": requestID])
                    throw DownloadError.parseDataFailed
                }
                if contentType.contains("application/json") {
                    let specialCode = try Self.handleSpecialCode(data: data, requestID: requestID)
                    switch specialCode {
                    case 9009:
                        return .fileIsEmpty
                    case 9010:
                        return .fileDeleted
                    default:
                        DocsLogger.error("space.thumbnail.downloader --- Unknown business response code", extraInfo: ["statusCode": statusCode, "code": specialCode, "requestID": requestID])
                        throw DownloadError.unknownBusinessCode(code: specialCode)
                    }
                }
                let etag = httpResponse.headerString(field: "Etag")
                DocsLogger.info("space.thumbnail.downloader --- download thumbnail complete", extraInfo: ["requestID": requestID, "etag": etag as Any])

                if Self.checkIsSpecialImageResponse(httpResponse.allHeaderFields) {
                    DocsLogger.info("space.thumbnail.downloader --- download thumbnail is specialPlaceholder", extraInfo: ["requestID": requestID, "etag": etag as Any])
                    /*
                      新定义一个类型，是为了不在业务层的success大类中里面写if else；
                      这个代表后台返回的一个展位icon，此icon需要抛到业务层去，根据不同的业务场景，生成不同尺寸的新图；
                      走到这里，可能的原因有：空白文档图、无权限、后台生成缩略图失败、文档已经被删除等等
                     */
                    return .specialPlaceHolder(result: data, etag: etag)
                }

                return .success(result: data, etag: etag)
            }
    }
    // enable-lint

    /// 解析
    static private func handleSpecialCode(data: Data?, requestID: String) throws -> Int {
        guard let data = data else {
            DocsLogger.error("space.thumbnail.downloader --- data is nil when handle special code", extraInfo: ["requestID": requestID])
            throw DownloadError.parseDataFailed
        }
        do {
            let decoder = JSONDecoder()
            let specialResponse = try decoder.decode(SpecialResponse.self, from: data)
            DocsLogger.info("space.thumbnail.downloader --- handle special code: \(specialResponse.code)", extraInfo: ["requestID": requestID])
            return specialResponse.code
        } catch {
            DocsLogger.error("space.thumbnail.downloader --- Parse special response code failed", extraInfo: ["requestID": requestID], error: error)
            throw DownloadError.parseDataFailed
        }
    }

    /// 根据加密类型获取解密对象
    static func decrypter(for encryptType: EncryptType) -> SpaceThumbnailDecrypter {
        switch encryptType {
        case .noEncryption:
            return TransparentDecrypter()
        case let .CBC(secret):
            return CBCDecrypter(secret: secret)
        case let .GCM(secret, nonce):
            if #available(iOS 13.0, *) {
                return CryptoKitGCMDecrypter(secret: secret, nonce: nonce)
            } else {
                return CryptoSwiftGCMDecrypter(secret: secret, nonce: nonce)
            }
        case let .SM4GCM(secret, nonce):
            return SM4GCMDecrypter(secret: secret, nonce: nonce)
        }
    }

    func getThumbnailURL(objType: DocsType, objToken: String) -> Single<EncryptInfo> {
        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.getThumbnailURL,
                                        params: ["obj_type": objType.rawValue, "obj_token": objToken])
            .set(method: .GET)
        return request.rxStart()
            .observeOn(ConcurrentDispatchQueueScheduler(queue: downloadQueue))
            .map { (json) -> EncryptInfo in
                guard let json = json else {
                    DocsLogger.error("space.thumbnail.downloader --- json is nil when get thumbnail URL")
                    throw DownloadError.parseDataFailed
                }
                guard let encryptType = json["data"]["decrypt_type"].int,
                    let encryptURL = json["data"]["url"].url else {
                        DocsLogger.error("space.thumbnail.downloader --- failed to parse parameters from json object")
                        throw DownloadError.parseDataFailed
                }
                switch encryptType {
                case 0:
                    return EncryptInfo(url: encryptURL, encryptType: .noEncryption)
                case 2:
                    guard let decryptKey = json["data"]["decrypt_key"].string else {
                        DocsLogger.error("space.thumbnail.downloader --- failed to parse CBC decrypt key when get thumbnail URL")
                        throw DownloadError.parseDataFailed
                    }
                    return EncryptInfo(url: encryptURL, encryptType: .CBC(secret: decryptKey))
                default:
                    DocsLogger.error("space.thumbnail.downloader --- unknown encrypt type when fetch thumbnail url", extraInfo: ["encrypt_type": encryptType])
                    throw DownloadError.parseDataFailed
                }
            }
    }
}

extension SpaceThumbnailDownloader {
    /// 特殊占位图：空白、无权限、后台生成失败、已经删除等情况。
    /// 2020-11-17，3.39及后续版本使用此方案应对: https://bytedance.feishu.cn/docs/doccnRYFxWIBlWXrGAlafZbFZvw#
    /// 2021-02-28，删除FG判断
    static private func checkIsSpecialImageResponse(_ headers: [AnyHashable: Any]) -> Bool {
        let dict = headers as? [String: Any]
        if let newDict = dict,
           let useNewThumbnail = newDict["access-new-default-thumbnail"] as? String,
           useNewThumbnail == "true" {
            return true
        }
        return false
    }
}
