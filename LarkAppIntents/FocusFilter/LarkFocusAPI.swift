//
//  LarkFocusAPI.swift
//  LarkAppIntents
//
//  Created by Hayden on 2022/9/5.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import LarkHTTP
import LarkExtensionServices

@available(iOS 16.0, *)
final class FocusAPI {
    static func getFocusList(_ completionHandler: (([ServerPB_Im_settings_UserCustomStatus]) -> Void)? = nil) {
        let request = ServerPB_Im_settings_PullUserCustomStatusesRequest()
        let data = wrapServerPBRequest(request, command: .pullUserCustomStatuses)

        HTTP.POSTForLark(data: data) { response in
            if let error = response.error {
                Logger.error("--->>> [LarkFocusAPI] getFocusList request failed: \(error)")
                completionHandler?([])
                return
            }
            do {
                let packet = try ServerPB_Improto_Packet(serializedData: response.data)
                let res = try ServerPB_Im_settings_PullUserCustomStatusesResponse(serializedData: packet.payload)
                // 系统状态 (systemV2) 不可手动设置，此处需要过滤掉
                let validStatuses = res.customStatuses.filter { $0.typeV2 != .systemV2 }
                Logger.info("--->>> [LarkFocusAPI] getFocusList succeed: \(validStatuses.map({ "[\($0.id), \($0.title)]" }))")
                completionHandler?(validStatuses)
            } catch let error {
                Logger.error("--->>> [LarkFocusAPI] getFocusList parse failed: \(error)")
                completionHandler?([])
            }
        }
    }

    static func getFocusList() async -> [ServerPB_Im_settings_UserCustomStatus] {
        return await withCheckedContinuation { continuation in
            getFocusList { statusList in
                continuation.resume(returning: statusList)
            }
        }
    }

    static func turnOffStatus(byID id: Int64, completionHandler: (() -> Void)? = nil) {
        var req = ServerPB_Im_settings_UpdateUserCustomStatusRequest()
        var updater = ServerPB_Im_settings_UpdateUserCustomStatus()
        updater.id = id
        updater.effectiveInterval.isShowEndTime = true
        updater.fields.append(.effectiveInterval)
        req.isSynFromSys = true
        req.updateStatuses = [updater]
        let data = wrapServerPBRequest(req, command: .updateUserCustomStatus)
        HTTP.POSTForLark(data: data) { response in
            completionHandler?()
            if let error = response.error {
                Logger.error("--->>> [LarkFocusAPI] turnOffStatus failed: \(error)")
            } else {
                Logger.info("--->>> [LarkFocusAPI] turnOffStatus succeed.")
            }
        }
    }

    static func turnOffStatus(byID id: Int64) async {
        return await withCheckedContinuation { continuation in
            turnOffStatus(byID: id) {
                continuation.resume()
            }
        }
    }

    static func turnOnStatus(byID id: Int64, completionHandler: (() -> Void)? = nil) {
        var req = ServerPB_Im_settings_UpdateUserCustomStatusRequest()
        var updater = ServerPB_Im_settings_UpdateUserCustomStatus()
        updater.id = id
        updater.lastCustomizedEndTime = Int64(Date().addingTimeInterval(30 * 24 * 60 * 60).timeIntervalSince1970)
        updater.effectiveInterval.startTime = Int64(Date().timeIntervalSince1970)
        updater.effectiveInterval.endTime = Int64(Date().addingTimeInterval(30 * 24 * 60 * 60).timeIntervalSince1970)
        updater.effectiveInterval.isShowEndTime = true
        updater.effectiveInterval.isOpenWithoutEndTime = true
        updater.fields.append(contentsOf: [.effectiveInterval, .lastCustomizedEndTime])
        req.isSynFromSys = true
        req.updateStatuses = [updater]
        let data = wrapServerPBRequest(req, command: .updateUserCustomStatus)
        HTTP.POSTForLark(data: data) { response in
            completionHandler?()
            if let error = response.error {
                Logger.error("--->>> [LarkFocusAPI] turnOnStatus failed: \(error)")
            } else {
                Logger.info("--->>> [LarkFocusAPI] turnOnStatus succeed.")
            }
        }
    }

    static func turnOnStatus(byID id: Int64) async {
        return await withCheckedContinuation { continuation in
            turnOnStatus(byID: id) {
                continuation.resume()
            }
        }
    }

    static func wrapServerPBRequest(_ request: LarkHTTP.Message, command: ServerPB_Improto_Command) -> Data {
        do {
            var requestPacket = ServerPB_Improto_Packet()
            requestPacket.cid = String.randomStr(len: 40)
            requestPacket.cmd = command
            requestPacket.payloadType = .pb2
            requestPacket.payload = try request.serializedData()
            let httpBody = try requestPacket.serializedData()
            return httpBody
        } catch {
            assertionFailure("should never reach here!")
            return Data()
        }
    }
}
