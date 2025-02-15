//
//  OpenAPIWifiErrno.swift
//  LarkOpenApis
//
//  GENERATED BY ANYCODE. DO NOT MODIFY!!!
//  TICKETID: 24012
//

/// Wi-FiErrno
public enum OpenAPIWifiErrno: OpenAPIErrnoProtocol {
    // wifi未连接
    case notConnected
    // Wi-Fi不可用，获取失败。
    case invalid

    public var bizDomain: Int { 15 }
    public var funcDomain: Int { 6 }

    public var rawValue: Int {
        switch self {
        case .notConnected:
            return 1
        case .invalid:
            return 2
        }
    }
    
    public var errString: String {
        switch self {
        case .notConnected:
            return "Wi-Fi not connected"
        case .invalid:
            return "Invalid Wi-Fi information"
        }
    }
}
