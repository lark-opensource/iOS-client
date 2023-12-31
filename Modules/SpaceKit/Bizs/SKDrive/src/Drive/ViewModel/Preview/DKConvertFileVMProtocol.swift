//
//  DKConvertFileVMProtocol.swift
//  SKDrive
//
//  Created by bupozhuang on 2022/5/19.
//

import SKCommon
import SKFoundation
import ObjectiveC
import SpaceInterface
import LarkDocsIcon

enum DriveConvertFileAction {
    case exitConverting
    case showFailedView(DriveImportFailedViewType)
    case routedToExternal(String, DocsType)
    case updateFileSizeText(String)
    case networkChanged(Bool)
    case showToast(String)
}

struct DriveConvertNewResult: Codable {
    let code: Int
    let data: ConvertData
}

struct ConvertResult: Codable {
    let jobStatus: Int
    let token: String?
    let url: String?
    let type: String?
    private enum CodingKeys: String, CodingKey {
        case jobStatus = "job_status"
        case token
        case url
        case type
    }
}

struct ConvertData: Codable {
    let result: ConvertResult
}

protocol DKConvertFileVMProtocol: NSObjectProtocol {
    var fileID: String { get }
    var fileType: DriveFileType { get }
    var fileSize: UInt64 { get }
    var name: String { get }
    var bindAction: ((DriveConvertFileAction) -> Void)? { get set }
    func isFileSizeOverLimit() -> Bool
    func convertFile()
}
