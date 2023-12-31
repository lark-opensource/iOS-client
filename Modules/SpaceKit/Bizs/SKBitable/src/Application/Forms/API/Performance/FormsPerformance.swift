import LKCommonsLogging
import SKFoundation

final class FormsPerformance {
    
    static let logger = Logger.formsSDKLog(FormsPerformance.self, category: "FormsPerformance")
    
    init() {
        Self.logger.info("FormsPerformance init")
    }
    
    deinit {
        Self.logger.info("FormsPerformance deinit")
    }
    
}
