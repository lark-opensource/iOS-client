import Foundation
@objc
public protocol KALoggerProtocol: AnyObject {
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

@objcMembers
public class KALoggerExternal: NSObject {
    public override init() {
        super.init()
    }
    
    public static let shared = KALoggerExternal()
    public var logger: KALoggerProtocol?
}

