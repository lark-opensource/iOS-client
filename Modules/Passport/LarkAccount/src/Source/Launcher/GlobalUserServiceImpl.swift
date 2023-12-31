import Swinject
import LarkContainer
import LKCommonsLogging

private let userIdListKey = "userIdList"

// TODO(tangjiacheng.chason): Double check the key name.
private let extensionProcessUserKey = "extensionProcessUser"

private final class UserDaoWrapper {
    
    fileprivate let userDao: UserDao
    
    fileprivate init(userDao: UserDao) {
        self.userDao = userDao
    }
}

internal final class GlobalUserServiceImpl: GlobalUserService {
    
    internal static let shared: GlobalUserService = GlobalUserServiceImpl(globalKvStorageService: GlobalKvStorageServiceImpl.shared)
    
    private let logger = Logger.plog(GlobalUserServiceImpl.self)
    
    private var globalKvStorageService: GlobalKvStorageService
    
    internal init(globalKvStorageService: GlobalKvStorageService) {
        self.globalKvStorageService = globalKvStorageService
    }
    
    private lazy var userIdSet: Set<String>? = {
        let userIdList: [String]? = globalKvStorageService.get(key: userIdListKey, userId: nil)
        
        return userIdList.flatMap { Set($0) }
    }() {
        didSet {
            let userIdList: [String]? = userIdSet.flatMap { innerUserIdList in
                if innerUserIdList.count > 0 {
                    return Array(innerUserIdList)
                } else {
                    return nil
                }
            }
            
            globalKvStorageService.set(key: userIdListKey, value: userIdList, userId: nil)
        }
    }
    
    private lazy var userDaoCache: NSCache<NSString, UserDaoWrapper> = NSCache()
    
    private func getUserDao(userId: String) -> UserDao? {
        if let userDao = userDaoCache.object(forKey: userId as NSString) {
            return userDao.userDao
        }
        let userDao: UserDao? = globalKvStorageService.get(key: extensionProcessUserKey, userId: userId)
        if let userDao {
            userDaoCache.setObject(.init(userDao: userDao), forKey: userId as NSString)
        }
        
        return userDao
    }
    
    private func setUserDao(userId: String, userDao: UserDao?) {
        if let userDao {
            userDaoCache.setObject(.init(userDao: userDao), forKey: userId as NSString)
        } else {
            userDaoCache.removeObject(forKey: userId as NSString)
        }
        globalKvStorageService.set(key: extensionProcessUserKey, value: userDao, userId: userId)
    }
    
    func updateUser(userId: String, userDao: UserDao?) {
        let boolValue = userIdSet?.contains(userId)
        if (boolValue == nil || boolValue == false) && userDao != nil {
            // Insert
            userIdSet?.insert(userId)
        } else if let boolValue, boolValue && userDao == nil {
            userIdSet?.remove(userId)
        }
        
        let cachedOrPersistentUserDao = getUserDao(userId: userId)
        if cachedOrPersistentUserDao == nil, let userDao {
            // Insert
            setUserDao(userId: userId, userDao: userDao)
        } else if let cachedOrPersistentUserDao, cachedOrPersistentUserDao != userDao {
            // Update or Delete.
            setUserDao(userId: userId, userDao: userDao)
        }
    }
}
