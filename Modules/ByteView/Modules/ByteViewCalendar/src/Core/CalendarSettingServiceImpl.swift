//
//  CalendarSettingService.swift
//  ByteViewMod
//
//  Created by kiri on 2023/6/29.
//

import Foundation
import ByteViewCommon
import ByteViewUI
import ByteViewNetwork
import ByteViewSetting
import ByteViewInterface
import LarkContainer

final class CalendarSettingServiceImpl: CalendarSettingService {
    let userResolver: UserResolver
    init(userResolver: UserResolver) {
        self.userResolver = userResolver
    }

    func openSettingForStart(vcSettingId: String?, from: UIViewController, completion: @escaping (Result<CalendarSettingResponse, Error>) -> Void) {
        do {
            let service = try userResolver.resolve(assert: UserSettingManager.self)
            var context: CalendarSettingContext
            if let vcSettingId = vcSettingId {
                context = .init(type: .preEdit(vcSettingId))
            } else {
                context = .init(type: .start)
            }
            context.createSubmitHandler = { r in
                completion(r.map({ CalendarSettingResponse(vcSettingId: $0.vcSettingID) }))
            }
            let viewController = service.ui.createCalendarSettingViewController(context: context)
            let vc = NavigationController(rootViewController: viewController)
            vc.modalPresentationStyle = .formSheet
            from.present(vc, animated: true)
        } catch {
            completion(.failure(error))
        }
    }

    func createWebinarConfigController(param: WebinarConfigParam) -> UIViewController? {
        do {
            let service = try userResolver.resolve(assert: UserSettingManager.self)
            let context = WebinarSettingContext(jsonString: param.configJson, speakerCanInviteOthers: param.speakerCanInviteOthers, speakerCanSeeOtherSpeakers: param.speakerCanSeeOtherSpeakers, audienceCanInviteOthers: param.audienceCanInviteOthers, audienceCanSeeOtherSpeakers: param.audienceCanSeeOtherSpeakers)
            return service.ui.createWebinarSettingViewController(context: context)
        } catch {
            Logger.calendar.error("resolve UserSettingManager failed, \(error)")
            return nil
        }
    }

    func getWebinarLocalConfig(vc: UIViewController) -> Result<WebinarConfigParam, Error>? {
        guard let vc = vc as? WebinarSettingViewController else { return nil }
        let result = vc.saveWebinarSettings()
        switch result {
        case .success(let settings):
            let param = WebinarConfigParam(configJson: try? settings.toJSONString(), speakerCanInviteOthers: settings.speakerCanInviteOthers, speakerCanSeeOtherSpeakers: settings.speakerCanSeeOtherSpeakers, audienceCanInviteOthers: settings.audienceCanInviteOthers, audienceCanSeeOtherSpeakers: settings.audienceCanSeeOtherSpeakers)
            return .success(param)
        case .failure(let error):
            return .failure(error)
        }
    }

    /// 预约会议时，获取最大参会人数上限
    func pullWebinarMaxParticipantsCount(organizerTenantId: Int64, organizerUserId: Int64, completion: @escaping (Result<Int64, Error>) -> Void) {
        do {
            let httpClient = try userResolver.resolve(assert: HttpClient.self)
            httpClient.getResponse(GetCalendarDefaultVCSettingsRequest(userId: userResolver.userID, organizerTenantId: organizerTenantId, organizerUserId: organizerUserId, isWebinar: true, needVcSetting: false)) { r in
                completion(r.map({ $0.maxParti }))
            }
        } catch {
            completion(.failure(error))
        }
    }

    func pullWebinarSuiteQuota(completion: @escaping (Result<Bool, Error>) -> Void) {
        do {
            let service = try userResolver.resolve(assert: UserSettingManager.self)
            service.refreshSuiteQuota(force: true, meetingId: nil) { r in
                completion(r.map({ $0.webinar }))
            }
        } catch {
            completion(.failure(error))
        }
    }
}
