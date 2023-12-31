//
//  RouteDependency.swift
//  ByteView
//
//  Created by kiri on 2023/6/25.
//

import Foundation
import ByteViewNetwork
import ByteViewMeeting

/// 对外需求：跳转到指定页面
public protocol RouteDependency {
    /// 跳转到升级页
    func gotoUpgrade(from: UIViewController)

    /// 初始化客服服务
    func launchCustomerService()

    /// 跳转到客服页
    func gotoCustomer(from: UIViewController)

    /// 跳转到docs
    func gotoDocs(urlString: String, context: [String: Any], from: UIViewController)

    /// 聊天页面
    func gotoChat(body: ChatBody, fromGetter: @escaping () -> UIViewController, completion: ((UIViewController, Int) -> Void)?)

    /// 个人信息
    func gotoUserProfile(userId: String, meetingTopic: String, sponsorName: String, sponsorId: String, meetingId: String, from: UIViewController)

    /// 跳转到H5
    func openURL(_ url: URL, from: UIViewController)

    /// 判断是否可以通过Navigator跳转
    func hasValidNavigableContent(for url: URL, context: [String: Any]) -> Bool

    /// lark内部跳转
    /// completion首参Bool表示push是否成功
    func push(_ url: URL, context: [String: Any], from: UIViewController, forcePush: Bool, animated: Bool,
              completion: ((Bool, Error?) -> Void)?)

    /// lark内部跳转
    /// completion首参Bool表示push是否成功
    func present(_ url: URL, context: [String: Any], from: UIViewController, animated: Bool,
                 completion: ((Bool, Error?) -> Void)?)

    /// iPad 应使用该接口
    /// completion首参Bool表示push是否成功
    func showDetailOrPush(_ url: URL,
                          context: [String: Any],
                          from: UIViewController,
                          animated: Bool,
                          completion: ((Bool, Error?) -> Void)?)

    func showImagePicker(from: UIViewController, sendButtonTitle: String?, takePhotoEnable: Bool,
                         completion: @escaping (UIViewController, PickedImage?) -> Void)

    /// 跳转到视频会议设置页面
    func gotoGeneralSettings(source: String, from: UIViewController)

    /// 跳转到ChatterPicker页面
    func gotoChatterPicker(_ msg: String, displayStatus: Int, disableUserKey: String?, disableGroupKey: String?, customView: UIView?, pickedConfirmCallBack: (([LivePermissionMember]) -> Void)?, defaultSelectedMembers: [LivePermissionMember]?, from: UIViewController)

    /// 跳转到直播认证页面
    func gotoLiveCert(from: UIViewController, wrap: UINavigationController.Type?, callback: ((Result<Void, Error>) -> Void)?)

    /// 显示一个页面
    func presentOrPushViewController(_ vc: UIViewController, from: UIViewController, style: UIModalPresentationStyle, withWrap: Bool)

    /// 跳转到rvc页面
    func gotoRVCPage(roomId: String, meetingId: String, from: UIViewController)

    /// lark主window
    var mainSceneWindow: UIWindow? { get }
}

public struct PickedImage {
    /// 需要在子线程调用
    public let originalImage: () -> UIImage?
    public let isGIF: Bool
    public let fileSize: Int64
    public let fileName: String?
    public let pixelSize: CGSize

    public init(fileSize: Int64, fileName: String?, pixelSize: CGSize, isGIF: Bool, originalImage: @escaping () -> UIImage?) {
        self.fileSize = fileSize
        self.fileName = fileName
        self.pixelSize = pixelSize
        self.isGIF = isGIF
        self.originalImage = originalImage
    }
}

public struct ChatBody {
    public let chatId: String
    public var position: Int32?
    public var showNormalBack: Bool
    public var isGroup: Bool
    public var switchFeedTab: Bool
    public var isPresent: Bool
    public var animated: Bool
    public var setFromWhere: Bool
    public var messageRenderBlock: (() -> Void)?
    public var messageCloseBlock: (() -> Void)?
    /// chat vc deinit
    public var messageDeinitBlock: (() -> Void)?

    public init(chatId: String, position: Int32? = nil, showNormalBack: Bool = false, isGroup: Bool = false, switchFeedTab: Bool = false, isPresent: Bool = false, animated: Bool = true, setFromWhere: Bool = false) {
        self.chatId = chatId
        self.position = position
        self.showNormalBack = showNormalBack
        self.isGroup = isGroup
        self.switchFeedTab = switchFeedTab
        self.isPresent = isPresent
        self.animated = animated
        self.setFromWhere = setFromWhere
    }
}
