//
// Created by duanxiaochen.7 on 2021/6/1.
// Affiliated with SKUIKit.
//
// Description:

import Foundation
import UIKit

public struct NavigationTitleInfo {
    /// 标题显示方式
    public enum DisplayType: Int {
        case title = 1
        // 小文字，doc 编辑态保存时会动态显示
        case subtitle = 2
        // 包含自定义图标，jira block 刷新数据时会动态显示。是否显示自定义图标右边的文字，根据
        // SKNavigationBarCustomTitleView 的 _sizeThatFits:forceLayout: 的 shouldShowTitleAndSubtitle 决定
        case customized = 3
        // 完全填充标题区域的自定义View
        case fullCustomized = 4
    }

    public var title: String?
    public var subtitle: String?
    public var docName: String?
    public var untitledName: String?
    public var customView: UIView?
    public var displayType: DisplayType = .title

    public init(title: String? = nil, subtitle: String? = nil, customView: UIView? = nil, displayType: DisplayType = .title) {
        self.title = title
        self.subtitle = subtitle
        self.customView = customView
        self.displayType = displayType
    }
}

/// 用于回调给前端的文档Icon所需数据集
public final class IconSelectionInfo {

    public var key: String

    public var type: Int

    public var fsUnit: String

    // 无需给前端，埋点需要
    public var id: Int

    public init(key: String, type: Int, fsUnit: String, id: Int) {
        self.key = key
        self.type = type
        self.fsUnit = fsUnit
        self.id = id
    }

    public func asDictionary() -> [String: Any] {
        [
            "key": key,
            "type": type,
            "fs_unit": fsUnit
        ]
    }

}

public protocol SKNavigationBarCustomTitleView: UIView {

    var title: String? { get set }

    var subtitle: String? { get set }

    var titleLabel: UILabel { get set }

    var subtitleLabel: UILabel { get set }

    var customView: UIView? { get set }

    var displayType: NavigationTitleInfo.DisplayType { get set }

    var iconInfo: IconSelectionInfo? { get set }

    var shouldShowTexts: Bool { get set }

    var needDisPlayTag: Bool { get set }
    
    var tagContent: String? { get set }

    var showSecondTag: Bool { get set }

    var titleHorizontalAlignment: UIControl.ContentHorizontalAlignment { get set }

    var titleFont: UIFont { get set }
    
    func layoutTitle(size: CGSize, leadingOffset: CGFloat, trailOffset: CGFloat) -> CGSize

}

extension SKNavigationBar {

    /// 导航栏所有按钮的 ID（包括左边、右边、文字、图标）
    /// 新建 item 请一定要在这里补充，这个 ID 用来做按需隐藏和按钮管控
    public enum ButtonIdentifier: Equatable, Hashable {
        case appealExit
        case back
        case close
        case fullScreenMode
        case showInNewScene
        case catalog
        case done
        case addMember  // collaborator
        case save  // collaborator
        case random  // icon picker
        case viewDocument  // like list
        case more
        case baseMore
        case search
        case filter
        case publishAnnouncement  // announcement
        case history  // announcement
        case undo
        case redo
        case comment
        case share
        case feed
        case outline  // mindnote
        case mindmap  // mindnote
        case checked  // slide
        case unchecked  // slide
        case switchListMode  // space
        case filterListState  // space
        case findAndReplace
        case remove  // cover
        case switchPresentationMode  // drive
        case cancel  // drive
        case addFile  // drive
        case add  // wiki
        case tree  // wiki
        case create  // wiki
        case move  // wiki
        case bookmark //pdf
        case unknown(String)
        case vcShare    // 视频会议分享
        case sensitivity // 密集权限管控
        case wikiSpaceStar // wiki 知识库收藏
        case wikiSpaceDetail // wiki知识库详情页
        case orientation //切换横竖屏按钮
        case aiChatMode // AI分会话
        case sideFold // Bitable 侧边目录
        case copy //同步块独立页复制
        case forward //同步块分享
        case syncedReferences //同步块引用文档

        public var priority: UILayoutPriority {
            switch self {
            case .catalog, .tree, /* .showInNewScene,*/.undo, .redo, .comment: return .defaultLow
            default: return .required
            }
        }
    }
    
    public enum ButtonExtraIdentifier: Equatable, Hashable {
        case historyExit    // 历史记录推出
        case unknown(String)
    }
    
    public enum SizeType {

        /// 次级导航栏高度，C 视图下使用
        case secondary

        /// iPad 以 formSheet 方法 present 出时使用
        case formSheet

        /// 一级导航栏高度，iPad R 视图下也使用
        case primary
    }

    public enum NavigationMode {

        /// 只有最最基础的导航能力（仅显示返回、退出能力的按钮）
        case basic

        /// 只对部分白名单开放，其他 SKBarButtonItem 设置了也不会显示出来
        case allowing(list: Set<ButtonIdentifier>)

        /// 对于配置的黑名单内的 SKBarButtonItem 设置了也不会显示出来
        case blocking(list: Set<ButtonIdentifier>)

        /// 任意 item 都可以显示出来
        case open
    }

}
