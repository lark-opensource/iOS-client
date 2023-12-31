//
//  EMTask.swift
//  LarkUrgent
//
//  Created by Saafo on 2021/8/9.
//

import Foundation
import BootManager
import LarkContainer
import LarkRustClient
import LarkSetting
import LarkStorage
import SwiftProtobuf
import RxSwift
import ServerPB
import LKCommonsLogging

private let logger = Logger.log(EMManager.self, category: "LarkEM.EMManager")

final class EMTask: UserFlowBootTask, Identifiable {
    static let identify = "EMTask"

    override class var compatibleMode: Bool { Urgent.userScopeCompatibleMode }

    override func execute(_ context: BootContext) {
        let featureGatingService = try? userResolver.resolve(assert: FeatureGatingService.self)

        guard featureGatingService?.staticFeatureGatingValue(with: FeatureGatingManager.Key(stringLiteral: EMManager.Cons.emEnabled)) ?? false else {
            EMManager.destruct()
            return
        }
        EMManager.setup(
            networkProvider: EMNetwork(client: try? userResolver.resolve(assert: RustService.self)),
            storageProvider: EMStorage(),
            logProvider: EMLogger()
        )
        logger.debug("EM finished setup")
    }
}

final class EMStorage: EMManagerStorageProvider {
    let store = KVStores.udkv(space: .global, domain: Domain.biz.messenger.child("Urgent"))
    func intValue(for key: String) -> Int? {
        return store[key]
    }
    func set(int value: Int?, for key: String) {
        store[key] = value
    }
    func dateValue(for key: String) -> Date? {
        return store[key]
    }
    func set(date value: Date?, for key: String) {
        store[key] = value
    }
}

final class EMLogger: EMManagerLogProvider {
    func error(_ message: String) {
        logger.error(message)
    }
    func info(_ message: String) {
        logger.info(message)
    }
}

final class EMNetwork: EMManagerNetworkProvider {
    init(client: RustService?) {
        self.client = client
    }
    private var client: RustService?

    private var disposeBag = DisposeBag()

    func sendToUser(completion: @escaping (Result<Int64, Error>) -> Void) {
        let request = ServerPB_Em_SendEMToUserRequest()
        client?.sendPassThroughAsyncRequest(request, serCommand: .sendEmToUser)
            .asSingle()
            .timeout(.seconds(6), scheduler: MainScheduler.instance)
            .subscribe(onSuccess: { (response: ServerPB_Em_SendEMToUserResponse) in
                logger.info("sendToUser network succeeded")
                completion(.success(response.recordID))
            }, onError: { error in
                logger.error("sendToUser network error: \(error)")
                if case .businessFailure(errorInfo: let info) = error as? RCError,
                   let emError = EMError(rawValue: Int(info.code)) {
                    completion(.failure(emError))
                } else {
                    completion(.failure(error))
                }
            }).disposed(by: disposeBag)
    }

    func sendInfo(_ info: Data, completion: @escaping (Result<Date, Error>) -> Void) {
        var request = ServerPB_Em_SendEMInfoRequest()
        request.payload = info
        client?.sendPassThroughAsyncRequest(request, serCommand: .sendEmInfo)
            .asSingle()
            .timeout(.seconds(6), scheduler: MainScheduler.instance)
            .subscribe(onSuccess: { (response: ServerPB_Em_SendEMInfoResponse) in
                logger.info("sendInfo network succeeded")
                let createDate = Date(timeIntervalSince1970: TimeInterval(Int(response.createTime)))
                completion(.success(createDate))
            }, onError: { error in
                logger.error("sendInfo network error: \(error)")
                if case .businessFailure(errorInfo: let info) = error as? RCError,
                   let emError = EMError(rawValue: Int(info.code)) {
                    completion(.failure(emError))
                } else {
                    completion(.failure(error))
                }
            }).disposed(by: disposeBag)
    }

    func checkStatus(completion: @escaping (Result<CheckStatusResponse, Error>) -> Void) {
        let request = ServerPB_Em_CheckEMStatusRequest()
        client?.sendPassThroughAsyncRequest(request, serCommand: .checkEmStatus)
            .asSingle()
            .timeout(.seconds(6), scheduler: MainScheduler.instance)
            .subscribe(onSuccess: { (response: ServerPB_Em_CheckEMStatusResponse) in
                logger.info("checkStatus network succeeded")
                let result: CheckStatusResponse
                if response.hasRecordID && response.status == .active {
                    result = CheckStatusResponse(
                        active: true, recordID: response.recordID,
                        lastSendInfoTime: Date(timeIntervalSince1970: TimeInterval(Int(response.lastSendInfoTime)))
                    )
                } else {
                    result = CheckStatusResponse(active: false, recordID: nil, lastSendInfoTime: nil)
                }
                completion(.success(result))
            }, onError: { error in
                logger.error("checkStatus network error: \(error)")
                if case .businessFailure(errorInfo: let info) = error as? RCError,
                   let emError = EMError(rawValue: Int(info.code)) {
                    completion(.failure(emError))
                } else {
                    completion(.failure(error))
                }
            }).disposed(by: disposeBag)
    }

    func existActiveRecord(completion: @escaping (Result<Bool, Error>) -> Void) {
        let request = ServerPB_Em_ExistActiveEMTaskRequest()
        client?.sendPassThroughAsyncRequest(request, serCommand: .existActiveEmTask)
            .asSingle()
            .timeout(.seconds(6), scheduler: MainScheduler.instance)
            .subscribe(onSuccess: { (response: ServerPB_Em_ExistActiveEMTaskResponse) in
                logger.info("existActiveRecord network succeeded")
                completion(.success(response.existActiveTask))
            }, onError: { error in
                logger.error("existActiveRecord network error: \(error)")
                if case .businessFailure(errorInfo: let info) = error as? RCError,
                   let emError = EMError(rawValue: Int(info.code)) {
                    completion(.failure(emError))
                } else {
                    completion(.failure(error))
                }
            }).disposed(by: disposeBag)
    }

    func pullRecords(completion: @escaping (Result<PullEMRecordsResponse, Error>) -> Void) {
        let request = ServerPB_Em_PullEMRecordsRequest()
        client?.sendPassThroughAsyncRequest(request, serCommand: .pullEmRecords)
            .asSingle()
            .timeout(.seconds(6), scheduler: MainScheduler.instance)
            .subscribe(onSuccess: { (response: ServerPB_Em_PullEMRecordsResponse) in
                logger.info("pullRecords network succeeded")
                let records = response.records.map {
                    PullEMRecordsResponse.EMRecord(
                        createTime: $0.createTime, active: $0.status == .active,
                        recordID: $0.recordID, deviceID: $0.deviceID
                    )
                }
                let result = PullEMRecordsResponse(records: records)
                completion(.success(result))
            }, onError: { error in
                logger.error("pullRecords network error: \(error)")
                if case .businessFailure(errorInfo: let info) = error as? RCError,
                   let emError = EMError(rawValue: Int(info.code)) {
                    completion(.failure(emError))
                } else {
                    completion(.failure(error))
                }
            }).disposed(by: disposeBag)
    }

    func cancelRequest(recordID: Int64, completion: @escaping (Result<CancelResponse, Error>) -> Void) {
        var request = ServerPB_Em_CancelEMRequest()
        request.recordID = recordID
        client?.sendPassThroughAsyncRequest(request, serCommand: .cancelEm)
            .asSingle()
            .timeout(.seconds(6), scheduler: MainScheduler.instance)
            .subscribe(onSuccess: { (response: ServerPB_Em_CancelEMResponse) in
                logger.info("cancelRequest network succeeded")
                let result = CancelResponse(recordID: response.recordID, existActiveTask: response.existActiveTask)
                completion(.success(result))
            }, onError: { error in
                logger.error("cancelRequest network error: \(error)")
                if case .businessFailure(errorInfo: let info) = error as? RCError,
                   let emError = EMError(rawValue: Int(info.code)) {
                    completion(.failure(emError))
                } else {
                    completion(.failure(error))
                }
            }).disposed(by: disposeBag)
    }
}
