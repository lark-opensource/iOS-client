//
//  SpaceNoticeHandler.swift
//  LarkSpaceKit
//
//  Created by chenjiahao.gill on 2019/8/5.
//  

import Foundation
import SwiftyJSON
import EENavigator
import SpaceInterface
import SKCommon
import SKFoundation

// 处理 Lark NoticePush 的事情
// 目前只有传图接力在使用，但是这个能力理论上可以被扩展，因此预留了这个 Handler
public final class SpaceNoticeHandler {

    public static let shared = SpaceNoticeHandler()

    enum PushType: String {
        case pushUploadPics = "PUSH_UPLOAD_PICS"
    }

    private lazy var uploadPicsHandler = {
        return PushUploadPicsHandler()
    }()

    public func handle(body: String) {
        DocsLogger.info("[传图接力] SpaceNoticeHandler handle: \(body)")
        let json = JSON(parseJSON: body)
        guard let type = json["type"].string else {
            DocsLogger.info("[传图接力] 没有带上类型")
            return
        }
        switch type {
        case PushType.pushUploadPics.rawValue: self.uploadPicsHandler.handlePushUploadPics(data: json["data"].dictionary)
        default: ()
        }
    }

    public func handleAppWillEnterForeground() {
        uploadPicsHandler.appEnterForeground()
    }
}

extension SpaceNoticeHandler {
    func setNeedShowUploadPics(_ need: Bool) {
        uploadPicsHandler.lock = need
    }
    func getNeedShowUploadPics() -> Bool {
        return uploadPicsHandler.lock
    }
}

// 传图接力
extension SpaceNoticeHandler {
    struct UploadPicsPush {
        let time: Int
        let uuid: String
        let token: String
        let sessionData: String?
    }
    class PushUploadPicsHandler {
        /// 防止用户通知横幅点击进入，会触发 appEnterForeground，也会触发路由 ImageHandoffHandler
        /// 这个参数相当于锁，防止打开两次页面
        fileprivate var lock = true

        private var lastPush: UploadPicsPush?

        fileprivate func handlePushUploadPics(data: [String: JSON]?) {
            DispatchQueue.main.async {
                guard let json = data, let uuid = json["uuid"]?.string,
                    let token = json["token"]?.string,
                    let time = json["time"]?.int else {
                        DocsLogger.info("[传图接力] 缺少参数 \(data ?? [:])")
                        return
                }
                DocsLogger.info("[传图接力] PushUploadPicsHandler \(json)")
                let sessionData = json["session_data"]?.string
                let push = UploadPicsPush(time: time, uuid: uuid, token: token, sessionData: sessionData)
                self.lastPush = push
                /// 应用在后台不打开
                if UIApplication.shared.applicationState != .background {
                    self.router(push)
                }
            }
        }

        private func emptyLastPush() {
            self.lastPush = nil
        }

        // 不超过 30 秒进入前台，会直接打开界面
        fileprivate func appEnterForeground() {
            guard let lastPush = lastPush else { return }
            DocsLogger.info("[传图接力] appEnterForeground")
            let min: Double = 30
            let time = lastPush.time
            if (Date().timeIntervalSince1970 - (Double(time) / 1000)) <= min {
                router(lastPush)
            }
        }

        private func router(_ push: UploadPicsPush) {
            DocsLogger.info("[传图接力] 跳转： UUID: \(push.uuid) Time: \(push.time)")
            //传图接力功能在很小灰度范围内，不再维护
            guard let fromView = Navigator.shared.mainSceneWindow?.rootViewController else { return }
            emptyLastPush()
        }

    }
}
