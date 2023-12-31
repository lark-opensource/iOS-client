//
//  SpanFrontCoordinator.swift
//  Calendar
//
//  Created by huoyunjie on 2022/4/21.
//

import Foundation
import LarkContainer
import LarkUIKit
import RxSwift
import RxCocoa
import LarkActionSheet
import UIKit
import LKCommonsLogging
import UniverseDesignToast
import UniverseDesignActionPanel
import EENavigator

struct SpanFront {
    static let logger = Logger.log(SpanFrontCoordinator.self, category: "lark.calendar.eventEdit.spanFront")

    static func logInfo(_ message: String) {
        logger.info(message)
    }

    static func logError(_ message: String) {
        logger.error(message)
    }

    static func logWarn(_ message: String) {
        logger.warn(message)
    }

    static func logDebug(_ message: String) {
        logger.debug(message)
    }

}

// SpanFrontCoordinator 是一个透明的vc，因 EventEditCoordinator 生命周期原因需要用它来承载 spanSheet
class SpanFrontCoordinator: UIViewController, UserResolverWrapper {

    @ScopedInjectedLazy var calendarAPI: CalendarRustAPI?

    let userResolver: UserResolver
    private let coordinator: EventEditCoordinator
    private let serverEvent: BehaviorSubject<Rust.Event?> = .init(value: nil)
    private let disposeBag = DisposeBag()

    init(coordinator: EventEditCoordinator, userResolver: UserResolver) {
        self.coordinator = coordinator
        self.userResolver = userResolver
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 开启编辑前置流程
    /// - Parameters:
    ///   - presentingViewController: 页面层级关系 presentingViewController -> SpanFrontCoordinator -> UDActionSheet
    ///   - source: 用于 iPad popOver 定位的 view
    func start(from presentingViewController: UIViewController, source: UIView? = nil) {
        let showEventEditVC: (Rust.Span?) -> Void = { [weak self] span in
            guard let self = self, let span = span else {
                // span 为 nil 时，presentingViewController dismiss 掉透明 vc
                presentingViewController.dismiss(animated: false)
                return
            }
            if span == .allEvents,
               case var .editFrom(event, instance) = self.coordinator.editInput {
                // 编辑所有 等同于 编辑重复性日程的第一个虚假日程信息
                instance.startTime = event.startTime
                instance.endTime = event.endTime
                instance.originalTime = event.originalTime
                instance.isEditable = event.isEditable
                let editInput = EventEditInput.editFrom(pbEvent: event, pbInstance: instance)
                self.coordinator.editInput = editInput
            }
            let vc = self.coordinator.prepare(span: span)

            // presentingViewController dismiss 透明 vc 后，展示编辑页面
            presentingViewController.dismiss(animated: false) {
                presentingViewController.present(vc, animated: true)
            }
        }
        prepareSpan(selectedSpan: showEventEditVC, source: source)
            .subscribeForUI(onNext: { actionSheet in
                if let vc = actionSheet {
                    self.present(vc, animated: true)
                }
            }).disposed(by: disposeBag)
    }

    /// 准备展示 span 的 actionSheet
    /// - Parameters:
    ///   - selectedSpan: 处理 span 选择的闭包
    ///   - source: 用于 iPad popOver 定位
    /// - Returns: actionSheet 生成存在异步，所以通过 rx 返回。
    ///            当新建、复制场景返回 nil 时，表示不弹出编辑前置弹窗，此时需要前置调用 selectedSpan；
    ///            其他场景 selectedSpan 包含在前置弹窗的点击事件中。
    private func prepareSpan(selectedSpan: @escaping (Rust.Span?) -> Void, source: UIView? = nil) -> Observable<UDActionSheet?> {
        switch coordinator.editInput {
        case .createWithContext, .copyWithEvent, .createWebinar, .editWebinar:
            selectedSpan(.noneSpan)
            return .just(nil)
        case .editFrom(let pbEvent, let pbInstance):
            guard let source = source else { return .just(nil) }
            if !pbEvent.rrule.isEmpty {
                // 重复性日程
                let isOriginalEditable = pbEvent.isEditable // 是否有完全编辑权限
                let actionSheet = self.prepareSpanSheet(
                    with: isOriginalEditable ? [.thisEvent, .futureEvents, .allEvents] : [.thisEvent, .allEvents],
                    selectedSpan: selectedSpan,
                    source: source,
                    tracerEvent: (pbInstance, pbEvent)
                )
                return .just(actionSheet)
            } else if pbEvent.originalTime != 0 {
                // 例外日程 需要异步进行 Span 权限校验
                return
                self.checkExceptionEventAllSpan(event: pbEvent)
                    .observeOn(MainScheduler.instance)
                    .map({ [weak self] (inOriginalEvent: Bool) -> UDActionSheet? in
                        return
                        self?.prepareSpanSheet(
                            with: [.thisEvent, .allEvents],
                            disabled: inOriginalEvent ? [] : [.allEvents],
                            selectedSpan: { [weak self] span in
                                guard let self = self,
                                      let span = span else { return selectedSpan(nil) }
                                if span == .thisEvent {
                                    selectedSpan(span)
                                } else if span == .allEvents {
                                    self.startLoading()
                                    // api 获取 serverEvent 信息后替换 input 的 event
                                    self.changeCoordinatorEvent()
                                        .observeOn(MainScheduler.instance)
                                        .subscribe(onNext: { [weak self] success in
                                            self?.endLoading(success)
                                            if success {
                                                selectedSpan(span)
                                            } else {
                                                selectedSpan(nil)
                                            }
                                        }).disposed(by: self.disposeBag)
                                }
                            },
                            source: source,
                            tracerEvent: (pbInstance, pbEvent)
                        )
                    })
            } else {
                // 普通日程
                selectedSpan(.noneSpan)
                return .just(nil)
            }

        case .editFromLocal(let ekEvent):
            guard let source = source else { return .just(nil) }
            if ekEvent.isDetached {
                // 例外日程
                selectedSpan(.thisEvent)
                return .just(nil)
            } else if ekEvent.recurrenceRules?.isEmpty ?? true {
                // 普通日程
                selectedSpan(.noneSpan)
                return .just(nil)
            } else {
                // 重复性日程
                let actionSheet = self.prepareSpanSheet(
                    with: [.thisEvent, .futureEvents],
                    selectedSpan: selectedSpan,
                    source: source,
                    tracerTuple: (ekEvent.eventIdentifier ?? "", Int64(ekEvent.startDate?.timeIntervalSince1970 ?? 0))
                )
                return .just(actionSheet)
            }
        }
    }

    private func prepareSpanSheet(
        with options: Set<Rust.Span>,
        disabled disabledOptions: Set<Rust.Span> = .init(),
        selectedSpan: @escaping (Rust.Span?) -> Void,
        source: UIView,
        tracerEvent: (Rust.Instance, Rust.Event)? = nil,
        tracerTuple: (String, Int64)? = nil
    ) -> UDActionSheet {
        let clickSpan: (Rust.Span?) -> Void = { [weak self] span in
            guard let self = self,
                  let span = span else {
                      SpanFront.logger.info("user span front interaction. cancel")
                      selectedSpan(nil)
                      return
                  }
            ReciableTracer.shared.recStartEditEvent()

            SpanFront.logger.info("user span front interaction. click span: \(span), span clickable status: \(!disabledOptions.contains(span))")
            let click: [Rust.Span: String] = [
                .thisEvent: "edit_this_event",
                .futureEvents: "edit_after_event",
                .allEvents: "edit_all_event"
            ]
            CalendarTracerV2.EventDetail.traceClick {
                $0.click(click[span] ?? "").target("cal_event_full_create_view")
                if let tracerEvent = tracerEvent {
                    $0.mergeEventCommonParams(commonParam: CommonParamData(instance: tracerEvent.0, event: tracerEvent.1))
                } else {
                    $0.mergeEventCommonParams(commonParam: CommonParamData(calEventId: tracerTuple?.0, eventStartTime: tracerTuple?.1.description ))
                }
            }

            let disabledToastStr: [Rust.Span: String] = [
                .futureEvents: I18n.Calendar_EditNo_ThisAndFollowingEvent_Hover,
                .allEvents: I18n.Calendar_EditNo_AllEvent_Hover
            ]

            if disabledOptions.contains(span) {
                UDToast.showTips(with: disabledToastStr[span] ?? "", on: self.presentingViewController?.view ?? self.view)
                selectedSpan(nil)
            } else {
                selectedSpan(span)
            }
        }
        let source = UDActionSheetSource(sourceView: source,
                                         sourceRect: source.bounds,
                                         preferredContentWidth: 200,
                                         arrowDirection: .up)
        let config = UDActionSheetUIConfig(isShowTitle: false, popSource: source) {
            clickSpan(nil)
        }
        let actionSheetVC = UDActionSheet(config: config)
        if options.contains(.thisEvent) {
            let item = UDActionSheetItem(title: I18n.Calendar_Edit_ThisEvent_Option,
                                         titleColor: disabledOptions.contains(.thisEvent) ? UIColor.ud.textDisable : UIColor.ud.textTitle) {
                clickSpan(.thisEvent)
            }
            actionSheetVC.addItem(item)
        }
        if options.contains(.futureEvents) {
            let item = UDActionSheetItem(title: I18n.Calendar_Edit_ThisAndFollowingEvent_Option,
                                         titleColor: disabledOptions.contains(.futureEvents) ? UIColor.ud.textDisable : UIColor.ud.textTitle) {
                clickSpan(.futureEvents)
            }
            actionSheetVC.addItem(item)
        }
        if options.contains(.allEvents) {
            let item = UDActionSheetItem(title: I18n.Calendar_Edit_AllEvent_Option,
                                         titleColor: disabledOptions.contains(.allEvents) ? UIColor.ud.textDisable : UIColor.ud.textTitle) {
                clickSpan(.allEvents)
            }
            actionSheetVC.addItem(item)
        }
        actionSheetVC.setCancelItem(text: I18n.Calendar_Common_Cancel) {
            clickSpan(nil)
        }
        return actionSheetVC
    }

    private func changeCoordinatorEvent() -> Observable<Bool> {
        self.serverEvent
            .filter({ $0 != nil })
            .map { [weak self] event in
                guard let self = self,
                      let event = event else { return false }
                if case let .editFrom(_, instance) = self.coordinator.editInput {
                    let input = EventEditInput.editFrom(pbEvent: event, pbInstance: instance)
                    self.coordinator.editInput = input
                }
                return true
            }.catchError { _ in return .just(false) }

    }

    private func checkExceptionEventAllSpan(event: Rust.Event) -> Observable<Bool> {
        // 判断是否在原日程中
        self.calendarAPI?.getEvent(calendarId: event.calendarID, key: event.key, originalTime: 0)
            .map({ [weak self] pbEvent in
                // 如果在原日程中，则获取原日程的 severpb 信息
                if pbEvent.selfAttendeeStatus == .removed { return false }
                self?.loadingServerEvent(serverId: pbEvent.serverID)
                return true
            })
            .catchErrorJustReturn(false) ?? .empty()
    }

    private func loadingServerEvent(serverId: String) {
        self.calendarAPI?.getServerPBEvent(serverId: serverId)
            .subscribe(onNext: { [weak self] event in
                self?.serverEvent.onNext(event)
            }, onError: { [weak self] error in
                self?.serverEvent.onError(error)
            }).disposed(by: self.disposeBag)
    }

    private func startLoading() {
        if let window = userResolver.navigator.mainSceneWindow {
            UDToast.showLoading(with: I18n.Calendar_Common_LoadingCommon, on: window)
        }
    }

    private func endLoading(_ succeed: Bool) {
        if let window = userResolver.navigator.mainSceneWindow {
            UDToast.removeToast(on: window)
            if !succeed {
                UDToast.showFailure(with: I18n.Calendar_Common_FailedToLoad, on: window)
            }
        }
    }
}
