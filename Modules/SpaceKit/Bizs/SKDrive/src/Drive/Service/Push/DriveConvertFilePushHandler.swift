//
//  DriveConvertFilePushHandler.swift
//  SpaceKit
//
//  Created by zenghao on 2019/8/14.
//

import Foundation
import SwiftyJSON
import SKCommon
import SKFoundation

protocol DriveConvertFilePushHandlerDelegate: AnyObject {
    func fileConvertionDidFinished(code: Int, ticket: String, token: String, type: String?)
}

class DriveConvertFilePushHandler {
    private let tagPrefix = StablePushPrefix.convertFile.rawValue

    let userId: String
    private let pushManager: StablePushManager

    weak var delegate: DriveConvertFilePushHandlerDelegate?

    init(userId: String) {
        self.userId = userId
        let tag = tagPrefix + "_" + userId
        let pushInfo = SKPushInfo(tag: tag,
                                  resourceType: StablePushPrefix.convertFile.resourceType(),
                                  routeKey: userId,
                                  routeType: SKPushRouteType.uid)
        pushManager = StablePushManager(pushInfo: pushInfo)
        pushManager.register(with: self)
    }

    deinit {
        pushManager.unRegister()
        DocsLogger.debug("DriveConvertFilePushHandler deinit")
    }
}

extension DriveConvertFilePushHandler: StablePushManagerDelegate {
    func stablePushManager(_ manager: StablePushManagerProtocol,
                           didReceivedData data: [String: Any],
                           forServiceType type: String,
                           andTag tag: String) {
        let json = JSON(data)
        guard let dataString = json["body"]["data"].string,
            let (code, ticket, token, type) = parse(dataString) else {
            DocsLogger.warning("DriveConvertFilePushHandler - didReceivedRNData: parse info from json failed")
            return
        }
        DocsLogger.driveInfo("DriveConvertFilePushHandler - didReceivedRNData: parse info from json succeed")
        delegate?.fileConvertionDidFinished(code: code, ticket: ticket, token: token, type: type)
    }
}

extension DriveConvertFilePushHandler {

    private func parse(_ infoString: String) -> (code: Int, ticket: String, token: String, type: String?)? {
        let json = JSON(parseJSON: infoString)
        guard let tokens = json["tokens"].arrayObject as? [String],
            let ticket = json["ticket"].string,
            let type = json["type"].string,
            let code = json["code"].int,
            let token = tokens.first  else {
                DocsLogger.warning("get token from data failed")
            return nil
        }
        return (code: code, ticket: ticket, token: token, type: type)
    }
}
