//
//  SKNoticePushRouterHandler.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/9/24.
//  

import EENavigator
import SpaceInterface
import SwiftyJSON
import SKCommon
import SKFoundation

public final class SKNoticePushRouterHandler: TypedRouterHandler<SKNoticePushRouterBody> {
    override public func handle(_ body: SKNoticePushRouterBody, req: EENavigator.Request, res: Response) {
        DocsLogger.info("[传图接力] SKNoticePushRouterHandler Data: \(body.data)")
        DocsLogger.info("[传图接力] SKNoticePushRouterHandler 测试不处理这里")
//        let json = JSON(parseJSON: body.data)
//        guard let type = json["type"].string else {
//            end(res)
//            return
//        }
//        let data = json["data"].dictionary
//        switch type {
//        case SpaceNoticeHandler.PushType.pushUploadPics.rawValue: redirectToImageHandoff(data, res: res)
//        default:
//            end(res)
//        }
        res.end(resource: nil)
    }

//    private func redirectToImageHandoff(_ data: [String: JSON]?, res: Response) {
//        guard let json = data, let uuid = json["uuid"]?.string,
//            let token = json["token"]?.string,
//            let time = json["time"]?.int else {
//                DocsLogger.info("[传图接力] 缺少参数 \(data ?? [:])")
//                return
//        }
//        DocsLogger.info("[传图接力] PushUploadPicsHandler \(json)")
//        let sessionData = json["session_data"]?.string
//        let newBody = ImageHandoffBody(uuid: uuid, token: token, sessionData: sessionData, time: time)
//        res.redirect(body: newBody)
//    }
//
//    private func end(_ res: Response) {
//        let error = NSError(domain: "com.lark.docs", code: 404, userInfo: ["descripsion": "Type can not be recognized"])
//        res.end(error: error)
//    }
}
