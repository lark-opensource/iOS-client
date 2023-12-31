//
//  DocPermissionProtocolImpl.swift
//  SKCommon
//
//  Created by liweiye on 2020/11/16.
//

import Foundation
import SwiftyJSON
import SKFoundation
import SpaceInterface
import EENavigator

public final class DocPermissionProtocolImpl: DocPermissionProtocol {
    private var deleteCollaboratorsRequest: DocsRequest<JSON>?
    private var adjustSettingsHandler: AdjustSettingsHandler?

    public init() {}

    public func deleteCollaborators(type: Int, token: String, ownerID: String, ownerType: Int, permType: Int, complete: @escaping (Swift.Result<Void, Error>) -> Void) {
        deleteCollaboratorsRequest?.cancel()
        let collaboratorSource: CollaboratorSource = CollaboratorSource(rawValue: permType) ?? .defaultType
        let context = DeleteCollaboratorsRequest(type: type, token: token, ownerID: ownerID, ownerType: ownerType, collaboratorSource: collaboratorSource)
        deleteCollaboratorsRequest = PermissionManager.getDeleteCollaboratorsRequest(context: context) { result, _  in
            complete(result)
        }
    }

    public func showAdjustExternalPanel(from: EENavigator.NavigatorFrom, docUrl: String, callback: @escaping ((Swift.Result<Void, AdjustExternalError>) -> Void)) {
        guard let url = URL(string: docUrl) else {
            DocsLogger.error("DocPermissionProtocol: docUrl is nil", extraInfo: ["docUrl": docUrl])
            return
        }
        guard let token = DocsUrlUtil.getFileToken(from: url) else {
            DocsLogger.error("DocPermissionProtocol: token is nil", extraInfo: ["docUrl": docUrl])
            return
        }
        guard let docType = DocsUrlUtil.getFileType(from: url) else {
            DocsLogger.error("DocPermissionProtocol: docType is nil", extraInfo: ["docUrl": docUrl])
            return
        }
        let type = ShareDocsType(rawValue: docType.rawValue)
        let isWiki = url.docs.isWikiDocURL
        adjustSettingsHandler = AdjustSettingsHandler(token: token, type: type, isSpaceV2: true, isWiki: isWiki)

        adjustSettingsHandler?.toAdjustSettingsIfEnabled(sceneType: .calenderDocCard, topVC: from.fromViewController, completion: { status in
            switch status {
            case .success:
                DocsLogger.info("DocPermissionProtocol: success")
                callback(.success(()))
            case .fail:
                DocsLogger.info("DocPermissionProtocol: fail")
                callback(.failure(.fail))
            case .disabled:
                DocsLogger.info("DocPermissionProtocol: disabled")
                callback(.failure(.disabled))
            }
        })
    }
}
