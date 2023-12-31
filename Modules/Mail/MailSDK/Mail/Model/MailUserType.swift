//
//  MailUserType.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/7/14.
//

import Foundation
import YYCache

protocol MailCleanAbleValue {
    mutating func mailClean()
}

extension Array: MailCleanAbleValue {
    mutating func mailClean() {
        self.removeAll()
    }
}

extension Dictionary: MailCleanAbleValue {
    mutating func mailClean() {
        self.removeAll()
    }
}

extension String: MailCleanAbleValue {
    mutating func mailClean() {
        self = ""
    }
}

extension ThreadSafeArray: MailCleanAbleValue {
    func mailClean() {
        self.removeAll()
    }
}

extension ThreadSafeDictionary: MailCleanAbleValue {
    func mailClean() {
        self.removeAll()
    }
}

extension Bool: MailCleanAbleValue {
    mutating func mailClean() {
        self = false
    }
}

extension Int64: MailCleanAbleValue {
    mutating func mailClean() {
        self = 0
    }
}

private class MailUserDataManager {
    static let shared = MailUserDataManager()

    var objects = NSHashTable<AnyObject>.weakObjects()

    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(handleClean),
                                               name: Notification.Name.Mail.MAIL_SDK_CLEAN_DATA,
                                               object: nil)
    }

    @objc
    private func handleClean() {
        for obj in objects.allObjects {
            if var value = obj as? MailCleanAbleValue {
                value.mailClean()
            }
        }
    }
}

@propertyWrapper
class MailAutoCleanData<T> {
    private var value: T

    init(_ value: T) {
        self.value = value
        addObserver()
    }

    init(wrappedValue: T) {
        self.value = wrappedValue
        addObserver()
    }

    var wrappedValue: T {
        get {
            value
        }
        set {
            self.value = newValue
        }
    }

    private func addObserver() {
        MailUserDataManager.shared.objects.add(self)
    }
}

extension MailAutoCleanData: MailCleanAbleValue {
    func mailClean() {
        if var obj = value as? MailCleanAbleValue {
            obj.mailClean()
        } else {
//            assert(false, "is your value confirm MailCleanAbleValue ?")
        }
    }
}

@propertyWrapper
final class MailAutoCleanDataLazy<T> {

    private let intialBlock: () -> T
    fileprivate var _wrappedValue: T?
    var wrappedValue: T {
        if let value = _wrappedValue {
            return value
        } else {
            _wrappedValue = intialBlock()
            return _wrappedValue!
        }
    }

    init(initialBlock: @escaping () -> T) {
        self.intialBlock = initialBlock
        addObserver()
    }

    private func addObserver() {
        MailUserDataManager.shared.objects.add(self)
    }
}

extension MailAutoCleanDataLazy: MailCleanAbleValue {
    func mailClean() {
        if var obj = _wrappedValue as? MailCleanAbleValue {
            obj.mailClean()
        } else if _wrappedValue != nil {
            assert(false, "is your value confirm MailCleanAbleValue ?")
        }
    }
}
