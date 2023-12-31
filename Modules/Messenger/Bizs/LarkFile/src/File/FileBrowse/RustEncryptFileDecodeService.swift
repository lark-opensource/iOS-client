//
//  RustEncryptFileDecodeService.swift
//  LarkFile
//
//  Created by zc09v on 2022/6/9.
//

import UIKit
import LarkMessengerInterface
import LarkRustClient
import RustPB
import Foundation
import LarkFoundation
import LarkSDKInterface
import LKCommonsLogging
import LarkStorage
import LarkContainer

private typealias Path = LarkSDKInterface.PathWrapper

//解密rust加密缓存的文件资源
final class RustEncryptFileDecodeServiceImpl: RustEncryptFileDecodeService, UserResolverWrapper {
    static let logger = Logger.log(RustEncryptFileDecodeServiceImpl.self, category: "Module.IM.Message")

    private lazy var rootPathOld: Path.Old = {
        return Path.Old.cachePath + "EncryptFileDecodeTemp"
    }()

    private lazy var rootPathNew: IsoPath = {
            return userResolver.isoPath(in: Domain.biz.messenger, type: .cache) + "EncryptFileDecodeTemp"
        }()

    let userResolver: UserResolver

    //是否已经进行过解密，临时文件启动任务会使用，如果已经有解密新文件了，本地清理暂不进行，以免把本次刚解密、正在使用的误删了
    private var hasDecoded: Bool = false
    private let client: SDKRustService
    private let queue: DispatchQueue = DispatchQueue(label: "RustEncryptFileDecodeService", qos: .utility)

    public init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        self.client = try userResolver.resolve(assert: SDKRustService.self)
    }

    //根据原始路径，返回解密后文件的路径
    public func decode(fileKey: String, fileType: String, sourcePath: URL, finish: @escaping (Result<URL, Error>) -> Void) {
        Self.logger.info("file logic trace decode \(fileKey)")
        let start = CACurrentMediaTime()
        self.queue.async { [weak self] in
            guard let self = self else { return }
            let cost = "\(Int64((CACurrentMediaTime() - start) * 1000)) ms"
            Self.logger.info("file logic trace decode in queue \(fileKey) \(cost)")
            self.hasDecoded = true
            var request = Media_V1_DecryptFileRequest()
            request.srcPath = sourcePath.path
            let pathUrl: URL
            if Path.useLarkStorage {
                let path = self.rootPathNew + "\(fileKey).\(fileType)"
                request.dstPath = path.absoluteString
                pathUrl = path.url
            } else {
                let path: Path.Old = self.rootPathOld + "\(fileKey).\(fileType)"
                request.dstPath = path.url.path
                pathUrl = path.url
            }

            do {
                if Path.useLarkStorage {
                    try self.rootPathNew.createDirectoryIfNeeded()
                } else {
                    try self.rootPathOld.createDirectoryIfNeeded()
                }
                let start = CACurrentMediaTime()
                Self.logger.info("file logic trace decode start \(fileKey)")
                let response: Media_V1_DecryptFileResponse = try self.client.sendSyncRequest(request)
                let cost = "\(Int64((CACurrentMediaTime() - start) * 1000)) ms"
                Self.logger.info("file logic trace decode end \(fileKey) \(cost)")
                DispatchQueue.main.async {
                    if response.isNotEncrypted {
                        //如果报没有加密，但意外调用了解密接口，直接返回原路径
                        Self.logger.info("file logic trace decode isNotEncrypted \(fileKey)")
                        finish(.success(sourcePath))
                    } else {
                        finish(.success(pathUrl))
                    }
                }
            } catch {
                Self.logger.error("file logic trace decode error \(fileKey)", error: error)
                DispatchQueue.main.async {
                    finish(.failure(error))
                }
            }
        }
    }

    public func clean(force: Bool) {
        Self.logger.info("file logic trace clean temp cache \(self.hasDecoded) \(force)")
        self.queue.async { [weak self] in
            guard let self = self else { return }
            Self.logger.info("file logic trace clean temp cache in queue")
            if !force, self.hasDecoded {
                //如果已经有解密新文件了，本次清理暂不进行，以免把本次刚解密、正在使用的误删了
                return
            }
            //清理
            do {
                Self.logger.info("file logic trace clean temp cache start clean")
                if Path.useLarkStorage {
                    if self.rootPathNew.exists {
                        try self.rootPathNew.removeItem()
                    }
                } else {
                    if self.rootPathOld.exists {
                        try self.rootPathOld.deleteFile()
                    }
                }
                Self.logger.info("file logic trace clean temp cache clean finish")
            } catch {
                Self.logger.error("file logic trace clean temp cache error", error: error)
            }
        }
    }
}
