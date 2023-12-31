//
//  InterviewChatService.swift
//  Calendar
//
//  Created by zhuheng on 2021/6/18.
//

import Foundation
import LarkContainer
import LarkCompatible
import LarkSetting
import EENavigator
import LarkUIKit
import UniverseDesignToast
import RxSwift

protocol InterviewChatService {
    func handleV1(req: EENavigator.Request, res: Response)
    func handleV2(req: EENavigator.Request, res: Response)
}

final class InterviewChatServiceImpl: InterviewChatService, UserResolverWrapper {
    let calendarDependency: CalendarDependency
    private let bag = DisposeBag()

    let userResolver: UserResolver

    init(userResolver: UserResolver) throws {
        self.userResolver = userResolver
        calendarDependency = try self.userResolver.resolve(assert: CalendarDependency.self)
    }

    private var peopleHost: String {
        DomainSettingManager.shared.currentSetting[DomainSettings.people]?.first ?? ""
    }

    func handleV1(req: EENavigator.Request, res: Response) {
        guard let from = req.from.fromViewController else { return }
        let url = req.url

        UDToast.showDefaultLoading(on: from.view)
        rxInterviewChatIDV1(url: url)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] chatID in
                UDToast.removeToast(on: from.view)
                self?.calendarDependency
                    .jumpToChatController(
                        from: from,
                        chatID: chatID,
                        onError: { [weak from] in
                            guard let from = from else { return }
                            UDToast.showFailure(with: BundleI18n.Calendar.Lark_Legacy_RecallMessage, on: from.view)
                        },
                        onLeaveMeeting: {})
                res.end(resource: nil)
            }, onError: { _ in
                UDToast.removeToast(on: from.view)
                UDToast.showFailure(with: BundleI18n.Calendar.Calendar_Common_FailedToLoad, on: from.view)
            }).disposed(by: bag)
    }

    func handleV2(req: EENavigator.Request, res: Response) {
        guard let from = req.from.fromViewController else { return }
        let url = req.url

        UDToast.showDefaultLoading(on: from.view)
        rxInterviewChatIDV2(url: url)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] chatID in
                UDToast.removeToast(on: from.view)
                self?.calendarDependency
                    .jumpToChatController(
                        from: from,
                        chatID: chatID,
                        onError: { [weak from] in
                            guard let from = from else { return }
                            UDToast.showFailure(with: BundleI18n.Calendar.Lark_Legacy_RecallMessage, on: from.view)
                        },
                        onLeaveMeeting: {})
                res.end(resource: nil)
            }, onError: { _ in
                UDToast.removeToast(on: from.view)
                UDToast.showFailure(with: BundleI18n.Calendar.Calendar_Common_FailedToLoad, on: from.view)
            }).disposed(by: bag)

    }

    private func body(boundary: String, key: String) -> Data {
        var body = String()
        let boundaryPrefix = "--\(boundary)\r\n"
        body += boundaryPrefix
        body += "Content-Disposition: form-data; name=\"interviewer_pk\"\r\n\r\n"
        body += key + "\r\n"
        body += "--".appending(boundary.appending("--"))
        return body.data(using: String.Encoding.utf8, allowLossyConversion: false) ?? Data()
    }

}

// MARK: - Request
extension InterviewChatServiceImpl {
    func rxInterviewChatIDV1(url: URL) -> Observable<String> {
        // URL跳转之前如果检测到是people的面试日程那么先向people请求一个chatId, 然后再跳转
        let isPeopleUrl = url.scheme == "https" && url.host == self.peopleHost && url.path.hasPrefix("/recruitment/chat/")
        if !isPeopleUrl {
            return .error(NSError())
        }

        let key = url.pathComponents.last ?? ""
        let peopleUrl = String(format: "https://\(self.peopleHost)/api/recruitment/interview/chat/hr/")
        guard let serviceUrl = URL(string: peopleUrl) else {
            return .error(NSError())
        }
        var request = URLRequest(url: serviceUrl)
        request.httpMethod = "POST"
        let boundary = "Boundary-\(UUID().uuidString)"
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        request.httpBody = self.body(boundary: boundary,
                                     key: key)

        return Observable<String>.create { [weak self] observer in
            let session = URLSession.shared
            session.dataTask(with: request) { (data, _, error) in
                if let err = error {// 请求发生了错误
                    observer.onError(err)
                    return
                }
                guard let responseData = data, let result = try? JSONSerialization.jsonObject(with: responseData, options: []), let resultDic = result as? [String: Any] else {
                    observer.onError(NSError())
                    return
                }
                // 正确的拿到chaId
                if let chatData = resultDic["data"] as? [String: Any], let chatId = chatData["chat_id"] as? String {
                    observer.onNext(chatId)
                    return
                }
                observer.onError(NSError())
            }.resume()

            return Disposables.create()
        }
    }

    func rxInterviewChatIDV2(url: URL) -> Observable<String> {
        guard let component = URLComponents(string: url.absoluteString)?.queryItems?.first(where: { $0.name == "need_lark_interception_jump_to_chat" })?.value,
              let redirectedURL = URL(string: component) else {
            return .error(NSError())
        }
        return Observable<String>.create { observer in
            var request = URLRequest(url: redirectedURL)
            request.httpMethod = "GET"
            let task = URLSession.shared.dataTask(with: request) { (data, _, _) in
                guard let jsonData = data, let json = try? JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any],
                      let dataDic = json["data"] as? [String: Any],
                      let chatId = dataDic["chat_id"] as? String else {
                    observer.onError(NSError())
                    return
                }
                observer.onNext(chatId)
            }
            task.resume()

            return Disposables.create()
        }
    }
}
