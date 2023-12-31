//
//  EventEditViewModel+Notes.swift
//  Calendar
//
//  Created by ByteDance on 2023/1/16.
//

import Foundation
import CalendarFoundation

// MARK: Setup Notesmanager {
extension EventEditViewModel {

    var notesModel: EventEditNotesManager? {
        self.models[EventEditModelType.notes] as? EventEditNotesManager
    }
    
    func makeNotesModel() -> EventEditNotesManager {
        let notes_model = EventEditNotesManager(userResolver: self.userResolver,
                                                input: self.input,
                                                identifier: EventEditModelType.notes.rawValue)
        notes_model.relyModel = [EventEditModelType.calendar.rawValue]
        notes_model.initMethod = { [weak self, weak notes_model] observer in
            guard let self = self, let notes_model = notes_model else {
                assertionFailureLog()
                return
            }
            if let calendar = self.calendarModel?.rxModel?.value.current {
                notes_model.updateNotesIfNeeded(forCalendarChanged: calendar)
            }
            observer.onCompleted()
        }
        notes_model.initLater = { [weak self, weak notes_model] in
            guard let self = self, let notes_model = notes_model else { return }
            self.calendarModel?.rxModel?.subscribe { [weak notes_model] (_, current) in
                guard let current = current, let notes_model = notes_model else { return }
                notes_model.updateNotesIfNeeded(forCalendarChanged: current)
            }.disposed(by: self.disposeBag)
        }
        return notes_model
    }
}
