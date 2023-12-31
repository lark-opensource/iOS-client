//
//  MailGroupEventBus.swift
//  LarkContact
//
//  Created by tefeng liu on 2021/11/11.
//

import Foundation
import RxSwift
import RxRelay
import LarkSDKInterface
import RustPB
import LarkMessengerInterface
import RxCocoa

extension MailGroupEventBus {
    enum GroupDetailChange {
        case groupInfo(MailContactGroup)
        case memberCount(Int)
        case managerCount(Int)
        case members([Email_Client_V1_MailGroupMember])
        case managers([Email_Client_V1_MailGroupManager])
        case permissionMember([Email_Client_V1_MailGroupPermissionMember])
        case permissionMemberCount(Int)
    }

    enum RefreshRequest {
        case mailGroupDetail
    }
}

final class MailGroupEventBus {
    static let shared = MailGroupEventBus()

    @EventValue<GroupDetailChange> var detailChange

    @EventValue<RefreshRequest> var refreshRequest

    // MARK: action
    func fireMailGroupInfoRaw(raw: RustPB.Email_Client_V1_MailGroupDetailResponse) {
        $detailChange.accept(.groupInfo(raw.mailGroup))
        $detailChange.accept(.managerCount(Int(raw.managerCount)))
        $detailChange.accept(.memberCount(Int(raw.memberCount)))
        $detailChange.accept(.members(raw.members))
        $detailChange.accept(.managers(raw.managerMembers))
        $detailChange.accept(.permissionMember(raw.permissionMembers))
        $detailChange.accept(.permissionMemberCount(Int(raw.permissionMemberCount)))
    }

    func fireRequestGroupDetail() {
        $refreshRequest.accept(.mailGroupDetail)
    }

    // MARK: ValueType
    @propertyWrapper
    struct EventValue<Value> {
        private var _wrappedValue: PublishSubject<Value>
        var wrappedValue: Observable<Value> {
            return _wrappedValue.asObservable()
        }

        // 通过$符号可以访问到
        @inlinable var projectedValue: EventValue {
            return self
        }

        init() {
            _wrappedValue = PublishSubject<Value>()
        }

        func accept(_ value: Value) {
            _wrappedValue.onNext(value)
        }
    }

}
