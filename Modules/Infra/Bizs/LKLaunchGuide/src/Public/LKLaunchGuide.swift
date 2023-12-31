//
//  File.swift
//  LKLaunchGuide
//
//  Created by quyiming on 2020/3/16.
//

import UIKit
import Foundation
import RxSwift
import Swinject
import LarkLocalizations

// swiftlint:disable missing_docs

public final class LaunchGuideFactory {
    public static func create(config: LaunchGuideConfigProtocol,
                              resolver: Resolver) -> LaunchGuideService {
        LaunchGuideServiceImpl(config: config, resolver: resolver)
    }
}

public protocol LaunchGuideConfigProtocol {
    // MARK: Guide

    /// launch guide card items
    /// - required
//    var guideViewItems: [LaunchGuideViewItem] { get }

    /// sign up button text
    /// - optional
    /// - default value: Lark_UserGrowth_guide_carousel_register
    var signUpText: String { get }

    /// log in button text
    /// - optional
    /// - default value: Lark_UserGrowth_guide_carousel_login
    var loginText: String { get }

    var delegate: LaunchGuideDelegate? { get }

    var enableJoinMeeting: Bool { get }

    func createJoinMeetingView() -> UIView?
}

// MARK: Guide

public extension LaunchGuideConfigProtocol {
    var signUpText: String { I18N.Lark_Passport_Newsignup_SignUpTeamButton(LanguageManager.bundleDisplayName) }

    var loginText: String { I18N.Lark_Passport_Newsignup_LoginButton }

    var enableJoinMeeting: Bool { false }

    func createJoinMeetingView() -> UIView? { nil }
}

// MARK: Privacy Alert

public extension LaunchGuideConfigProtocol {

    var delegate: LaunchGuideDelegate? { nil }
}

public struct LottieResource {
    let bundle: Bundle
    let name: String

    public init(name: String, bundle: Bundle) {
        self.name = name
        self.bundle = bundle
    }
}

public final class LaunchGuideViewItem {
    let name: String
    let title: String
    let description: String
    let imageResource: ImageResource

    /// init
    /// - Parameter name: can be used for identify this item
    public init(name: String = "",
                title: String,
                description: String,
                imageResource: ImageResource) {
        self.name = name
        self.title = title
        self.description = description
        self.imageResource = imageResource
    }

    public enum ImageResource {
        case image(_ image: UIImage)
        case images(_ images: [UIImage])
        case lottie(_ lottie: LottieResource)
    }
}

public enum LaunchAction: String {
    case skip
    case login
    case createTeam
}

public protocol LaunchGuideService {

    func willSkip(showGuestGuide: Bool) -> Bool

    func checkShowGuide(window: UIWindow?, showGuestGuide: Bool) -> Observable<LaunchAction>

    /// try to scroll to item, success when first page is showing and doesnt change before.
    /// true for success, false for failure
    /// - Parameter name: item name
    @discardableResult
    func tryScrollToItem(name: String) -> Bool
}

extension LaunchGuideService {
    public func checkShowGuide(window: UIWindow?) -> Observable<LaunchAction> {
        self.checkShowGuide(window: window, showGuestGuide: false)
    }
}

public protocol LaunchGuideDelegate: AnyObject {
    func launchGuideDidShowPage(index: Int)
}

// swiftlint:enable missing_docs
