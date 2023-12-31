import LarkAccountInterface
import LarkEnv
import LarkContainer
import LarkReleaseConfig

internal final class UserEnvironmentServiceImpl: UserEnvironmentService, UserResolverWrapper {
    
    // Property 'userResolver' must be as accessible as its enclosing type because it matches a requirement in protocol 'UserResolverWrapper'
    internal let userResolver: UserResolver
    
    @ScopedInjectedLazy private var globalEnvironmentService: GlobalEnvironmentService?
    
    @ScopedInjectedLazy private var userService: PassportUserService?

    var userEnvironment: (TenantBrand, Env) {
        if let unit = userService?.user.userUnit, let geo = userService?.user.geo, let tenantBrand = userService?.user.tenant.tenantBrand {
            return (tenantBrand, Env(unit: unit, geo: geo, type: globalEnvironmentService?.packageEnvironment.1.type ?? .release))
        }
        
        return globalEnvironmentService?.packageEnvironment ?? (ReleaseConfig.isLark ? (TenantBrand.lark, Env(unit: LarkEnv.Unit.EA, geo: Geo.us.rawValue, type: .release)) : (TenantBrand.feishu, Env(unit: LarkEnv.Unit.NC, geo: Geo.cn.rawValue, type: .release)))
    }
    
    internal init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }
}
