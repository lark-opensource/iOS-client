//
//  LRVCWebContainerBody.swift
//  LarkRVC
//
//  Created by zhouyongnan on 2022/11/9.
//

import Foundation
import EENavigator
import LarkRustClient
import RustPB
import LarkContainer
import RxSwift
import ServerPB
import ByteViewNetwork
import LarkNavigator

public struct LRVCWebContainerBody: PlainBody {
    public static let pattern = "//client/videoconference/lrvc"

    public let roomId: String
    public let meetingId: String

    public init(roomId: String, meetingId: String) {
        self.roomId = roomId
        self.meetingId = meetingId
    }
}

public final class LRVCWebContainerHandler: UserTypedRouterHandler {
    
    public func handle(_ body: LRVCWebContainerBody, req: EENavigator.Request, res: EENavigator.Response) {
        let request = GetLrvcUrlRequest(roomId: body.roomId, meetingId: body.meetingId)
        let userId = userResolver.userID
        HttpClient(userId: userId).getResponse(request) { result in
            if let urlStr = result.value?.lrvcURL,
               let url = URL(string: urlStr) {
                    Util.runInMainThread {
                        let vc = LarkRoomWebViewManager.createLarkRoomWebViewVC(url: url, userId: userId)
                        LarkRoomWebViewManager.logger.info("lrvc url request success, create lrvc page")
                        res.end(resource: vc)
                }
            } else {
                LarkRoomWebViewManager.logger.error("get lrvc url fail, error: \(result.error?.localizedDescription)")
                res.end(error: result.error)
            }
        }
        LarkRoomWebViewManager.logger.info("start get room lrvc request!")
        res.wait()
    }

}
