//
//  CalendarDocsFromMeetingRouterHandler.swift
//  Calendar
//
//  Created by tuwenbo on 2023/5/9.
//

import Foundation
import LarkContainer
import LarkNavigator
import EENavigator
import RxSwift
import LarkAlertController
import UniverseDesignToast


final class CalendarDocsFromMeetingRouterHandler: UserTypedRouterHandler {

    @ScopedInjectedLazy var calendarRustApi: CalendarRustAPI?

    let disposeBag = DisposeBag()

    func handle(_ body: CalendarDocsFromMeeting, req: EENavigator.Request, res: EENavigator.Response) throws {
        guard let from = req.context.from() else {
            assertionFailure("Missing request.context.from")
            return
        }
        self.getMeetingSummaryUrl(with: body.chatId, alertName: body.alertName, from: from) { (result) in
            switch result {
            case .success(let url):
                DispatchQueue.main.async {
                    res.redirect(url)
                }
            case .failure(let error):
                res.end(error: error)
            }
        }
        res.wait()
    }

    public func getMeetingSummaryUrl(with chatId: String, alertName: String, from: NavigatorFrom, urlGetter: @escaping ((Result<URL, Error>) -> Void)) {
        calendarRustApi?.getDocsUrl(by: chatId).subscribe(onNext: { (urlString) in
            if let url = URL(string: urlString) {
                urlGetter(.success(url))
            } else {
                urlGetter(.failure(MsError.cannotGenerateUrl))
            }
        }, onError: { (error) in
            if error.errorType() == .upgradeExternalMeetingErr {
                DispatchQueue.main.async {
                    let alertController = LarkAlertController()
                    alertController.setContent(text: BundleI18n.Calendar.Calendar_MeetingMinutes_UnavailableDueToAdminPermissionSettings(name: alertName))
                    alertController.addPrimaryButton(text: BundleI18n.Calendar.Calendar_Common_GotIt)
                    self.userResolver.navigator.present(alertController, from: from)
                }
            } else {
                DispatchQueue.main.async {
                    UDToast.showFailure(with: error.getTitle() ?? BundleI18n.Calendar.Calendar_Manage_UnableCreateTryLater, on: UIApplication.shared.windows.first { $0.isKeyWindow }
 ?? UIWindow())
                }
            }
        }).disposed(by: disposeBag)
    }

    enum MsError: Error {
        case cannotGenerateUrl
    }

}
