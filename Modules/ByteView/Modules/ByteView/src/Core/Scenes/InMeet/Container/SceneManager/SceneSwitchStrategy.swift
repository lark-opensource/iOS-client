//
//  SceneSwitchStrategy.swift
//  ByteView
//
//  Created by liujianlong on 2023/2/9.
//

import Foundation
import ByteViewNetwork

extension UserStorage {
    fileprivate var shareScene: InMeetSceneManager.SceneMode {
        get {
            self.string(forKey: .shareScene).flatMap({ InMeetSceneManager.SceneMode(rawValue: $0) }) ?? .thumbnailRow
        }
        set {
            guard self.shareScene != newValue, newValue != .gallery else { return }
            Logger.scene.info("set shareScene \(newValue)")
            self.set(newValue.rawValue, forKey: .shareScene)
        }
    }
}

final class SceneSwitchStrategy {
    struct SceneControllerState: Equatable {
        var flowScene: InMeetSceneManager.SceneMode
        var shareScene: InMeetSceneManager.SceneMode
        var webinarStageScene: InMeetSceneManager.SceneMode
        var content: InMeetSceneManager.ContentMode
        var webinarStageInfo: WebinarStageInfo?
        var isFocusing: Bool
        var isMobileLandscape: Bool
        var is1V1: Bool
        var hasHostCohostAuthority: Bool
    }

    let hasSwitchSceneEntrance: Bool

    private(set) var lastShareSceneMode: InMeetSceneManager.SceneMode?
    private var shareSceneMode: InMeetSceneManager.SceneMode {
        didSet {
            guard self.shareSceneMode != oldValue else {
                return
            }
            if oldValue == .speech || oldValue == .thumbnailRow {
                self.lastShareSceneMode = oldValue
            }
        }
    }
    private var flowSceneMode: InMeetSceneManager.SceneMode
    private var webinarStageSceneMode: InMeetSceneManager.SceneMode
    var webinarStageInfo: WebinarStageInfo? {
        didSet {
            guard webinarStageInfo != oldValue else {
                return
            }
            if webinarStageInfo == nil && self.webinarStageSceneMode != .webinarStage {
                // 停止舞台模式后，重置舞台模式下的默认布局为 webinarStage，确保下次开启舞台模式时，视图类型自动切换为 webinarStage
                self.webinarStageSceneMode = .webinarStage
            }
        }
    }
    var hasHostCohostAuthority: Bool
    let storage: UserStorage

    init(state: SceneControllerState, hasSwitchSceneEntrance: Bool, storage: UserStorage) {
        self.storage = storage
        self.is1V1 = state.is1V1
        self.flowSceneMode = state.flowScene
        self.shareSceneMode = state.shareScene
        self.webinarStageSceneMode = state.webinarStageScene
        self.webinarStageInfo = state.webinarStageInfo
        self.contentMode = state.content
        self.isFocusing = state.isFocusing
        self.isMobileLandscapeMode = state.isMobileLandscape
        self.hasSwitchSceneEntrance = hasSwitchSceneEntrance
        self.hasHostCohostAuthority = state.hasHostCohostAuthority
    }


    var is1V1: Bool {
        didSet {
            guard self.is1V1 != oldValue else { return }
            Logger.scene.info("is1V1 change \(oldValue) --> \(self.is1V1)")
            if self.flowSceneMode != .thumbnailRow {
                self.flowSceneMode = (is1V1 && Display.pad) ? .speech : .gallery
            }
        }
    }

    var isFocusing: Bool
    var isMobileLandscapeMode: Bool
    var contentMode: InMeetSceneManager.ContentMode {
        didSet {
            guard self.contentMode != oldValue else {
                return
            }
            if !oldValue.isShareContent && self.contentMode.isShareContent && self.flowSceneMode != .gallery {
                // 非共享场景进入共享场景，如果是 缩略视图或演讲者视图，就不切换视图类型
                self.shareSceneMode = self.flowSceneMode
            } else if oldValue.isShareContent && !self.contentMode.isShareContent {
                // 停止共享时，避免将共享 scene 保存为 gallery
                self.shareSceneMode = storage.shareScene
            }
        }
    }

    private var webinarStageMode: Bool {
        self.webinarStageInfo != nil && self.contentMode != .selfShareScreen
    }

    func onUserSwitchScene(sceneMode: InMeetSceneManager.SceneMode) {
        if sceneMode == .webinarStage && !self.webinarStageMode {
            // 没有开启舞台同步时，禁止切换到舞台模式
            return
        }
        if isFocusing {
            // 焦点视频时，禁止切换视图模式
            return
        }
        if webinarStageMode {
            self.webinarStageSceneMode = sceneMode
        } else if self.contentMode.isShareContent {
            // 共享场景，记忆上次使用的是缩略图或者演讲者视图
            if sceneMode == .thumbnailRow || sceneMode == .speech {
                storage.shareScene = sceneMode
            }
            self.shareSceneMode = sceneMode
        } else {
            self.flowSceneMode = sceneMode
        }
    }

    var sceneMode: InMeetSceneManager.SceneMode {
        let sceneMode: InMeetSceneManager.SceneMode
        if !hasSwitchSceneEntrance {
            // Mobile, WebinarAttendee 不支持切换视图
            if self.webinarStageMode {
                sceneMode = .webinarStage
            } else {
                switch contentMode {
                case .flow:
                    sceneMode = .gallery
                case .follow, .selfShareScreen, .webSpace:
                    sceneMode = .thumbnailRow
                case .whiteboard, .shareScreen:
                    sceneMode = isMobileLandscapeMode ? .gallery : .thumbnailRow
                }
            }
            return sceneMode
        }

        assert(Display.pad)

        if isFocusing {
            sceneMode = .speech
        } else if self.webinarStageMode {
            if let stageInfo = self.webinarStageInfo,
               !stageInfo.allowGuestsChangeView,
               !self.hasHostCohostAuthority {
                self.webinarStageSceneMode = .webinarStage
                sceneMode = .webinarStage
            } else {
                sceneMode = self.webinarStageSceneMode
            }
        } else if contentMode.isShareContent {
            sceneMode = self.shareSceneMode
        } else {
            sceneMode = self.flowSceneMode
        }
        return sceneMode
    }

    func saveSceneState(_ sceneState: inout SceneControllerState) {
        sceneState.flowScene = self.flowSceneMode
        sceneState.shareScene = self.shareSceneMode
        sceneState.webinarStageScene = self.webinarStageSceneMode
        sceneState.webinarStageInfo = self.webinarStageInfo
        sceneState.content = self.contentMode
        sceneState.isFocusing = self.isFocusing
        sceneState.isMobileLandscape = self.isMobileLandscapeMode
        sceneState.is1V1 = self.is1V1
        sceneState.hasHostCohostAuthority = self.hasHostCohostAuthority
    }
}

extension SceneSwitchStrategy.SceneControllerState {
    static var `default`: SceneSwitchStrategy.SceneControllerState {
        SceneSwitchStrategy.SceneControllerState(flowScene: .gallery,
                                                 shareScene: .thumbnailRow,
                                                 webinarStageScene: .webinarStage,
                                                 content: .flow,
                                                 isFocusing: false,
                                                 isMobileLandscape: false,
                                                 is1V1: false,
                                                 hasHostCohostAuthority: false)
    }
}
