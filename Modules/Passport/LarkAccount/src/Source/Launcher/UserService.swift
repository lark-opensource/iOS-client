internal struct UserDao: Codable, Equatable {
    
    private let session: String
        
    private let tenantId: String
    
    private let unit: String
        
    private let encryptedUserId: String
    
    internal init(session: String, tenantId: String, unit: String, encryptedUserId: String) {
        self.session = session
        self.tenantId = tenantId
        self.unit = unit
        self.encryptedUserId = encryptedUserId
    }
}

internal protocol GlobalUserService {
    
    func updateUser(userId: String, userDao: UserDao?)
}
