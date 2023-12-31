//
//  AVAssetWriterInputHooker.swift
//  LarkMedia
//
//  Created by FakeGourmet on 2023/12/25.
//

import Foundation

class AVAssetWriterInputHooker: Hooker {

    lazy var setterArray: [(Selector, Selector)] = {
        var array = [
            (
                #selector(AVAssetWriterInput.init(mediaType:outputSettings:)),
                #selector(AVAssetWriterInput.lk_init(mediaType:outputSettings:))
            ),
            (
                #selector(AVAssetWriterInput.init(mediaType:outputSettings:sourceFormatHint:)),
                #selector(AVAssetWriterInput.lk_init(mediaType:outputSettings:sourceFormatHint:))
            ),
        ]
        return array
    }()

    func willHook() {
    }

    func hook() {
        setterArray.forEach {
            swizzleInstanceMethod(AVAssetWriterInput.self, from: $0.0, to: $0.1)
        }
    }

    func didHook() {
        LarkAudioSession.logger.info("AVAssetWriterInput swizzle start")
    }
}

private extension AVAssetWriterInput {
    @objc dynamic func lk_init(mediaType: AVMediaType, outputSettings: [String : Any]?) -> AVAssetWriterInput {
        LarkAudioSession.hook(mediaType, outputSettings, block: {
            lk_init(mediaType: mediaType, outputSettings: outputSettings)
        })
    }

    @objc dynamic func lk_init(mediaType: AVMediaType, outputSettings: [String : Any]?, sourceFormatHint: CMFormatDescription?) -> AVAssetWriterInput {
        LarkAudioSession.hook(mediaType, outputSettings, sourceFormatHint, block: {
            lk_init(mediaType: mediaType, outputSettings: outputSettings, sourceFormatHint: sourceFormatHint)
        })
    }
}
