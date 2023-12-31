import Foundation
import LarkOpenAPIModel

// MARK: - DeleteAttachment Model
final class FormsDeleteAttachmentParams: OpenAPIBaseParams {
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "attachmentIDs")
    var attachmentIDs: [String]
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_attachmentIDs]
    }
}

// MARK: - deleteAttachment
extension FormsAttachment {
    
    func deleteAttachment(
        params: FormsDeleteAttachmentParams,
        success: @escaping () -> Void
    ) {
        cancelOrDeleteUploadTasks(
            attachmentInfos: params
                .attachmentIDs
                .compactMap { attachmentID in
                    Self.choosenAttachments[attachmentID]
                },
            needRemoveMemoryAndDeleteAttachment: true
        )
        
        success()
    }
    
}
