//
//  DriveHTMLDataProvider.swift
//  SKECM
//
//  Created by zenghao on 2021/2/1.
//

import Foundation
import RxSwift
import SwiftyJSON
import SKCommon
import SKFoundation
import SKInfra

class DriveHTMLDataProvider {
    
    enum DownloadError: LocalizedError {
        case unknownStatusCode(code: Int)
        case parseDataFailed

        public var errorDescription: String? {
            switch self {
            case let .unknownStatusCode(code):
                return "unknown http status code: \(code)"
            case .parseDataFailed:
                return "failed to parse data"
            }
        }
    }
    
    let fileToken: String
    let dataVersion: String?
    let fileSize: UInt64?
    let authExtra: String?
    let mountPoint: String

    private let downloadQueue = DispatchQueue(label: "drive.html.download", attributes: [.concurrent])
    private let disposeBag = DisposeBag()

    init(fileToken: String,
         dataVersion: String?,
         fileSize: UInt64?,
         authExtra: String?,
         mountPoint: String) {
        self.fileToken = fileToken
        self.dataVersion = dataVersion
        self.fileSize = fileSize
        self.authExtra = authExtra
        self.mountPoint = mountPoint
    }
    
    static func canPreviewHtmlByMaxSize(extraInfo: String, tabMaxSize: UInt64) -> Bool {
        let dict = JSON(parseJSON: extraInfo)
        guard let sheets = dict["sheets"].array, sheets.count != 0 else {
            DocsLogger.warning("html extra sheets not found")
            return false
        }
        
        for sheet in sheets {
            guard let size = sheet["size"].int64 else {
                DocsLogger.warning("html extra sheet size not found")
                return false
            }
            
            if size > tabMaxSize {
                DocsLogger.warning("html extra sheet size is too big")
                return false
            }
        }
        
        return true
    }
    
    // 按照租户维度来缓存：uid + token + vesion + subId
    func saveData(subId: String, data: Data, fileName: String, manualOffline: Bool = false) {
        let basicInfo = DriveCacheServiceBasicInfo(cacheType: .htmlSubData(id: subId),
                                                   source: manualOffline ? .manual : .standard,
                                                   token: fileToken,
                                                   fileName: fileName,
                                                   fileType: nil,
                                                   dataVersion: dataVersion,
                                                   originFileSize: fileSize)
        let context = SaveDataContext(data: data, basicInfo: basicInfo)
        DriveCacheService.shared.saveDriveData(context: context)
    }
    
    func getData(subId: String) -> Data? {
        guard let driveData = try? DriveCacheService.shared.getDriveData(type: .htmlSubData(id: subId),
                                                                         token: fileToken,
                                                                         dataVersion: dataVersion,
                                                                         fileExtension: nil).get() else {
            return nil
        }
        
        return driveData.1
    }
    
    func isDataExisted(subId: String) -> Bool {
        let cacheType = DriveCacheType.htmlSubData(id: subId)
        return DriveCacheService.shared.isDriveFileExist(type: cacheType,
                                                         token: fileToken,
                                                         dataVersion: dataVersion,
                                                         fileExtension: nil)
    }
    
    func isExtraInfoExisted() -> Bool {
        let cacheType = DriveCacheType.htmlExtraInfo
        return DriveCacheService.shared.isDriveFileExist(type: cacheType,
                                                         token: fileToken,
                                                         dataVersion: dataVersion,
                                                         fileExtension: nil)
    }
    
    func getExtraInfo() -> String? {
        guard let (_, driveData) = try? DriveCacheService.shared.getDriveData(type: .htmlExtraInfo,
                                                                              token: fileToken,
                                                                              dataVersion: dataVersion,
                                                                              fileExtension: nil).get() else {
            return nil
        }
        return String(decoding: driveData, as: UTF8.self)
    }
    
    func saveExtraInfo(_ extraInfo: String, fileName: String, manualOffline: Bool = false) {
        let data = Data(extraInfo.utf8)
        let basicInfo = DriveCacheServiceBasicInfo(cacheType: .htmlExtraInfo,
                                                   source: manualOffline ? .manual : .standard,
                                                   token: fileToken,
                                                   fileName: fileName,
                                                   fileType: nil,
                                                   dataVersion: dataVersion,
                                                   originFileSize: nil)
        let context = SaveDataContext(data: data, basicInfo: basicInfo)
        DriveCacheService.shared.saveDriveData(context: context)
    }
    
    // MARK: - fetch data
    // https://bytedance.feishu.cn/wiki/wikcnnx6X3KMIcKQszifWMyvBkf#eug4sp
    // url: {{domain}}/space/api/box/stream/download/preview_sub/{{fileToken}}?version={}&preview_type={}&sub_id={}
    func fetchTabData(subId: String) -> Single<Data> {
        let APIPath = OpenAPI.APIPath.drivePreviewHtmlSubTable + "/\(fileToken)"
        var querys: [String: Any] = ["version": dataVersion ?? "0",
                                     "preview_type": 8,
                                     "sub_id": subId]
        if let extra = authExtra {
            querys["extra"] = extra
        }
        querys["mount_point"] = mountPoint
        
        let request = DocsRequest<JSON>(path: APIPath, params: querys).set(method: .GET)
        let requestID = request.requestID
        
        return request.rxData()
            .observeOn(ConcurrentDispatchQueueScheduler(queue: downloadQueue)) // 派发数据解析处理到下载线程
            .map { (data, response) -> Data in
                DocsLogger.driveInfo("fetchTabData, subId: \(subId), data: \(String(describing: data?.count))")
                guard let httpResponse = response as? HTTPURLResponse else {
                    DocsLogger.error("drive.html.downloader --- response is not a http response", extraInfo: ["requestID": requestID])
                    throw DownloadError.parseDataFailed
                }
                
                let statusCode = httpResponse.statusCode
                // nolint-next-line: magic number
                guard statusCode == 200 else {
                    DocsLogger.error("drive.html.downloader --- unknown http status code", extraInfo: ["statusCode": statusCode, "requestID": requestID])
                    throw DownloadError.unknownStatusCode(code: statusCode)
                }
                
                guard let realData = data else {
                    DocsLogger.error("drive.html.downloader --- can not get data", extraInfo: ["statusCode": statusCode, "requestID": requestID])
                    throw DownloadError.parseDataFailed
                }
                
                return realData
            }
    }

}
