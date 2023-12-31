//
//  WPNormalHomeDataService.swift
//  LarkWorkplace
//
//  Created by ByteDance on 2022/12/13.
//

import Foundation
import LKCommonsLogging

protocol WPNormalHomeDataService: AnyObject {

    func updateHomeData(dataModel: WorkPlaceDataModel?)

    func getHomeData() -> WorkPlaceDataModel?
}

final class WPNormalHomeDataServiceImpl: WPNormalHomeDataService {
    static let logger = Logger.log(WPNormalHomeDataService.self)

    private var workplaceDataModel: WorkPlaceDataModel?

    func updateHomeData(dataModel: WorkPlaceDataModel?) {
        if let workplaceDataModel = dataModel {
            Self.logger.info("update workplaceDataModel")
            self.workplaceDataModel = workplaceDataModel
        }
    }

    func getHomeData() -> WorkPlaceDataModel? {
        return workplaceDataModel
    }
}
