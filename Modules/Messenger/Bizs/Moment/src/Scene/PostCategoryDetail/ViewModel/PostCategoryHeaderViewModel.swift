//
//  PostCategoryHeaderViewModel.swift
//  Moment
//
//  Created by liluobin on 2021/4/28.

import Foundation
import RxSwift
import LarkContainer
import RxCocoa
import LKCommonsLogging

final class PostCategoryHeaderViewModel: UserResolverWrapper {
    let userResolver: UserResolver
    static let logger = Logger.log(PostCategoryHeaderViewModel.self, category: "Module.Moments.PostCategoryHeaderViewModel")

    @ScopedInjectedLazy var categoriesApi: PostCategoriesApiService?
    private let disposeBag = DisposeBag()
    let categoryInputs: CategoryDetailInputs

    var catgegoryEntity: RawData.PostCategory? {
        var entity: RawData.PostCategory?
        switch categoryInputs {
        case .categoryEntity(let entityData):
            entity = entityData
        case .categoryID:
            break
        }
        return entity
    }

    init(userResolver: UserResolver, categoryInputs: CategoryDetailInputs) {
        self.userResolver = userResolver
        self.categoryInputs = categoryInputs
    }

    func getCategoryDetailWithRefreshBlock(_ refresh: ((RawData.CategoryInfoEntity?) -> Void)?) {
        self.categoriesApi?
            .getCategoryDetailRequestWidth(categoryID: self.categoryInputs.id)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { (categoryInfoEntity) in
                refresh?(categoryInfoEntity)
            }, onError: { (error) in
                refresh?(nil)
                Self.logger.error("getCategoryDetailRequest fail --\(error)")
            }).disposed(by: disposeBag)
    }
}
