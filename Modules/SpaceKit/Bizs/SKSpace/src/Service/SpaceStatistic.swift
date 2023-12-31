//
//  SpaceStatistic.swift
//  SKECM
//
//  Created by Weston Wu on 2021/3/30.
//

import Foundation
import SwiftyJSON
import SKCommon
import SKFoundation

public enum SpaceStatistic {

    struct ContentManagementReportInfo {
        var source: String = ""
        var module: String?
        var subModule: String?
        var action: String = ""
        var fileType: String?
        var fileID: String?
        var exParams: [String: String]?
    }

    private static func reportClientContentManagement(reportInfo: ContentManagementReportInfo) {
        var params = ["source": reportInfo.source,
                      "action": reportInfo.action]
        let encryptFileID = DocsTracker.encrypt(id: reportInfo.fileID ?? "")
        params = checkToAddParam(key: "module", value: reportInfo.module, params: params)
        params = checkToAddParam(key: "subModule", value: reportInfo.subModule, params: params)
        params = checkToAddParam(key: "file_type", value: reportInfo.fileType, params: params)
        params = checkToAddParam(key: "file_id", value: encryptFileID, params: params)

        if let exParams = reportInfo.exParams, !exParams.isEmpty {
            exParams.forEach { (key, value) in
                params[key] = value
            }
        }
        var newParams: [String: Any] = params
        newParams = FileListStatistics.addParamsInto(newParams)

        DocsTracker.log(enumEvent: .clientContentManagement, parameters: newParams)
    }

    private static func checkToAddParam(key: String, value: String?, params: [String: String]) -> [String: String] {
        var newParams = params
        if let value = value, !value.isEmpty {
            newParams[key] = value
        }
        return newParams
    }

    public static func reportManuOfflineAction(for file: SpaceEntry, module: String, isAdd: Bool) {
        var params = file.makeStatisticsParams()
        params["module"] = module
        let action: FileListStatistics.Action = isAdd ? .addManuOffline : .removeManuOffline
        FileListStatistics.reportClientContentManagement(action: action, params: params)
    }
}

final class SubFolderVCChecker: SubFolderVCProtocol {
    func isSubFolderViewController(_ viewController: UIViewController) -> Bool {
        viewController is SpaceFolderContainerController
    }
}
