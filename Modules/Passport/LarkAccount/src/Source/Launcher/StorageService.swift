internal protocol GlobalKvStorageService {
    func get<T: Codable>(key: String, userId: String?) -> T?
    func set<T: Codable>(key: String, value: T?, userId: String?)
    func clear(userId: String?)
}
