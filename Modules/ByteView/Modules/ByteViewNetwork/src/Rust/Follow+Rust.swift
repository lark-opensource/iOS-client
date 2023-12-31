//
//  Follow+Rust.swift
//  ByteViewNetwork
//
//  Created by kiri on 2021/12/9.
//  Copyright © 2021 Bytedance.Inc. All rights reserved.
//

import Foundation
import RustPB
import ServerPB

typealias PBFollowPatch = Videoconference_V1_FollowPatch
typealias PBFollowState = Videoconference_V1_FollowState
typealias PBFollowWebData = Videoconference_V1_FollowWebData
typealias PBFollowResource = Videoconference_V1_FollowResource
typealias PBUrlBrief = Videoconference_V1_UrlBrief
typealias PBFollowGrootCellPayload = Videoconference_V1_FollowGrootCellPayload

typealias ServerPBFollowPatch = ServerPB_Videochat_FollowPatch
typealias ServerPBFollowState = ServerPB_Videochat_FollowState
typealias ServerPBFollowWebData = ServerPB_Videochat_FollowWebData
typealias ServerPBFollowResource = ServerPB_Videochat_FollowResource
typealias ServerPBUrlBrief = ServerPB_Videochat_UrlBrief
typealias ServerPBFollowGrootCellPayload = ServerPB_Videochat_FollowGrootCellPayload

extension PBUrlBrief {
    var vcType: FollowUrlBrief {
        .init(url: url, title: title, type: .init(rawValue: type.rawValue) ?? .unknown,
              subtype: .init(rawValue: subtype.rawValue) ?? .unknown, isDirty: isDirty, openInBrowser: openInBrowser, docTenantWatermarkOpen: docTenantWatermarkOpen, docTenantID: docTenantID)
    }
}

extension PBFollowPatch {
    var vcType: FollowPatch {
        .init(sender: sender, opType: .init(rawValue: opType.rawValue) ?? .unknown,
              dataType: .init(rawValue: dataType.rawValue) ?? .unknown, stateKey: nil, webData: hasWebData ? webData.vcType : nil)
    }
}

extension PBFollowState {
    var vcType: FollowState {
        .init(sender: sender, dataType: .init(rawValue: dataType.rawValue) ?? .unknown, stateKey: nil, webData: hasWebData ? webData.vcType : nil)
    }
}

extension PBFollowWebData {
    var vcType: FollowWebData {
        .init(id: id, strategyID: strategyID, payload: payload)
    }
}

extension PBFollowResource {
    var vcType: FollowResource {
        .init(id: id, version: version, type: .init(rawValue: type.rawValue) ?? .unknown, content: content, path: path, isEntry: isEntry)
    }
}

extension FollowWebData {
    var pbType: PBFollowWebData {
        var webData = PBFollowWebData()
        webData.id = id
        webData.strategyID = strategyID
        webData.payload = payload
        return webData
    }

    var serverPbType: ServerPBFollowWebData {
        var webData = ServerPBFollowWebData()
        webData.id = id
        webData.strategyID = strategyID
        webData.payload = payload
        return webData
    }
}

extension FollowPatch {
    var pbType: PBFollowPatch {
        var patch = PBFollowPatch()
        patch.sender = sender
        patch.opType = .init(rawValue: opType.rawValue) ?? .unknownPatchType
        patch.dataType = .init(rawValue: dataType.rawValue) ?? .followDataUnknown
        if let data = webData {
            patch.webData = data.pbType
        }
        if let sk = stateKey {
            patch.stateKey = sk
        }
        return patch
    }

    var serverPbType: ServerPBFollowPatch {
        var patch = ServerPBFollowPatch()
        patch.sender = sender
        patch.opType = .init(rawValue: opType.rawValue) ?? .unknownPatchType
        patch.dataType = .init(rawValue: dataType.rawValue) ?? .followDataUnknown
        if let data = webData {
            patch.webData = data.serverPbType
        }
        return patch
    }
}

extension FollowState {
    var pbType: PBFollowState {
        var state = PBFollowState()
        state.sender = sender
        state.dataType = .init(rawValue: dataType.rawValue) ?? .followDataUnknown
        if let data = webData {
            state.webData = data.pbType
        }
        if let sk = stateKey {
            state.stateKey = sk
        }
        return state
    }

    var serverPbType: ServerPBFollowState {
        var state = ServerPBFollowState()
        state.sender = sender
        state.dataType = .init(rawValue: dataType.rawValue) ?? .followDataUnknown
        if let data = webData {
            state.webData = data.serverPbType
        }
        return state
    }
}


extension FollowUrlBrief: ProtobufDecodable {
    typealias ProtobufType = Videoconference_V1_UrlBrief
    init(pb: Videoconference_V1_UrlBrief) {
        self.init(url: pb.url, title: pb.title,
                  type: .init(rawValue: pb.type.rawValue) ?? .unknown,
                  subtype: .init(rawValue: pb.subtype.rawValue) ?? .unknown,
                  isDirty: pb.isDirty, openInBrowser: pb.openInBrowser,
                  docTenantWatermarkOpen: pb.docTenantWatermarkOpen,
                  docTenantID: pb.docTenantID)
    }

    init(serverPb: ServerPB_Videochat_UrlBrief) {
        self.init(url: serverPb.url, title: serverPb.title,
                  type: .init(rawValue: serverPb.type.rawValue) ?? .unknown,
                  subtype: .init(rawValue: serverPb.subtype.rawValue) ?? .unknown,
                  isDirty: serverPb.isDirty, openInBrowser: serverPb.openInBrowser,
                  docTenantWatermarkOpen: serverPb.docTenantWatermarkOpen,
                  docTenantID: serverPb.docTenantID)
    }
}

extension ServerPBUrlBrief {
    var vcType: FollowUrlBrief {
        .init(url: url, title: title, type: .init(rawValue: type.rawValue) ?? .unknown,
              subtype: .init(rawValue: subtype.rawValue) ?? .unknown, isDirty: isDirty, openInBrowser: openInBrowser, docTenantWatermarkOpen: docTenantWatermarkOpen, docTenantID: /* docTenantID */"")
    }
}

extension ServerPBFollowPatch {
    var vcType: FollowPatch {
        .init(sender: sender, opType: .init(rawValue: opType.rawValue) ?? .unknown,
              dataType: .init(rawValue: dataType.rawValue) ?? .unknown, stateKey: nil, webData: hasWebData ? webData.vcType : nil)
    }
}

extension ServerPBFollowState {
    var vcType: FollowState {
        .init(sender: sender, dataType: .init(rawValue: dataType.rawValue) ?? .unknown, stateKey: nil, webData: hasWebData ? webData.vcType : nil)
    }
}

extension ServerPBFollowWebData {
    var vcType: FollowWebData {
        .init(id: id, strategyID: strategyID, payload: payload)
    }
}

extension ServerPBFollowResource {
    var vcType: FollowResource {
        .init(id: id, version: version, type: .init(rawValue: type.rawValue) ?? .unknown, content: content, path: path, isEntry: isEntry)
    }
}
