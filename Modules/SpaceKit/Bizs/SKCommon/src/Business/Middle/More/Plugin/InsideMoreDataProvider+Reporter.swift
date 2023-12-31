//
//  InsideMoreDataProvider+Reporter.swift
//  SKCommon
//
//  Created by lizechuang on 2021/3/8.
//

import SKFoundation
import SpaceInterface

extension InsideMoreDataProvider {
    func generateParas() -> [AnyHashable: Any] {
        var paras: [AnyHashable: Any] = [:]
        paras["file_type"] = docsInfo.type.name
        paras["file_id"] = DocsTracker.encrypt(id: docsInfo.objToken)
        return paras
    }

    public func reportForFeedShortcut(_ status: Bool) {
        let parameters = ["source": docsInfo.type.name, "file_token": DocsTracker.encrypt(id: docsInfo.objToken)]
        DocsTracker.log(enumEvent: status ? .pinToQuickswitcher : .unpinToQuickswitcher, parameters: parameters)
    }

    func reportAddStar(file: SpaceEntry) {
        var params = file.makeStatisticsParams()
        params["module"] = file.type.name
        DocsTracker.log(enumEvent: .clickFileStar, parameters: params)
    }

    func reportCancelStar(file: SpaceEntry) {
        var params = file.makeStatisticsParams()
        params["module"] = file.type.name
        DocsTracker.log(enumEvent: .clickFileCancelStar, parameters: params)
    }

    func reportAddSubscrible(file: SpaceEntry) {
        var params = file.makeStatisticsParams()
        params["module"] = file.type.name
        DocsTracker.log(enumEvent: .clickFileSubscrible, parameters: params)
    }

    func reportCancelSubscrible(file: SpaceEntry) {
        var params = file.makeStatisticsParams()
        params["module"] = file.type.name
        DocsTracker.log(enumEvent: .clickFileCancelSubscrible, parameters: params)
    }

    func reportAddPin(file: SpaceEntry, success: Bool) {
        var params = file.makeStatisticsParams()
        params["module"] = file.type.name
        params["toast"] = success ? "success" : "failure"
        DocsTracker.log(enumEvent: .clickFilePin, parameters: params)
    }

    func reportCancelPin(file: SpaceEntry) {
        var params = file.makeStatisticsParams()
        params["module"] = file.type.name
        DocsTracker.log(enumEvent: .clickFilePinCancel, parameters: params)
    }

    public func reportClickHistory() {
        let eventParams = ["file_type": self.docsInfo.type.name,
                           "file_id": DocsTracker.encrypt(id: self.docsInfo.objToken)]
         DocsTracker.log(enumEvent: .clickEnterHistoryWithin, parameters: eventParams)
    }

    public func reportClickDeleteFile() {
        DocsTracker.log(enumEvent: .clickFileDeleteWith, parameters: generateParas())
    }

    func reportClientCopyAction(_ url: String, fileType: DocsType, error: String) {
        let array = url.split(separator: "/")
        let token = String(array.last ?? "")
        let params = ["status_name": error,
            "file_type": fileType.name,
            "file_id": DocsTracker.encrypt(id: token)] as [String: Any]
        DocsTracker.log(enumEvent: .clickMakeCopy, parameters: params)
    }

    func reportClickCustomService() {
        DocsTracker.log(enumEvent: .clickEnterCustomerservice, parameters: self.generateParas())
    }
    
    public func reportClickDeleteVersion(type: String) {
        var param: [String: Any] = ["click": type, "target": "none"]
        if let common = self.trackerParams {
            param.merge(other: common)
        }
        if docsInfo.inherentType == .sheet {
            DocsTracker.newLog(enumEvent: .sheetDeleteVersionClick, parameters: param)
        } else {
            DocsTracker.newLog(enumEvent: .docsDeleateVersionClick, parameters: param)
        }
    }
    
    public func reportDeleteVersion() {
        if docsInfo.inherentType == .sheet {
            DocsTracker.newLog(enumEvent: .sheetDeleteVersion, parameters: self.trackerParams)
        } else {
            DocsTracker.newLog(enumEvent: .docsDeleateVersion, parameters: self.trackerParams)
        }
    }
}
