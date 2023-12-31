import LarkOpenAPIModel
import LKCommonsLogging
import SKFoundation

final class FormsOpenAbility {
    
    static let logger = Logger.formsSDKLog(FormsOpenAbility.self, category: "FormsOpenAbility")
    
    var chooseContactSuccessBlock: ((FormsChooseContactResult) -> Void)?
    
    var chooseContactCancelBlock: (() -> Void)?
    
    init() {
        Self.logger.info("FormsOpenAbility init")
    }
    
    deinit {
        Self.logger.info("FormsOpenAbility deinit")
    }
    
    func cleanChooseContactBlocks() {
        
        chooseContactSuccessBlock = nil
        
        chooseContactCancelBlock = nil
        
    }
    
}
