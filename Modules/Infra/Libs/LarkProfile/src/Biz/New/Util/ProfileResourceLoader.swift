//
//  ProfileResourceLoader.swift
//  LarkProfile
//
//  Created by Yuri on 2022/8/16.
//

import Foundation
import LarkLocalizations
import UniverseDesignColor
import UniverseDesignIcon
import UIKit
import RxSwift

final class ProfileResourceLoader {
    enum I18nKey: String {
        case larkServerSystemContentBlockedTipInChat
        case newContactsAcceptContactRequestButton
        case profileMyBadges
    }
    
    enum IconKey: String {
        case more
        case rightOutlined
        case defaultBgImage
        case shareOutlined
        case moreBoldOutlined
        case leftOutlined
        case chatFilled
        case chatSecretFilled
        case safeFilled
        case callFilled
        case videoFilled
        case privateSafeChatOutlined
    }
    typealias StringMap = [I18nKey: String]
    typealias ImageMap = [IconKey: UIImage]
    public let resources = BehaviorSubject(value: (StringMap(), ImageMap()))
    public let strings = PublishSubject<[I18nKey: String]>()
    public let images = PublishSubject<[IconKey: UIImage]>()
    
    private let queue = DispatchQueue(label: "com.lark.profile.resource_loader")
    private let disposeBag = DisposeBag()
    
    var stringMap: [I18nKey: String] = [:]
    var imageMap: [IconKey: UIImage] = [:]
    
    init() {
        Observable.combineLatest(strings, images)
            .subscribe(resources).disposed(by: disposeBag)
        loadStrings()
        loadImages()
    }
    
    typealias I18n = BundleI18n.LarkProfile
    public func loadStrings() {
        queue.async {
            self.stringMap = [
                .newContactsAcceptContactRequestButton: I18n.Lark_NewContacts_AcceptContactRequestButton,
                .profileMyBadges: BundleI18n.LarkProfile.Lark_Profile_MyBadges
                
            ]
            self.strings.onNext(self.stringMap)
        }
    }
    
    public func loadImages() {
        queue.async {
            self.imageMap = [
                .more: BundleResources.LarkProfile.more.ud.withTintColor(UIColor.ud.iconN2),
                .rightOutlined: UDIcon.rightOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill),
                .defaultBgImage: BundleResources.LarkProfile.default_bg_image,
                .shareOutlined: UDIcon.shareOutlined.ud.withTintColor(UIColor.ud.iconN1),
                .moreBoldOutlined: UDIcon.moreBoldOutlined.ud.withTintColor(UIColor.ud.iconN1),
                .chatFilled: UDIcon.chatFilled,
                .chatSecretFilled: UDIcon.chatSecretFilled,
                .safeFilled: UDIcon.safeFilled,
                .callFilled: UDIcon.callFilled,
                .videoFilled: UDIcon.videoFilled,
                .leftOutlined: UDIcon.getIconByKey(.leftOutlined).ud.resized(to: ProfileNaviBar.Cons.iconSize).withRenderingMode(.alwaysTemplate),
                .privateSafeChatOutlined: UDIcon.privateSafeChatOutlined
            ]
            self.images.onNext(self.imageMap)
        }
    }
}
