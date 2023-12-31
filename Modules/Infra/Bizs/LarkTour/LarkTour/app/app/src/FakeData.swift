//
//  FakeData.swift
//  LarkTourDev
//
//  Created by Meng on 2020/9/29.
//

import Foundation
import RxSwift
import SwiftProtobuf
import RustPB
import LarkTour
import RoundedHUD

class FakeData {
    static var id: String = ""
    static var platform: String = ""

    private let fakeURL = URL(string: "https://cloudapi.bytedance.net/faas/services/tto71l/invoke/GetDynamicFlow")!

    func fetchFakePB() -> Observable<GetDynamicFlowResponse> {
        if Self.id.isEmpty || Self.platform.isEmpty {
            Self.showAPIError("id or platform is empty")
            return .just(GetDynamicFlowResponse())
        }
        return fetchFakePB(id: Self.id, platform: Self.platform)
    }

    func fetchFakePB(id: String, platform: String) -> Observable<GetDynamicFlowResponse> {
        let url = fakeURL.append(parameters: ["id": id, "platform": platform])
        return Observable<GetDynamicFlowResponse>.create { (observer) -> Disposable in
            let task = URLSession.shared.dataTask(with: url) { (data, _, _) in
                var options = JSONDecodingOptions()
                options.ignoreUnknownFields = true
                if let data = data,
                   let jsonString = String(data: data, encoding: .utf8),
                   let res = try? GetDynamicFlowResponse(jsonString: jsonString, options: options) {
                    observer.onNext(res)
                } else {
                    Self.showAPIError("Can not generate response")
                }
                observer.onCompleted()
            }
            task.resume()
            return Disposables.create()
        }
    }

    private static func showAPIError(_ error: String) {
        DispatchQueue.main.async {
            RoundedHUD.showTips(with: error)
        }
    }
}
