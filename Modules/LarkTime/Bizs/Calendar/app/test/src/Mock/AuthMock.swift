////
////  AuthMock.swift
////  CalendarTests
////
////  Created by heng zhu on 2018/12/26.
////  Copyright © 2018 EE. All rights reserved.
////
//
//import Foundation
//import LarkRustClient
//import RustPB
//
//class AuthMock {
//    static let shareInstance = AuthMock()
//    private let uid = "6497014513127129357"
//    private let appVersion = "1.16.0"
//    private var deviceId = "0"
//    private var installId = "0"
//    private let session = "05341f2d-6852-49cb-9b82-b9b27ac89ef2"
//    private let queue = DispatchQueue(label: "com.lark.sdk.client.cbqueue", qos: .utility)
//    private lazy var userAgent: String = {
//        let appVersionStr = self.appVersion
//        let systemVersion = UIDevice.current.systemVersion.replacingOccurrences(of: ".", with: "_")
//        return "Mozilla/5.0 "
//            + "(iPhone; CPU iPhone OS \(systemVersion) like Mac OS X) "
//            + "AppleWebKit/603.1.30 (KHTML, like Gecko) "
//            + "Mobile Lark/\(appVersionStr)"
//    }()
//
//    func userClient() -> RustClient {
//        let client = RustClient(configuration: self.rustConfig(userId: self.uid))
//        self.setConfiguration(client: client, deviceId: self.deviceId, installId: self.installId)
//        _ = self.setAccessToken(client: client, userId: self.uid, accessToken: self.session)
//        return client
//    }
//
//    private func setAccessToken(client: RustService, userId: String, accessToken: String) -> Bool {
//        var request = RustPB.Tool_V1_SetAccessTokenRequest()
//        request.userID = userId
//        request.accessToken = accessToken
//        do {
//            return try client.sendSyncRequest(request) { (response: RustPB.Tool_V1_SetAccessTokenResponse) -> Bool in
//                return response.isClearDb
//            }
//        } catch {
//            assertionFailure()
//            return false
//        }
//    }
//
//    private func setConfiguration(client: RustService, deviceId: String, installId: String) {
//        var request = RustPB.Device_V1_SetDeviceRequest()
//        request.deviceID = deviceId
//        request.installID = installId
//        try? client.sendSyncRequest(request)
//    }
//
//    private func rustConfig(userId: String?) -> RustClientConfiguration {
//        var path = self.documentsDirectoryURL()
//        if let uid = userId {
//            path = self.createUserDirectoryIfNotExists(uid)!
//        }
//        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
//
//        return RustClientConfiguration(
//            identifier: "AuthRustClient",
//            storagePath: path,
//            version: appVersion,
//            userAgent: userAgent,
//            env: .online,
//            appId: "1161",
//            localeIdentifier: "en_US",
//            clientLogStoragePath: "",
//            dataSynchronismStrategy: .broadcast,
//            domainInitConfig: DomainInitConfig()
//        )
//    }
//
//    private func logPath() -> String {
//        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
//        return "\(paths[0])/logs"
//    }
//
//    private func documentsDirectoryURL() -> URL {
//        let URLs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
//        let URL = URLs[URLs.count - 1]
//        return URL
//    }
//
//    private func createUserDirectoryIfNotExists(_ userId: String) -> URL? {
//        let docName = "LarkUser_\(userId)"
//        let url = documentsDirectoryURL().appendingPathComponent(docName, isDirectory: true)
//        if !FileManager.default.fileExists(atPath: url.path) {
//            do {
//                try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
//            } catch {
//                assertionFailure()
//                return nil
//            }
//        }
//        return url
//    }
//}
