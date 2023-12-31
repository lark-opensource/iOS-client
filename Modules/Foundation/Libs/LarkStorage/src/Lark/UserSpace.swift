//
//  UserSpace.swift
//  LarkStorage
//
//  Created by 7Up on 2022/12/22.
//

import Foundation
import RxSwift
import LKCommonsLogging

/// NOTE: 从 EEKeyValue 迁移过来，后续逐渐推进下掉

public protocol UserSpaceService: AnyObject {
    // will be deprecated soon.
    var currentUserDirectory: URL? { get }
}

public final class UserSpace: UserSpaceService {
    public static let shared = UserSpace()

    public var currentUserDirectory: URL? {
        guard let userId = getCurrentUserID?() else { return nil }
        return createUserDirectoryIfNotExists(userId)
    }
    public var getCurrentUserID: (() -> String?)? = nil

    private static let userDirectoryPrefix = "LarkUser_"
    private let userDefaultsVersion = "_v3"

    private static let logger = Logger.log(UserSpace.self, category: "Library.UserSpace")

    private let userDirectorySubject = ReplaySubject<URL>.create(bufferSize: 1)

    private init() {}

    private var _currentUserID: String = ""

    var currentUserID: String {
        if let newUserID = getCurrentUserID?(), newUserID != _currentUserID {
            _currentUserID = newUserID
        }
        return _currentUserID
    }

    private func createUserDirectoryIfNotExists(_ userId: String) -> URL? {
        let docName = userDocumentsName(userId)
        let url = AbsPath.document.url.appendingPathComponent(docName, isDirectory: true)
        UserSpace.ColdStartup.firstLoginFlag = false
        if !FileManager.default.fileExists(atPath: url.path) {
            UserSpace.ColdStartup.firstLoginFlag = true
            do {
                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
            } catch {
                UserSpace.logger.error(
                    "创建用户目录失败",
                    additionalData: ["userId": userId],
                    error: error
                )
                return nil
            }
        }
        UserDefaults.standard.synchronize()
        return url
    }

    func userDocumentsName(_ userId: String) -> String {
        return UserSpace.userDirectoryPrefix + userId
    }
}

// 首次登陆的 KV 部分
public extension UserSpace {
    struct ColdStartup {
        private static let globalStore = KVStores.udkv(
            space: .global,
            domain: Domain.biz.infra.child("ColdStartup")
        )
        
        @KVConfig(key: "first_login_flag", default: false, store: globalStore)
        public static var firstLoginFlag: Bool
    }
}
