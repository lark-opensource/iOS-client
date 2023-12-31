import LarkContainer
import LarkCoreLocation
import LKCommonsLogging
import SKFoundation

final class FormsLocation {
    
    static let logger = Logger.formsSDKLog(FormsLocation.self, category: "FormsLocation")
    
    // 中台定位服务权限对象
    @InjectedSafeLazy var locationAuth: LocationAuthorization
    
    // 中台定位服务对象
    @InjectedSafeLazy var locationService: LocationService
    
    // 定位任务
    var locationTasks = [AnyHashable: SingleLocationTask]()
    
    init() {
        Self.logger.info("FormsLocation init")
    }
    
    deinit {
        Self.logger.info("FormsLocation deinit")
    }
    
}
