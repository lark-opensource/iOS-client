//
//  AnimationView.swift
//  Common
//
//  Created by Songwen Ding on 2018/1/7.
//

import UIKit
import Lottie
import SKFoundation
import SKResource
import LibArchiveKit

enum AnimationType: Int {
    case typeDocsLoading = 1
    case typeRefreshForward
    case typeRefreshBackward
    case typeLoading
    case typeSheetExportImage
    case typeDriveUploadCheck
    case typeAudioRecording
    case typeCommentTranslating
    case typeWikiTreeNodeLoading
    case typeRecording
    case typeLoadingGray
    case typeCommentSendLoading
    case typeSheetAlertLoading
    case smartComposeOnboarding
    case typeWikiOnboardingGesture
    case bitableStageComplete
    case bitableRecordSuscribe
    case bitableHomeTabHomepage
    case bitableHomeTabRecommend
    case bitableHomeTabNew
}

@objcMembers
public final class AnimationViews {

    private static var resourceAvailable = false // 资源是否已经解压好了
    
    public class var recording: LOTAnimationView? {
        return AnimationViews.animationViewByType(type: .typeRecording)
    }

    public class var commentTranslting: LOTAnimationView? {
        return AnimationViews.animationViewByType(type: .typeCommentTranslating)
    }

    public class var refreshForward: LOTAnimationView? {
        return AnimationViews.animationViewByType(type: .typeRefreshForward)
    }

    public class var refreshBackward: LOTAnimationView? {
        return AnimationViews.animationViewByType(type: .typeRefreshBackward)
    }

    public class var loadingAnimation: LOTAnimationView {
        return AnimationViews.animationViewByType(type: .typeLoading)
    }
    
    public class var driveUploadCheckAnimation: LOTAnimationView {
        return AnimationViews.animationViewByType(type: .typeDriveUploadCheck)
    }

    public class var audioRecordingAnimation: LOTAnimationView {
        return AnimationViews.animationViewByType(type: .typeAudioRecording)
    }

    public class var wikiTreeNodeAnimation: LOTAnimationView {
        return AnimationViews.animationViewByType(type: .typeWikiTreeNodeLoading)
    }

    public class var commentSendLoadingAnimation: LOTAnimationView {
        return AnimationViews.animationViewByType(type: .typeCommentSendLoading)
    }
    
    public class var sheetAlertLoadingAnimation: LOTAnimationView {
        return AnimationViews.animationViewByType(type: .typeSheetAlertLoading)
    }

    public class var smartComposeOnboarding: LOTAnimationView {
        return AnimationViews.animationViewByType(type: .smartComposeOnboarding)
    }
    
    public class var wikiOnboardingGestureAnimation: LOTAnimationView {
        return AnimationViews.animationViewByType(type: .typeWikiOnboardingGesture)
    }
    
    public class var bitableStageCompleteAnimation: LOTAnimationView{
        return AnimationViews.animationViewByType(type: .bitableStageComplete)
    }
    
    public class var bitableRecordSubscribeAnimation: LOTAnimationView{
        return AnimationViews.animationViewByType(type: .bitableRecordSuscribe)
    }

    public static var bitableHomeTabHomePageAnimation: LOTAnimationView {
        return AnimationViews.animationViewByType(type: .bitableHomeTabHomepage)
    }

    public static var bitableHomeTabRecommendAnimation: LOTAnimationView {
        return AnimationViews.animationViewByType(type: .bitableHomeTabRecommend)
    }

    public static var bitableHomeTabNewAnimation: LOTAnimationView {
        return AnimationViews.animationViewByType(type: .bitableHomeTabNew)
    }

    class func animationViewByType(type: AnimationType) -> LOTAnimationView {
        
        unzipResourcesIfNeeded()
        
        var resourceName: String = ""
        switch type {
        case .typeRefreshForward:
            resourceName = "refreshForward"
        case .typeRefreshBackward:
            resourceName = "refreshBackward"
        case .typeLoading:
            resourceName = "loading"
        case .typeDriveUploadCheck:
            resourceName = "driveUploadCheck"
        case .typeAudioRecording:
            resourceName = "audioRecording"
        case .typeCommentTranslating:
            resourceName = "commentTranslating"
        case .typeWikiTreeNodeLoading:
            resourceName = "WikiTreeNodeLoading"
        case .typeRecording:
            resourceName = "voice_comment"
        case .typeCommentSendLoading:
            resourceName = "commentSendLoading"
        case .typeSheetAlertLoading:
            resourceName = "sheet_alert_loading"
        case .smartComposeOnboarding:
            resourceName = "smartCompose"
        case .typeWikiOnboardingGesture:
            resourceName = "Wiki_onboarding_gesture"
        case .bitableStageComplete:
            resourceName = "bitableStageComplete"
        case .bitableRecordSuscribe:
            resourceName = "bitable_record_subscribe"
        case .bitableHomeTabHomepage:
            resourceName = "bitable_home_tab_homepage"
        case .bitableHomeTabRecommend:
            resourceName = "bitable_home_tab_recommend"
        case .bitableHomeTabNew:
            resourceName = "bitable_home_tab_new"
        default:()
        }

        let jsonPath = outputPath.appendingRelativePath("\(resourceName).json")
        let view = LOTAnimationView(filePath: jsonPath.pathString)
        view.backgroundColor = UIColor.clear
        view.autoReverseAnimation = true
        view.loopAnimation = true
        return view
    }
}

// MARK: 解压动画资源
extension AnimationViews {

    private static var appVersion: String? { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String }
    
    private static var outputPath: SKFilePath {  SKFilePath.globalSandboxWithLibrary.appendingRelativePath("bundle_lottie_animations") } // 解压路径
    private static var versionPath: SKFilePath { outputPath.appendingRelativePath("_unzip_bundle_version") } // 版本号记录
    
    private static func unzipResourcesIfNeeded() {
        
        if Self.resourceAvailable { return }
        
        if versionPath.exists {
            let lastVersion = try? String.read(from: versionPath) // 上次解压的版本号
            DocsLogger.info("get lastVersion: \(lastVersion ?? "unknown")")
            let versionSame = (lastVersion != nil && lastVersion == appVersion)
            if versionSame {
                Self.resourceAvailable = true
            } else {
                do {
                    DocsLogger.info("try to remove old version files")
                    try outputPath.removeItem()
                } catch {
                    DocsLogger.info("removeItem failed:\(error)")
                }
                _unzipResources()
            }
        } else {
            _unzipResources()
        }
    }
    
    private static func _unzipResources() {
        guard let srcPath = I18n.resourceBundle.path(forResource: "lottie_animations", ofType: "7z") else {
            DocsLogger.error("cannot get lottie_animations zipfile")
            return
        }
        do {
            let file = try LibArchiveFile(path: srcPath)
            try file.extract7z(toDir: outputPath.pathURL)
            DocsLogger.info("decompress succeed")
            if let version = appVersion, !version.isEmpty {
                try version.write(to: versionPath)
                DocsLogger.info("write version [\(version)] to file:\(versionPath)")
            } else {
                DocsLogger.info("appVersion is empty")
            }
        } catch {
            DocsLogger.error("decompress failed", error: error)
        }
    }
}
