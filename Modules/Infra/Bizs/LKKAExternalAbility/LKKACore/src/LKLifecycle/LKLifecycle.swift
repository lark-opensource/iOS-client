import Foundation
@objcMembers
public class LKLifecycle: NSObject {
    /// 应用启动时通知名称
    public static let start: String = "LKLifecycleStart"
    /// 应用切到前台时通知名称
    public static let resume: String = "LKLifecycleResume"
    /// 应用切到后台时通知名称
    public static let pause: String = "LKLifecyclePause"
    /// 飞书账号登录成功时通知名称，object: { "isFastLogin": "true" or "false" }
    public static let onLoginSuccess: String = "LKLifecycleOnLoginSuccess"
    /// 飞书账号登录失败时通知名称，object: { "isFastLogin": "true" or "false" }
    public static let onLoginFail: String = "LKLifecycleOnLoginFail"
    /// 飞书账号登出时通知名称
    public static let onLogout: String = "LKLifecycleOnLogout"
    /// 飞书账号准备切换租户通知名称（解决 cookie 问题）
    public static let beforeSwitchAccout: String = "LKLifecycleBeforeSwitchAccout"
    /// 飞书账号切换租户成功通知名称（解决 cookie 问题）
    public static let switchAccountSucceed: String = "LKLifecycleSwitchAccountSucceed"
}
