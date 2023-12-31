//
//  EventEmailAttendeeViewModel.swift
//  Calendar
//
//  Created by 张威 on 2020/4/8.
//

import RxSwift
import RxCocoa

final class EventEmailAttendeeViewModel {

    var onAllCellDataUpdate: (() -> Void)?
    let rxInput = BehaviorRelay(value: "")
    let rxSuggestion = BehaviorRelay(value: "")

    internal private(set) var attendees: [EventEditEmailAttendee]

    private var cellDataArray: [CellData] = []
    private var attendeeThatNeedsAutoInsert: EventEditEmailAttendee?
    private let disposeBag = DisposeBag()
    // 描述编辑前的参与人，删除参与人时，用于判断设置 removed 还是删除
    private let originalAttendees: [EventEditEmailAttendee]

    init(
        attendees: [EventEditEmailAttendee],
        originalAttendees: [EventEditEmailAttendee],
        attendeeThatNeedsAutoInsert: EventEditEmailAttendee? = nil
    ) {
        self.attendees = attendees
        self.originalAttendees = originalAttendees
        self.attendeeThatNeedsAutoInsert = attendeeThatNeedsAutoInsert
        self.updateCellData()
        self.rxInput
            .distinctUntilChanged()
            .throttle(.microseconds(500), scheduler: MainScheduler.instance)
            .map { [weak self] text -> String in
                guard let self = self else { return "" }

                let addrs = self.extractAddrsFromInput()
                guard !addrs.isEmpty else { return "" }

                let text = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if addrs.count == 1 {
                    return text
                } else {
                    return BundleI18n.Calendar.Calendar_EmailGuest_AddXEmailsMobile(number: addrs.count, emails: text)
                }
            }
            .bind(to: rxSuggestion)
            .disposed(by: disposeBag)
    }
}

// MARK: ViewData

extension EventEmailAttendeeViewModel {

    struct CellData: EventEmailAttendeeCellDataType, Avatar {
        var emailAttendee: EventEditEmailAttendee
        var identifier: String
        var avatar: Avatar { self }
        var address: String { emailAttendee.address }
        var canDelete: Bool { emailAttendee.permission.isEditable }

        var avatarKey: String = ""
        var userName: String { address }
    }

    func numberOfRows() -> Int {
        return cellDataArray.count
    }

    func sectionHeaderTitle() -> String? {
        guard !cellDataArray.isEmpty else {
            return nil
        }
        return "\(BundleI18n.Calendar.Calendar_GoogleCal_AddedContacts)(\(cellDataArray.count))"
    }

    func cellData(at index: Int) -> EventEmailAttendeeCellDataType? {
        guard index >= 0 && index < cellDataArray.count else {
            return nil
        }
        return cellDataArray[index]
    }

    private func updateCellData() {
        let visibleAttendees = EventEditAttendee.visibleAttendees(of: attendees.map { EventEditAttendee.email($0) })
        let deduplicatedAttendees = EventEditAttendee.deduplicated(of: visibleAttendees)
        self.cellDataArray = deduplicatedAttendees.compactMap {
            guard case .email(let attendee) = $0 else { return nil }
            return CellData(emailAttendee: attendee, identifier: "")
        }
    }
}

// MARK: ViewAction

extension EventEmailAttendeeViewModel {

    private func checkValidForEmail(_ address: String) -> Bool {
        let emailRegex = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        let emailTest = NSPredicate(format: "SELF MATCHES %@", emailRegex)
        return emailTest.evaluate(with: address)
    }

    private func extractAddr(from text: String) -> String? {
        guard let leftBracketIndex = text.range(of: "<")?.lowerBound else {
            return checkValidForEmail(text) ? text : nil
        }
        guard let rightBracketIndex = text.range(of: ">")?.lowerBound else {
            return nil
        }
        guard leftBracketIndex < text.endIndex,
              rightBracketIndex <= text.endIndex,
              leftBracketIndex < rightBracketIndex else {
            return nil
        }
        let addrText = String(text[text.index(after: leftBracketIndex) ..< rightBracketIndex])
            .trimmingCharacters(in: .whitespaces)
        return checkValidForEmail(addrText) ? addrText : nil
    }

    private func extractAddrsFromInput() -> [String] {
        let rawText = rxInput.value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !rawText.isEmpty else {
            return []
        }

        let separators: CharacterSet
        if rawText.contains("<") {
            // 分隔符：全角/半角分号，全角/半角逗号
            separators = CharacterSet(charactersIn: ";；,，")
        } else {
            // 分隔符：全角/半角分号，全角/半角逗号，全角/半角空格
            separators = CharacterSet(charactersIn: ";；,， 　")
        }
        let texts = rawText.components(separatedBy: separators)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        let validAddrs = texts.compactMap(extractAddr(from:))
        guard texts.count == validAddrs.count else {
            return []
        }

        return validAddrs
    }

    private func addEmailAttendee(withAddress address: String) {
        let noVisibleAttendee = (attendees.filter({ $0.status != .removed }).isEmpty)
        if attendees.contains(where: { $0.hasAddress(address) }) {
            for index in 0 ..< attendees.count
                where attendees[index].hasAddress(address) && attendees[index].status == .removed {
                if let autoInsertAttendee = attendeeThatNeedsAutoInsert,
                    attendees[index].hasSameAddress(with: autoInsertAttendee) {
                    attendees[index].status = autoInsertAttendee.status
                } else {
                    attendees[index].status = .needsAction
                }
            }
        } else {
            if let autoInsertAttendee = attendeeThatNeedsAutoInsert,
               autoInsertAttendee.hasAddress(address) {
                attendees.append(autoInsertAttendee)
            } else {
                let newAttendee = EventEditEmailAttendee(
                    address: address,
                    calendarId: "",
                    status: .needsAction,
                    permission: .writable
                )
                attendees.append(newAttendee)
            }
        }
        // 如果 visible 参与人数量是从 0 到 1，则主动插入 autoInsertAttendee
        if let autoInsertAttendee = attendeeThatNeedsAutoInsert,
           noVisibleAttendee,
           attendees.filter({ $0.status != .removed }).count == 1 {
            attendees.removeAll { $0.hasSameAddress(with: autoInsertAttendee) }
            attendees.insert(autoInsertAttendee, at: 0)
        }
    }

    // 添加参与人
    func addEmailAttendeeFromInput() -> Bool {
        let addrs = extractAddrsFromInput()
        guard !addrs.isEmpty else {
            return false
        }

        addrs.forEach(addEmailAttendee(withAddress:))
        updateCellData()
        onAllCellDataUpdate?()
        return true
    }

    // 删除参与人
    func deleteRow(at index: Int) {
        guard index >= 0 && index < cellDataArray.count else {
            return
        }
        let targetAttendee = cellDataArray[index].emailAttendee
        guard targetAttendee.permission.isEditable else {
            EventEdit.logger.error("delete email attendee failed because of permission")
            return
        }
        let needsRemovedStatus = originalAttendees.contains { $0.hasSameAddress(with: targetAttendee) }
        if needsRemovedStatus {
            for i in 0 ..< attendees.count where attendees[i].hasSameAddress(with: targetAttendee) {
                attendees[i].status = .removed
            }
        } else {
            attendees.removeAll { $0.hasSameAddress(with: targetAttendee) }
        }
        updateCellData()
        onAllCellDataUpdate?()
    }

}
