//
//  AudioKeyboardDataService.swift
//  LarkAudio
//
//  Created by 白镜吾 on 2023/2/16.
//

import Foundation
import RxSwift
import RxCocoa
import ServerPB
import Reachability
import LarkContainer
import LarkRustClient
import LarkLocalizations
import LarkFeatureGating
import LKCommonsLogging

typealias GetSpeechConfigResponse = ServerPB_Recognition_GetSpeechConfigResponse
typealias PutSpeechConfigResponse = ServerPB_Recognition_PutSpeechConfigResponse

final class AudioKeyboardDataService {
    /// 【自动语种识别】在服务端的字段
    static var autoInServer: String = "un_auto"
    /// 【普通话识别】在服务端的字段
    static var zhCNInServer: String = "zh_ch"

    static let logger = Logger.log(AudioKeyboardDataService.self, category: "LarkAudio")

    static var shared: AudioKeyboardDataService = AudioKeyboardDataService()

    private var disposeBag = DisposeBag()

    /// 当前设置的语种
    var currentLang: Lang {
        get {
            return RecognizeLanguageManager.shared.recognitionLanguage
        }
        set {
            RecognizeLanguageManager.shared.recognitionLanguage = newValue
        }
    }

    /// 当前设置的语种对应的 i18n 文案，currentLangI18n 由服务端下发
    /// 此处 currentLangI18n 需要在 currentLang 前设置，否则监听 recognitionLanguage 改变后，label 就会被重新赋值，此时 currentLangI18n 还未更新
    var currentLangI18n: String {
        get {
            return RecognizeLanguageManager.shared.recognitionLanguageI18n
        }
        set {
            RecognizeLanguageManager.shared.recognitionLanguageI18n = newValue
        }
    }

    /// 当前支持的语种列表
    var supportLangs: [Lang] = [.zh_CN, .en_US]

    /// 当前支持的语种列表及对应的 i18n 文案字典，默认兜底展示 普通话 / 英语
    var supportLangsi18nMap: [Lang: String] = [.zh_CN: AudioKeyboardHelper.convertString(from: .zh_CN),
                                               .en_US: AudioKeyboardHelper.convertString(from: .en_US)]

    /// 刷新 FG
    /// 通过语种枚举生成服务端需要字段
    static func generateLocaleIdentifier(lang: Lang) -> String {
        switch lang {
        case .un_AUTO:
            return AudioKeyboardDataService.autoInServer
        case .zh_CN:
            /// zh_CN 字段单独处理原因，参考 `static func generateLang(rawValue: String) -> Lang` 下方注释
            return AudioKeyboardDataService.zhCNInServer
        default:
            return lang.localeIdentifier
        }
    }

    /// 通过服务端下发字段生成对应语种枚举
    static func generateLang(rawValue: String) -> Lang {
        switch rawValue {
        case AudioKeyboardDataService.autoInServer:
            return .un_AUTO
        case AudioKeyboardDataService.zhCNInServer:
            /// 此处需要专门处理为 zh_ch 的深层原因为：上古时代开发语音转写功能时，服务端、客户端定义的普通话字段为 "zh_ch"
            /// iOS 由于直接使用 Lang 的 rawvalue 进行转化，所以上传给服务端的字段为 zh_cn
            /// 由于 6.0 之前只存在 普通话 /  英语 两种语言转写能力，zh_cn 无法命中服务端数据，会 fallback 为 zh_ch，所以 6.0 之前运行正常
            /// 6.0 后支持服务端下发转写语种，且存在自动语种识别，所以发现了此问题。
            /// 遂与服务端 / 安卓进行了约定
            /// - 1. 用户手动选择的语种配置，服务端配置普通话为“zh_ch”，自动识别字段为"un_auto"，字段均为小写，
            /// - 2. 语音转写时，客户端上传的 speechLocale 值，普通话为 “zh_ch”，自动识别字段为"un_auto"，客户端上传的值为小写
            return .zh_CN
        default:
            /// 此处我们组件内数据传递使用 Lang 进行传递，如 英语的rawvalue 为 “en_US”，服务端下发英语为 “en_us”
            /// 此处数据进行数据转换，“_” 前的转为小写，“_” 后的转为大写
            let components = rawValue.components(separatedBy: "_")
            guard let componentFirst = components.first,
                  let componentLast = components.last else { return Lang(rawValue: rawValue) }
            let value = componentFirst.lowercased() + "_" + componentLast.uppercased()
            return Lang(rawValue: value)
        }
    }

    /// 服务端下掉对应语种 、断网等情况，展示兜底配置
    func resetAudioSpeechConfig() {
        /// 如果缓存语种非普通话或非英语，则按照本地语言设置，中文设置为普通话，其他语言设置为 英语
        if RecognizeLanguageManager.shared.recognitionLanguage != .zh_CN || RecognizeLanguageManager.shared.recognitionLanguage != .en_US {
            var lang: Lang
            if LanguageManager.currentLanguage == .zh_CN {
                RecognizeLanguageManager.shared.recognitionLanguageI18n = AudioKeyboardHelper.convertString(from: .zh_CN)
                RecognizeLanguageManager.shared.recognitionLanguage = .zh_CN
            } else {
                RecognizeLanguageManager.shared.recognitionLanguageI18n = AudioKeyboardHelper.convertString(from: .en_US)
                RecognizeLanguageManager.shared.recognitionLanguage = .en_US
            }
        }

        /// 语音识别支持的语种默认为 普通话 和 英语
        AudioKeyboardDataService.shared.supportLangs = [.zh_CN, .en_US]
        AudioKeyboardDataService.shared.supportLangsi18nMap = [.zh_CN: AudioKeyboardHelper.convertString(from: .zh_CN),
                                                               .en_US: AudioKeyboardHelper.convertString(from: .en_US)]
    }

    /// 获取服务端语种配置, 语音加文字或语音转文字用 【按住说话，上方的语种标签】
    func getSpeechConfig(client: RustService?) -> Observable<GetSpeechConfigResponse> {
        let request = ServerPB_Recognition_GetSpeechConfigRequest()
        return client?.sendPassThroughAsyncRequest(request, serCommand: .getSpeechConfig) { (response: GetSpeechConfigResponse) in
            return response
        } ?? .empty()
    }

    /// 端上设置新的语种配置，推送服务端更新数据【按住说话，上方的语种标签】
    func putSpeechConfig(client: RustService?, manualConfLang: Lang) -> Observable<PutSpeechConfigResponse> {
        var request = ServerPB_Recognition_PutSpeechConfigRequest()
        request.manualConfLang = AudioKeyboardDataService.generateLocaleIdentifier(lang: manualConfLang)
        return client?.sendPassThroughAsyncRequest(request, serCommand: .putSpeechConfig) { (response: PutSpeechConfigResponse) in
            return response
        } ?? .empty()
    }

    /// 键盘每次展示时，均拉取一次服务端数据进行同步
    func fetchSpeechConfigData(userResolver: UserResolver) {
        guard checkNetworkConnection() else {
            AudioKeyboardDataService.shared.resetAudioSpeechConfig()
            return
        }
        let client = try? userResolver.resolve(assert: RustService.self)
        AudioKeyboardDataService.shared.getSpeechConfig(client: client)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { speechConfig in
                guard !speechConfig.supportLangList.isEmpty else { return }

                var supportLangs: [Lang] = []
                var supportLangsi18nMap: [Lang: String] = [:]

                /// 更新支持语种列表
                for supportLang in speechConfig.supportLangList {
                    let lang = AudioKeyboardDataService.generateLang(rawValue: supportLang.langCode)
                    supportLangs.append(lang)
                    supportLangsi18nMap[lang] = supportLang.langName
                }

                /// 服务端值存在
                AudioKeyboardDataService.shared.supportLangs = supportLangs
                AudioKeyboardDataService.shared.supportLangsi18nMap = supportLangsi18nMap

                /// 更新手动设置的语种的语言文案
                /// 1. 服务端用户配置空
                ///     a. 服务端从未配置过 -> 同步本地配置
                ///     b. 服务端下掉了对应的语种识别能力 -> 检查服务端支持语种中，是否存在本地缓存，存在的话走缓存，不存在走兜底 -> 同步本地配置
                /// 2. 不为空则说明用户已设置，以服务端用户配置为准
                if speechConfig.manualConfLang.isEmpty {
                    /// 支持语种不包含本地缓存，走兜底逻辑
                    if !AudioKeyboardDataService.shared.supportLangs.contains(AudioKeyboardDataService.shared.currentLang) {
                        AudioKeyboardDataService.shared.resetAudioSpeechConfig()
                    }
                    self.putLocalSpeechConfigToServer(client: client)
                } else {
                    let lang = AudioKeyboardDataService.generateLang(rawValue: speechConfig.manualConfLang)
                    AudioKeyboardDataService.shared.currentLangI18n = supportLangsi18nMap[lang] ?? ""
                    AudioKeyboardDataService.shared.currentLang = lang
                }

                let clientLanguage = AudioKeyboardDataService.generateLocaleIdentifier(lang: AudioKeyboardDataService.shared.currentLang)
                AudioKeyboardDataService.logger.info("Successed to fetch language Config, supportCount: \(supportLangs.count), server: \(speechConfig.manualConfLang) client: \(clientLanguage))")
            }, onError: { error in
                AudioKeyboardDataService.logger.error("Failed to fetch language Config, error: \(error)")
                AudioKeyboardDataService.shared.resetAudioSpeechConfig()
            })
            .disposed(by: self.disposeBag)
    }

    /// 更新端上配置到服务端
    private func putLocalSpeechConfigToServer(client: RustService?) {
        AudioKeyboardDataService.shared.putSpeechConfig(client: client, manualConfLang: RecognizeLanguageManager.shared.recognitionLanguage)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { response in
                AudioKeyboardDataService.logger.error("Successed to sync selected language, code:\(response.code), requestNo: \(response.requestNo)")
            }).disposed(by: self.disposeBag)
    }

    /// 检查网络连接
    private func checkNetworkConnection() -> Bool {
        guard let reach = Reachability() else { return false }
        if reach.connection == .none {
            return false
        }
        return true
    }
}
