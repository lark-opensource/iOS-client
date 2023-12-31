import RxSwift

// swiftlint:disable missing_docs

public struct LoginDevice: Codable, Equatable {
    public let id: String
    public let name: String
    public let os: String
    public let model: String
    public let terminal: Terminal
    public let tenantName: String
    public let loginTime: TimeInterval
    public let loginIP: String
    public var isCurrent: Bool = false
    public var isAbnormal: Bool?

    public enum Terminal: Int, Codable {
        case unknown
        case pc
        case web
        case android
        case ios
    }

    public init(id: String, name: String, os: String, model: String, terminal: Terminal, tenantName: String, loginTime: TimeInterval, loginIP: String, isCurrent: Bool = false, isAbnormal: Bool? = nil) {
        self.id = id
        self.name = name
        self.os = os
        self.model = model
        self.terminal = terminal
        self.tenantName = tenantName
        self.loginTime = loginTime
        self.loginIP = loginIP
        self.isCurrent = isCurrent
        self.isAbnormal = isAbnormal
    }

    enum CodingKeys: String, CodingKey {
        case id = "device_id"
        case name = "device_name"
        case os = "device_os"
        case model = "device_model"
        case terminal = "terminal_type"
        case tenantName = "tenant_name"
        case loginTime = "login_time"
        case loginIP = "login_ip"
        case isCurrent = "is_current"
        case isAbnormal = "is_abnormal"
    }
}

public protocol DeviceManageServiceProtocol {
    /// 所有已登录设备
    var loginDevices: Observable<[LoginDevice]> { get }
    /// 拉取登录设备
    func fetchLoginDevices()
    /// 踢出登录设备
    func disableLoginDevice(deviceID: String) -> Observable<Bool>
    /// 更新登录设备信息
    func updateLoginDevices(_ devices: [LoginDevice])
}
