//
//  ZoomMeetingPhoneListViewModel.swift
//  Calendar
//
//  Created by pluto on 2022-10-20.
//

import Foundation
import RxSwift
import RxRelay
import LKCommonsLogging
import LarkContainer
import ServerPB

protocol ZoomMeetingPhoneListViewModelDelegate: AnyObject {
    func reloadPhoneList(meetingID: String, password: String)
}

final class ZoomMeetingPhoneListViewModel: UserResolverWrapper {

    private let logger = Logger.log(ZoomMeetingPhoneListViewModel.self, category: "calendar.ZoomMeetingPhoneListViewModel")
    private let disposeBag = DisposeBag()

    weak var delegate: ZoomMeetingPhoneListViewModelDelegate?

    let userResolver: UserResolver

    @ScopedInjectedLazy var calendarAPI: CalendarRustAPI?

    let zoomConfigInfo: Rust.ZoomVideoMeetingConfigs
    var zoomPhoneNumModels: [Server.ZoomPhoneNums] = []

    init(zoomConfigInfo: Rust.ZoomVideoMeetingConfigs, userResolver: UserResolver) {
        self.zoomConfigInfo = zoomConfigInfo
        self.userResolver = userResolver
        loadPhoneNumberList()
    }

    private func loadPhoneNumberList() {
        calendarAPI?.getZoomMeetingPhoneNumsRequest(meetingID: zoomConfigInfo.meetingID, creatorAccount: zoomConfigInfo.creatorAccount, isDefault: false, creatorUserID: zoomConfigInfo.creatorUserID)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (response) in
                guard let self = self else {
                    return
                }
                self.logger.info("getPhoneNumbeList success")
                self.zoomPhoneNumModels = response.phoneNums
                let meetingID = self.zoomConfigInfo.meetingID.description.formatZoomMeetingNumber()
                let password = response.pstnPassword
                self.delegate?.reloadPhoneList(meetingID: meetingID, password: password)
            }, onError: {[weak self] error in
                guard let self = self else {
                    return
                }
                self.logger.error("getPhoneNumbeList failed: \(error)")
            }).disposed(by: disposeBag)
    }
}

extension String {
    // 会议号格式化 默认会议号长度 10、11位 预期格式3 4 4 、3 3 4
    func formatZoomMeetingNumber() -> String {
        let s = self
        let numberRegex = "^[0-9]+$"
        let numberTest = NSPredicate(format: "SELF MATCHES %@", numberRegex)
        // 非纯数字的串不切割。直接返回
        if !numberTest.evaluate(with: s) { return s }
        guard s.count >= 10 else {
            return s
        }
        let index1 = s.index(s.startIndex, offsetBy: 3)
        let index2 = s.index(s.endIndex, offsetBy: -4)
        return "\(s[..<index1]) \(s[index1..<index2]) \(s[index2..<s.endIndex])"
    }
}
