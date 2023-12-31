//
//  CTADialogDefine.swift
//  CTADialog
//
//  Created by aslan on 2023/10/18.
//

import Foundation

struct CTADialogDefine {
    enum Cons {
        static let profileScheme = "profile"
        static let primaryButton = "primary"
    }

    enum filedType {
        static let user = "user"
        static let plainText = "plain_text"
        static let image = "image"
    }

    enum Request {
        static let path = "/boss/api/v1/feature/stuck_spot"
        static let cookieKey = "Cookie"
        static let locale = "locale"
        static let deviceType = "X-Device-Type"
        static let responseSuccessCode = 200
    }
}

