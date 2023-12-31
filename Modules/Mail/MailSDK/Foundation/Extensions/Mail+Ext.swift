//
//  Mail+Ext.swift
//  Action
//
//  Created by tefeng liu on 2019/6/5.
//
import Foundation

final class MailExtension<BaseType> {
    var base: BaseType
    init(_ base: BaseType) {
        self.base = base
    }
}

protocol MailExtensionCompatible {
    associatedtype MailCompatibleType
    var mail: MailCompatibleType { get }
    static var mail: MailCompatibleType.Type { get }
}

extension MailExtensionCompatible {
    var mail: MailExtension<Self> {
        return MailExtension(self)
    }
    static var mail: MailExtension<Self>.Type {
        return MailExtension.self
    }
}
