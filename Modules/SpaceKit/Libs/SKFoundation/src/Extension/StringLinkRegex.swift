//
//  StringLinkRegex.swift
//  SKFoundation
//
//  Created by zengsenyuan on 2022/9/28.
//  

import Foundation

// swiftlint:disable line_length
public final class LinkRegex {
    public static var PROTOCOL = "https?|s?ftp|ftps|nfs"
    // const CHINESE_RANGE = '\u4e00-\u9fa5';
    // TODO: @chenyiyin 先移除对中文的支持
    static var CHINESE_RANGE = ""
    static var encodeContent = "%[0-9a-f]{2}"
    static var charAndNumber = "a-zA-Z0-9" // 前端是A-Z0-9，因为前端默认忽略大小写
    static var LINK_SUFFIX =
        "\\b([/#\\?]([\\-\(charAndNumber)@:_+.~#?&'/=;$,!\\*\\[\\]\\(\\){}^|<>]|" +
        "(\(encodeContent)))*([\\-\(charAndNumber)&@#/=~\\(\\)_|]|(\(encodeContent)))?)?"
    static var LOCALHOST_REG = "localhost(:[0-9]{2,5})?"
    static var IP_ADDRESS_REG =
        "(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5]).){3}(2[0-4][0-9]|25[0-5]|1[0-9]{2}|[1-9][0-9]|[0-9])(:[0-9]{2,5})?"
    static var TOP_DOMAIN =
        "com|org|net|int|edu|gov|mil|ac|ad|ae|af|ag|ai|al|am|an|ao|aq|ar|as|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cc|cf|cg|ch|ci|ck|cl|cm|cn|co|cr|cu|cv|cw|cx|cy|cz|de|dj|dk|dm|do|dz|ec|ee|eg|eh|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gh|gi|gl|gm|gn|gp|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|io|iq|ir|is|it|jm|jo|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mf|mg|mh|mk|ml|mm|mn|mo|mp|mq|mr|ms|mt|mu|mv|mw|mx|my|mz|na|nc|ne|nf|ng|ni|nl|no|np|nr|nu|nz|om|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|ps|pt|pw|py|qa|re|ro|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|ss|st|su|sv|sx|sy|sz|tc|td|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|tt|tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|za|zm|zw|site|top|wtf|xxx|xyz|cloud|engineering|help|one"
    static var TOP_DOMAIN_LITE = "com|cn|tk|de|net|org|uk|info|nl|ru|hk"
    static var IP_REG =
        "((((\(PROTOCOL))://)?(\(LOCALHOST_REG)))|(((\(PROTOCOL))://)(\(IP_ADDRESS_REG))))\(LINK_SUFFIX)"
    //这里和前端不一致，去掉了 [${CHINESE_RANGE}]{1,256}(\.){1,50}| ，原因是CHINESE_RANGE目前为空，java不接受这样的正则语法
    static var URL_HOST_BODY = "(([\\-\(charAndNumber)_+~#@]{1,256}\\.){1,50})"
    static var ANY_TOP_DOMAIN = "[a-z0-9\\-]{2,15}"
    static var HYPERTEXT_PROTOCOL = "https?"

    static var HYPERTEXT_URL_REG = "^\\s*((\(HYPERTEXT_PROTOCOL)" +
        ":\\/\\/\(URL_HOST_BODY)\(ANY_TOP_DOMAIN))(:[0-9]{2,5})?\(LINK_SUFFIX)\\s*$"

    static var LOOSE_URL_REG =
        "(((\(PROTOCOL)):\\/\\/)?(\(URL_HOST_BODY))(\(ANY_TOP_DOMAIN)))(:[0-9]{2,5})?\(LINK_SUFFIX)"

    static var URL_REG =
        "(((\(PROTOCOL)):\\/\\/\(URL_HOST_BODY)\(ANY_TOP_DOMAIN))|(\(URL_HOST_BODY)(\(TOP_DOMAIN_LITE))))(:[0-9]{2,5})?\(LINK_SUFFIX)"

    static var EMAIL_URL_BODY = "[\\w.!#$%&'*+-/=?^_\\`{|}~]{1,2000}@[A-Za-z0-9_.-]+\\."

    static var LENGTH_LIMITED_EMAIL_REG =
        "^(?!data:)((mailto:\(EMAIL_URL_BODY)\(ANY_TOP_DOMAIN))|(\(EMAIL_URL_BODY)(\(TOP_DOMAIN))))\\b"

    public static var LOOSE_LINK_REG = "\(LENGTH_LIMITED_EMAIL_REG)|\(LOOSE_URL_REG)|\(IP_REG)"

    public static var LINK_REG = "\(LENGTH_LIMITED_EMAIL_REG)|\(URL_REG)|\(IP_REG)"

//    static var ISV_BLOCK_SCHEMA_REG = "block:\\/\\/([\\w-]+)\\?from=([\\w-]+)&id=([\\w-]+)"

    static let predicate = NSPredicate(format: "SELF MATCHES[c] %@", LinkRegex.LOOSE_LINK_REG)

    public static func looseLinkValid(_ urlString: String) -> Bool {
        return predicate.evaluate(with: urlString)
    }
}
