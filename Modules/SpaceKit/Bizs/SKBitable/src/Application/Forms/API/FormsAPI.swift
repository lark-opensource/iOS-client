import Foundation
import LKCommonsLogging
import SKFoundation

/// 收集表/表单分享页 API 管理对象
@objcMembers final class FormsAPI: NSObject {
    
    static let logger = Logger.formsSDKLog(FormsAPI.self, category: "FormsAPI")
    
    /// 定位/地图管理对象
    lazy var formsLocation = FormsLocation()
    
    /// 设备能力管理对象
    lazy var formsDevice = FormsDevice()
    
    /// 附件能力管理对象
    lazy var formsAttachment = FormsAttachment()
    
    /// 开放能力管理对象
    lazy var formsOpenAbility = FormsOpenAbility()
    
    /// 性能管理对象
    lazy var formsPerformance = FormsPerformance()
    
    override init() {
        super.init()
        Self.logger.info("FormsAPI init")
    }
    
    deinit {
        Self.logger.info("FormsAPI deinit")
    }
}

fileprivate var ocKey: Int = 0

// MARK: - API Impl
extension UIViewController {
    
    /// 获取挂载在 UIViewController 上的收集表/表单分享页 API 管理对象，如无则创建并挂在
    var formsAPI: FormsAPI {
        if let api = objc_getAssociatedObject(self, &ocKey) as? FormsAPI {
            return api
        }
        let apiImpl = FormsAPI()
        objc_setAssociatedObject(
            self,
            &ocKey,
            apiImpl,
            .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        )
        return apiImpl
    }
    
    /// 尝试获取挂载在 UIViewController 上的收集表/表单分享页 API 管理对象
    var formsAPIOptional: FormsAPI? {
        objc_getAssociatedObject(self, &ocKey) as? FormsAPI
    }
    
}
