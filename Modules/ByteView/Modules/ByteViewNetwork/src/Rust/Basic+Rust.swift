//
//  Basic+Rust.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/11/29.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import ByteViewCommon
import RustPB
import ServerPB

typealias PBI18nKeyInfo = Videoconference_V1_I18nKeyInfo
typealias PBMsgInfo = Videoconference_V1_MsgInfo
typealias PBMegaI18n = Videoconference_V1_MegaI18n
typealias PBGetAdminSettingsResponse = Videoconference_V1_GetAdminSettingsResponse
typealias PBMeetingBackground = Videoconference_V1_MeetingBackground

typealias ServerPBI18nKeyInfo = ServerPB_Videochat_I18nKeyInfo
typealias ServerPBMsgInfo = ServerPB_Videochat_MsgInfo
typealias ServerPBMegaI18n = ServerPB_Videochat_MegaI18n
typealias ServerPBGetAdminSettingsResponse = ServerPB_Videochat_GetAdminSettingsResponse
typealias ServerPBMeetingBackground = ServerPB_Videochat_MeetingBackground
typealias ServerPBPSTNPhone = ServerPB_Videochat_PSTNPhone

extension PBI18nKeyInfo {
    var vcType: I18nKeyInfo {
        .init(key: key, params: params, type: .init(rawValue: type.rawValue) ?? .unknown,
              jumpScheme: jumpScheme, newKey: newKey,
              i18NParams: i18NParams.mapValues({ $0.vcType }))
    }
}

private extension PBI18nKeyInfo.I18nParam {
    var vcType: I18nKeyInfo.I18nParam {
        .init(type: .init(rawValue: type.rawValue) ?? .unknown, val: val)
    }
}

extension ServerPBI18nKeyInfo {
    var vcType: I18nKeyInfo {
        .init(key: key, params: params, type: .init(rawValue: type.rawValue) ?? .unknown,
              jumpScheme: jumpScheme, newKey: newKey,
              i18NParams: i18NParams.mapValues({ $0.vcType }))
    }
}

private extension ServerPBI18nKeyInfo.I18nParam {
    var vcType: I18nKeyInfo.I18nParam {
        .init(type: .init(rawValue: type.rawValue) ?? .unknown, val: val)
    }
}

extension MsgInfo: _NetworkDecodable, NetworkDecodable {
    typealias ProtobufType = PBMsgInfo

    init(pb: PBMsgInfo) {
        self.init(type: .init(rawValue: pb.type.rawValue) ?? .unknown, expire: pb.expire, message: pb.message,
                  isShow: pb.isShow, isOverride: pb.isOverride,
                  msgI18NKey: pb.hasMsgI18NKey ? pb.msgI18NKey.vcType : nil,
                  msgTitleI18NKey: pb.hasMsgTitleI18NKey ? pb.msgTitleI18NKey.vcType : nil,
                  popupType: .init(rawValue: pb.popUpType.rawValue) ?? .unknown,
                  alert: pb.hasAlert ? pb.alert.vcType : nil,
                  toastIcon: .init(rawValue: pb.icon.rawValue) ?? .unknown,
                  msgButtonI18NKey: pb.hasMsgButtonI18NKey ? pb.msgButtonI18NKey.vcType : nil,
                  monitor: pb.monitor.vcType)
    }


    init(serverPb: ServerPBMsgInfo) {
        self.init(type: .init(rawValue: serverPb.type.rawValue) ?? .unknown, expire: serverPb.expire, message: serverPb.message,
                  isShow: serverPb.isShow, isOverride: serverPb.isOverride,
                  msgI18NKey: serverPb.hasMsgI18NKey ? serverPb.msgI18NKey.vcType : nil,
                  msgTitleI18NKey: serverPb.hasMsgTitleI18NKey ? serverPb.msgTitleI18NKey.vcType : nil,
                  popupType: .init(rawValue: serverPb.popUpType.rawValue) ?? .unknown,
                  alert: serverPb.hasAlert ? serverPb.alert.vcType : nil,
                  toastIcon: .init(rawValue: serverPb.icon.rawValue) ?? .unknown,
//                  msgButtonI18NKey: serverPb.hasMsgButtonI18NKey ? serverPb.msgButtonI18NKey.vcType : nil)
                  msgButtonI18NKey: nil, monitor: nil)
    }


    init(jsonString: String) throws {
        self.init(pb: try PBMsgInfo(jsonString: jsonString, options: .ignoreUnknownFieldsOption))
    }
}

extension PBMsgInfo {
    var vcType: MsgInfo {
        MsgInfo(pb: self)
    }
}

extension ServerPBMsgInfo {
    var vcType: MsgInfo {
        MsgInfo(serverPb: self)
    }
}

extension PBMsgInfo.Alert {
    var vcType: MsgInfo.Alert {
        .init(title: title.vcType, body: body.vcType,
              footer: hasFooter ? footer.vcType : nil,
              footer2: hasFooter2 ? footer2.vcType : nil)
    }
}

extension PBMsgInfo.Alert.Text {
    var vcType: MsgInfo.Alert.Text {
        .init(i18NKey: i18NKey)
    }
}

extension PBMsgInfo.Alert.Button {
    var vcType: MsgInfo.Alert.Button {
        .init(text: text.vcType, waitTime: waitTime, color: .init(rawValue: color.rawValue) ?? .black)
    }
}

extension ServerPBMsgInfo.Alert {
    var vcType: MsgInfo.Alert {
        .init(title: title.vcType, body: body.vcType,
              footer: hasFooter ? footer.vcType : nil,
              footer2: hasFooter2 ? footer2.vcType : nil)
    }
}

extension ServerPBMsgInfo.Alert.Text {
    var vcType: MsgInfo.Alert.Text {
        .init(i18NKey: i18NKey)
    }
}

extension ServerPBMsgInfo.Alert.Button {
    var vcType: MsgInfo.Alert.Button {
        .init(text: text.vcType, waitTime: waitTime, color: .init(rawValue: color.rawValue) ?? .black)
    }
}

extension PBMegaI18n {
    var vcType: MegaI18n {
        .init(key: key, data: data.mapValues({
            MegaI18n.I18nData(type: .init(rawValue: $0.type.rawValue) ?? .unknown, payload: $0.payload)
        }))
    }
}

extension ServerPBMegaI18n {
    var vcType: MegaI18n {
        .init(key: key, data: data.mapValues({
            MegaI18n.I18nData(type: .init(rawValue: $0.type.rawValue) ?? .unknown, payload: $0.payload)
        }))
    }
}

extension PSTNPhone: ProtobufDecodable, ProtobufEncodable {
    typealias ProtobufType = Videoconference_V1_PSTNPhone

    init(pb: Videoconference_V1_PSTNPhone) {
        self.country = pb.country
        self.type = .init(rawValue: pb.type.rawValue) ?? .unknown
        self.number = pb.number
        self.numberDisplay = pb.numberDisplay
    }

    func toProtobuf() -> Videoconference_V1_PSTNPhone {
        var pb = ProtobufType()
        pb.country = country
        pb.type = .init(rawValue: type.rawValue) ?? .unknown
        pb.number = number
        pb.numberDisplay = numberDisplay
        return pb
    }
}

extension ServerPBPSTNPhone {
    var vcType: PSTNPhone {
        .init(country: country,
              type: .init(rawValue: type.rawValue) ?? .unknown,
              number: number,
              numberDisplay: numberDisplay)
    }
}

extension PBMsgInfo.Monitor {
    var vcType: MsgInfo.Monitor {
        .init(logID: logID,
              blockType: .init(rawValue: blockType.rawValue) ?? .unknown,
              ownerTenantID: ownerTenantID)
    }
}
