import LKCommonsLogging
import SKFoundation

final class FormsDevice {
    
    static let logger = Logger.formsSDKLog(FormsDevice.self, category: "FormsDevice")
    
    init() {
        Self.logger.info("FormsDevice init")
    }
    
    deinit {
        Self.logger.info("FormsDevice deinit")
    }
    
}
