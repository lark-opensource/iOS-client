//
//  FetchClientLogPathAPI.swift
//  LarkAccount
//
//  Created by au on 2021/9/22.
//

import Foundation
import LarkContainer
import LarkRustClient
import LKCommonsLogging
import RustPB
import RxCocoa
import RxSwift

typealias fetchClientLogPathRequest = RustPB.Tool_V1_CompressedPackageLogRequest
typealias fetchClientLogPathResponse = RustPB.Tool_V1_CompressedPackageLogResponse

/// 获取日志存储的绝对路径，Rust 对接 @limingjian
class FetchClientLogPathAPI {

    @Provider var service: GlobalRustService
    
    static let logger = Logger.plog(FetchClientLogPathAPI.self, category: "Passport.FetchClientLogPathAPI")
    
    func fetchClientLogPath(completion: @escaping (String?) -> Void) {
        var request = fetchClientLogPathRequest()
        // 考虑到跨一个周末的场景，和 Android 一致
        request.days = 4
        // 传空字符串
        request.compressedPackagePath = ""
        
        return service
            .async(RequestPacket(message: request)) { (responsePacket: ResponsePacket<fetchClientLogPathResponse>) -> Void in
                do {
                    Self.logger.info("n_action_fetch_client_log_path_succ")
                    let path = try responsePacket.result.get().compressedPackagePath
                    completion(path)
                } catch {
                    Self.logger.error("n_action_fetch_client_log_path_error", error: error)
                    completion(nil)
                }
            }
    }
}

typealias PackAndUploadLogRequest = RustPB.Tool_V1_PackAndUploadLogRequest
typealias PackAndUploadLogResponse = RustPB.Tool_V1_PackAndUploadLogResponse
typealias PackAndUploadLogFailedReason = RustPB.Tool_V1_PackAndUploadLogResponse.FailedReason

final class PackAndUploadLogAPI {

    @Provider var service: GlobalRustService

    static let logger = Logger.log(PackAndUploadLogAPI.self, category: "Passport.PackAndUploadLogAPI")

    func packAndUploadLog(token: UInt32, completion: @escaping (PackAndUploadLogFailedReason?) -> Void) {
        var request = PackAndUploadLogRequest()
        request.logifierToken = token
        Self.logger.info("n_action_client_log_upload_api: enter")
        return service
            .async(RequestPacket(message: request)) { (responsePacket: ResponsePacket<PackAndUploadLogResponse>) -> Void in
                let result = responsePacket.result
                switch result {
                case .success:
                    do {
                        let isSuccess = try result.get().isSuccess
                        if isSuccess {
                            Self.logger.info("n_action_client_log_upload_api: success")
                            completion(nil)
                        } else {
                            let reason = try result.get().failedReason
                            Self.logger.error("n_action_client_log_upload_api: request success but result failed \(reason.rawValue)")
                            completion(reason)
                        }
                    } catch {
                        Self.logger.error("n_action_client_log_upload_api: unknown error (succ part) \(error.localizedDescription)")
                        completion(PackAndUploadLogFailedReason.unknown)
                    }
                case .failure:
                    do {
                        let reason = try result.get().failedReason
                        Self.logger.info("n_action_client_log_upload_api: failed \(reason.rawValue)")
                        completion(reason)
                    } catch {
                        Self.logger.error("n_action_client_log_upload_api: unknown error (fail part) \(error.localizedDescription)")
                        completion(PackAndUploadLogFailedReason.unknown)
                    }
                }
            }
    }
}
