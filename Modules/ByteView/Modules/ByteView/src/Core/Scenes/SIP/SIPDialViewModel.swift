//
//  SIPDialAggViewModel.swift
//  ByteView
//
//  Created by admin on 2022/5/27.
//

import Foundation
import RxRelay
import RxSwift
import ByteViewNetwork

class SIPDialViewModel {

    enum StateType {
        case none
        case arrow
        case loading
        case error
    }

    let meeting: InMeetMeeting

    private(set) var isLoading = false
    private var _currentIPAddr: H323Info?
    private var h323AccessList: [GetSIPInviteInfoResponse.H323Access] = []
    private var sipDomain: String?

    var currentIPAddr: H323Info? {
        get {
            if _currentIPAddr == nil && !ipAddrs.isEmpty {
                return ipAddrs.first
            }
            return _currentIPAddr
        }
        set {
            _currentIPAddr = newValue
        }
    }

    private let sipInviteRelay: BehaviorRelay<([H323Info], Error?)> = BehaviorRelay(value: ([], nil))
    var sipInviteObservable: Observable<([H323Info], Error?)> { sipInviteRelay.asObservable() }

    private(set) var ipAddrs: [H323Info] = []
    private(set) var error: Error?

    var sipURI: String {
        guard meeting.data.inMeetingInfo != nil, let domain = sipDomain else {
            return ""
        }

        return "\(meeting.info.meetNumber)@\(domain)"
    }

    var ipAddrTitle: String {
        if isLoading || (!isLoading && error != nil) {
            return ""
        }
        return currentIPAddr?.h323Description ?? ""
    }

    var formattedMeetingNumber: String {
        return meeting.info.formattedMeetingNumber
    }

    var ipAddrStateType: StateType {
        if isLoading {
            return .loading
        }

        if !isLoading && error != nil {
            return .error
        }

        return .arrow
    }

    var httpClient: HttpClient { meeting.httpClient }

    init(meeting: InMeetMeeting) {
        self.meeting = meeting
    }

    func fetchIPAddrs() {
        if !ipAddrs.isEmpty {
            return
        }

        isLoading = true
        httpClient.getResponse(GetSIPInviteInfoRequest(tenantID: meeting.accountInfo.tenantId)) { [weak self] result in
            guard let self = self else {
                return
            }

            switch result {
            case .success(let resp):
                self.error = nil
                self.sipDomain = resp.sipDomain
                self.h323AccessList = resp.h323AccessList
                let h323CountryKeys = self.h323AccessList.map { $0.country }
                self.handleH323Country(h323CountryKeys: h323CountryKeys)
            case .failure(let error):
                self.isLoading = false
                self.error = error
                Logger.meeting.info("getSIPInviteInfo error: \(error)")
                self.sipDomain = nil
                self.ipAddrs = []
                self.sipInviteRelay.accept(([], error))
            }
        }
    }

    private func handleH323Country(h323CountryKeys: [String]) {
        httpClient.i18n.get(h323CountryKeys) { [weak self] result in
            guard let self = self else {
                return
            }
            var ipAddrs: [H323Info] = []
            if let templates = result.value {
                let list = self.h323AccessList.compactMap { item -> H323Info? in
                    guard let country = templates[item.country] else { return nil }
                    return H323Info(ip: item.ip, country: country)
                }
                ipAddrs = list
            }
            self.error = result.error
            self.ipAddrs = ipAddrs
            self.isLoading = false
            self.sipInviteRelay.accept((ipAddrs, self.error))
        }
    }

    func isIPAddrChosen(_ ipAddr: H323Info?) -> Bool {
        guard let ipAddr = ipAddr, let currIPAddr = currentIPAddr else {
            return false
        }

        return currIPAddr == ipAddr
    }
}
