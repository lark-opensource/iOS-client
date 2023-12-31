//
//  MagicShare+Rust.swift
//  ByteViewNetwork
//
//  Created by liurundong.henry on 2023/5/15.
//

import Foundation
import RustPB

typealias PBFollowInfo = Videoconference_V1_FollowInfo
typealias PBThumbnailDetail = Videoconference_V1_ThumbnailDetail
typealias PBFollowStrategy = Videoconference_V1_FollowStrategy

extension PBFollowInfo {
    var vcType: FollowInfo {
        .init(userID: userID,
              userType: userType.vcType,
              deviceID: deviceID,
              thumbnail: thumbnail.vcType,
              url: url,
              rawURL: rawURL,
              options: hasOptions ? options.vcType : nil,
              lifeTime: .init(rawValue: lifeTime.rawValue) ?? .unknown,
              shareID: shareID,
              shareType: .init(rawValue: shareType.rawValue) ?? .unknown,
              shareSubtype: .init(rawValue: shareSubtype.rawValue) ?? .unknown,
              docToken: docToken,
              docType: .init(rawValue: docType.rawValue) ?? .unknown,
              docTitle: docTitle,
              strategies: strategies.map({ $0.vcType }),
              version: version,
              initSource: .init(rawValue: initSource.rawValue) ?? .unknown,
              extraInfo: extraInfo.vcType)
    }
}

extension PBFollowInfo.Options {
    var vcType: FollowInfo.Options {
        .init(defaultFollow: defaultFollow,
              forceFollow: forceFollow)
    }
}

extension PBFollowStrategy {
    var vcType: FollowStrategy {
        .init(id: id,
              resourceVersions: resourceVersions,
              settings: settings,
              keepOrder: keepOrder,
              iosResourceIds: iosResourceIds)
    }
}

extension PBThumbnailDetail {
    var vcType: FollowInfo.ThumbnailDetail {
        .init(thumbnailURL: thumbnailURL,
              decryptKey: decryptKey,
              cipherType: .init(rawValue: cipherType.rawValue) ?? .unencrypted,
              nonce: nonce)
    }
}

extension PBFollowInfo.ShareSubType {
    var vcType: FollowShareSubType {
        .init(rawValue: rawValue) ?? .ccmDoc
    }
}

extension PBFollowInfo.ExtraInfo {
    var vcType: FollowInfo.ExtraInfo {
        .init(sharerTenantWatermarkOpen: sharerTenantWatermarkOpen,
              docTenantWatermarkOpen: docTenantWatermarkOpen,
              actionUniqueID: actionUniqueID,
              docTenantID: docTenantID)
    }
}
