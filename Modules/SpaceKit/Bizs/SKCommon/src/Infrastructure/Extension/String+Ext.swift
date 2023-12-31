//
//  String+Ext.swift
//  SKCommon
//
//  Created by lijuyou on 2020/7/14.
//  


import SKFoundation

// From BaseDataPlugin
extension String {
    public var isClientVarKey: Bool {
        return contains("CLIENT_VARS")
    }

    public static var docsChangeSetKey: String {
        guard let userId = User.current.info?.userID, let tenantID = User.current.info?.tenantID else {
            spaceAssertionFailure("userID/tenantID is nil")
            return "_COMMITED_CHANGESET"
        }
        return tenantID + "_" + userId + "_COMMITED_CHANGESET"
    }
}
