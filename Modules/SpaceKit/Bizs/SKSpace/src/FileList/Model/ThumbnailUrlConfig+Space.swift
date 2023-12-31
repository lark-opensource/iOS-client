//
//  ThumbnailUrlConfig.swift
//  SKECM
//
//  Created by guoqp on 2020/7/17.
//

import Foundation
import SwiftyJSON
import SKCommon
import SKUIKit

extension ThumbnailUrlConfig {
    public static var gridThumbnailSizeParams: [String: Any] {
        let size = SpaceGridCell.thumbnailSizeForRequest
        return thumbnailParams(size: size)
    }
}
