import Foundation
import LarkAssembler
import LKLoggerExternal
import LKCommonsLogging

public class LKLoggerExternalAssembly: LarkAssemblyInterface {
    public init() {
      KALoggerExternal.shared.logger = KALoggerImpl()
    }
}

final class KALoggerImpl {
  let logger = Logger.log(KALoggerImpl.self, category: "Module.LKLoggerExternalAssembly")
}

extension KALoggerImpl: KALoggerProtocol {
  func verbose(tag: String, _ msg: String) {
      logger.log(level: .low, msg, tag: tag, additionalData: nil, error: nil)
  }
  func debug(tag: String, _ msg: String) {
      logger.debug(msg, tag: tag, additionalData: nil, error: nil)
  }
  func info(tag: String, _ msg: String) {
      logger.info(msg, tag: tag, additionalData: nil, error: nil)
  }
  func warning(tag: String, _ msg: String) {
      logger.warn(msg, tag: tag, additionalData: nil, error: nil)
  }
  func error(tag: String, _ msg: String) {
      logger.error(msg, tag: tag, additionalData: nil, error: nil)
  }
  
}
