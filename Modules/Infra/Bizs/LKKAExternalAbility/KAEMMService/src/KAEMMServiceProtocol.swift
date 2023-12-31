@objc
public protocol KAEMMDependencyProtocol: AnyObject {
  /// 使用 logger 打印日志可以供飞书回捞
  var logger: KAEMMServiceLoggerProtocol { get }
  /// 获取 config
  /// - Parameters:
  ///   - key: isv key
  ///   - space: isv space
  /// - Returns: 远端配置
  func getConfig(space: String, key: String) -> [String: Any]
  ///  获取设备 ID
  /// - Returns: 设备ID
  func getDeviceId() -> String
  ///  获取 Group ID
  /// - Returns: Group ID
  func getGroupId() -> String
  /// 获取登录 token
  /// - Parameters:
  ///   - appId: appID
  ///   - result: token
  func getLoginToken(appId: String, result: @escaping (String) -> Void)
  /// 退出飞书
  func logoutFeishu()
}

@objc
public protocol KAEMMServiceLoggerProtocol: AnyObject {
  /// 输出更多 debug 的信息
  /// - Parameters:
  ///   - tag: tag name
  ///   - msg: debug information
  func verbose(tag: String, _ msg: String)
  /// 只在 debug 下输出信息
  /// - Parameters:
  ///   - tag: tag name
  ///   - msg: debug information
  func debug(tag: String, _ msg: String)
  /// 输出普通信息
  /// - Parameters:
  ///   - tag: tag name
  ///   - msg: debug information
  func info(tag: String, _ msg: String)
  /// 输出警告信息
  /// - Parameters:
  ///   - tag: tag name
  ///   - msg: debug information
  func warning(tag: String, _ msg: String)
  /// 输出错误信息
  /// - Parameters:
  ///   - tag: tag name
  ///   - msg: debug information
  func error(tag: String, _ msg: String)
}

@objc
public protocol KAEMMServiceProtocol: AnyObject {
  /// 飞书启动阶段，异步完成相关初始化之后，调用该方法
  init()
  /// 使用飞书能力调用可以使用的功能
  var dependency: KAEMMDependencyProtocol { set get }
  /// 飞书完成登录操作后调用
  /// - Parameters:
  ///  - token：飞书登录用户唯一标识
  func onLogin()
  /// 飞书退出登录时调用
  func onLogout()
  /// 飞书 App didFinishlaunch 后调用，不建议执行耗时操作
  func onAppFinishLaunch()
}
