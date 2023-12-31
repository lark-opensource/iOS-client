import LarkSetting

internal let passportStorageCipherMigration: Bool = {
    let fgValue = GlobalFeatureGatingManager.shared.globalFeatureValue(of: .init(.make(golbalKeyLiteral: "passport_storage_cipher_migration")))
    PassportStore.logger.info("n_action_passport_store: FG value is \(fgValue).")
    if fgValue {
        migrateToUniversalStorage()
    } else {
        rollbackToLegacyStorage()
    }
    
    return fgValue
}()
