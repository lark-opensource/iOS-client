import Foundation
import LKCommonsLogging
final class FixRequestManager {
    static let logger = Logger.lkwlog(FixRequestManager.self, category: "FixRequestManager")
    static let shared = FixRequestManager()
    private var fixRequestDataMap = [String: FixRequestData]()
    private var lock: pthread_rwlock_t
    private init() {
        lock = pthread_rwlock_t()
        pthread_rwlock_init(&lock, nil)
    }
    deinit {
        pthread_rwlock_destroy(&lock)
    }
    func setFixRequestData(with requestID: String, fixRequestData: FixRequestData) {
        Self.logger.info("set fix request data for requestID:\(requestID)")
        pthread_rwlock_wrlock(&lock)
        fixRequestDataMap[requestID] = fixRequestData
        pthread_rwlock_unlock(&lock)
    }
    func fixRequestData(with requestID: String) -> FixRequestData? {
        pthread_rwlock_rdlock(&lock)
        guard let fixRequestData = fixRequestDataMap[requestID] else {
            pthread_rwlock_unlock(&lock)
            let msg = "should not get nil body for requestID:\(requestID))"
            Self.logger.error(msg)
            return nil
        }
        fixRequestDataMap[requestID] = nil
        pthread_rwlock_unlock(&lock)
        return fixRequestData
    }
}
