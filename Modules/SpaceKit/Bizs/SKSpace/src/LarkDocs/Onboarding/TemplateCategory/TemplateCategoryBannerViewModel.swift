//
//  TemplateCategoryBannerViewModel.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/26.
//

import Foundation
import RxSwift
import RxRelay
import RxCocoa
import SKCommon
import SKFoundation
import SwiftyJSON

enum TemplateCategoryBannerViewModel {
    struct Category: Codable {
        let name: String
        let categoryID: Int
        let imageURL: URL

        enum CodingKeys: String, CodingKey {
            case name
            case categoryID = "category_id"
            case imageURL = "mobile_image_url"
        }
    }
}
