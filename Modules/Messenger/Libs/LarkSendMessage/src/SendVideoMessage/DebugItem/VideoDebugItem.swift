//
//  VideoDebugItem.swift
//  LarkMessageCore
//
//  Created by 李晨 on 2022/5/24.
//

import UIKit
import Foundation
import LarkDebugExtensionPoint // DebugCellItem
import EENavigator // Navigator
import LarkStorage // KVConfig
import LarkVideoDirector // VideoEditorLoggerDelegate

struct VideoDebugItem: DebugCellItem {
    let title = "VideoDebug"
    func didSelect(_ item: DebugCellItem, debugVC: UIViewController) {
        guard #available(iOS 13, *) else { return }
        #if ALPHA
        let videoDebugVC = VideoDebug().embeddedInHostingController()
        DispatchQueue.main.async {
            Navigator.shared.push(videoDebugVC, from: debugVC) // foregroundUser
        }
        #endif
    }
}

enum VideoDebugKVStore {

    static private let videoDebugStore = KVStores.udkv(space: .global, domain: Domain.biz.messenger.child("SendMessage").child("VideoDebug"))

    @KVConfig(key: "video_debug_enable", default: false, store: videoDebugStore)
    static var innerVideoDebugEnable: Bool

    @KVConfig(key: "preprocess_video", default: true, store: videoDebugStore)
    static var preprocessVideo: Bool

    enum DebugAICodecStrategy: CaseIterable, Identifiable, KVNonOptionalValue {
        case auto, forceDisable, forceEnable
        public var id: Self { self }
    }
    @KVConfig(key: "use_ai_codec", default: .auto, store: videoDebugStore)
    static var useAICodec: DebugAICodecStrategy

    @KVConfig(key: "big_side", default: CGFloat(960.0), store: videoDebugStore)
    static var bigSideMax: CGFloat

    @KVConfig(key: "small_side", default: CGFloat(540.0), store: videoDebugStore)
    static var smallSideMax: CGFloat

    static let defaultRemuxResolutionSetting: Int32 = 540 * 960
    @KVConfig(key: "remuxResolutionSettingKey", default: VideoDebugKVStore.defaultRemuxResolutionSetting, store: videoDebugStore)
    static var remuxResolutionSetting: Int32

    static let defaultRemuxFPSSetting: Int32 = 60
    @KVConfig(key: "remuxFPSSettingKey", default: VideoDebugKVStore.defaultRemuxFPSSetting, store: videoDebugStore)
    static var remuxFPSSetting: Int32

    static let defaultRemuxBitratelimitSetting: String = "{\"setting_values\":{\"normal_bitratelimit\": 1258291,\"hd_bitratelimit\":1258291}}"
    @KVConfig(key: "remuxBitratelimitSettingKey", default: VideoDebugKVStore.defaultRemuxBitratelimitSetting, store: videoDebugStore)
    static var remuxBitratelimitSetting: String

    // swiftlint:disable line_length
    static let defaultSetting: String = "{\"compile\":{\"encode_mode\":\"hw\",\"hw\":{\"bitrate\":3145728,\"sd_bitrate_ratio\":0.4,\"full_hd_bitrate_ratio\":1.5,\"hevc_bitrate_ratio\":1,\"h_fps_bitrate_ratio\":1.4,\"effect_bitrate_ratio\":1.4,\"fps\":30,\"audio_bitrate\":128000}}}"
    @KVConfig(key: "setting", default: VideoDebugKVStore.defaultSetting, store: videoDebugStore)
    static var setting: String
    // swiftlint:enable line_length

    static var videoDebugEnable: Bool {
        #if ALPHA
        return innerVideoDebugEnable
        #else
        return false
        #endif
    }
}

#if ALPHA

import SwiftUI

@available(iOS 13.0, *)
struct VideoDebug: View {

    @State private var enable: Bool = VideoDebugKVStore.innerVideoDebugEnable
    @State private var preprocessVideo: Bool = VideoDebugKVStore.preprocessVideo
    @State private var useAICodec = VideoDebugKVStore.useAICodec
    @State private var bigSideMax: CGFloat = VideoDebugKVStore.bigSideMax
    @State private var smallSideMax: CGFloat = VideoDebugKVStore.smallSideMax
    @State private var remuxResolutionSetting: Int32 = VideoDebugKVStore.remuxResolutionSetting
    @State private var remuxFPSSetting: Int32 = VideoDebugKVStore.remuxFPSSetting
    @State private var remuxBitratelimitSetting: String = VideoDebugKVStore.remuxBitratelimitSetting
    @State private var setting: String = VideoDebugKVStore.setting
    @State private var enableVeNslog: Bool = VideoEditorLoggerDelegate.useNSLog

    @EnvironmentObject private var hostingProvider: ViewControllerProvider

    // MARK: Body

    var body: some View {
        List {
            videoDebugSection()
            veSection()
            cameraSection()
        }
        .navigationBarTitle("VideoDebug", displayMode: .inline)
        // MARK: value change
        .valueChanged(value: enable, onChange: { VideoDebugKVStore.innerVideoDebugEnable = $0 })
        .valueChanged(value: preprocessVideo, onChange: { VideoDebugKVStore.preprocessVideo = $0 })
        .valueChanged(value: useAICodec, onChange: { VideoDebugKVStore.useAICodec = $0 })
        .valueChanged(value: bigSideMax, onChange: { VideoDebugKVStore.bigSideMax = $0 })
        .valueChanged(value: smallSideMax, onChange: { VideoDebugKVStore.smallSideMax = $0 })
        .valueChanged(value: remuxResolutionSetting, onChange: { VideoDebugKVStore.remuxResolutionSetting = $0 })
        .valueChanged(value: remuxFPSSetting, onChange: { VideoDebugKVStore.remuxFPSSetting = $0 })
        .valueChanged(value: remuxBitratelimitSetting, onChange: { VideoDebugKVStore.remuxBitratelimitSetting = $0 })
        .valueChanged(value: setting, onChange: { VideoDebugKVStore.setting = $0 })
        .valueChanged(value: enableVeNslog, onChange: { VideoEditorLoggerDelegate.useNSLog = $0 })
    }

    private func videoDebugSection() -> some View {
        Section {
            Toggle("Enable", isOn: $enable)
            if enable {
                Toggle("Enable preprocess", isOn: $preprocessVideo)
                Picker(.init("Use AICodec"), selection: $useAICodec) {
                    ForEach(VideoDebugKVStore.DebugAICodecStrategy.allCases) {
                        Text(verbatim: "\($0)")
                    }
                }
                TextField("", value: $bigSideMax, formatter: NumberFormatter())
                    .alwaysShownTitle("Big side:")
                TextField("", value: $smallSideMax, formatter: NumberFormatter())
                    .alwaysShownTitle("Small side:")
                TextField("", value: $remuxResolutionSetting, formatter: NumberFormatter())
                    .alwaysShownTitle("remux resolution:")
                TextField("", value: $remuxFPSSetting, formatter: NumberFormatter())
                    .alwaysShownTitle("remux fps:")
                EditorView(title: "remux bit limit:", value: $remuxBitratelimitSetting)
                EditorView(title: "setting:", value: $setting)
            }
        } header: {
            Text("Video send debug")
        }
        .valueChanged(value: enable, onChange: { enabled in
            if !enabled { // reset
                enable = false
                preprocessVideo = true
                useAICodec = .auto
                bigSideMax = 960
                smallSideMax = 540
                remuxResolutionSetting = VideoDebugKVStore.defaultRemuxResolutionSetting
                remuxFPSSetting = VideoDebugKVStore.defaultRemuxFPSSetting
                remuxBitratelimitSetting = VideoDebugKVStore.defaultRemuxBitratelimitSetting
                setting = VideoDebugKVStore.defaultSetting
            }
        })
    }

    private func veSection() -> some View {
        Section {
            Toggle("Enable VE NSLog", isOn: $enableVeNslog)
        } header: {
            Text("VE debug")
        }
    }

    private func cameraSection() -> some View {
        Section {
            Button {
                guard #available(iOS 15, *) else { return }
                let vc = CameraKitConfigView().embeddedInHostingController()
                hostingProvider.viewController?
                    .navigationController?.pushViewController(vc, animated: true)
            } label: {
                Text("CameraKit")
            }
        } header: {
            Text("Camera")
        }
    }
}

@available(iOS 13.0, *)
private struct EditorView: View {
    @State var title: LocalizedStringKey
    @Binding var value: String

    @State private var content: String = ""
    @State private var editing = false

    var body: some View {
        Group {
            if #available(iOS 14, *) {
                VStack {
                    HStack {
                        Text(title)
                            .foregroundColor(.secondary)
                        Spacer()
                        if editing {
                            Button {
                                editing = false
                                value = content
                                UIApplication.shared
                                    .sendAction(#selector(UIResponder.resignFirstResponder),
                                                to: nil, from: nil, for: nil)
                            } label: {
                                Text("Done")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    ZStack {
                        TextEditor(text: $content)
                            .autocorrectionDisabled()
                            .onTapGesture {
                                editing = true
                            }
                        Text(content)
                            .opacity(0).padding(.all, 8)
                    }
                    .font(.caption)
                }
                .onAppear {
                    content = value
                }
            } else {
                Text("do not support Text Editor below iOS 14")
            }
        }
    }
}

@available(iOS 13.0, *)
extension TextField {
    func alwaysShownTitle(_ title: LocalizedStringKey) -> some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            self
        }
    }
}

import Combine

@available(iOS 13.0, *)
private extension View {
    /// A backwards compatible wrapper for iOS 14 `onChange`
    @ViewBuilder func valueChanged<T: Equatable>(value: T, onChange: @escaping (T) -> Void) -> some View {
        if #available(iOS 14.0, *) {
            self.onChange(of: value, perform: onChange)
        } else {
            self.onReceive(Just(value)) { (value) in
                onChange(value)
            }
        }
    }
}

#endif
