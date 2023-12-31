//
//  UniversalRecommendRepo.swift
//  LarkSearch
//
//  Created by Patrick on 2021/8/24.
//

import Foundation
import RxSwift
import RxCocoa
import ServerPB

typealias UniversalRecommendRequest = ServerPB_Search_urecommend_UniversalRecommendRequest

protocol UniversalRecommendRepo {
    func getRecommendSection(contentWidth: CGFloat) -> Driver<[UniversalRecommendSection]>
}
