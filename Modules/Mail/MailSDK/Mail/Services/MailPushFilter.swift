//
//  MailPushFilter.swift
//  MailSDK
//
//  Created by tefeng liu on 2023/5/30.
//

import Foundation
import RxSwift

class MailPushFilter<Element> {
    fileprivate var recorder = Set<String>()

    typealias FilterMapFunc = (Element) -> (isBlock: Bool, type: String)

    fileprivate var mapFunc: FilterMapFunc?

    private(set) var enableBlock: Bool = false
}

// MARK: public api
extension MailPushFilter {
    func setup(mapFunc: @escaping FilterMapFunc) {
        self.mapFunc = mapFunc
    }

    func startRecord() {
        self.enableBlock = true
        MailLogger.info("[MailPushFilter] startRecord")
    }

    func getRecord() -> [String] {
        return Array(recorder)
    }
    
    func updateRecord(_ type: String) {
        MailLogger.info("[mail_swipe_actions] enableBlock: \(enableBlock) type: \(type)")
        if !enableBlock { return }
        recorder.insert(type)
    }

    func clearRecordAndStop() {
        self.enableBlock = false
        recorder.removeAll()
        MailLogger.info("[MailPushFilter] clearRecordAndStop")
    }

    fileprivate func check(e: Element) -> (Bool, String) {
        return mapFunc?(e) ?? (false, "")
    }
}

extension Observable {
    func addMailFilter(mailFilter: MailPushFilter<Element>) -> Observable<Element> {
        return self.filter { (element) -> Bool in
            if !mailFilter.enableBlock { return true }
            let (block, type) = mailFilter.check(e: element)
            if !block {
                return true
            } else {
                MailLogger.info("[MailPushFilter] mail push has been block \(element)")
                mailFilter.recorder.insert(type)
                return false
            }
        }
    }
}
