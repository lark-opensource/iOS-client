//
//  LarkLiveDependencyImpl.swift
//  LarkLiveMod
//
//  Created by Supeng on 2021/10/15.
//

import Foundation
import LarkLive
import Swinject
import EENavigator
#if ByteViewMod
import ByteViewInterface
#endif
#if MinutesMod
import MinutesInterface
#endif

#if MessengerMod
import LarkMessengerInterface
import LarkNavigation
import LarkUIKit
#endif

import LarkAccountInterface

class LarkLiveDependencyImpl: LarkLiveDependency{

    private let resolver: Resolver

    init(resolver: Resolver) {
        self.resolver = resolver
    }

    var isInRecording: Bool {
        #if MinutesMod
        if let service = resolver.resolve(MinutesAudioRecordService.self) {
            return service.isRecording()
        } else {
            return false
        }
        #else
        return false
        #endif
    }

    var isInMeeting: Bool {
        #if ByteViewMod
        if let service = try? resolver.resolve(assert: MeetingService.self) {
            return service.currentMeeting?.isActive == true
        } else {
            return false
        }
        #else
        return false
        #endif
    }

    var isInPodcast: Bool {
        #if MinutesMod
        if let service = resolver.resolve(MinutesPodcastService.self) {
            return service.isPodcast
        } else {
            return false
        }
        #else
        return false
        #endif
    }

    func stopPodcast() {
        #if MinutesMod
        if let service = resolver.resolve(MinutesPodcastService.self) {
            service.stopPodcast()
        }
        #endif
    }

    func pushOrPresentShareContentBody(text: String, from: NavigatorFrom?, style: Int) {
        #if MessengerMod
        var fromViewController: NavigatorFrom?

        if let from = from {
            fromViewController = from
        } else {
            fromViewController = Navigator.shared.mainSceneTopMost
        }

        if let fromViewController = fromViewController {
            let body = ShareContentBody(title: "", content: text)
            Navigator.shared.present(body: body, from: fromViewController, prepare: {
                if #available(iOS 13.0, *) {
                    $0.overrideUserInterfaceStyle = UIUserInterfaceStyle(rawValue: style) ?? .unspecified
                }
                $0.modalPresentationStyle = .formSheet
                //$0.modalPresentationCapturesStatusBarAppearance = true
            })
        }
        #endif
    }

    func getLocalUserInfo() -> (name: String, url: String, userId: String) {
        if let service = resolver.resolve(LarkAccountInterface.AccountService.self)  {
            let avatarUrl = service.currentAccountInfo.avatarUrl
            let name = service.currentAccountInfo.name
            let userId = service.currentAccountInfo.userID
            return (name: name, url: avatarUrl, userId: userId)
        } else {
            return (name: "", url: "", userId: "")
        }
    }

    func getAccountTenant() -> LarkAccountInterface.Tenant? {
        if let service = resolver.resolve(LarkAccountInterface.AccountService.self) {
            return service.currentAccountInfo.tenant
        }
        return nil
    }
}
