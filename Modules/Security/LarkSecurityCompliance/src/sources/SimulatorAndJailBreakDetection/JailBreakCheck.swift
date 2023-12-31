//
//  JailBreakCheck.swift
//  LarkSecurityCompliance
//
//  Created by ByteDance on 2022/8/30.
//

import Foundation
import LKCommonsLogging
import LarkSecurityComplianceInfra

// ignoring lark storage check for jail break check
// lint:disable lark_storage_check anyobject_protocol

public final class JailBreakCheck {

    private static let urlsToCheck: [String] = [
        "Y3lkaWE6Ly8="
    ]

    private static let filePathsToCheck: [String] = [
        "L0FwcGxpY2F0aW9ucy9BTFMuYXBw",
        "L0FwcGxpY2F0aW9ucy9DeWRpYS5hcHA=",
        "L0FwcGxpY2F0aW9ucy9saW1lcmExbi5hcHA=",
        "L0FwcGxpY2F0aW9ucy9JY3kuYXBw",
        "L0FwcGxpY2F0aW9ucy9ncmVlbnBvaXMwbi5hcHA=",
        "L0FwcGxpY2F0aW9ucy9yZWRzbjB3LmFwcA==",
        "L0FwcGxpY2F0aW9ucy9NeFR1YmUuYXBw",
        "L0FwcGxpY2F0aW9ucy9NVGVybWluYWwuYXBw",
        "L0FwcGxpY2F0aW9ucy9Sb2NrQXBwLmFwcA==",
        "L0FwcGxpY2F0aW9ucy9ibGFja3JhMW4uYXBw",
        "L0FwcGxpY2F0aW9ucy9ncmVlbnBvaXMwbi5hcHA=",
        "L0FwcGxpY2F0aW9ucy9XaW50ZXJCb2FyZC5hcHA=",
        "L0FwcGxpY2F0aW9ucy9TaWxlby5hcHA=",
        "L0FwcGxpY2F0aW9ucy9TQlNldHR0aW5ncy5hcHA=",
        "L0FwcGxpY2F0aW9ucy9UYXVyaW5lLmFwcA==",
        "L0FwcGxpY2F0aW9ucy9GYWtlQ2Fycmllci5hcHA=",
        "L0FwcGxpY2F0aW9ucy9GaWx6YS5hcHA=",
        "L0FwcGxpY2F0aW9ucy9GbHlKQi5hcHA=",
        "L0FwcGxpY2F0aW9ucy9JbnRlbGxpU2NyZWVuLmFwcA==",
        "L0FwcGxpY2F0aW9ucy9Tbm9vcC1pdENvbmZpZy5hcHA=",
        "L0FwcGxpY2F0aW9ucy9BYnNpbnRoZS5hcHA=",
        "L3Zhci9iaW5wYWNr",
        "L3Zhci9saWIvY3lkaWE=",
        "L3Zhci9saWIvYXB0Lw==",
        "L3Zhci9sb2cvc3lzbG9n",
        "L3Zhci90bXAvY3lkaWEubG9n",
        "L3Zhci9jaGVja3JhMW4uZG1n",
        "L3Zhci9jYWNoZS9hcHQv",
        "L0xpYnJhcnkvTW9iaWxlU3Vic3RyYXRl",
        "L0xpYnJhcnkvTW9iaWxlU3Vic3RyYXRlL0R5bmFtaWNMaWJyYXJpZXM=",
        "L0xpYnJhcnkvTW9iaWxlU3Vic3RyYXRlL0R5bmFtaWNMaWJyYXJpZXMvTGl2ZUNsb2NrLnBsaXN0",
        "L0xpYnJhcnkvTW9iaWxlU3Vic3RyYXRlL0R5bmFtaWNMaWJyYXJpZXMvVmVlbmN5LnBsaXN0",
        "L0xpYnJhcnkvTW9iaWxlU3Vic3RyYXRlL0N5ZGlhU3Vic3RyYXRlLmR5bGli",
        "L0xpYnJhcnkvTW9iaWxlU3Vic3RyYXRlL01vYmlsZVN1YnN0cmF0ZS5keWxpYg==",
        "L0xpYnJhcnkvTW9iaWxlU3Vic3RyYXRlL0R5bmFtaWNMaWJyYXJpZXMveENvbi5keWxpYg==",
        "L0xpYnJhcnkvTW9iaWxlU3Vic3RyYXRlL0R5bmFtaWNMaWJyYXJpZXMvVmVlbmN5LnBsaXN0",
        "L0xpYnJhcnkvTW9iaWxlU3Vic3RyYXRlL0R5bmFtaWNMaWJyYXJpZXMvTGl2ZUNsb2NrLnBsaXN0",
        "L0xpYnJhcnkvUHJlZmVyZW5jZUJ1bmRsZXMvTGliZXJ0eVByZWYuYnVuZGxl",
        "L0xpYnJhcnkvUHJlZmVyZW5jZUJ1bmRsZXMvU2hhZG93UHJlZmVyZW5jZXMuYnVuZGxl",
        "L0xpYnJhcnkvUHJlZmVyZW5jZUJ1bmRsZXMvQUJ5cGFzc1ByZWZzLmJ1bmRsZQ==",
        "L0xpYnJhcnkvUHJlZmVyZW5jZUJ1bmRsZXMvRmx5SkJQcmVmcy5idW5kbGU=",
        "L0xpYnJhcnkvTGF1bmNoRGFlbW9ucy9jb20ub3BlbnNzaC5zc2hkLnBsaXN0",
        "L0xpYnJhcnkvTGF1bmNoRGFlbW9ucy9jb20uc2F1cmlrLkN5ZGlhLlN0YXJ0dXAucGxpc3Q=",
        "L0xpYnJhcnkvTGF1bmNoRGFlbW9ucy9jb20udGlnaXNvZnR3YXJlLmZpbHphLmhlbHBlci5wbGlzdA==",
        "L0xpYnJhcnkvTGF1bmNoRGFlbW9ucy9jb20ucnBldHJpY2gucm9ja2V0Ym9vdHN0cmFwZC5wbGlzdA==",
        "L0xpYnJhcnkvTGF1bmNoRGFlbW9ucy9kaHBkYWVtb24ucGxpc3Q=",
        "L0xpYnJhcnkvTGF1bmNoRGFlbW9ucy9yZS5mcmlkYS5zZXJ2ZXIucGxpc3Q=",
        "L3Vzci9saWIvbGliaG9va2VyLmR5bGli",
        "L3Vzci9saWIvbGlic3Vic3RpdHV0ZS5keWxpYg==",
        "L3Vzci9saWIvc3Vic3RyYXRl",
        "L3Vzci9saWIvVHdlYWtJbmplY3Q=",
        "L3Vzci9saWIvbGliY3ljcmlwdC5keWxpYg==",
        "L3Zhci9saWIvY3lkaWE=",
        "L3Zhci9saWIvZHBrZy9pbmZv",
        "L3Vzci9iaW4vc3No",
        "L3Vzci9iaW4vY3ljcmlwdA==",
        "L3Vzci9iaW4vc3NoZA==",
        "L3Vzci9zYmluL3NzaGQ=",
        "L3Vzci9zYmluL2ZyaWRhLXNlcnZlcg==",
        "L3Vzci9saWJleGVjL3NmdHAtc2VydmVy",
        "L3Vzci9saWJleGVjL2N5ZGlhLw==",
        "L3Vzci9saWJleGVjL3NzaC1rZXlzaWdu",
        "L3Vzci9saWJleGVjL3NmdHAtc2VydmVy",
        "L3Vzci9sb2NhbC9iaW4vY3ljcmlwdA==",
        "L2Jpbi9iYXNo",
        "L2Jpbi5zaA==",
        "L2Jpbi9zaA==",
        "L2V0Yy9hcHQ=",
        "L2V0Yy9zc2gvc3NoZF9jb25maWc=",
        "L3ByaXZhdGUvdmFyL2xpYi9hcHQ=",
        "L3ByaXZhdGUvdmFyL2xpYi9jeWRpYQ==",
        "L3ByaXZhdGUvdmFyL2xvZy9zeXNsb2c=",
        "L3ByaXZhdGUvdmFyL3RtcC9jeWRpYS5sb2c=",
        "L3ByaXZhdGUvdmFyL2NhY2hlL2FwdC8=",
        "L3ByaXZhdGUvZXRjL2Rwa2cvb3JpZ2lucy9kZWJpYW4=",
        "L3ByaXZhdGUvZXRjL2FwdA==",
        "L3ByaXZhdGUvZXRjL2FwdC9wcmVmZXJlbmNlcy5kL2NoZWNrcmExbg==",
        "L3ByaXZhdGUvZXRjL2FwdC9wcmVmZXJlbmNlcy5kL2N5ZGlh",
        "L3ByaXZhdGUvZXRjL3NzaC9zc2hkX2NvbmZpZw==",
        "L3ByaXZhdGUvdmFyL21vYmlsZUxpYnJhcnkvU0JTZXR0aW5nc1RoZW1lcy8=",
        "L3ByaXZhdGUvdmFyL21vYmlsZS9MaWJyYXJ5L1NCU2V0dGluZ3MvVGhlbWVz",
        "L3ByaXZhdGUvdmFyL3N0YXNo",
        "L1N5c3RlbS9MaWJyYXJ5L0xhdW5jaERhZW1vbnMvY29tLnNhdXJpay5DeWRpYS5TdGFydHVwLnBsaXN0",
        "L1N5c3RlbS9MaWJyYXJ5L0xhdW5jaERhZW1vbnMvY29tLmlrZXkuYmJvdC5wbGlzdA==",
        "L2V0Yy9hcHQv",
        "L2V0Yy9zc2gvc3NoZF9jb25maWc="
    ]

    private static let filesReadingToCheck: [String] = [
        "L2Jpbi9iYXNo",
        "L2Jpbi9zaA==",
        "L3Vzci9zYmluL3NzaGQ=",
        "L2V0Yy9hcHQ=",
        "L3Zhci9sb2cvYXB0",
        "L0FwcGxpY2F0aW9ucy9DeWRpYS5hcHA=",
        "L0xpYnJhcnkvTW9iaWxlU3Vic3RyYXRlL01vYmlsZVN1YnN0cmF0ZS5keWxpYg==",
        "Ly5pbnN0YWxsZWRfdW5jMHZlcg==",
        "Ly5ib290c3RyYXBwZWRfZWxlY3RyYQ=="
    ]

    public class func check() -> Bool {
        // 由于UIApplication.shared.canOpenURL(url)需要在主线程中调用，需要使用回调的形式返回结果，所以这里单独进行判断
        var urlCheckResult = false
        urlCheck { res in urlCheckResult = res }
        if urlCheckResult {
            return true
        }

        var checkMethods = [() -> Bool]()
        checkMethods.append(filePathCheck)
        checkMethods.append(fileWritingCheck)
        checkMethods.append(fileReadingCheck)
        checkMethods.append(runningOnRootCheck)
        for checkMethod in checkMethods where checkMethod() {
            return true
        }
        return false
    }

    private class func urlCheck(completion: @escaping (Bool) -> Void) {
        Logger.info("jailBreakCheck0: urlCheck")
        for urlString in urlsToCheck {
            guard let urlString = urlString.base64Decoded() else {
                continue
            }
            guard let url = URL(string: urlString) else {
                continue
            }
            var handled = false
            if Thread.isMainThread {
                handled = UIApplication.shared.canOpenURL(url)
            } else {
                DispatchQueue.main.sync {
                    handled = UIApplication.shared.canOpenURL(url)
                }
            }
            if handled {
                completion(true)
                return
            }
        }
        completion(false)
    }

    private class func filePathCheck() -> Bool {
        Logger.info("jailBreakCheck1: filePathCheck")
        for filePath in filePathsToCheck {
            guard let filePath = filePath.base64Decoded() else {
                continue
            }
            Logger.info(filePath)
            if FileManager.default.fileExists(atPath: filePath) {
                return true
            }
        }
        return false
    }

    private class func fileWritingCheck() -> Bool {
        Logger.info("jailBreakCheck2: fileWritingCheck")
        let path = "/private/" + NSUUID().uuidString
        do {
            try "anyString".write(toFile: path, atomically: true, encoding: String.Encoding.utf8)
            try FileManager.default.removeItem(atPath: path)
            return true
        } catch {
            return false
        }
    }

    private class func fileReadingCheck() -> Bool {
        Logger.info("jailBreakCheck3: fileReadingCheck")
        for path in filesReadingToCheck {
            guard let path = path.base64Decoded() else {
                continue
            }
            if FileManager.default.isReadableFile(atPath: path) {
                return true
            }
        }
        return false
    }

    private class func runningOnRootCheck() -> Bool {
        Logger.info("jailBreakCheck5: runningOnRootCheck")
        let root = getgid()
        return root <= 10
    }
}
