import Foundation
/// 场景key
public struct OPSceneKey {
    public static var key = "from"
}
// TODO: 需要和 OPAppScene 合并为新的 OPScene，并删除此处代码
/// 打开场景（请严格按照字典顺序排序，否则看着不舒服）
public enum OPScene: String {
    case album_qrcode
    case app
    case app_flag_cardlink
    case appcenter
    case appcenter_search
    case bot
    case camera_qrcode
    case convenientTab
    case feed
    case global_search
    case mainTab
    case message                // 消息（上游变动导致未能识别的情况）
    case p2p_message            // 消息-单人聊天-内部link
    case group_message          // 消息-多人聊天-内部link
    case thread_topic           // 消息-话题群或详情页-内部link
    case micro_app
    case mini_program
    case multi_appplus
    case multi_cardlink
    case multi_innerlink
    case topic_cardlink         // 消息卡片-话题群或详情页-cardlink
    case topic_innerlink        // 消息卡片-话题群或详情页-内部link
    case multi_task             // 多任务浮窗启动
    case press_image_qrcode
    case single_appplus
    case single_cardlink
    case single_innerlink
    case undefined
    case web_url
    /// 云空间打开小程序
    case doc
    // Message Action
    case message_action
    
    // 上游来源信息适配
    public static func build(context: [String: Any]?) -> OPScene {
        guard let context = context, let from = context[OPSceneKey.key] as? String else {
            return .undefined
        }
        guard let scene = OPScene.init(rawValue: from) else {
            return .undefined
        }
        
        if scene == .message {
            // message 类型要识别成更具体的情况
            guard let chatType = context["chat_type"] as? String else {
                return scene
            }
            if chatType == "group" {
                return .group_message
            } else if chatType == "single" {
                return .p2p_message
            } else if chatType == "topicGroup" {
                return .thread_topic
            }
        }
        
        return scene
    }
}
extension OPScene {
    /// 获取场景值（请严格按照数字大小排序，否则看着不舒服）
    public func sceneCode() -> Int {
        switch self {
        case .undefined, .message:
            return 1000         // 其他暂时未定义的场景值目前统一设置成1000，非卡片消息聊天也归为1000，后续有定义再修改
        case .appcenter:
            return 1001         // "发现栏小程序主入口，「最近使用」列表，小程序包更新时重启小程序。"
        case .feed:
            return 1002
        case .global_search:
            return 1005
        case .appcenter_search:
            return 1006
        case .single_cardlink:
            return 1007         // 消息卡片-单人聊天-cardlink
        case .multi_cardlink:
            return 1008         // 消息卡片-多人聊天-cardlink
        case .topic_cardlink:
            return 1514         // 消息卡片-话题群或详情页-cardlink
        case .single_innerlink:
            return 1009         // 消息卡片-单人聊天-内部link
        case .multi_innerlink:
            return 1010         // 消息卡片-多人聊天-内部link
        case .topic_innerlink:
            return 1514         // 消息卡片-话题群或详情页-内部link
        case .camera_qrcode:
            return 1011         // 扫码-摄像头扫描
        case .press_image_qrcode:
            return 1012         // 扫码-长按图片识别
        case .album_qrcode:
            return 1013         // 扫码-相册识别
        case .micro_app, .mini_program:
            return 1037         // 小程序打开小程序
        case .app:
            return 1069         // 外部应用打开小程序
        case .bot:
            return 1504         // bot中打开
        case .single_appplus:
            return 1509         // 在单聊的加号菜单中打开
        case .multi_appplus:
            return 1510         // 在群聊的加号菜单中打开
        case .mainTab:
            return 1506         //  主导航
        case .convenientTab:
            return 1507         //  快捷导航
        case .app_flag_cardlink:
            return 1511         // 消息卡片底部小程序链接
        case .web_url:
            return 1513         // web链接跳转小程序
        case .doc:
            return 1515         // 云空间打开小程序
        case .p2p_message:
            return 1009         // 消息-单人聊天-内部link
        case .group_message:
            return 1010         // 消息-多人聊天-内部link
        case .thread_topic:
            return 1514         // 消息-话题群或详情页-内部link
        case .message_action:
            return 1516         // Message Action 导索页面
        case .multi_task:
            return 1187         // 多任务浮窗启动
        }
    }
}
