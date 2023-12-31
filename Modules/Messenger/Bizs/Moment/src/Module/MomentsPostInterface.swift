//
//  MomentsPostInterface.swift
//  MomentInterface
//
//  Created by zhuheng on 2020/12/30.
//

import UIKit
import EENavigator
import Foundation
import LarkModel
import RustPB
import SuiteCodable
import LarkMessengerInterface
import LarkAssetsBrowser

public enum MomentsDetialPageSource: String, Codable, HasDefault {
    case feed = "feed_post"
    case profile = "community_profile"
    case notification = "notification_page"
    case pushBot = "push_bot"
    case shareChat = "share_chat"

    public static func `default`() -> MomentsDetialPageSource {
        return .feed
    }
}

public struct MomentPostDetailByIdBody: CodableBody {
    public static var appLinkPattern: String {
        return "/client/moments/detail"
    }

    private static let prefix = "//client/moment/postDetail"
    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:postId(\\d+)", type: .path)
    }
    public var _url: URL {
        if let toCommentId = toCommentId {
            return URL(string: "\(MomentPostDetailByIdBody.prefix)/\(postId)#\(toCommentId)") ?? URL(string: MomentPostDetailByIdBody.prefix) ?? .init(fileURLWithPath: "")
        }
        return URL(string: "\(MomentPostDetailByIdBody.prefix)/\(postId)") ?? URL(string: MomentPostDetailByIdBody.prefix) ?? .init(fileURLWithPath: "")
    }

    public let postId: String
    //是否需要定位到具体某条评论
    public let toCommentId: String?
    public let autoShowKeyboard: Bool
    public let source: MomentsDetialPageSource?
    public let canRouteToFeed: Bool

    public init(postId: String,
                toCommentId: String? = nil,
                autoShowKeyboard: Bool = false,
                source: MomentsDetialPageSource?,
                canRouteToFeed: Bool = false) {
        self.postId = postId
        self.toCommentId = toCommentId
        self.autoShowKeyboard = autoShowKeyboard
        self.source = source
        self.canRouteToFeed = canRouteToFeed
    }
}

public enum PostDetailScrollState {
    case toCommentId(String?)
    case toFirstComent
}

public struct MomentPostDetailByPostBody: Body {

    private static let prefix = "//client/moment/postDetail/by/post"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:postId(\\d+)", type: .path)
    }

    public var _url: URL {
        switch scrollState {
        case .toCommentId(let id):
            if let id = id {
                return URL(string: "\(MomentPostDetailByPostBody.prefix)/\(post.id)#\(id)") ?? .init(fileURLWithPath: "")
            } else {
                return URL(string: "\(MomentPostDetailByPostBody.prefix)/\(post.id)") ?? .init(fileURLWithPath: "")
            }
        default:
            return URL(string: "\(MomentPostDetailByPostBody.prefix)/\(post.id)") ?? .init(fileURLWithPath: "")
        }
    }

    public let post: RawData.PostEntity
    //是否需要定位到具体某条评论
    public let scrollState: PostDetailScrollState?
    public let autoShowKeyboard: Bool
    public let source: MomentsDetialPageSource?
    public let canRouteToFeed: Bool

    public init(
        post: RawData.PostEntity,
        scrollState: PostDetailScrollState? = nil,
        autoShowKeyboard: Bool = false,
        source: MomentsDetialPageSource?,
        canRouteToFeed: Bool = false) {
        self.post = post
        self.scrollState = scrollState
        self.autoShowKeyboard = autoShowKeyboard
        self.source = source
        self.canRouteToFeed = canRouteToFeed
    }
}

/// 跳转公司圈的profile页
public struct MomentUserProfileByIdBody: CodableBody {

    public static var appLinkPattern: String {
        return "/client/moments/user"
    }

    private static let prefix = "//client/moments/user"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:userId(\\d+)", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(MomentUserProfileByIdBody.prefix)/\(userId)") ?? .init(fileURLWithPath: "")
    }

    public let userId: String

    public init(userId: String) {
        self.userId = userId
    }
}

/// 跳转公司圈的花名页
public struct MomentsUserNicknameProfileByIdBody: Body {

    public static var appLinkPattern: String {
        return "/client/moments/nickname"
    }

    private static let prefix = "//client/moments/nickname"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:userId(\\d+)", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(MomentsUserNicknameProfileByIdBody.prefix)/\(userId)") ?? .init(fileURLWithPath: "")
    }

    public let userId: String
    public let selectPostTab: Bool

    /// 这两个赋值，可以加快界面的UI展示
    public let userInfo: (name: String, avatarKey: String)

    public init(userId: String,
                userInfo: (name: String, avatarKey: String),
                selectPostTab: Bool = true) {
        self.userId = userId
        self.userInfo = userInfo
        self.selectPostTab = selectPostTab
    }
}

/// 跳转公司圈的板块编辑页
public struct MomentsCategoryEditBody: PlainBody {
    public static let pattern = "//client/moments/categoryEditBody"
    let usedTabs: [RawData.PostTab]
    let selectedTab: RawData.PostTab
    let selectBlock: ((RawData.PostTab) -> Void)?
    let finishBlock: (([RawData.PostTab]) -> Void)?
    public init(selectedTab: RawData.PostTab,
                usedTabs: [RawData.PostTab],
                selectBlock: ((RawData.PostTab) -> Void)?,
                finishBlock: (([RawData.PostTab]) -> Void)?) {
        self.selectedTab = selectedTab
        self.usedTabs = usedTabs
        self.selectBlock = selectBlock
        self.finishBlock = finishBlock
    }
}

/// 跳转公司圈的板块详情页
public struct MomentsPostCategoryDetialByCategoryBody: Body {

    private static let prefix = "//client/moments/category/detail/by/category"

    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:categoryId(\\d+)", type: .path)
    }

    public var _url: URL {
        return URL(string: "\(MomentsPostCategoryDetialByCategoryBody.prefix)/\(category.category.categoryID)") ?? .init(fileURLWithPath: "")
    }

    public let category: RawData.PostCategory
    public var isPresented: Bool = false //true表示VC是present出来的，false表示是push出来的

    public init(category: RawData.PostCategory) {
        self.category = category
    }
}

/// 跳转公司圈的板块详情页
public struct MomentsPostCategoryDetialByIDBody: Body {
    public static let appLinkPatter = "/client/moments/category"
    private static let prefix = "//client/moments/category/detail"
    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:categoryId(\\d+)", type: .path)
    }
    public var _url: URL {
        return URL(string: "\(MomentsPostCategoryDetialByIDBody.prefix)/\(categoryID)") ?? .init(fileURLWithPath: "")
    }
    public let categoryID: String
    public var isPresented: Bool = false //true表示VC是present出来的，false表示是push出来的
    public init(categoryID: String) {
        self.categoryID = categoryID
    }
}

/// 跳转公司圈的hashTag详情页
public struct MomentsHashTagDetialByIDBody: Body {
    public static let appLinkPatter = "/client/moments/hashtag"
    private static let prefix = "//client/moments/hashtag/detail"
    public static var patternConfig: PatternConfig {
        return PatternConfig(pattern: "\(prefix)/:hashtagId(\\d+)", type: .path)
    }
    public var _url: URL {
        return URL(string: "\(MomentsHashTagDetialByIDBody.prefix)/\(hashTagID)") ?? .init(fileURLWithPath: "")
    }
    public let hashTagID: String
    public let content: String?
    public var isPresented: Bool = false //true表示VC是present出来的，false表示是push出来的
    public init(hashTagID: String,
                content: String?) {
        self.hashTagID = hashTagID
        self.content = content
    }
}

/// 图片的基本信息
public struct PostCommonItemInfo {
    public let width: CGFloat
    public let height: CGFloat
    public let token: String
    public let localPath: String
}

/// 视频的基本信息 封面 + 视频信息
public struct PostItemVideoInfo {
    public let corveImage: PostCommonItemInfo
    public let videoInfo: PostCommonItemInfo
    /// 视频时长 秒
    public let videoDurationSec: TimeInterval
}

public struct PostImageMediaInfo {
    public let imageInfo: PostCommonItemInfo?
    public let videoInfo: PostItemVideoInfo?
}

/// 公司圈发帖界面
public struct MomentsSendPostBody: PlainBody {
    public static let pattern = "//client/moments/sendPostBody"
    // 板块ID
    public let categoryID: String?
    public let source: String?
    public let hashTagContent: String?
    let sendPostCallBack: ((String?, Bool, RustPB.Basic_V1_RichText?, [PostImageMediaInfo]?) -> Void)
    public init(categoryID: String?,
                source: String?,
                hashTagContent: String? = nil,
                sendPostCallBack: @escaping ((String?, Bool, RustPB.Basic_V1_RichText?, [PostImageMediaInfo]?) -> Void)) {
        self.categoryID = categoryID
        self.hashTagContent = hashTagContent
        self.source = source
        self.sendPostCallBack = sendPostCallBack
    }
}

/// 花名设置的style，select表示选择花名的选项（默认为此选项），modify表示修改花名的选项
public enum NickNameSettingStyle {
    case select
    case modify(nickNameID: String, nickName: String, avatarKey: String)
}

/// 跳转花名页面
public struct MomentsUserNickNameSelectBody: PlainBody {
    public static let pattern = "//client/moments/UserNickNameSelect"
    public let circleId: String
    let completeBlock: ((_ momentUser: RawData.RustMomentUser, _ renewNicknameTime: Int64) -> Void)?
    let nickNameSettingStyle: NickNameSettingStyle
    public init(circleId: String,
                completeBlock: ((_ momentUser: RawData.RustMomentUser, _ renewNicknameTime: Int64) -> Void)?,
                nickNameSettingStyle: NickNameSettingStyle = .select) {
        self.circleId = circleId
        self.completeBlock = completeBlock
        self.nickNameSettingStyle = nickNameSettingStyle
    }
}

/// 跳转设置页面
public struct MomentsSettingBody: CodablePlainBody {
    public static let pattern = "//client/moments/setting"
    public init() {
    }
}

///跳转图片查看器页面
public struct MomentsPreviewImagesBody: PlainBody {
    public static let pattern = "//client/moments/preview/images"

    public let postId: String?
    public let assets: [Asset]
    public let pageIndex: Int

    public let shouldDetectFile: Bool
    public var canSaveImage: Bool
    public var canEditImage: Bool
    public var hideSavePhotoBut: Bool

    public let buttonType: LKAssetBrowserViewController.ButtonType

    public init(
        postId: String?,
        assets: [Asset],
        pageIndex: Int,
        shouldDetectFile: Bool = true,
        canSaveImage: Bool = true,
        canEditImage: Bool = true,
        hideSavePhotoBut: Bool = false,
        buttonType: LKAssetBrowserViewController.ButtonType = .onlySave) {
            self.postId = postId
            self.assets = assets
            self.pageIndex = pageIndex
            self.shouldDetectFile = shouldDetectFile
            self.canSaveImage = canSaveImage
            self.canEditImage = canEditImage
            self.hideSavePhotoBut = hideSavePhotoBut
            self.buttonType = buttonType
    }
}

public protocol MomentInterface {
}
