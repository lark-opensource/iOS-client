import Foundation
import LarkOpenAPIModel
import LKCommonsLogging
import SKFoundation

// MARK: - CheckAttachment Model
final class FormsCheckAttachmentParams: OpenAPIBaseParams {
    
    @OpenAPIRequiredParam(userRequiredWithJsonKey: "attachmentIDs")
    var attachmentIDs: [String]
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_attachmentIDs]
    }
}

struct FormsCheckedInfo {
    
    var attachmentID: String
    
    var valid: Bool
}

final class FormsCheckAttachmentResult: OpenAPIBaseResult {
    
    let infos: [FormsCheckedInfo]
    
    init(infos: [FormsCheckedInfo]) {
        self.infos = infos
        super.init()
    }
    
    override func toJSONDict() -> [AnyHashable: Any] {
        let arr = infos.map { info in
            var dic = [String: Any]()
            dic["attachmentID"] = info.attachmentID
            dic["valid"] = info.valid
            return dic
        }
        return [
            "checkedInfo": arr
        ]
    }
}

// MARK: - CheckAttachment
extension FormsAttachment {
    
    func checkAttachment(
        params: FormsCheckAttachmentParams,
        success: @escaping ([FormsCheckedInfo]) -> Void
    ) {
        let checkedInfos = params.attachmentIDs.map { attachmentID in
            let valid: Bool
            
            if let atta = Self.choosenAttachments[attachmentID] {
                let fileExists = FileManager.default.fileExists(atPath: atta.url.path)
                Self.logger.info("fileExists for \(attachmentID) is \(fileExists)")
                valid = fileExists
            } else {
                Self.logger.error("Self.choosenAttachments is nil for \(attachmentID)")
                valid = false
            }
            return FormsCheckedInfo(attachmentID: attachmentID, valid: valid)
        }
        success(checkedInfos)
    }
    
}
