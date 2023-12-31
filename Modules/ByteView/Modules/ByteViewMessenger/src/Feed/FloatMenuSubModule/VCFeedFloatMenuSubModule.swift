//
//  VCFeedFloatMenuSubModule.swift
//  MessengerMod
//
//  Created by liuxianyu on 2022/12/18.
//

import UniverseDesignIcon
import LarkOpenIM
import LarkOpenFeed
import EENavigator
import ByteViewInterface
import LarkKAFeatureSwitch
import LarkFeatureGating
import LarkContainer
import LarkSetting

private extension FeedFloatMenuContext {
    var userId: String { userResolver.userID }
    var navigator: Navigatable { userResolver.navigator }
}

final class VCNewMeetingMenuSubModule: FeedFloatMenuSubModule {
    public override class var name: String { return "VCNewMeetingMenuSubModule" }

    public override var type: FloatMenuOptionType {
        return .newMeeting
    }

    public override class func canInitialize(context: FeedFloatMenuContext) -> Bool {
        return true
    }

    public override func canHandle(model: FeedFloatMenuMetaModel) -> Bool {
        return suiteVcFg
    }

    public override func handler(model: FeedFloatMenuMetaModel) -> [Module<FeedFloatMenuContext, FeedFloatMenuMetaModel>] {
        return [self]
    }

    public override func menuOptionItem(model: FeedFloatMenuMetaModel) -> FloatMenuOptionItem? {
        return FloatMenuOptionItem(
            icon: UDIcon.getIconByKey(.videoOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2),
            title: BundleI18n.ByteViewMessenger.Lark_View_NewMeeting,
            type: type
        )
    }

    public override func didClick() {
        guard let from = context.feedContext.page else { return }
        let body = StartMeetingBody(entrySource: .createNewMeeting)
        context.navigator.present(body: body, from: from)
    }
}

final class VCJoinMeetingMenuSubModule: FeedFloatMenuSubModule {
    public override class var name: String { return "VCJoinMeetingMenuSubModule" }

    public override var type: FloatMenuOptionType {
        return .joinMeeting
    }

    public override class func canInitialize(context: FeedFloatMenuContext) -> Bool {
        return true
    }

    public override func canHandle(model: FeedFloatMenuMetaModel) -> Bool {
        return suiteVcFg
    }

    public override func handler(model: FeedFloatMenuMetaModel) -> [Module<FeedFloatMenuContext, FeedFloatMenuMetaModel>] {
        return [self]
    }

    public override func menuOptionItem(model: FeedFloatMenuMetaModel) -> FloatMenuOptionItem? {
        return FloatMenuOptionItem(
            icon: UDIcon.getIconByKey(.newJoinMeetingOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2),
            title: BundleI18n.ByteViewMessenger.Lark_View_JoinMeeting,
            type: type
        )
    }

    public override func didClick() {
        guard let from = context.feedContext.page else { return }
        let body = JoinMeetingBody(id: "", idType: .number, entrySource: .joinRoom)
        context.navigator.present(body: body, from: from)
    }
}

final class VCShareScreenMenuSubModule: FeedFloatMenuSubModule {
    public override class var name: String { return "VCShareScreenMenuSubModule" }

    public override var type: FloatMenuOptionType {
        return .shareScreen
    }

    public override class func canInitialize(context: FeedFloatMenuContext) -> Bool {
        return true
    }

    public override func canHandle(model: FeedFloatMenuMetaModel) -> Bool {
        return suiteVcFg && shareScreenFg
    }

    public override func handler(model: FeedFloatMenuMetaModel) -> [Module<FeedFloatMenuContext, FeedFloatMenuMetaModel>] {
        return [self]
    }

    public override func menuOptionItem(model: FeedFloatMenuMetaModel) -> FloatMenuOptionItem? {
        return FloatMenuOptionItem(
            icon: UDIcon.getIconByKey(.shareScreenOutlined, size: CGSize(width: 20, height: 20)).ud.withTintColor(UIColor.ud.iconN2),
            title: BundleI18n.ByteViewMessenger.Lark_View_ShareScreenButton,
            type: type
        )
    }

    public override func didClick() {
        guard let from = context.feedContext.page else { return }
        let body = ShareContentBody(source: .groupPlus)
        context.navigator.present(body: body, from: from)
    }

    private var shareScreenFg: Bool {
        do {
            let fg = try userResolver.resolve(assert: FeatureGatingService.self)
            return fg.staticFeatureGatingValue(with: "byteview.callmeeting.ios.screenshare_entry")
        } catch {
            return false
        }
    }
}

private extension FeedFloatMenuSubModule {
    var suiteVcFg: Bool {
        do {
            let fg = try userResolver.resolve(assert: SettingService.self)
            let dict = try fg.setting(with: UserSettingKey.make(userKeyLiteral: "feature_switch_client"))
            if let b = dict["suite_vc"] as? Bool {
                return b
            } else {
                return true
            }
        } catch {
            return true
        }
    }
}
