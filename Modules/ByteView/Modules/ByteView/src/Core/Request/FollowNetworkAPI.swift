//
//  FollowNetworkAPI.swift
//  ByteView
//
//  Created by kiri on 2022/12/19.
//

import Foundation
import ByteViewNetwork

extension HttpClient {
    var follow: FollowNetworkAPI {
        FollowNetworkAPI(self)
    }
}

final class FollowNetworkAPI {
    private let logger = Logger.vcFollow
    private let httpClient: HttpClient
    fileprivate init(_ httpClient: HttpClient) {
        self.httpClient = httpClient
    }

    func startShareDocument(_ documentURL: String,
                            meetingId: String,
                            lifeTime: FollowInfo.LifeTime,
                            initSource: FollowInfo.InitSource,
                            authorityMask: Int32?,
                            breakoutRoomId: String?,
                            shareId: String? = nil,
                            isSameToCurrent: Bool = false,
                            completion: ((Result<ShareFollowResponse, Error>) -> Void)? = nil) {
        logger.info("start share document: meetingId = \(meetingId), documentURL = \(documentURL.vc.removeParams().hashValue), lifeTime = \(lifeTime), initSource = \(initSource), authorityMask = \(String(describing: authorityMask)), shareId.isNil: \(shareId == nil), isSameToCurrent = \(isSameToCurrent)")
        let startShareDocumentTimeInterval = Date().timeIntervalSince1970
        MagicShareTracks.trackBeforeShareFollowRequest()
        updateShareFollowRequest(meetingId: meetingId,
                                 action: (shareId != nil && isSameToCurrent) ? .takeOver : .start, // 如果当前正在共享的文档，与选择的文档一致，发起共享类型从.startNew更换为.takeOver
                                 documentURL: documentURL,
                                 lifetime: lifeTime,
                                 initSource: initSource,
                                 authorityMask: authorityMask,
                                 shareID: shareId,
                                 breakoutRoomId: breakoutRoomId) {
            switch $0 {
            case .success(let response):
                MagicShareTracks.trackOnShareFollowRequestSuccess(
                    duration: Date().timeIntervalSince1970 - startShareDocumentTimeInterval,
                    shareId: response.followInfo.shareID)
            case .failure(let error):
                MagicShareTracks.trackOnShareFollowRequestFail(error: error)
            }
            completion?($0)
        }
    }

    // authorityMask: https://bytedance.feishu.cn/wiki/wikcnPnYMdZvM1Zb2xvIqFkKQxd
    // GRANT_INTERNAL_EDIT = 2; GRANT_EXTERNAL_EDIT = 32;
    func createAndShareDocs(_ type: VcDocType, meetingId: String, isExternalMeeting: Bool, breakoutRoomId: String?, tenantTag: TenantTag?) {
        httpClient.getResponse(CreateDocRequest(docType: type)) { r in
            guard let url = r.value?.url else { return }
            self.startShareDocument(url, meetingId: meetingId, lifeTime: .ephemeral, initSource: .initDirectly, authorityMask: (isExternalMeeting || tenantTag != .standard) ? 34 : 2, breakoutRoomId: breakoutRoomId)
        }
    }

    func backToPreviousDocument(_ documentURL: String,
                                meetingId: String,
                                shareID: String,
                                breakoutRoomId: String?,
                                completion: ((Result<Void, Error>) -> Void)? = nil) {
        logger.info("reactivate share document: documentURL = \(documentURL.vc.removeParams().hashValue), shareID = \(shareID)")
        let startShareDocumentTimeInterval = Date().timeIntervalSince1970
        MagicShareTracks.trackBeforeShareFollowRequest()
        updateShareFollowRequest(meetingId: meetingId, action: .reactivate,
                                 documentURL: documentURL,
                                 shareID: shareID,
                                 breakoutRoomId: breakoutRoomId) { result in
            switch result {
            case .success(let response):
                MagicShareTracks.trackOnShareFollowRequestSuccess(
                    duration: Date().timeIntervalSince1970 - startShareDocumentTimeInterval,
                    shareId: response.followInfo.shareID)
                completion?(.success(Void()))
            case .failure(let error):
                MagicShareTracks.trackOnShareFollowRequestFail(error: error)
                completion?(.failure(error))
            }
        }
    }

    func stopShareDocument(_ documentURL: String, meetingId: String, breakoutRoomId: String?) {
        logger.info("stop share document, documentURL: \(documentURL.vc.removeParams().hashValue)")
        updateShareFollowRequest(meetingId: meetingId, action: .stop, documentURL: documentURL, breakoutRoomId: breakoutRoomId)
    }

    func takeOverDocument(_ documentURL: String, meetingId: String, shareID: String, breakoutRoomId: String?) {
        logger.info("take over document, documentURL: \(documentURL), shareID: \(shareID)")
        updateShareFollowRequest(meetingId: meetingId, action: .takeOver, documentURL: documentURL, shareID: shareID, breakoutRoomId: breakoutRoomId)
    }

    func transferSharer(_ documentURL: String, meetingId: String, sharer: Participant, breakoutRoomId: String?,
                        completion: ((Result<ShareFollowResponse, Error>) -> Void)? = nil) {
        logger.info("transfer documentURL: \(documentURL.vc.removeParams().hashValue) to sharer: \(sharer)")
        let transPresenterData = ShareFollowRequest.TransPresenterData(newPresenter: sharer.user)
        updateShareFollowRequest(meetingId: meetingId, action: .transPresenter,
                                 documentURL: documentURL,
                                 transData: transPresenterData,
                                 breakoutRoomId: breakoutRoomId, completion: completion)
    }

    func grantFollowToken(_ documentURL: String, meetingId: String, breakoutRoomId: String?, accessToken: String, passportDomain: String,
                          completion: ((Result<Void, Error>) -> Void)? = nil) {
        logger.info("called grant follow token, documentURL: \(documentURL.vc.removeParams().hashValue)")
        let url = "https://\(passportDomain)/suite/api/login/disposable/?app_id=2"
        let httpRequest = SendHttpRequest(url: url, method: .post, headers: ["Cookie": "session=\(accessToken)"])
        httpClient.getResponse(httpRequest) { (result) in
            switch result {
            case .failure(let error):
                self.logger.warn("sendHTTP(2167) failed, error.failReasonCode: \(error.toErrorCode())")
                completion?(.failure(error))
            case .success(let resp):
                guard let json = try? JSONSerialization.jsonObject(with: resp.body, options: []) else {
                    self.logger.warn("sendHTTP(2167) success, resp toJSON() failed, resp.status: \(resp.status), resp.statusCode: \(resp.httpStatusCode)")
                    completion?(.failure(VCError.unknown))
                    return
                }
                guard let jsonDic = json as? [String: Any] else {
                    self.logger.warn("sendHTTP(2167) success, json toDic() failed")
                    completion?(.failure(VCError.unknown))
                    return
                }
                guard let token = jsonDic["loginParameters"] as? String else {
                    self.logger.warn("sendHTTP(2167) success, get token failed, loginParameters is invalid")
                    completion?(.failure(VCError.unknown))
                    return
                }
                self.logger.info("will send grant follow token request, mID: \(meetingId), breakoutRoomId: \(breakoutRoomId), token: \(token.hashValue)")
                let request = GrantFollowTokenRequest(meetingId: meetingId, breakoutRoomId: breakoutRoomId, token: token, url: documentURL)
                self.httpClient.send(request, completion: completion)
            }
        }
    }

    func postMagicShareInfo(eventType: Int, meetingId: String, objToken: String?, timestamp: Int64, shareId: String?, info: String?) {
        let req = MagicShareInfoRequest(eventType: eventType, meetingId: meetingId, objToken: objToken ?? "", timestamp: timestamp, shareId: shareId ?? "", info: info)
        httpClient.getResponse(req, options: .retry(2, owner: nil)) { result in
            switch result {
            case .success(let res):
                if !res.success {
                    self.logger.info("post magic share info, error: \(res.errMsg)")
                }
            case .failure(let error):
                self.logger.info("post magic share info, error: \(error)")
            }
        }
    }

    private func updateShareFollowRequest(meetingId: String,
                                          action: ShareFollowRequest.Action,
                                          documentURL: String,
                                          transData: ShareFollowRequest.TransPresenterData? = nil,
                                          lifetime: FollowInfo.LifeTime? = nil,
                                          initSource: FollowInfo.InitSource = .unknown,
                                          authorityMask: Int32? = nil,
                                          shareID: String? = nil,
                                          breakoutRoomId: String? = nil,
                                          completion: ((Result<ShareFollowResponse, Error>) -> Void)? = nil) {
        let request = ShareFollowRequest(meetingId: meetingId, breakoutMeetingId: breakoutRoomId, action: action, url: documentURL, initSource: initSource, shareId: shareID, authorityMask: authorityMask, lifeTime: lifetime, transPresenterData: transData)
        httpClient.getResponse(request, completion: completion)
    }
}
