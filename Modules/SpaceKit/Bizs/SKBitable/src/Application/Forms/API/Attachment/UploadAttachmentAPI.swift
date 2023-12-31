import Foundation
import LarkOpenAPIModel
import LKCommonsLogging
import RxSwift
import SKFoundation
import SwiftyJSON

// MARK: - UploadAttachment Model
final class FormsUploadAttachmentParams: OpenAPIBaseParams {
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "attachmentID")
    var attachmentID: String
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "shareToken")
    var shareToken: String
    
    @OpenAPIOptionalParam(jsonKey: "mountPoint")
    var mountPoint: String?
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_attachmentID, _shareToken, _mountPoint]
    }
    
}

final class FormsUploadAttachmentResult: OpenAPIBaseResult {
    
    let token: String
    
    init(token: String) {
        self.token = token
        super.init()
        
    }
    
    override func toJSONDict() -> [AnyHashable: Any] {
        [
            "token": token
        ]
    }
    
}

// MARK: - uploadAttachment
extension FormsAttachment {
    
    func uploadAttachment(
        params: FormsUploadAttachmentParams,
        success: @escaping (String) -> Void,
        failure: @escaping (OpenAPIError) -> Void
    ) {
        
        guard let attachment = Self.choosenAttachments[params.attachmentID] else {
            let code = FormsAttachmentErrorCode.noAttachment
            let msg = "no attachment for \(params.attachmentID)"
            Self.logger.error(msg)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage(msg)
                .setOuterMessage(msg)
                .setOuterCode(code)
            failure(error)
            return
        }
        
        guard let uploader = uploader else {
            let code = FormsAttachmentErrorCode.uploadNil
            let msg = "uploader is nil for \(params.attachmentID)"
            Self.logger.error(msg)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage(msg)
                .setOuterMessage(msg)
                .setOuterCode(code)
            failure(error)
            return
        }
        
        let localPath = attachment.url.path
        let fileName = attachment.name
        let attachmentID = attachment.attachmentID
        
        var mountPoint = "bitable_file"
        if let point = params.mountPoint, !point.isEmpty {
            mountPoint = point
        }
        
        requestUploadCode(
            shareToken: params.shareToken,
            attachment: attachment,
            mountPoint: mountPoint
        ) { [weak self] result in
            guard let self = self else {
                Self.logger.error("uploadAttachment error, FormsAPI is nil")
                return
            }
            
            switch result {
            case .success(let uploadCode):
                guard FileManager.default.fileExists(atPath: localPath) else {
                    let code = FormsAttachmentErrorCode.fileNotExist
                    let msg = "file not exist for \(attachmentID)"
                    Self.logger.error(msg)
                    let e = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setMonitorMessage(msg)
                        .setOuterMessage(msg)
                        .setOuterCode(code)
                    failure(e)
                    return
                }
                
                Self.logger.info("upload start, attachmentID: \(attachmentID), mountPoint: \(mountPoint)")
                
                uploader
                    .upload(
                        localPath: localPath,
                        fileName: fileName,
                        mountPoint: mountPoint,
                        uploadCode: uploadCode,
                        copyInsteadMoveAfterSuccess: true,
                        priority: .default
                    )
                    .observeOn(MainScheduler.instance)
                    .subscribe(
                        onNext: { key, progress, token, status in
                            Self.logger.info("upload onNext status \(status), attachmentID: \(attachmentID), mountPoint: \(mountPoint), key \(key), progress \(progress)")
                            Self.choosenAttachments[attachmentID]?.uploadStatus[key] = (key, progress, token, status)
                            if status == .success {
                                success(token)
                            }
                        },
                        onError: { error in
                            let code = FormsAttachmentErrorCode.driveUploadOnError
                            let msg = "upload onError, attachmentID: \(attachmentID), mountPoint: \(mountPoint), error: \(error)"
                            Self.logger.error(msg, error: error)
                            let e = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                                .setError(error)
                                .setMonitorMessage(msg)
                                .setOuterMessage(msg)
                                .setOuterCode((error as? NSError)?.code ?? code)
                            failure(e)
                        }
                    )
                    .disposed(by: self.bag)
            case .failure(let e):
                failure(e)
            }
        }
        
    }
    
    private func requestUploadCode(
        shareToken: String,
        attachment: FormsChooseAttachmentInfo,
        mountPoint: String,
        completionHandler: @escaping (Result<String, OpenAPIError>) -> Void
    ) {
        let attachmentID = attachment.attachmentID
        var params: [String: Any] = [
            "shareToken": shareToken,
            "fileName": attachment.name,
            "size": attachment.size,
            "mountPoint": mountPoint
        ]
        
        Self.logger.info("request uploadCode start, attachmentID: \(attachmentID), mountPoint: \(mountPoint), size: \(attachment.size)")
        
        DocsRequest<JSON>(
            path: "/api/bitable/external/share/uploadCode",
            params: params
        )
        .set(method: .GET)
        .set(encodeType: .urlEncodeAsQuery)
        .makeSelfReferenced()
        .start(
            result: { (json, error) in
                if let error = error {
                    let code = FormsAttachmentErrorCode.requestUploadCodeError
                    let msg = "request uploadCode error, attachmentID: \(attachmentID), mountPoint: \(mountPoint),  error: \(error)"
                    Self.logger.error(msg, error: error)
                    let e = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setError(error)
                        .setMonitorMessage(msg)
                        .setOuterMessage(msg)
                        .setOuterCode((error as? NSError)?.code ?? code)
                    completionHandler(.failure(e))
                    return
                }
                
                if let json = json {
                    let data = json["data"]
                    if let uploadCode = data["uploadCode"].string {
                        Self.logger.info("request uploadCode success, attachmentID: \(attachmentID), mountPoint: \(mountPoint)")
                        completionHandler(.success(uploadCode))
                    } else {
                        let code = json["code"].int ?? FormsAttachmentErrorCode.requestUploadCodeUploadCodeStringNilDefault
                        let msg = "request uploadCode error, data.uploadCode.string is nil, attachmentID: \(attachmentID), mountPoint: \(mountPoint), and backend msg is \(json["msg"].string)"
                        Self.logger.error(msg)
                        let e = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                            .setMonitorMessage(msg)
                            .setOuterMessage(msg)
                            .setOuterCode(code)
                        completionHandler(.failure(e))
                    }
                } else {
                    let code = FormsAttachmentErrorCode.requestUploadCodeJsonNil
                    let msg = "request uploadCode error, json is nil, attachmentID: \(attachmentID), mountPoint: \(mountPoint)"
                    Self.logger.error(msg)
                    let e = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                        .setMonitorMessage(msg)
                        .setOuterMessage(msg)
                        .setOuterCode(code)
                    completionHandler(.failure(e))
                }
            }
        )
    }
    
}
