//
//  RustVideoAPI.swift
//  LarkSDK
//
//  Created by zc09v on 2019/6/4.
//

import Foundation
import LarkSDKInterface

import RustPB
import RxSwift

final class RustVideoAPI: LarkAPI, VideoAPI {
    func fetchVideoSourceUrl(url: String) -> Observable<String> {
        var request = RustPB.Media_V1_GetPreviewVideoSourceRequest()
        request.url = url
        return self.client.sendAsyncRequest(request, transform: { (response: RustPB.Media_V1_GetPreviewVideoSourceResponse) -> String in
            return response.videoSrc
        }).subscribeOn(scheduler)
    }
}
