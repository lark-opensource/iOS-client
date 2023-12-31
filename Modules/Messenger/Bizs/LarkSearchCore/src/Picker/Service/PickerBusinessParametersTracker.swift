//
//  PickerBusinessParametersTracker.swift
//  LarkSearchCore
//
//  Created by Yuri on 2023/9/12.
//

import Foundation
import LarkModel
import LarkFoundation

// swiftlint:disable all
class PickerBusinessParametersTracker {
    static func track(scene: PickerScene, config: PickerDebugConfig) {
#if !LARK_NO_DEBUG
        DispatchQueue.global().async {
            guard let url = URL(string: "https://tes.bytedance.net/openapi/business/lark/office/subunit/config") else {
                return
            }
            let currentVersion = LarkFoundation.Utils.appVersion
            // 裁剪掉后缀, 只关心大版本变动
            let versionComponent = currentVersion.components(separatedBy: "-")
            let version = versionComponent.first ?? currentVersion

            do {
                let data = try JSONEncoder().encode(config)
                let json = String(data: data, encoding: .utf8)
                // 创建请求体数据
                let parameters = [
                    "scene": scene.rawValue,
                    "version": version,
                    "config": json
                ]
                let jsonData = try? JSONSerialization.data(withJSONObject: parameters)

                // 创建Request对象
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                request.httpBody = jsonData

                // 创建URLSession对象
                let session = URLSession.shared

                // 发起请求任务
                let task = session.dataTask(with: request) { (data, res, error) in
                    // 处理响应结果
                    if let error = error {
                        print("Error: \(error)")
                    } else if let data = data {
                        // 解析返回的数据
                        if let result = String(data: data, encoding: .utf8) {
                            print("Response: \(result) \(res)")
                        }
                    }
                }
                task.resume()
            } catch {
                print(error.localizedDescription)
            }
        }
#endif
    }
}
// swiftlint:enable all
