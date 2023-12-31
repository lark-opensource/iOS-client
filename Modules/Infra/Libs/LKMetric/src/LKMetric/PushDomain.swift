import Foundation

// MARK: - Push Level 2

public enum Push: Int32, MetricDomainEnum {
    case unknown
    case token, apns, voip
}

// MARK: - Passport Level 3

public enum VoIP: Int32, MetricDomainEnum {
    case unknown
    case receive, notice
}
