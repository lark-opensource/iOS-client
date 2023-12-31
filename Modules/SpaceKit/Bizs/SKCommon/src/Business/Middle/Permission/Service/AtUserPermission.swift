//
//  AtUserPermissionManager.swift
//  SKCommon
//
//  Created by chenhuaguan on 2021/10/25.
//

import SKFoundation
import SwiftyJSON
import SpaceInterface
import SKInfra

public typealias AtUserPermissionCallBack = ([String: UserPermissionMask]) -> Void
public struct AtUserDocsKey: Hashable {
    public let token: FileListDefine.ObjToken
    public let type: DocsType
    public init(token: FileListDefine.ObjToken, type: DocsType) {
        self.token = token
        self.type = type
    }
}
class AtUserPermission {
    var sKDocsKey: AtUserDocsKey?
    var needRequestUids: Set<String> = Set()
    private var userPermissionCache = ThreadSafeDictionary<String, UserPermissionMask>()
    static var atUserPermissionKey: UInt8 = 0
    private lazy var observers: NSHashTable<AnyObject> = NSHashTable(options: .weakMemory)
    private let handerQueue = DispatchQueue(label: "com.bytedance.docs.AtUserPermission.\(UUID().uuidString)")
    var isRequesting: Bool = false

    init(sKDocsKey: AtUserDocsKey) {
        self.sKDocsKey = sKDocsKey
    }

    func fetchAtUserPermission(ids: [String], handler: AnyObject, block: @escaping AtUserPermissionCallBack) {
        self.handerQueue.async {
            DocsLogger.info("fetchAtUserPermission, count=\(ids.count)", component: LogComponents.atUserPerm)
            ids.forEach { key in
                self.needRequestUids.insert(key)
            }
            objc_setAssociatedObject(handler,
                                     &Self.atUserPermissionKey, block,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            self.observers.add(handler)

            self.innerFetchAtUserPermission()
        }
    }

    func innerFetchAtUserPermission() {
        guard !isRequesting else { return }
        guard needRequestUids.count > 0 else {
            notifyObervers()
            return
        }
        isRequesting = true
        var currentRequestIds: Set<String> = Set()
        for (index, uid) in needRequestUids.enumerated() {
            if index < 20 {
                currentRequestIds.insert(uid)
            } else {
                break
            }
        }

        guard let token = sKDocsKey?.token, let type = sKDocsKey?.type else { return }
        let parameters: [String: Any] = [
            "token": token,
            "type": type.rawValue,
            "user_ids": Array(currentRequestIds)
        ]

        let request = DocsRequest<JSON>(path: OpenAPI.APIPath.suitePermissionUserMget, params: parameters)
            .set(method: .POST)
            .set(timeout: 20)
            .set(encodeType: .jsonEncodeDefault)
            .set(needVerifyData: false)

        request.makeSelfReferenced()
        request.start(result: { (json, error) in
            self.handerQueue.async {
                let deferBlock = {
                    self.isRequesting = false
                    self.needRequestUids = self.needRequestUids.subtracting(currentRequestIds)
                    self.innerFetchAtUserPermission()
                }

                guard error == nil else {
                    DocsLogger.info("error, occor=\(String(describing: error))", component: LogComponents.atUserPerm)
                    deferBlock()
                    return
                }
                guard let json = json, json["code"].int != nil, json["msg"].string != nil, let data = json["data"].dictionaryObject,
                    let permisonDic = data["permissions_v2"] as? [String: Any] else {
                    DocsLogger.info("invalid data", component: LogComponents.atUserPerm)
                    deferBlock()
                    return
                }

                DocsLogger.info("get result from service,count=\(permisonDic.count)", component: LogComponents.atUserPerm)
                for (key, value) in permisonDic {
                    if let intVale = value as? Int {
                        self.userPermissionCache.updateValue(UserPermissionMask(rawValue: intVale), forKey: key)
                    }
                }

                deferBlock()
            }
        })
    }

    private func notifyObervers() {
        handerQueue.async {
            let observers = self.observers.allObjects
            self.observers.removeAllObjects()
            let cache = self.userPermissionCache.all()
            DispatchQueue.main.async {
                for observer in observers {
                    let block = objc_getAssociatedObject(observer, &Self.atUserPermissionKey)
                    guard let callback = block as? AtUserPermissionCallBack else { return }
                    callback(cache)
                }
            }
        }
    }

    func hasPermissionForUser(uid: String) -> Bool? {
        guard let userPermission = userPermissionCache.value(ofKey: uid) else { return nil }
        return userPermission.contains(.read)
    }

    // for unittest
    func updateUserPermissionCache(key: String, value: UserPermissionMask) {
        userPermissionCache.updateValue(value, forKey: key)
    }
}
