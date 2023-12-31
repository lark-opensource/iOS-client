//
//  OPAppAuditServiceImpl.swift
//  LarkOpenPlatform
//
//  Created by changrong on 2021/1/12.
//

import Foundation
import LarkSecurityAudit
import LarkOPInterface

final class OPAppAuditServiceImpl: OPAppAuditService {
    private let securityAudit: SecurityAudit

    public init(currentUserID: String) {
        self.securityAudit = SecurityAudit()
        var event = Event()
        event.operator = OperatorEntity()
        event.operator.type = .entityUserID
        event.operator.value = currentUserID
        self.securityAudit.sharedParams = event
    }
    
    public func auditEnterApp(_ appID: String) {
        var event = Event()
        var objectEntity = ObjectEntity()
        event.module = .moduleApp
        event.operation = .operationRead
        objectEntity.type = .entityMiniProgramsAndH5
        objectEntity.value = appID
        event.objects = [objectEntity]
        securityAudit.auditEvent(event)
    }

}
