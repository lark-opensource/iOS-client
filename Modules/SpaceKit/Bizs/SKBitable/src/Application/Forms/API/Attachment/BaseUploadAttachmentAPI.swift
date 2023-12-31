import Foundation
import LarkOpenAPIModel
import LKCommonsLogging
import RxSwift
import SKFoundation

// MARK: - BaseUploadAttachment Model
final class FormsUploadAttachmentBaseParams: OpenAPIBaseParams {
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "attachmentID")
    var attachmentID: String
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "baseID")
    var baseID: String
    
    @OpenAPIOptionalParam(jsonKey: "mountPoint")
    var mountPoint: String?
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_attachmentID, _baseID, _mountPoint]
    }
}

// MARK: - uploadAttachment
extension FormsAttachment {
    
    func baseUploadAttachment(
        params: FormsUploadAttachmentBaseParams,
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
                mountNodePoint: params.baseID,
                mountPoint: mountPoint,
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
        
    }
    
}
