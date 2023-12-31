import EENavigator
import Foundation
import LarkOpenAPIModel
import LKCommonsLogging
import SpaceInterface
import SKCommon
import SKFoundation

// MARK: - PreviewAttachment Model
final class FormsPreviewAttachmentParams: OpenAPIBaseParams {
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "attachmentIDs")
    var attachmentIDs: [String]
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "index")
    var index: Int
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_attachmentIDs, _index]
    }
}

// MARK: - previewAttachment
extension FormsAttachment {
    
    func previewAttachment(
        vc: UIViewController,
        params: FormsPreviewAttachmentParams,
        success: @escaping () -> Void,
        failure: @escaping (OpenAPIError) -> Void
    ) {
        if params.index < 0 {
            let code = -4
            let msg = "previewAttachment error, index < 0, index is \(params.index)"
            Self.logger.error(msg)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage(msg)
                .setOuterMessage(msg)
                .setOuterCode(code)
            
            failure(error)
            return
        }
        let files = params
            .attachmentIDs
            .compactMap { attachmentID in
                Self.choosenAttachments[attachmentID]
            }
            .map { info in
                DriveSDKLocalFileV2(
                    fileName: info.name,
                    fileType: info.type,
                    fileURL: info.url,
                    fileId: info.url.lastPathComponent,
                    dependency: BTLocalDependencyImpl()
                )
            }
        
        Self.logger.info("previewAttachment attachmentIDs.count is \(params.attachmentIDs.count) and files.count is \(files.count), and index is \(params.index)")
        
        if files.isEmpty {
            let code = -5
            let msg = "previewAttachment error, attachments is empty"
            Self.logger.error(msg)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage(msg)
                .setOuterMessage(msg)
                .setOuterCode(code)
            
            failure(error)
            return
        }
        
        if params.index >= files.count {
            let code = -6
            let msg = "previewAttachment error, params.index >= files.count"
            Self.logger.error(msg)
            let error = OpenAPIError(code: OpenAPICommonErrorCode.unknown)
                .setMonitorMessage(msg)
                .setOuterMessage(msg)
                .setOuterCode(code)
            
            failure(error)
            return
        }
        
        let config = DriveSDKNaviBarConfig(titleAlignment: .leading, fullScreenItemEnable: false)
        let body = DriveSDKLocalFileBody(
            files: files,
            index: params.index,
            appID: DKSupportedApp.bitableLocal.rawValue,
            thirdPartyAppID: nil,
            naviBarConfig: config
        )
        
        Navigator
            .shared
            .push(body: body, from: vc)
        success()
    }
    
}
