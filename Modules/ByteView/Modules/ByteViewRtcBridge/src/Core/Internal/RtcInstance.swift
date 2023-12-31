//
//  RtcInstance.swift
//  ByteViewRtcBridge
//
//  Created by kiri on 2023/5/29.
//

import Foundation

protocol RtcInstance: AnyObject {
    var instanceId: String { get }
    var isDestroyed: Bool { get }
    var createParams: RtcCreateParams { get }

    init(params: RtcCreateParams, listeners: RtcListeners)
    func destroy()

    func reuse(_ params: RtcCreateParams, checkSession: Bool) throws

    /// 是否提前启动audio unit , callkit模式下标志无效
    static func enableAUPreStart(_ needPreStart: Bool)

    /// 设置运行时的参数，JoinChannel前调用
    /// - 引入需求 https://bytedance.feishu.cn/docx/VksBd5HDQo6ak0x8UV9c52Rrnr8
    /// - parameter parameters: 保留参数
    func setRuntimeParameters(_ parameters: [String: Any])

    /// 设置业务标识参数
    /// - 可通过 businessId 区分不同的业务场景。businessId 由客户自定义，相当于一个“标签”，可以分担和细化现在 AppId 的逻辑划分的功能，但不需要鉴权。
    /// - businessId 只是一个标签，颗粒度需要用户自定义。
    func setBusinessId(_ businessId: String?)

    /// 加入频道
    ///
    /// - 该方法让用户加入通话频道，在同一个频道内的用户可以互相通话，多个用户加入同一个频道，可以群聊。
    /// - 使用不同App ID的应用程序是不能互通的。
    /// - 如果已在通话中，用户必须调用leaveChannel退出当前通话，才能进入下一个频道。
    /// - SDK在通话中使用iOS系统的AVAudioSession共享对象进行录音和播放，应用程序对该对象的操作可能会影响SDK的音频相关功能。
    /// - 加入房间成功后，会触发didJoinChannel回调。
    ///
    /// - parameters:
    ///     - channelKey: 用户对应的key。测试环境下可设置为nil
    ///     - channelName: 加入的频道的名称
    ///     - info: 合流转推信息，不需要此功能时，置为nil
    ///     - traceId: 额外的用户标记（仅用于事件中区分用户）
    func joinChannel(byKey channelKey: String?, channelName: String, info: String?, traceId: String)

    /// 离开频道
    ///
    /// - 离开频道，即挂断或退出通话。当调用joinChannelByKey API方法后，必须调用leaveChannel结束通话，否则无法开始下一次通话。
    /// - 不管当前是否在通话中，都可以调用leaveChannel
    /// - 没有副作用。该方法会把会话相关的所有资源释放掉。该方法是异步操作，调用返回时并没有真正退出频道。
    func leaveChannel()

    /// 设置用户角色
    /// - 可设置的用户角色为主播、观众、静默观众，默认用户角色为观众。
    func setClientRole(_ role: RtcClientRole)

    func enableSimulcastMode(_ isEnabled: Bool)

    /// 设置 RTC SDK 内部采集时的视频采集参数。
    ///
    /// - 如果你的项目使用了 SDK 内部采集模块，可以通过本接口指定视频采集参数包括模式、分辨率、帧率。
    /// - 建议同一设备上的不同 Engine 使用相同的视频采集参数。
    /// - 如果调用本接口前使用内部模块开始视频采集，采集参数默认为 Auto 模式。
    /// - note: 本接口在引擎创建后可调用，调用后立即生效。建议在调用 startVideoCapture 前调用本接口。
    ///
    /// - parameters:
    ///     - videoSize: 视频采集分辨率
    ///     - frameRate: 视频采集帧率，单位：fps。
    func setVideoCaptureConfig(videoSize: CGSize, frameRate: Int)

    func setVideoEncoderConfig(channel: [RtcVideoEncoderConfig], main: [RtcVideoEncoderConfig])

    func setScreenVideoEncoderConfig(_ config: RtcVideoEncoderConfig)

    /// 设置simulcast参数，需要指定定每组分辨率的宽、高、帧率、码率
    func forceSetVideoProfiles(_ descriptions: [RtcVideoStreamDescription])

    // MARK: - Core Audio Methods

    /// 静音/开启本地音频流
    ///
    /// 该方法静音本地音频流/取消静音。调用该方法后，房间中的其他用户会收到didAudioMuted的回调。
    func muteLocalAudioStream(_ muted: Bool)

    func isMuteLocalAudio() -> Bool

    /// 本地播放端数字静音/取消静音
    func muteAudioPlayback(_ muted: Bool)

    /// 硬件静音
    func setInputMuted(_ muted: Bool)

    /// 开始麦克风音频采集
    /// - 默认是关闭的
    func startAudioCapture(scene: RtcAudioScene) throws

    /// 停止麦克风音频采集
    /// - 停止后调用muteLocalAudio/MuteLocalAudioStream无效
    func stopAudioCapture()

    // MARK: - Core Video Methods

    /// 立即开启内部视频采集。默认为关闭状态。
    ///
    /// 内部视频采集指：使用 RTC SDK 内置视频采集模块，进行采集。
    ///
    /// 调用该方法后，本地用户会收到 onVideoDeviceStateChanged的回调。
    ///
    /// 非隐身用户进房后调用该方法，房间中的其他用户会收到 onUserStartVideoCapture的回调。
    ///
    /// - note: 调用 stopVideoCapture可以停止内部视频采集。否则，只有当销毁引擎实例时，内部视频采集才会停止。
    ///
    /// 创建引擎后，无论是否发布视频数据，你都可以调用该方法开启内部视频采集。只有当（内部或外部）视频采集开始以后视频流才会发布。
    ///
    /// 如果需要从自定义视频采集切换为内部视频采集，你必须先停止发布流，关闭自定义采集，再调用此方法手动开启内部采集。
    ///
    /// 内部视频采集使用的摄像头由 switchCamera: 接口指定。
    func startVideoCapture(scene: RtcCameraScene) throws

    /// 立即关闭内部视频采集。默认为关闭状态。
    ///
    /// 内部视频采集指：使用 RTC SDK 内置视频采集模块，进行采集。
    ///
    /// 调用该方法后，本地用户会收到 onVideoDeviceStateChanged的回调。
    ///
    /// 非隐身用户进房后调用该方法，房间中的其他用户会收到 onUserStopVideoCapture的回调。
    ///
    /// - note: 调用 startVideoCapture{@link #RTCVideo#startVideoCapture} 可以开启内部视频采集。
    ///
    /// 如果不调用本方法停止内部视频采集，则只有当销毁引擎实例时，内部视频采集才会停止。
    func stopVideoCapture()

    /// 停止/开启本地视频流发送
    ///
    /// 调用该方法后，房间中的其他用户会收到didVideoMuted的回调。
    func muteLocalVideoStream(_ muted: Bool)

    func isMuteLocalVideo() -> Bool

    /// 切换前置/后置摄像头
    func switchCamera(isFront: Bool)

    func enablePIPMode(_ enable: Bool)

    /// 背景虚化开关
    func enableBackgroundBlur(_ isEnabled: Bool)

    /// 背景替换开关
    func setBackgroundImage(_ filePath: String)

    /// 设置设备角度
    func setDeviceOrientation(_ orientation: Int)

    /// 应用特效sdk/ios/ByteRtcEngineKit/ByteRtcMeetingEngineKit.mm
    func applyEffect(_ effectRes: RtcFetchEffectInfo, with type: RtcEffectType, contextId: String,
                     cameraEffectType: RtcCameraEffectType)

    /// 取消panel面板对应的exclusive类型特效
    ///
    /// 对于buildin类型的特效， 使用 applyEffect接口，设置param参数为0来取消特效
    func cancelEffect(_ panel: String, cameraEffectType: RtcCameraEffectType)


    // MARK: - Rtm
    /// 实时消息通信：必须先登录注册一个 uid，才能发送房间外消息和向业务服务器发送消息
    ///
    /// - parameter token: 动态密钥。用户登录必须携带的 Token，用于鉴权验证。本 Token 与加入房间时必须携带的 Token 不同。测试时可使用控制台生成临时 Token，正式上线需要使用密钥 SDK 在你的服务端生成并下发 Token。
    /// - parameter uid: 用户 ID。用户 ID 在 appid的维度下是唯一的。
    /// - note: 在调用本接口登录后，如果想要登出，需要调用 logout 登出后，才能再次登录。
    ///
    /// 本地用户调用此方法登录后，会收到 onLoginResult回调通知登录结果，远端用户不会收到通知。
    func login(_ token: String, uid: String)

    /// 实时消息通信: 调用本接口登出后，无法调用房间外消息以及端到服务器消息相关的方法或收到相关回调。
    /// - note: 调用本接口登出前，必须先调用 `login(_:uid:)` 登录
    ///
    /// 本地用户调用此方法登出后，会收到 rtcEngineOnLogout 回调通知结果，远端用户不会收到通知。
    func logout()

    /// 实时消息通信: 设置业务服务器参数
    ///
    /// 客户端调用 sendServerMessage 或 sendServerBinaryMessage发送消息给业务服务器之前，必须需要设置有效签名和业务服务器地址。
    /// - parameter signature: 动态签名。业务服务器会使用该签名对请求进行鉴权验证。
    /// - parameter url: 业务服务器的地址
    /// - note: 用户必须调用`login(_:uid:)` 登录后，才能调用本接口。
    ///
    /// 调用本接口后，SDK 会使用 onServerParamsSetResult返回相应结果。
    func setServerParams(_ signature: String, url: String)

    /// 实时消息通信:  客户端给业务服务器发送二进制消息（P2Server）
    /// - parameter message: 发送的二进制消息内容, 消息不超过 46KB。
    /// - returns >0：发送成功，返回这次发送消息的编号，从 1 开始递增， -1：发送失败，RtcEngine 实例未创建
    /// - note: 在向业务服务器发送二进制消息前，先调用 login:uid:完成登录，随后调用 `setServerParams(_:url:)`设置业务服务器。
    ///
    /// 调用本接口后，会收到一次 onServerMessageSendResult回调，通知消息发送方发送成功或失败；
    ///
    /// 若二进制消息发送成功，则之前调用`setServerParams(_:url:)`设置的业务服务器会收到该条消息。
    @discardableResult
    func sendServerBinaryMessage(_ message: Data) -> Int64

    // MARK: - EncodedVideo

    /// 视频管理: 设置向 SDK 输入的视频源
    ///
    /// 默认使用内部采集。内部采集指：使用 RTC SDK 内置的视频采集机制进行视频采集。
    /// - parameter type: 视频输入源类型
    /// - parameter streamIndex: 视频流的属性
    /// - note: 该方法进房前后均可调用。
    ///
    /// 当你已调用 startVideoCapture开启内部采集后，再调用此方法切换至自定义采集时，SDK 会自动关闭内部采集。
    ///
    /// 当你调用此方法开启自定义采集后，想要切换至内部采集，你必须先调用此方法关闭自定义采集，然后调用 startVideoCapture手动开启内部采集。
    ///
    /// 当你需要向 SDK 推送自定义编码后的视频帧，你需调用该方法将视频源切换至自定义编码视频源。
    func setVideoSourceType(_ type: RtcVideoSourceType, with streamIndex: RtcStreamIndex)

    // MARK: - Multi transport

    /// 设置是否开启移动网络改善传输质量。
    /// - parameter config: 功能配置。
    func setCellularEnhancement(_ config: RtcCellularEnhancementConfig)

    // MARK: - External Video Data

    /// 【屏幕共享外部采集】发布本地共享视频流（仅用于屏幕共享外部采集，内部采集请勿调用）
    func publishScreen()

    /// 【屏幕共享外部采集】取消发布本地共享视频流（仅用于屏幕共享外部采集，内部采集请勿调用）
    func unpublishScreen()

    /// 向屏幕共享 Extension 发送自定义消息
    /// - note: 在 startScreenCapture:bundleId: 后调用该方法。
    func sendScreenCaptureExtensionMessage(_ messsage: Data)

    /// 更新屏幕共享采集数据类型
    /// - parameter type: 屏幕采集数据类型
    /// - note: 该函数必须在 startScreenCapture 函数之后调用
    ///
    /// 本地用户会收到 onMediaDeviceStateChanged 的回调。参数 device_state 值为 ByteRTCMediaDeviceStateStarted 或 ByteRTCMediaDeviceStateStopped，device_error 值为 ByteRTCMediaDeviceErrorOK
    func updateScreenCapture(_ type: RtcScreenMediaType)

    /// 指定publish到哪个频道
    /// - 支持会前、会中设置
    /// - 同一路流的音视频同一时刻不支持pub到不同频道
    func setPublishChannel(_ channelName: String)

    /// 指定sub哪些频道
    /// - 支持会前、会中设置
    /// - parameter channelIds: 指定用户sub的频道Id列表
    func setSubChannels(_ channelIds: [String])

    /// 同声传译场景下，是否对main频道上的声音进行压制
    func enableRescaleAudioVolume(_ enable: Bool)

    /// 指定加入哪个分组
    /// - 支持会中设置
    /// - parameter groupName: 待加入分组名
    /// - parameter subMain: 是否收听主会场声音
    func joinBreakDownRoom(_ groupName: String, subMain: Bool)

    /// 离开分组会议，若当前未进入，则接口无效
    /// - 支持会中设置
    func leaveBreakDownRoom()

    /// 设置推送流的转码流类型，必须在joinChannel之前调用
    ///
    /// 设置成功后，publish的所有流将被标记为此种类型的转码流，只有设置了接收该类型转码流的客户端会收到新流的通知。
    func setRemoteUserPriority(_ uid: RtcUID, priority: RtcRemoteUserPriority)

    /// 设置视频盒子状态
    func setChannelProfile(_ channelProfile: RtcMeetingChannelProfileType)

    // MARK: - Audio Mix Related

    /// 开始播放指定音效文件
    ///
    /// 该方法开始播放指定音效文件。请在频道内调用该方法。
    ///
    /// - parameters:
    ///     - soundId: 音效ID，APP调用者维护，请保证唯一性
    ///     - filePath: 指定需要混音的音频文件名和文件路径名。支持以下音频格式: mp3，aac，m4a，3gp，wav
    ///     - loopback: YES:只有本地可以听到混音或替换后的音频流；NO:本地和对方都可以听到混音或替换后的音频流
    ///     - playCount: 指定音频文件循环播放的次数:正整数，循环的次数；负数，无限循环
    /// - returns: 0 :方法调用成功 <0:方法调用失败
    func startAudioMixing(_ soundId: Int32, filePath: String, loopback: Bool, playCount: Int) -> Int

    /// 停止播放音频文件及混音。
    ///
    /// - parameter mixId: 混音 ID
    ///
    /// - note: 调用 startAudioMixing:filePath:config:{@link #ByteRTCAudioMixingManager#startAudioMixing:filePath:config:} 方法开始播放音频文件及混音后，可以调用本方法停止播放音频文件及混音。
    ///
    /// 调用本方法停止播放音频文件后，SDK 会向本地回调通知已停止混音，见 `onAudioMixingStateChanged`。
    ///
    /// 调用本方法停止播放音频文件后，该音频文件会被自动卸载。
    func stopAudioMixing(_ soundId: Int32)

    // MARK: - Manual Performance Control

    /// RTC新降级
    /// 开启手动降级
    /// 调用时机：引擎创建后，进会前
    func enablePerformanceAdaption(_ enable: Bool)

    /// 设置降价等级
    /// 取值范围【0， 19】
    func setPerformanceLevel(_ level: Int)

    // MARK: - E2EE
    func setCustomEncryptor(_ cryptor: RtcCrypting)

    func removeCustomEncryptor()

    func updateLocalVideoRes(_ res: Int)
}

extension RtcInstance {
    var sessionId: String { createParams.sessionId }
    var proxy: RtcActionProxy { createParams.actionProxy }
    var renderConfig: RtcRenderConfig { createParams.renderConfig }
}
