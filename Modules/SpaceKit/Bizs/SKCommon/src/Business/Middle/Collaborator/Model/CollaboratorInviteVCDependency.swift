//
//  CollaboratorInviteVCDependency.swift
//  SKCommon
//
//  Created by guoqp on 2020/12/31.
//

import Foundation
import SKFoundation

public final class CollaboratorInviteVCDependency {
    private(set) var fileModel: CollaboratorFileModel
    private(set) var items: [Collaborator]
    private(set) var modeConfig: CollaboratorInviteModeConfig
    private(set) var needShowOptionBar: Bool
    private(set) var source: CollaboratorInviteSource
    private(set) var statistics: CollaboratorStatistics?
    public var permStatistics: PermissionStatistics?
    private(set) var bitablePermissonRule: BitablePermissionRule?
    var userPermisson: UserPermissionAbility?

    public init(fileModel: CollaboratorFileModel,
         items: [Collaborator],
         layoutConfig: CollaboratorInviteModeConfig,
         needShowOptionBar: Bool,
         source: CollaboratorInviteSource,
         statistics: CollaboratorStatistics?,
         permStatistics: PermissionStatistics?,
         userPermisson: UserPermissionAbility?,
         bitablePermissonRule: BitablePermissionRule? = nil) {
        self.items = items
        self.fileModel = fileModel
        self.modeConfig = layoutConfig
        self.needShowOptionBar = needShowOptionBar
        self.source = source
        self.statistics = statistics
        self.permStatistics = permStatistics
        self.userPermisson = userPermisson
        self.bitablePermissonRule = bitablePermissonRule
    }

//    public func updateSource(newSource: CollaboratorInviteSource) {
//        self.source = newSource
//    }
}

struct CollaboratorSearchConfig {

    enum InviteExternalOption: Equatable {
        case all
        case userOnly
        case none
    }
    let shouldSearchOrganization: Bool
    let shouldSearchUserGroup: Bool
    var inviteExternalOption: InviteExternalOption
}
