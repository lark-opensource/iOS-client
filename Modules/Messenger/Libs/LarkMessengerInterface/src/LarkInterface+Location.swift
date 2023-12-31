//
//  LarkInterface+Location.swift
//  LarkInterface
//
//  Created by Fangzhou Liu on 2019/6/14.
//  Copyright © 2019 ByteDance Inc. All rights reserved.
//

import Foundation
import LarkModel
import EENavigator
import SuiteCodable
import CoreLocation
import UIKit

public enum LocationSource {
    case common
    case favorite(id: String)
}

public enum LocationSystem {
    case WGS84
    case GCJ02
}

/// 定位 导航
public struct LocationNavigateBody: PlainBody {
    public static var pattern: String = "//client/chat/navigate"

    public let messageID: String
    public let message: Message?
    public let fromCryptoChat: Bool
    public let source: LocationSource
    public let psdaToken: String

    public init(messageID: String,
                message: Message? = nil,
                source: LocationSource,
                psdaToken: String,
                isCrypto: Bool = false) {
        self.messageID = messageID
        self.message = message
        self.fromCryptoChat = isCrypto
        self.source = source
        self.psdaToken = psdaToken
    }
}

/// open  api for miniprograme
public struct OpenLocationBody: PlainBody {
    public static var pattern: String = "//client/location/open"

    public let location: CLLocationCoordinate2D
    public let name: String
    public let address: String
    public let type: LocationSystem
    public let zoomLevel: Double
    public let psdaToken: String

    public init(location: CLLocationCoordinate2D,
                name: String,
                address: String,
                zoomLevel: Double = 14.5,
                type: LocationSystem,
                psdaToken: String) {
        self.location = location
        self.name = name
        self.address = address
        self.type = type
        self.zoomLevel = zoomLevel
        self.psdaToken = psdaToken
    }
}

public struct SendLocationBody: PlainBody {
    public static var pattern: String = "//client/chat/sendlocation"

    public var sendAction: ((LocationContent, UIImage, String, String) -> Void)?

    public let psdaToken: String
    public init(psdaToken: String) {
        self.psdaToken = psdaToken
    }
}

public struct LarkLocation {
    var name: String
    var address: String
    var location: CLLocationCoordinate2D
    var zoomLevel: Double
    var isInternal: Bool
    var image: UIImage
    // enum: .amap or .apple
    var mapType: String
    // enum: defatult, list or search
    var selectType: String

    public init(
        name: String,
        address: String,
        location: CLLocationCoordinate2D,
        zoomLevel: Double,
        isInternal: Bool = true,
        image: UIImage,
        mapType: String,
        selectType: String
    ) {
        self.name = name
        self.address = address
        self.location = location
        self.zoomLevel = zoomLevel
        self.isInternal = isInternal
        self.image = image
        self.mapType = mapType
        self.selectType = selectType
    }
}

/// open  api for miniprograme
public struct ChooseLocationBody: PlainBody {
    public static var pattern: String = "//client/location/choose"

    public var sendAction: ((LarkLocation) -> Void)?
    public var cancelAction: (() -> Void)?
    public let psdaToken: String

    public init(psdaToken: String) {
        self.psdaToken = psdaToken
    }
}
