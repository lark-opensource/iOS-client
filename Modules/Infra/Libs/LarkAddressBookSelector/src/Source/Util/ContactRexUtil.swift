//
//  ContactRexUtil.swift
//  LarkAddressBookSelector
//
//  Created by mochangxing on 2019/7/4.
//

import Foundation

final class ContactRexUtil: NSObject {
    private static let emailRegex: String = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
    private static let emailPredicate: NSPredicate = NSPredicate(format: "SELF MATCHES %@", emailRegex)

    class func validateEmail(email: String) -> Bool {
        return emailPredicate.evaluate(with: email)
    }
}
