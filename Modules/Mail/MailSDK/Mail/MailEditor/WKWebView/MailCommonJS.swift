//
//  MailCommonJs.swift
//  MailSDK
//
//  Created by tefeng liu on 2020/3/18.
//

import Foundation

enum MailCommonJS {
    static var whiteScreenDetectJS: String {
        return "(function(a){a=\"false\";20>document.getElementsByTagName(\"*\").length&&(a=\"true\");return a})(window);\n"
    }
}
