import ECOInfra
import LKCommonsLogging

/// 需要恢复Body的内存态管理器，请在主线程调用相关能力
final class RecoverRequestBodyManager {
    
    static let logger = Logger.lkwlog(RecoverRequestBodyManager.self, category: "RecoverRequestBodyManager")
    
    /// 存储body的字典
    private var bodyMap = [String: [AnyHashable: Any]]()
    
    private var lock: pthread_rwlock_t
    
    private init() {
        lock = pthread_rwlock_t()
        pthread_rwlock_init(&lock, nil)
    }
    
    deinit {
        pthread_rwlock_destroy(&lock)
    }
    
    static let shared = RecoverRequestBodyManager()
    
    func setBody(with requestID: String, body: [AnyHashable: Any]?) {
        Self.logger.info("set body for requestID:\(requestID)")
        pthread_rwlock_wrlock(&lock)
        bodyMap[requestID] = body
        pthread_rwlock_unlock(&lock)
    }
    
    func body(with requestID: String) -> [AnyHashable: Any]? {
        pthread_rwlock_rdlock(&lock)
        guard let body = bodyMap[requestID] else {
            pthread_rwlock_unlock(&lock)
            let msg = "should not get nil body for requestID:\(requestID))"
            assertionFailure(msg)
            Self.logger.error(msg)
            return nil
        }
        pthread_rwlock_unlock(&lock)
        setBody(with: requestID, body: nil)
        return body
    }
}
