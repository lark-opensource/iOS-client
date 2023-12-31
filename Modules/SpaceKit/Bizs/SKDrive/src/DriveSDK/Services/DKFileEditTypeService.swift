//
//  DKFileEditTypeService.swift
//  SKDrive
//
//  Created by ZhangYuanping on 2023/5/8.
//  

import RxSwift
import RxCocoa
import SwiftyJSON
import SKCommon
import SKFoundation
import SKInfra
import LarkDocsIcon

enum FileEditMethod {
    case wps
    case sheet(url: URL)
    case none
}

enum ShadowFileURLParam {
    static let isExcel = "isExcel"
    static let shadowFileId = "shadow_file_id"
    static let docFrom = "from"
}

struct ExcelFileEditInfo: Codable {
    enum EditType: Int, Codable {
        case processing = 0
        case wps = 1
        case sheet = 2
        case unknown = 3
    }

    let editType: EditType
    let sheetToken: String?
    let url: String?

    func editMethod() -> FileEditMethod {
        switch editType {
        case .sheet:
            if let urlStr = url, let url = URL(string: urlStr) {
                let url = url.append(name: ShadowFileURLParam.isExcel, value: "true")
                return .sheet(url: url)
            }
            return .none
        case .wps:
            return .wps
        case .unknown, .processing:
            return .none
        }
    }
}

protocol DKFileEditTypeService {
    func requestEditType() -> Single<ExcelFileEditInfo>
}

class DKFileEditTypeServiceImpl: DKFileEditTypeService {

    private let fileId: String
    private let fileType: DriveFileType

    private let loopInterval = 1000
    private var maxLoopCount = 10
    private var disposeBag = DisposeBag()

    init(fileId: String, fileType: DriveFileType) {
        self.fileId = fileId
        self.fileType = fileType
    }

    func requestEditType() -> Single<ExcelFileEditInfo> {
        // 目前仅支持 Excel 文件获取编辑方式
        guard fileType.isExcel else {
            return .just(ExcelFileEditInfo(editType: .unknown, sheetToken: nil, url: nil))
        }
        let APIPath = OpenAPI.APIPath.excelFileEditType + fileId
        let request = DocsRequest<JSON>(path: APIPath, params: nil)
            .set(method: .GET)
            .set(needVerifyData: false)
        return request.rxStart()
            .map { result -> ExcelFileEditInfo in
                guard let json = result,
                      let code = json["code"].int else {
                    DocsLogger.driveError("requestExcelEditType: result invalid")
                    throw DriveError.fileEditTypeError
                }
                guard code == 0 else {
                    DocsLogger.driveError("requestExcelEditType: result code: \(code)")
                    throw DriveError.serverError(code: code)
                }
                guard let dataDic = json["data"].dictionaryObject,
                      let data = try? JSONSerialization.data(withJSONObject: dataDic, options: []),
                      let fileEditInfo = try? JSONDecoder().decode(ExcelFileEditInfo.self, from: data) else {
                    DocsLogger.driveError("requestExcelEditType: parse data to ExcelFileEditType failed")
                    throw DriveError.fileEditTypeError
                }
                if fileEditInfo.editType == .processing {
                    DocsLogger.driveInfo("requestExcelEditType: processing")
                    // 状态正在处理中，抛出错误进行重试
                    throw DriveError.fileEditTypeError
                }
                DocsLogger.driveInfo("requestExcelEditType success: \(fileEditInfo.editType)")
                return fileEditInfo
            }
            .retryWhen { errors in
                errors.enumerated().flatMap{ attempt, error -> Observable<Int> in
                    guard attempt < self.maxLoopCount else {
                        return Observable.error(error)
                    }
                    let interval = RxTimeInterval.milliseconds(self.loopInterval)
                    return Observable.timer(interval, scheduler: MainScheduler.instance)
                }
            }
            .catchErrorJustReturn(ExcelFileEditInfo(editType: .unknown, sheetToken: nil, url: nil))
    }
}
