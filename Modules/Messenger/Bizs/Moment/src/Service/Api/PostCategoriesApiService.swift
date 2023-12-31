//
//  PostCategoriesApiService.swift
//  Moment
//
//  Created by bytedance on 2021/4/22.
//

import Foundation
import RxSwift
import RustPB
import ServerPB

enum CategoryApi { }
extension CategoryApi {
    typealias RxGetCategories = Observable<[RawData.PostCategory]>
}
/// 获取Categories列表接口
protocol PostCategoriesApiService {
    func getListCategories(forceRemote: Bool) -> CategoryApi.RxGetCategories
    func getCategoryDetailRequestWidth(categoryID: String) -> Observable<RawData.CategoryInfoEntity>
}

extension RustApiService: PostCategoriesApiService {

    func getCategoryDetailRequestWidth(categoryID: String) -> Observable<RawData.CategoryInfoEntity> {
        var request = Moments_V1_GetCategoryDetailRequest()
        request.categoryID = categoryID
        return client.sendAsyncRequest(request)
            .map { (response: Moments_V1_GetCategoryDetailResponse) -> RawData.CategoryInfoEntity in
                let category = response.entities.categories.values.first
                var adminUsers: [MomentUser]?
                if let category = category {
                    adminUsers = category.adminUserIds.compactMap({ userId in
                        return response.entities.users[userId]
                    })
                }
                let data = RawData.CategoryInfoEntity(adminUsers: adminUsers, category: response.entities.categories.values.first, categoryStats: response.stats)
                return data
            }
    }

    func getListCategories(forceRemote: Bool = false) -> CategoryApi.RxGetCategories {
        var request = RustPB.Moments_V1_ListCategoriesRequest()
        request.forceRemote = forceRemote
        return client.sendAsyncRequest(request).map { (response: Moments_V1_ListCategoriesResponse) -> [RawData.PostCategory] in
            let datas = response.categoryIds.compactMap { (id) -> RawData.PostCategory? in
                if let category = response.entities.categories[id] {
                    let adminUsers: [MomentUser] = category.adminUserIds.compactMap({ userId in
                        return response.entities.users[userId]
                    })
                    return RawData.PostCategory(category: category, adminUsers: adminUsers)
                }
                return nil
            }
            return datas
        }
    }
}
