//
//  EventDetailRefreshHandle.swift
//  Calendar
//
//  Created by Rico on 2021/10/21.
//

import Foundation
import EventKit
import RxSwift

enum EventDetailRefreshReason: CustomStringConvertible, CustomDebugStringConvertible {

    // 本地日程更新
    case local(ekEvent: EKEvent)
    // 编辑页返回的日程更新
    case edit(newEvent: EventDetail.Event, span: EventDetail.Event.Span)
    // 直接使用event刷新
    case newEvent(newEvent: EventDetail.Event)
    // 制定reformer刷新
    case newReformer(newReformer: EventDetailViewModelDataReformer)
    // 使用入口reformer刷新
    case sameReformer

    var description: String {
        switch self {
        case let .local(ekEvent): return "local: \(ekEvent.description)"
        case let .edit(newEvent, span): return "edit: \(newEvent.dt.description), span: \(span)"
        case let .newEvent(newEvent): return " new Event: \(newEvent.dt.description)"
        case let .newReformer(newReformer): return " new reformer: \(newReformer.description)"
        case .sameReformer: return "same reformer"
        }
    }

    var debugDescription: String {
        switch self {
        case let .local(ekEvent): return "local: \(ekEvent.debugDescription)"
        case let .edit(newEvent, span): return "edit: \(newEvent.dt.debugDescription), span: \(span)"
        case let .newEvent(newEvent): return " new Event: \(newEvent.dt.debugDescription)"
        case let .newReformer(newReformer): return " new reformer: \(newReformer.debugDescription)"
        case .sameReformer: return "same reformer"
        }
    }
}

final class EventDetailRefreshHandle {

    private let refreshSubject: PublishSubject<EventDetailRefreshReason>

    init(refreshSubject: PublishSubject<EventDetailRefreshReason>) {
        self.refreshSubject = refreshSubject
    }

    func refresh(ekEvent: EKEvent) {
        refreshSubject.onNext(.local(ekEvent: ekEvent))
    }

    func refresh(newEvent: EventDetail.Event) {
        refreshSubject.onNext(.newEvent(newEvent: newEvent))
    }

    func refreshByEdit(newEvent: EventDetail.Event, span: EventDetail.Event.Span) {
        refreshSubject.onNext(.edit(newEvent: newEvent, span: span))
    }

    func refreshWith(reformer: EventDetailViewModelDataReformer) {
        refreshSubject.onNext(.newReformer(newReformer: reformer))
    }

    /// 慎用，这个代表使用第一次进入详情页接口的参数重新刷新，如果页面声明周期内参数变化的话，可能拿到的结果非预期
    func refresh() {
        refreshSubject.onNext(.sameReformer)
    }
}
