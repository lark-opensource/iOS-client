//
//  EventEditNotesManager.swift
//  Calendar
//
//  Created by 张威 on 2020/4/25.
//

import RxCocoa
import RxSwift
import LarkContainer

/// 日程编辑 - 描述管理
/// docs  类型： Lark日历，oapi 创建的日程可能出现 data，text 数据不一致情况，以 data 为主，data 为空取 text
/// html   类型： 三方日历
/// plain  类型： 本地日历

final class EventEditNotesManager: EventEditModelManager<EventNotes> {

    let rxNotes: BehaviorRelay<EventNotes>
    // 获取 docs data 数据
    var docsDataGetter: (() -> Observable<(data: String, plainText: String)>)?
    // 获取 html data 数据
    var htmlDataGetter: (() -> Observable<String>)?

    private var calendar: EventEditCalendar?
    private let input: EventEditInput
    private let disposeBag = DisposeBag()

    init(userResolver: UserResolver, input: EventEditInput, identifier: String) {
        self.input = input

        let notes: EventNotes = .docs(data: "", plainText: "")

        self.rxNotes = BehaviorRelay(value: notes)

        super.init(userResolver: userResolver, identifier: identifier, rxModel: self.rxNotes)
    }

    // notes 的真正初始化，依赖于 calendar 的初始化完成
    private func initNotes(with calendar: EventEditCalendar) {
        let notes: EventNotes
        switch input {
        case .createWithContext, .createWebinar:
            switch calendar.source {
            case .lark:
                notes = .docs(data: "", plainText: "")
            case .google, .exchange:
                notes = .html(text: "")
            case .local:
                notes = .plain(text: "")
            }
        case .editFromLocal(let ekEvent):
            notes = .plain(text: ekEvent.notes ?? "")
        case .editFrom(let pbEvent, _), .copyWithEvent(let pbEvent, _), .editWebinar(pbEvent: let pbEvent, _):
            switch calendar.source {
            case .lark:
                notes = .docs(data: pbEvent.docsDescription, plainText: pbEvent.description_p)
            case .google, .exchange:
                notes = .html(text: pbEvent.description_p)
            case .local:
                assertionFailure("日程描述--逻辑上不会走到这里")
                notes = .plain(text: pbEvent.description_p )
            }
        }
        self.rxNotes.accept(notes)
    }

    private func switchNotesIfNeeded(fromCalendar: EventEditCalendar, toCalendar: EventEditCalendar) {
        switch (fromCalendar.source, toCalendar.source) {
        case (.lark, .exchange), (.lark, .google):
            if rxNotes.value.isEmpty {
                rxNotes.accept(.html(text: ""))
                return
            }

            assert(htmlDataGetter != nil)
            let rxHtmlData = (htmlDataGetter ?? { .just("") })()
            rxHtmlData.observeOn(MainScheduler.instance)
                .subscribe(
                    onNext: { [weak self] htmlText in
                        self?.rxNotes.accept(.html(text: htmlText))
                    },
                    onError: { [weak self] error in
                        guard let self = self else { return }
                        assertionFailure("get html data failed. notes: \(self.rxNotes.value), error: \(error)")
                        self.rxNotes.accept(.html(text: ""))
                    }
                )
                .disposed(by: disposeBag)
        case (.exchange, .lark), (.google, .lark):
            if rxNotes.value.isEmpty {
                rxNotes.accept(.docs(data: "", plainText: ""))
                return
            }

            assert(docsDataGetter != nil)
            let rxDocsData = (docsDataGetter ?? { .just(("", "")) })()
            rxDocsData.observeOn(MainScheduler.instance)
                .subscribe(
                    onNext: { [weak self] tuple in
                        self?.rxNotes.accept(.docs(data: tuple.data, plainText: tuple.plainText))
                    },
                    onError: { [weak self] error in
                        guard let self = self else { return }
                        assertionFailure("get docs data failed. notes: \(self.rxNotes.value), error: \(error)")
                        self.rxNotes.accept(.docs(data: "", plainText: ""))
                    }
                )
                .disposed(by: disposeBag)
        default:
            break
        }
    }

    func updateNotesIfNeeded(forCalendarChanged newCalendar: EventEditCalendar) {
        let oldCalendar = calendar
        calendar = newCalendar

        if let oldCalendar = oldCalendar {
            switchNotesIfNeeded(fromCalendar: oldCalendar, toCalendar: newCalendar)
        } else {
            // fix notes for initializing calendar
            initNotes(with: newCalendar)
        }
    }

    func updateNotes(_ notes: EventNotes) {
        #if DEBUG
        switch calendar?.source ?? .lark {
        case .lark:
            if case .html = notes { assertionFailure() }
        default:
            if case .docs = notes { assertionFailure() }
        }
        #endif

        rxNotes.accept(notes)
    }

    func clearNotes() {
        guard let calendar = calendar else {
            assertionFailure()
            updateNotes(.html(text: ""))
            return
        }
        switch calendar.source {
        case .lark:
            updateNotes(.docs(data: "", plainText: ""))
        default:
            updateNotes(.html(text: ""))
        }
    }

}
