//
//  CommonUtil.swift
//  RichTextEditor
//
//  Created by chenhuaguan on 2020/6/29.
//

import UIKit

extension String {
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }

}

extension Dictionary where Key == String {
    var json: Data? {
        do {
            return try JSONSerialization.data(withJSONObject: self)
        } catch {
            return nil
        }
    }

    var jsonString: String? {
        guard let data = self.json else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

extension DispatchQueue {
    private static var _onceTracker = [String]()

    func once(file: String = #fileID, function: String = #function, line: Int = #line, block: () -> Void) {
        let token = file + ":" + function + ":" + String(line)
        self.once(token: token, block: block)
    }

    func once(token: String, block: () -> Void) {
        objc_sync_enter(self)
        defer { objc_sync_exit(self) }
        if DispatchQueue._onceTracker.contains(token) {
            return
        }
        DispatchQueue._onceTracker.append(token)
        block()
    }
}

extension UIImage {
    class func rtBase64Image(strBase64: String, scale: CGFloat = 3) -> UIImage? {
        guard let imageUrl = URL(string: strBase64) else { return nil }
        do {
            let data = try Data.read(from: imageUrl.asAbsPath())
            return UIImage(data: data, scale: scale)
        } catch let error {
            Logger.error("image 出错", error: error)
            return nil
        }
    }
    class func rtDatImage(datBase64: String, scale: CGFloat = 3) -> UIImage? {
        guard let data = Data(base64Encoded: datBase64, options: .ignoreUnknownCharacters) else { return nil }
        return UIImage(data: data, scale: scale)
    }

}

struct Timeline {
    var startTime = CFAbsoluteTimeGetCurrent()

}
