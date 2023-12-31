//
//  RouteDependency.swift
//  TodoInterface
//
//  Created by 张威 on 2021/1/25.
//

import EENavigator
import RustPB

/// 路由依赖

// MARK: 路由配置

/// 路由配置参数
public struct RouteParams {

    public typealias OpenType = EENavigator.OpenType

    /// 打开类型
    public var openType = OpenType.present
    /// 来源 ViewController
    public var from: UIViewController
    /// 是否有动画
    public var animated = true
    /// 上下文
    public var context = [String: Any]()
    /// 结束回调
    public var completion = (() -> Void)?.none
    /// 定制 VC，在 present 生效
    public var prepare = ((UIViewController) -> Void)?.none
    /// 是否对 vc 进行 wrap，在 present 和 showDetail 生效
    public var wrap = UINavigationController.Type?.none

    public init(from: UIViewController) {
        self.from = from
    }
}

public enum PreviewImages {
    case imageSet([Basic_V1_ImageSet])
    case property([RustPB.Basic_V1_RichTextElement.ImageProperty])
}

/// 描述 Todo 业务对外的路由依赖
public protocol RouteDependency {

    /// 选择分享目标
    func selectSharingItem(with body: SelectSharingItemBody, params: RouteParams)

    /// 显示 profile 页
    func showProfile(with chatterId: String, params: RouteParams)

    /// 显示 at picker
    func showAtPicker(
        title: String,
        chatId: String,
        onSelect: @escaping ((_ viewConroller: UIViewController?, _ seletedId: String) -> Void),
        onCancel: @escaping (() -> Void),
        params: RouteParams
    )

    /// 显示选负责人picker，特殊点是底部有批量回调
    /// - Parameters:
    ///   - title: title
    ///   - chatId: chatid
    ///   - selectedChatterIds:已选
    ///   - supportbatchAdd: 批量的info，supportAdd 为true
    ///   - disableBatchAdd: 置灰批量按钮
    ///   - batchHandler: 回调
    ///   - selectedCallback: 回调
    ///   - params: 路由
    func showOwnerPicker(
        title: String,
        chatId: String?,
        selectedChatterIds: [String],
        supportbatchAdd: Bool,
        disableBatchAdd: Bool,
        batchHandler: ((UIViewController) -> Void)?,
        selectedCallback: ((UIViewController?, [String]) -> Void)?,
        params: RouteParams
    )

    /// 显示选人组件
    func showChatterPicker(
        title: String,
        chatId: String?,
        isAssignee: Bool,
        selectedChatterIds: [String],
        selectedCallback: ((UIViewController?, [String]) -> Void)?,
        params: RouteParams
    )

    /// 显示分享选人组件
    func showSharePicker(
        title: String,
        selectedChatterIds: [String],
        selectedCallback: ((UIViewController?, [TodoContactPickerResult], [TodoContactPickerResult]) -> Void)?,
        params: RouteParams
    )

    /// 显示 消息详情
    func showMergedMessageDetail(withEntity entity: Basic_V1_Entity, messageId: String, params: RouteParams)

    /// 显示 chat
    /// - Parameters:
    ///   - position: 填充则高亮对应消息
    func showChat(with chatId: String, position: Int32?, params: RouteParams)

    /// 显示 话题
    /// - Parameters:
    ///   - position: 填充则高亮对应消息
    func showThread(with threadId: String, position: Int32?, params: RouteParams)

    /// 跳转到大搜
    /// - Parameter from: home
    func showMainSearchVC(from: UIViewController)

    /// 显示 images
    func previewImages(
        _ images: PreviewImages,
        sourceIndex: Int,
        sourceView: UIImageView?,
        from: UIViewController
    )

    /// 显示本地文件选择页
    func showLocalFile(
        from: UIViewController,
        enableCount: Int,
        chooseLocalFiles: (([TaskFileInfo]) -> Void)?,
        chooseFilesChange: (([String]) -> Void)?,
        cancelCallback: (() -> Void)?
    )
}
