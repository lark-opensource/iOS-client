import LarkContainer
import LarkStorageCore
import LKCommonsLogging

internal func getKvStorage(userId: String, logger: Log) -> KVStore {
    if userId == UserStorageManager.placeholderUserID {
        logger.warn("userId == LarkContainer.UserStorageManager.placeholderUserID")
    }

    let kvStore = KVStores.mmkv(space: .user(id: userId), domain: Domain.biz.passport, mode: .shared).usingCipher()
    excludeFromBackup(kvStore: kvStore, logger: logger)

    return kvStore
}
