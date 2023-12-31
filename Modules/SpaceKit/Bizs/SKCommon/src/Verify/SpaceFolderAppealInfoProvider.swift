//
//  SpaceFolderAppealInfoProvider.swift
//  SKCommon
//
//  Created by Weston Wu on 2022/1/25.
//

import Foundation
import SKFoundation
import SwiftyJSON
import SKResource
import SKInfra

public final class SpaceFolderAppealInfoProvider: AppealInfoProvider {
    let token: String
    let isSingleContainer: Bool
    private var request: DocsRequest<JSON>?

    public var appealingTipsLine1: String {
        BundleI18n.SKResource.CreationMobile_appealing_folder_line1
    }

    public var appealingTipsLine2: String {
        BundleI18n.SKResource.CreationMobile_appealing_folder_line2
    }

    public var appealingTipsLine3: String {
        BundleI18n.SKResource.CreationMobile_appealing_folder_line3
    }

    public var appealingTitle: String {
        BundleI18n.SKResource.CreationMobile_appealing_folder_descripiton
    }

    public var appealingSubmitTitle: String {
        BundleI18n.SKResource.CreationMobile_Appealing_folder_Result
    }

    public init(token: String, isSingleContainer: Bool) {
        self.token = token
        self.isSingleContainer = isSingleContainer
    }

    public func fetchAppealInfo(completion: @escaping (Result<AppealInfo, Error>) -> Void) {
        var apiPath = OpenAPI.APIPath.folderDetail
        if isSingleContainer {
            apiPath = OpenAPI.APIPath.childrenListV3
        }
        request?.cancel()
        request = DocsRequest<JSON>(path: apiPath, params: ["token": token])
            .set(method: .GET)
            .start(result: { result, error in
                if let error = error {
                    DocsLogger.error("error \(error.localizedDescription)")
                    completion(.failure(error))
                    return
                }
                guard let json = result,
                      let name = json["data"]["entities"]["nodes"][self.token]["name"].string,
                      let description = json["data"]["entities"]["nodes"][self.token]["extra"]["description"].string else {
                    DocsLogger.error("request failed data invalid")
                          completion(.failure(DocsNetworkError.invalidData))
                    return
                }
                completion(.success(AppealInfo(title: name, contentDescription: description)))
            })
    }
}

public final class DriveAppealInfoProvider: AppealInfoProvider {
    let token: String

    public var appealingTipsLine1: String {
        BundleI18n.SKResource.LarkCCM_Appeal_SubmitToFS_Doc_Note1_Mob
    }

    public var appealingTipsLine2: String {
        BundleI18n.SKResource.LarkCCM_Appeal_SubmitToFS_Doc_Note2_Mob
    }

    public var appealingTipsLine3: String {
        BundleI18n.SKResource.LarkCCM_Appeal_SubmitToFS_Doc_Note3_Mob()
    }

    public var appealingTitle: String {
        BundleI18n.SKResource.LarkCCM_Appeal_SubmitToFS_SubTheDoc_Descrip()
    }

    public var appealingSubmitTitle: String {
        BundleI18n.SKResource.LarkCCM_Appeal_SubmitToFS_Submitted_Descrip
    }

    public init(token: String) {
        self.token = token
    }

    public func fetchAppealInfo(completion: @escaping (Result<AppealInfo, Error>) -> Void) {

    }
}
