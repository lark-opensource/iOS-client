//
//  AtInfoXMLParserInterface.swift
//  SpaceInterface
//
//  Created by huayufan on 2023/4/3.
//  


import Foundation

public protocol AtInfoXMLParserInterface {
    func attrString(encodeString: String,
                                 attributes: [NSAttributedString.Key: Any],
                                 isHighlightSelf: Bool,
                                 useSelfCache: Bool,
                                 lineBreakMode: NSLineBreakMode,
                                 permissionBlock: PermissionQuerryBlock?,
                                 userId: String?,
                                 selfNameMaxWidth: CGFloat,
                                 atSelfYOffset: CGFloat?,
                                 atInfoTransform: ((AtInfo) -> AtInfo)?) -> NSAttributedString
    
    func decodedAttrString(model: CommentDraftModel, attributes: [NSAttributedString.Key: Any], permissionBlock: PermissionQuerryBlock?) -> NSAttributedString
    func decodedAttrString(model: CommentDraftModel, attributes: [NSAttributedString.Key: Any],
                           token: String, type: DocsType?, checkPermission: Bool) -> NSAttributedString
}
