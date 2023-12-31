//
//  SketchSettings+RustClient.swift
//  ByteView
//
//  Created by 刘建龙 on 2020/3/13.
//

import Foundation
import RxSwift
import ByteViewNetwork

extension SketchSettings {
    static func settings(httpClient: HttpClient) -> Observable<SketchSettings> {
        return RxTransform.single {
            httpClient.getResponse(GetSettingsRequest(fields: [SketchSettings.sketchSettingField]), completion: $0)
        }.asObservable().map({ rsp -> SketchSettings in
            let decoder = JSONDecoder()
            decoder.keyDecodingStrategy = .convertFromSnakeCase
            if let jsonStr = rsp.fieldGroups[SketchSettings.sketchSettingField], let data = jsonStr.data(using: .utf8) {
                return try decoder.decode(SketchSettings.self, from: data)
            } else {
                ByteViewSketch.logger.error("failed decoding SketchSettings, \(rsp) received")
                return .default
            }
        }).catchError({ e in
            ByteViewSketch.logger.error("failed getting SketchSettings, \(e)")
            return .just(.default)
        }).share(replay: 1, scope: .forever)
    }
}
