import LarkAccountInterface
import LarkEnv
import LarkReleaseConfig

private func getLarkRelease() -> Env {
    return Env(unit: LarkEnv.Unit.EA, geo: Geo.us.rawValue, type: .release)
}

private func getFeishuRelease() -> Env {
    return Env(unit: LarkEnv.Unit.NC, geo: Geo.cn.rawValue, type: .release)
}

internal struct GlobalEnvironmentServiceImpl: GlobalEnvironmentService {

    var packageEnvironment: (TenantBrand, Env) {
#if DEBUG || BETA || ALPHA
        if let tenantBrandString = UserDefaults.standard.string(forKey: EnvManager.tenantBrandKey), let tenantBrand = TenantBrand(rawValue: tenantBrandString), let debugEnvironment = EnvManager.getDebugEnvironment() {
            return (tenantBrand, debugEnvironment)
        }
#endif
        let tenantBrand = ReleaseConfig.isLark ? TenantBrand.lark : TenantBrand.feishu
        if let defaultUnit = ReleaseConfig.defaultUnit, let defaultGeo = ReleaseConfig.defaultGeo, !defaultUnit.isEmpty && !defaultGeo.isEmpty {
            return (tenantBrand, Env(unit: defaultUnit, geo: defaultGeo, type: .release))
        } else {
            let environment: Env
            switch ReleaseConfig.ReleaseChannel(rawValue: ReleaseConfig.releaseChannel) ?? .release {
            case .release:
                environment = getFeishuRelease()
            case .oversea:
                environment = getLarkRelease()
#if DEBUG || BETA || ALPHA
            case .preRelease:
                environment = Env(unit: LarkEnv.Unit.NC, geo: Geo.cn.rawValue, type: .preRelease)
            case .staging:
                environment = Env(unit: LarkEnv.Unit.BOECN, geo: Geo.boeCN.rawValue, type: .staging)
            case .overseaStaging:
                environment = Env(unit: LarkEnv.Unit.BOEVA, geo: Geo.boeUS.rawValue, type: .staging)
#endif
            @unknown default:
                assertionFailure("Incorrect release config type, please contact Passport Oncall.")
                if ReleaseConfig.isLark {
                    environment = getLarkRelease()
                } else {
                    environment = getFeishuRelease()
                }
            }
            
            return (tenantBrand, environment)
        }
    }
}
