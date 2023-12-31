//
//  FollowModuleState.swift
//  SpaceKit
//
//  Created by lijuyou on 2020/4/8.
//  


import SwiftyJSON
import SKFoundation
import Foundation
import SpaceInterface

extension FollowModuleState {
    /// 获取传给 Web 的文档附件 Follow 数据（Module: BoxPreview）
    public func getBoxPreviewData() -> String {
        var moduleData: [String: Any] = [:]
        moduleData["module"] = FollowModule.boxPreview.rawValue
        moduleData["actionType"] = "drive_update"
        let dataDict = self.data.dictionaryObject
        guard JSONSerialization.isValidJSONObject(dataDict) else {
            DocsLogger.error("follow moudule data is inValidJSONObject")
            return ""
        }
        moduleData["data"] = self.data.dictionaryObject
        guard let data = try? JSONSerialization.data(withJSONObject: moduleData, options: []) else {
            DocsLogger.warning("convertToBoxPreviewData Fail")
            return ""
        }
        return String(data: data, encoding: String.Encoding.utf8) ?? ""
    }
    
    /// 获取传给 Web 的同层附件 Follow 数据（Module: DocxBoxPreview）
    public func getDocxBoxPreviewData(mountToken: String) -> String {
        var moduleData: [String: Any] = [:]
        moduleData["module"] = FollowModule.docxBoxPreview.rawValue
        moduleData["actionType"] = "drive_update"
        let dataDict = self.data.dictionaryObject
        // 判断是否 Valid 的 JSON 数据避免 "NaN in JSON write"
        guard JSONSerialization.isValidJSONObject(dataDict) else {
            DocsLogger.error("follow moudule data is inValidJSONObject")
            return ""
        }
        moduleData["data"] = ["driveUpdateRecordIdMap": ["\(mountToken)": dataDict]]
        guard let data = try? JSONSerialization.data(withJSONObject: moduleData, options: []) else {
            DocsLogger.error("convertToDocxBoxPreviewData Fail")
            return ""
        }
        return String(data: data, encoding: String.Encoding.utf8) ?? ""
    }
}
