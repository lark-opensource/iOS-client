//
//  ProfileMockProvider.swift
//  LarkProfileDev
//
//  Created by 姚启灏 on 2021/7/13.
//

import UIKit
import Foundation
import LarkProfile
import UniverseDesignIcon
import UniverseDesignTag
import RxSwift
import RichLabel

public class ProfileMockData: ProfileData { }

public class ProfileMockProvider: ProfileDataProvider {

    private var relationshipReplay = ReplaySubject<ProfileRelationship>.create(bufferSize: 1)
    public var relationship: Observable<ProfileRelationship> {
        return relationshipReplay.asObserver()
    }

    public func changeRelationship(_ relationship: ProfileRelationship) {
        relationshipReplay.onNext(relationship)
    }

    public static var identifier: String = "ProfileMockProvider"

    public static func createDataProvider(by data: ProfileData) -> ProfileDataProvider? {
        guard let data = data as? ProfileMockData else { return nil }
        return ProfileMockProvider(data: data)
    }

    private var statusReplay: ReplaySubject<ProfileStatus> = ReplaySubject<ProfileStatus>.create(bufferSize: 1)
    public var status: Observable<ProfileStatus> {
        return statusReplay.asObserver()
    }

    public weak var profileVC: ProfileViewController?

    public func getTabs() -> [ProfileTab] {
        let pushItem = ProfileFieldPushItem(
            title: "Push Cell",
            contentText: "跳转") {
            print("Push Success")
        }

        let linkItem = ProfileFieldLinkItem(
            title: "Link Cell",
            contentText: "链接跳转",
            url: "www.bytedance.com"
        )

        let normalItem = ProfileFieldNormalItem(
            title: "Normal Cell",
            contentText: "内容区域",
            enableLongPress: true
        )

        let textList = [
            "测试爱撒娇打哈萨克大会上京东sdasdasjdhajshdkashfkashfkjasfa卡是多少"
//            "asdqw;ikhjljakfgajksgfqlblasbcascjaaskh",
//            "asdhasjkfghjkdaskjdhaksdhaskdhaksjdkashdadasfafasfaasfgjaksfgjafgajksfa",
//            "qjjwqjjj",
//            "asdjasfasfsafb",
//            "asdasfasf"
        ]
        let textListItem = ProfileFieldTextListItem(
            title: "Text List",
            textList: textList
        )

        for index in 0..<textList.count {
            textListItem.expandItemDir[index] = .expandable(expanding: false) // 初始值
        }

        let linkListItem = ProfileFieldHrefListItem(
            title: "Link List",
            hrefList: [
                ProfileHref(url: "www.baidu.com", text: "https://三达不溜.百度.康姆")
//                ProfileHref(url: "www.baidu.com", text: "assadasdasdaskjdaskjdhas"),
//                ProfileHref(url: "www.baidu.com", text: "askjdawhefjkfgksafkafafafasfsafskjdhas")
            ]
        )

        let phoneItem = ProfileFieldPhoneNumberItem(
            title: "Phone Cell",
            contentText: "显示",
            userID: "1",
            phoneNumber: "182-****-0001",
            countryCode: "+86",
            isPlain: false
        )

        let data = ProfileFieldData(
            title: "个人信息",
            fields: [pushItem, linkItem, normalItem, phoneItem, textListItem, linkListItem]
        )
        return [ProfileFieldTab(data: data),
                ProfileFieldTab(data: data)]
    }

    public func getAvtarView() -> UIImageView? {
        return UIImageView(image: UIImage(named: "avatar")!)
    }

    public func getBackgroundView() -> UIImageView? {
        return UIImageView(image: UIImage(named: "header_img")!)
    }

    public func getUserInfo() -> ProfileUserInfo {
        let company = CompanyAuthView()
        company.configUI(tenantName: "北京男子职业技术学院",
                         hasAuth: true,
                         isAuth: true,
                         tapCallback: nil)

        var nameTag: [UIView] = []
        nameTag.append(UDTag(icon: UDIcon.getIconByKey(.femaleFilled),
                             iconConfig: UDTagConfig.IconConfig(
                                cornerRadius: 2,
                                iconColor: UIColor.ud.primaryOnPrimaryFill,
                                backgroundColor: UIColor.ud.C400,
                                height: 18,
                                iconSize: CGSize(width: 12, height: 12))))
        nameTag.append(UDTag(text: "03/11-03/14 请假",
                             textConfig: UDTagConfig.TextConfig(
                                textColor: UIColor.ud.primaryOnPrimaryFill,
                                backgroundColor: UIColor.ud.functionDangerFillHover)))

        var customBadge: [UIView] = []
        for i in (0...5) {
            let tagConfig = UDTagConfig.TextConfig(textColor: UIColor.ud.primaryOnPrimaryFill,
                                                   backgroundColor: UIColor.ud.functionDangerContentDefault)
            let tagView = UDTag(text: "测试标签 \(i)", textConfig: tagConfig)
            tagView.setContentCompressionResistancePriority(UILayoutPriority(Float(1_000 - i)), for: .horizontal)
            customBadge.append(tagView)
        }

        let descriptionView = ProfileStatusView()
        descriptionView.setStatus("Tel: 18203770001 \nTalk is cheap, show me the code: http://www.github.com. Talk is cheap, show me the code. Talk is cheap, show me the code. Talk is cheap, show me the code. ") {
            print("Did tap description label")
        }
        descriptionView.delegate = self

        return ProfileUserInfo(name: "你斌哥你斌哥",
                               descriptionView: descriptionView,
                               nameTag: nameTag,
                               customBadges: customBadge,
                               companyView: company)
    }

    public func reloadData() {

    }

    public func getCTA() -> [ProfileCTAItem] {
        return [ProfileCTAItem(title: "Chat",
                               icon: UDIcon.chatFilled.ud.withTintColor(UIColor.ud.colorfulBlue),
                               enable: true,
                               denyDescribe: "无法点击",
                               tapCallback: {
                                print("Chat button")
                               }),
                ProfileCTAItem(title: "Secret",
                               icon: UDIcon.chatSecretFilled.ud.withTintColor(UIColor.ud.colorfulBlue),
                               enable: false,
                               denyDescribe: "无法点击",
                               tapCallback: {
                                print("Secret button")
                               }),
                ProfileCTAItem(title: "Voice",
                               icon: UDIcon.callFilled.ud.withTintColor(UIColor.ud.colorfulBlue),
                               enable: true,
                               denyDescribe: "无法点击",
                               tapCallback: {
                                print("Voice button")
                               }),
                ProfileCTAItem(title: "Video",
                               icon: UDIcon.videoFilled.ud.withTintColor(UIColor.ud.colorfulBlue),
                               enable: true,
                               denyDescribe: "无法点击",
                               tapCallback: {
                                print("Video button")
                               })]
    }

    public func getNavigationButton() -> [UIButton] {
        let shareButton = UIButton()
        shareButton.setImage(UDIcon.getIconByKey(.shareOutlined), for: .normal)
        let moreButton = UIButton()
        moreButton.setImage(UDIcon.getIconByKey(.moreBoldOutlined), for: .normal)
        return [shareButton, moreButton]
    }

    public init(data: ProfileMockData) {
        self.statusReplay.onNext(.normal)
        ProfileFieldFactory.register(type: ProfileFieldPhoneCell.self)
    }
}

extension ProfileMockProvider: LKLabelDelegate {
    public func attributedLabel(_ label: LKLabel, didSelectLink url: URL) {
        print(url.absoluteString)
    }

    public func attributedLabel(_ label: LKLabel, didSelectPhoneNumber phoneNumber: String) {
        print(phoneNumber)
    }

    public func attributedLabel(_ label: LKLabel, didSelectText text: String, didSelectRange range: NSRange) -> Bool {
        return true
    }

    public func shouldShowMore(_ label: LKLabel, isShowMore: Bool) {}
    public func tapShowMore(_ label: LKLabel) {}
    public func showFirstAtRect(_ rect: CGRect) {}
}
