//
//  LocationContent.swift
//  LarkModel
//
//  Created by Fangzhou Liu on 2019/6/10.
//  Copyright © 2019 ByteDance Inc. All rights reserved.
//

import Foundation
import UIKit
import RustPB

public struct LocationContent: MessageContent {
    public typealias PBModel = RustPB.Basic_V1_Message

    // 固有字段
    public let latitude: String
    public let longitude: String
    public let zoomLevel: Int32
    public let vendor: String
    public var image: ImageSet
    public let location: RustPB.Basic_V1_Location
    public var isInternal: Bool

    public init(
        latitude: String,
        longitude: String,
        zoomLevel: Int32,
        vendor: String,
        image: ImageSet,
        location: RustPB.Basic_V1_Location,
        isInternal: Bool
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.zoomLevel = zoomLevel
        self.vendor = vendor
        self.image = image
        self.location = location
        self.isInternal = isInternal
    }

    public static func transform(pb: PBModel) -> LocationContent {
        return LocationContent(
            latitude: pb.content.locationContent.latitude,
            longitude: pb.content.locationContent.longitude,
            zoomLevel: pb.content.locationContent.zoomLevel,
            vendor: pb.content.locationContent.vendor,
            image: pb.content.locationContent.image,
            location: pb.content.locationContent.location,
            isInternal: pb.content.locationContent.isInternal
        )
    }

    public func complement(entity: RustPB.Basic_V1_Entity, message: Message) {}
}
