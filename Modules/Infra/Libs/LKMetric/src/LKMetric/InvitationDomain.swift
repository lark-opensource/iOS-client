//
//  InvitationDomain.swift
//  LKMetric
//
//  Created by shizhengyu on 2019/12/29.
//

import Foundation

// MARK: - Invitation Level 2
public enum Invitation: Int32, MetricDomainEnum {
    case unknown
    case invite, receive, contacts, award
}

// MARK: - Invitation Level 3
public enum Invite: Int32, MetricDomainEnum {
    case unknown
    case `interal`, external
}

public enum Receive: Int32, MetricDomainEnum {
    case unknown
    case `interal`, external
}

public enum Contacts: Int32, MetricDomainEnum {
    case unknown
}

public enum Award: Int32, MetricDomainEnum {
    case unknown
    case `interal`, external
}

// MARK: - Invitation Level 4
public enum Internal: Int32, MetricDomainEnum {
    case unknown
    case orientation, nonDirectional
}

public enum External: Int32, MetricDomainEnum {
    case unknown
    case orientation, nonDirectional
}
