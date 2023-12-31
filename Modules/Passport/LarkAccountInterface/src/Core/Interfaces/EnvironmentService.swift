import LarkEnv

public protocol UserEnvironmentService {
    
    var userEnvironment: (TenantBrand, Env) { get }
}

public protocol GlobalEnvironmentService {
    
    var packageEnvironment: (TenantBrand, Env) { get }
}
