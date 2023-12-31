//
//  WPAppSearchModel.swift
//  LarkWorkplace
//
//  Created by 李论 on 2020/6/24.
//

import RustPB
import RxSwift
import SwiftyJSON
import Swinject
import LarkWorkplaceModel
import LarkSetting

final class WPAppSearchModel: NSObject {
    private let dataManager: AppCenterDataManager
    private let configService: WPConfigService

    var lastSearchedText = ""

    init(dataManager: AppCenterDataManager, configService: WPConfigService) {
        self.dataManager = dataManager
        self.configService = configService
    }

    func search(
        keyWord: String,
        disposeBag: DisposeBag,
        success: @escaping (_ model: WPSearchCategoryApp) -> Void,
        failure: @escaping (_ error: Error) -> Void
    ) {
        dataManager.asyncQueryApps(
            with: keyWord,
            disposeBag: disposeBag,
            success: { (model) in
                success(model)
            },
            failure: { (err) in
                failure(err)
            }
        )
    }
}
