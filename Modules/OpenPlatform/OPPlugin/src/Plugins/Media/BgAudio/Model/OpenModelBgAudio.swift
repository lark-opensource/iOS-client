//
//  OpenBgAudioModel.swift
//  OPPlugin
//
//  Created by zhysan on 2022/5/9.
//

import Foundation
import LarkOpenAPIModel

final class OPAPIParamSetBgAudioState: OpenAPIBaseParams {
    
    // 音频源链接
    @OpenAPIOptionalParam(jsonKey: "src", validChecker: { !$0.isEmpty && $0.isHTTPURL })
    public var src: String?
    
    // 开始时间，比如希望音频从 30s 开始播放，单位：ms 后面的全部时间单位全是 ms
    @OpenAPIOptionalParam(jsonKey: "startTime", validChecker: OpenAPIValidChecker.range(0...))
    public var startTime: TimeInterval?
    
    // 这个没啥意义，可以去掉
    @OpenAPIOptionalParam(jsonKey: "currentTime")
    public var currentTime: TimeInterval?
    
    // 播放速率
    @OpenAPIRequiredParam(userOptionWithJsonKey: "playbackRate",
                          defaultValue: CGFloat(1),
                          validChecker: OpenAPIValidChecker.range(0.5...2))
    public var playbackRate: CGFloat
    
    // 音频标题
    @OpenAPIOptionalParam(jsonKey: "title")
    public var title: String?
    
    // 音频封面
    @OpenAPIOptionalParam(jsonKey: "coverImgUrl")
    public var coverImgUrl: String?
    
    // 点击浮窗展开，跳转的页面路由
    @OpenAPIOptionalParam(jsonKey: "audioPage")
    public var audioPage: [AnyHashable: Any]?
    
    private var srcDict: [AnyHashable: Any]
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_src,
         _startTime,
         _currentTime,
         _playbackRate,
         _title,
         _coverImgUrl,
         _audioPage,]
    }
    
    public required init(with params: [AnyHashable: Any]) throws {
        srcDict = params
        try super.init(with: params)
    }
    
    override var description: String {
        "\(srcDict)"
    }
}

final class OPAPIParamOperateBgAudio: OpenAPIBaseParams {
    enum OperateBgAudioType: String, OpenAPIEnum {
        case play, pause, stop, seek
    }
    
    // 播放类型
    @OpenAPIRequiredParam(userOptionWithJsonKey: "operationType", defaultValue: .play)
    var operationType: OperateBgAudioType
    
    // seek 时的 time
    @OpenAPIOptionalParam(jsonKey: "currentTime")
    var currentTime: TimeInterval?
    
    override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        [_operationType, _currentTime]
    }
    
}
// 对照 OPAPIParamSetBgAudioState
final class OPAPIResultGetBgAudioState: OpenAPIBaseResult {
    public var src: String?
    public var startTime: TimeInterval?
    public var playbackRate: CGFloat?
    public var title: String?
    public var coverImgUrl: String?
    public var audioPage: [AnyHashable: Any]?
    
    
    public var duration: TimeInterval?
    public var currentTime: TimeInterval?
    /// JS 层对应 playing，非 playing 态都视为 paused
    public var paused: Bool?
    public var buffered: TimeInterval?
    
    override func toJSONDict() -> [AnyHashable: Any] {
        var map: [AnyHashable: Any] = [:]
        
        map["src"] = src
        map["startTime"] = startTime
        map["playbackRate"] = playbackRate
        map["title"] = title
        map["coverImgUrl"] = coverImgUrl
        map["audioPage"] = audioPage
        
        map["duration"] = duration
        map["currentTime"] = currentTime
        map["paused"] = paused
        map["buffered"] = buffered
        
        return map
    }
}
