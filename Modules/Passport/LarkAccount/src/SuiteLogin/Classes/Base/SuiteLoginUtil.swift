//
//  SuiteLoginUtil.swift
//  SuiteLogin
//
//  Created by Yiming Qu on 2019/6/13.
//

import Foundation
import LKCommonsLogging
import LarkReleaseConfig
import LarkLocalizations
import RxSwift
import ECOProbe

class SuiteLoginUtil {
    static let logger = Logger.log(SuiteLoginUtil.self, category: "SuiteLogin.Util")

    static func runOnMain(_ block: @escaping () -> Void) {
        if Thread.current == .main {
            block()
        } else {
            DispatchQueue.main.async(execute: block)
        }
    }

    static func queryURL(urlString: String, params: [String: Any], keepOldItems: Bool = false, sortedKey: Bool = true) -> URL? {
        if params.isEmpty {
            return URL(string: urlString)
        }
        guard let urlComponents = NSURLComponents(string: urlString) else {
            Self.logger.error("n_action_domain_construct_url_components_fail", additionalData: ["urlSring": urlString])
            return nil
        }
        let keys: [String]
        if sortedKey {
            keys = params.keys.sorted { $0 < $1 }
        } else {
            keys = params.keys.map({ $0 })
        }
        let items = keys.flatMap { key -> [URLQueryItem] in
            if let value = params[key] {
                if let v = value as? String {
                    return [URLQueryItem(name: key, value: v)]
                } else if let vs = value as? [Any] {
                    return vs.map { (v)  in
                        URLQueryItem(name: key, value: "\(v)")
                    }
                } else {
                    return [URLQueryItem(name: key, value: "\(value)")]
                }
            } else {
                return []
            }
        }
        if keepOldItems {
            urlComponents.queryItems?.append(contentsOf: items)
        } else {
            urlComponents.queryItems = items
        }
        return urlComponents.url
    }

    static func userDefault() -> UserDefaults {
        return userDefault(suiteName: PassportConf.shared.groupId)
    }

    static func userDefault(suiteName: String) -> UserDefaults {
        if let ud = UserDefaults(suiteName: suiteName) {
            return ud
        } else {
            Self.logger.warn("UserDefaults init with suiteName: \(suiteName) failed.")
            return UserDefaults.standard
        }
    }

    static func removeWhiteSpaceAndNewLines(_ text: String) -> String {
        let text = text.filter({ !$0.isWhitespace && !$0.isNewline })
        // replace pinyin space if has, usually happy when inputting email using pinyin
        return text.replacingOccurrences(of: pinyinSpace, with: "")
    }

    static func isNetworkEnable() -> Bool {
        guard let reach = UploadLogManager.reach else { return false }
        switch reach.connection {
        case .none:
            return false
        case .wifi, .cellular:
            return true
        @unknown default:
            return true
        }
    }

    class func currentLanguage(action: (Lang) -> Bool, fallbackAction: (Lang) -> Void) {
        if !action(LanguageManager.currentLanguage) {
            fallbackAction(.en_US)
        }
    }

    static func serial<T: CustomStringConvertible>(
        value: T?,
        defaultValue: String = "empty"
    ) -> String {
        if let v = value {
            return v.description
        } else {
            return defaultValue
        }
    }

    class func jsonToObj<T: Codable>(type: T.Type, json: [AnyHashable: Any]) -> T? {
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: .init())
            let info = try JSONDecoder().decode(type, from: data)
            return info
        } catch {
            logger.error("SuiteLoginUtil: can not decode json dic to info \(type) error: \(error)")
            return nil
        }
    }

    class func jsonArrayToObj<T: Codable>(type: T.Type, json: [Any]) -> T? {
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: .init())
            let info = try JSONDecoder().decode(type, from: data)
            return info
        } catch {
            logger.error("SuiteLoginUtil: can not decode json dic to info \(type) error: \(error)")
            return nil
        }
    }

    static func addSkipBackupForFile(_ url: NSURL) {
        DispatchQueue.global(qos: .utility).async {
            guard url.isFileURL else {
                logger.warn("SuiteLoginUtil: not file url: \(url)")
                return
            }
            do {

                guard url.checkResourceIsReachableAndReturnError(nil) else {
                    logger.warn("SuiteLoginUtil: file not exist \(url)")
                    return
                }
                var isExcludedFromBackup: AnyObject?
                try url.getResourceValue(&isExcludedFromBackup, forKey: URLResourceKey.isExcludedFromBackupKey)
                if let value = isExcludedFromBackup as? Bool, value == false {
                    try url.setResourceValue(true, forKey: URLResourceKey.isExcludedFromBackupKey)
                }
            } catch {
                logger.error("SuiteLoginUtil: can not add skip backup attribute to fileURL: \(url)", error: error)
            }
        }
    }
}

// MARK: - RSA

extension SuiteLoginUtil {

    enum RSAConst {
        static let keyLeading: String = "-----BEGIN RSA PUBLIC KEY-----\n"
        static let keyTrailing: String = "\n-----END RSA PUBLIC KEY-----"
    }

    class func rsaEncrypt(plain: String, publicKey: String, encrptKeySizeInBits: NSNumber = NSNumber(value: 1024)) -> String? {
        guard let leadingRange = publicKey.range(of: RSAConst.keyLeading),
            let trailingRange = publicKey.range(of: RSAConst.keyTrailing),
            leadingRange.upperBound < trailingRange.lowerBound else {
                SuiteLoginUtil.logger.error("can not find key leading or trailing")
                return nil
        }

        let keyString = String(publicKey[leadingRange.upperBound ..< trailingRange.lowerBound])
        let data = Data(base64Encoded: keyString, options: .ignoreUnknownCharacters)
        let plainData = plain.data(using: .utf8)
        let keyDict: [CFString: AnyObject] = [
            kSecAttrKeyType: kSecAttrKeyTypeRSA,
            kSecAttrKeyClass: kSecAttrKeyClassPublic,
            kSecAttrKeySizeInBits: encrptKeySizeInBits,
            kSecReturnPersistentRef: kCFBooleanTrue,
            kSecClass: kSecClassKey,
            kSecReturnData: kCFBooleanTrue
        ]
        guard let safeData = data,
            let safePlainData = plainData else {
                SuiteLoginUtil.logger.error("key data length \(data?.count ?? 0), plain data length \(plainData?.count ?? 0)")
                return nil
        }
        var error: Unmanaged<CFError>?
        let publicKeySi = SecKeyCreateWithData(safeData as CFData, keyDict as CFDictionary, &error)
        /// encrpt with public key
        guard let safePublicKeySi = publicKeySi,
            error == nil else {
                SuiteLoginUtil.logger.error("create secKey data error \(String(describing: error))")
                return nil
        }
        if let encryptedMessageData: Data = SecKeyCreateEncryptedData(safePublicKeySi, .rsaEncryptionOAEPSHA256, safePlainData as CFData, &error) as Data? {
            return encryptedMessageData.base64EncodedString()
        } else {
            SuiteLoginUtil.logger.error("encrypt data error: no final data")
            return nil
        }
    }
}

// MARK: Select Last User

extension SuiteLoginUtil {
    // MARK: last user

     /// 获取登录时使用的user的index
     /// 选中user的优先级 userID > localUserID > serverLastUserID, 没有指定userID的话选择第一个未冻结的userID
     /// - Parameters:
     ///   - users: 用户列表
     ///   - userID: 内存中的usrID （用于c端激活，指定选中的user）
     ///   - localUserID: 本地持久化的userID
     ///   - serverLastUserID: 服务器记录的上一次登录的userid
     /// - Returns: 选中的user的index
     static func chooseUserIndex(
        users: [V4UserInfo],
        userID: String? = nil,
        localUserID: String? = nil,
        serverLastUserID: String? = nil
     ) -> Array<V3UserInfo>.Index? {
         var accountIdx: Array<AccountUserInfo>.Index?
         if let uid = userID {
            // TODO: 替换 .isFrozen 逻辑是否正确？
            accountIdx = users.firstIndex(where: { ($0.userID == uid && $0.user.status != .freeze) })
             if accountIdx == nil {
                 Self.logger.error("not found memory userID: \(uid)/")
             } else {
                 Self.logger.info("choose memory userID: \(uid)/")
             }
         }

         if accountIdx == nil, let localUserID = localUserID, !localUserID.isEmpty {
             accountIdx = users.firstIndex(where: { $0.userID == localUserID && $0.user.status != .freeze })
             if accountIdx == nil {
                 Self.logger.info("not found local userID: \(localUserID)/")
             } else {
                 Self.logger.info("choose local userID: \(localUserID)/")
             }
         }

         if accountIdx == nil, let serverUserID = serverLastUserID, !serverUserID.isEmpty {
             accountIdx = users.firstIndex(where: { $0.userID == serverUserID && $0.user.status != .freeze })
             if accountIdx == nil {
                 Self.logger.error("not found server userID: \(serverUserID)/")
             } else {
                 Self.logger.info("choose server userID: \(serverUserID)/")
             }
         }

         if accountIdx == nil {
             accountIdx = users.firstIndex(where: { $0.user.status != .freeze })
             if accountIdx == nil {
                 Self.logger.warn("not found unfrozen user")
             } else {
                 Self.logger.info("choose first unfrozen user userIdx: \(String(describing: accountIdx))")
             }
         }
         Self.logger.info("choose user finish userID: \(String(describing: userID)) localUserID: \(String(describing: localUserID)) serverUserID: \(String(describing: serverLastUserID)) result account Idx: \(String(describing: accountIdx))")
         return accountIdx
     }
}

extension Dictionary {
    func jsonString() -> String {
        if self.isEmpty {
            return ""
        }
        if let data = try? JSONSerialization.data(withJSONObject: self, options: .sortedKeys) {
            return String(data: data, encoding: .utf8) ?? ""
        } else {
            SuiteLoginUtil.logger.error("make json string failed")
            return ""
        }
    }
}

extension URL {
    var queryParameters: [String: String] {
        // example result:
        //   query: name=lwl&age=12
        //   output: ["name": "lwl", "age": "12"]
        guard let components = URLComponents(url: self, resolvingAgainstBaseURL: false),
            let queryItems = components.queryItems else { return [:] }

        var items: [String: String] = [:]

        for queryItem in queryItems {
            items[queryItem.name] = queryItem.value?.removingPercentEncoding
        }
        return items
    }
}

extension Error {
    func loginCodeAndMsg() -> (code: Int, msg: String) {
        let unknownCode = -1
        if let err = self as? EventBusError {
            return (unknownCode, err.description)
        } else if let err = self as? V3LoginError {
            if case .badServerCode(let errorInfo) = err {
                return (Int(errorInfo.rawCode), errorInfo.message)
            } else {
                return (unknownCode, err.description)
            }
        } else {
            let nsError = self as NSError
            return (nsError.code, nsError.localizedDescription)
        }
    }
}

extension Log {
    func errorWithAssertion(_ description: String, additionalData: [String: String]? = nil, error: Error? = nil) {
        assertionFailure(description)
        self.error(description, additionalData: additionalData, error: error)
    }
}

extension ObservableType {
    func trace(
        _ tag: String,
        params: [String: String] = [:]
    ) -> Observable<Self.Element> {
        SuiteLoginUtil.logger.info("[\(tag)] on begin", additionalData: params)
        return self.do(onNext: { _ in
            SuiteLoginUtil.logger.info("[\(tag)] on next", additionalData: params)
        }, onError: { error in
            SuiteLoginUtil.logger.error(
                "[\(tag)] on error",
                additionalData: params,
                error: error
            )
        })
    }

    func monitor(
        _ processMonitorCode: ProcessMonitorCode,
        context: UniContextProtocol
    ) -> Observable<Self.Element> {
        var opTrace: OPTrace?
        if let traceId = context.trace.traceId {
            opTrace = OPTrace(traceId: traceId)
        }

        OPMonitor(processMonitorCode.start)
            .tracing(opTrace)
            .addCategoryValue(CommonConst.cp, context.credential.cp)
            .flush()
        return self.do(onNext: { element in

            if let step = element as? V3.Step {
                PassportMonitor.flush(processMonitorCode.success, categoryValueMap: [ProbeConst.nextStep: step.stepData.nextStep], context: context)
            } else {
                OPMonitor(processMonitorCode.success)
                    .setResultTypeSuccess()
                    .tracing(opTrace)
                    .addCategoryValue(CommonConst.cp, context.credential.cp)
                    .flush()
            }

        }, onError: { error in
            var bizCode: Int32?
            if let err = error as? V3LoginError, case .badServerCode(let info) = err {
                bizCode = info.bizCode
            }
            let monitor = OPMonitor(processMonitorCode.failure)
                .setResultTypeFail()
                .tracing(opTrace)
                .addCategoryValue(CommonConst.cp, context.credential.cp)
                .setError(error)
            if let bizCode = bizCode {
                _ = monitor.addCategoryValue(V3.Const.bizCode, String(describing: bizCode))
            }
            monitor.flush()
        })
    }
}

extension String {
    public func passport_fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
    public func passport_toBase64() -> String {
        return Data(self.utf8).base64EncodedString()
    }

    func passport_urlQueryEncodedString() -> String {
        addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed) ?? self
    }
}

extension String {
    func height(withConstrainedWidth width: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)

        return ceil(boundingBox.height)
    }

    func width(withConstrainedHeight height: CGFloat, font: UIFont) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: [.font: font], context: nil)

        return ceil(boundingBox.width)
    }

    func height(withConstrainedWidth width: CGFloat, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)

        return ceil(boundingBox.height)
    }

    func width(withConstrainedHeight height: CGFloat, attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        let constraintRect = CGSize(width: .greatestFiniteMagnitude, height: height)
        let boundingBox = self.boundingRect(with: constraintRect, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)

        return ceil(boundingBox.width)
    }
}

extension UIViewController {
    func presentedTopMost() -> UIViewController {
        if let presentedVC = presentedViewController {
            return presentedVC.presentedTopMost()
        }
        return self
    }
}

extension Character {
    /// 是否为Emoji表情 https://stackoverflow.com/questions/30757193/find-out-if-character-in-string-is-emoji
    /// 所有Emoji表情 https://unicode.org/Public/emoji/13.0/
    var isEmoji: Bool {
        guard let scalar = unicodeScalars.first else { return false }
        return scalar.properties.isEmoji && (scalar.value > 0x238C || unicodeScalars.count > 1)
    }
}

// MARK: Array
extension Array {
    func uniqued<H: Hashable>(_ filter: (Element) -> H) -> [Element] {
        var result = [Element]()
        var map = [H: Element]()
        for ele in self {
            let key = filter(ele)
            if map[key] == nil {
                map[key] = ele
                result.append(ele)
            }
        }
        return result
    }
}
