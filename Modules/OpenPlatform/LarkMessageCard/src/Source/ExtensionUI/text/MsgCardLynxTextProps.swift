//
//  MsgCardLynxTextProps.swift
//  LarkMessageCard
//
//  Created by majiaxin.jx on 2022/11/20.
//

import Foundation

// 最好都继承
protocol Props: Decodable {
    var tag: String? { get }
    var id: String? { get }
}

enum TextAlign: String, Decodable {
    case left = "left"
    case center = "center"
    case right = "right"
    case unknown = "unknown"
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self = Self(rawValue: string) ?? .unknown
    }
}


enum Ellipsize: String, Decodable {
    case start = "start"
    case end = "end"
    case middle = "middle"
    case marquee = "marquee"
    case unknown = "unknown"
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self = Self(rawValue: string) ?? .unknown
    }
}

enum TextDeciration: String, Decodable {
    case strikethrough = "strikethrough"
    case underline = "underline"
    case bold = "bold"
    case italic = "italic"
    case unknown = "unknown"
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self = Self(rawValue: string) ?? .unknown
    }
}

enum ListType: String, Decodable {
    case ol = "ol"
    case ul = "ul"
    case unknown = "unknown"
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let string = try container.decode(String.self)
        self = Self(rawValue: string) ?? .unknown
    }
}

protocol TextViewStyle: Decodable {

    //文本整体背景色
    var bgColor: String? { get }
    // 最大行数
    var maxLines: Int? { get }
    // 文本行间距, 仅 Android
    var lineSpacing: CGFloat? { get }
    // 文本对齐方式，可以是left|right|center|
    var align: TextAlign? { get }
    // 文字长度超出容器时的显示模式
    var ellipsize: Ellipsize? { get }
    // 容器默认字符颜色
    //（属于特化逻辑，给 Header 设置省略号颜色， 对整个 text 生效， 其余场景未验证）
    var textColor: String? { get }
    //文本行高
    var lineHeight: CGFloat? { get }
    
    //文本控件左内边距（控件左边离文字左边的间距，单位为dp）
    var paddingLeft: CGFloat? { get }
    //文本控件右内边距（控件右边离文字右边的间距，单位为dp）
    var paddingRight: CGFloat? { get }
    //文本控件上内边距（控件上边离文字上边的间距，单位为dp）
    var paddingTop: CGFloat? { get }
    //文本控件下内边距（控件下边离文字下边的间距，单位为dp）
    var paddingBottom: CGFloat? { get }
    //禁用at样式
    var disableAtStyle: Bool? { get }
    
}

struct ContentProps: Decodable {
    let tag: String?
    let id: String?
    var plainTextProps: TextProps?
    let atProps: AtProps?
    let linkProps: LinkProps?
    let emojProps: EmojProps?
    let hrProps: HrProps?
    let brProps: BrProps?
    let textTagProps: TextTagProps?
    let codeBlockProps: String?
    let imageProps: ListItemImageProps?
    let listProps: [ListItemProps]?
}

struct TextViewProps : Props, TextViewStyle {
    
    let tag: String?
    let id: String?
    
    // 文本最大行数,如果最大行设置为1，默认设置singleLine为true（超出的部分会显示省略号）
    let maxLines: Int?
    // 文本整体背景色
    let bgColor: String?
    // 文本行间距, 仅 Android
    let lineSpacing: CGFloat?
    
    // 文本水平对齐方式
    let align: TextAlign?
    // 文字长度超出容器时的显示模式, 仅 Android 有用(目前都显示 ...)
    var ellipsize: Ellipsize?
    // 容器默认字符颜色
    //（属于特化逻辑，给 Header 设置省略号颜色， 对整个 text 生效， 其余场景未验证）
    var textColor: String?
    //文本行高
    let lineHeight: CGFloat?
    
    //文本控件左内边距（控件左边离文字左边的间距，单位为dp）
    let paddingLeft: CGFloat?
    //文本控件右内边距（控件右边离文字右边的间距，单位为dp）
    let paddingRight: CGFloat?
    //文本控件上内边距（控件上边离文字上边的间距，单位为dp）
    let paddingTop: CGFloat?
    //文本控件下内边距（控件下边离文字下边的间距，单位为dp）
    let paddingBottom: CGFloat?
    // at 文本是否可点击
    let atClickable: Bool?
    // link 文本是否可点击
    let linkClickable: Bool?
    // 是否禁用 at 特有样式
    let disableAtStyle: Bool?
    // 是否禁用 text_tag 特有样式
    let disableTagStyle: Bool?
    // 文字大小缩放,是否受宽度限制(在字体放大时,是否允许大于最大宽度)
    let isFontSizeLimit: Bool?
    //文本内容，如果包含多个元素，比如Text
    
    let isTranslateElement: Bool?
    
    var contentProps: [ContentProps]?
    
    static func from(dict: [String: Any?]) throws -> Self {
        return try JSONDecoder().decode(
            TextViewProps.self,
            from: JSONSerialization.data(withJSONObject: dict)
        )
    }
}

protocol TextStyle: Decodable {
    // 文字大小，默认14sp，Lynx前端要注意，注意button的字号
    var textSize: CGFloat? { get }
    // 文本颜色
    var textColor: String? { get }
    // 文本颜色 token
    var textColorToken: String? { get }
    // 文本背景色
    var textBgColor: String? { get }
    // 文本背景色 token
    var textBgColorToken: String? { get }
    // 文本对齐
    var align: String? { get }
    // 文本最大行数
    var maxLines: Int? { get }
    /**
     * 文本样式,可以是几种组合
     * strikethrough：删除线
     * underline：下划线
     * bold 粗体
     * italic 斜体
     */
    var textDecoration: [TextDeciration]? { get }
    
}

protocol TextProtocol: TextStyle, Decodable {
    
    /**
     * 富文本的文本内容，不同类型span传的内容不一样
     * at人：Native根据attachment计算出来
     * url:Lynx前端传的是链接文本
     * emoj：Lynx前端什么也不传，是Native计算出来的
     * 其他传文本内容，比如带下划线、加粗、斜体、删除线样式区域的文本、
     */
    var content: String? { get }
}

struct TextProps: TextProtocol  {
    //文字大小，默认14sp，Lynx前端要注意，注意button的字号
    let textSize: CGFloat?
    //文本颜色
    let textColor: String?
    // 文本颜色 token
    var textColorToken: String?
    //文本背景色
    let textBgColor: String?
    // 文本背景色 token
    var textBgColorToken: String?
    //文本对齐
    let align: String?
    // 文本最大行数
    let maxLines: Int?
    /**
     * 文本样式,可以是几种组合
     * strikethrough：删除线
     * underline：下划线
     * bold 粗体
     * italic 斜体
     */
    let textDecoration: [TextDeciration]?
    
    // 文本内容
    var content: String?
}

struct AtProps: TextProtocol {
    //文字大小，默认14sp，Lynx前端要注意，注意button的字号
    let textSize: CGFloat?
    //文本颜色
    let textColor: String?
    // 文本颜色 token
    var textColorToken: String?
    //文本背景色
    let textBgColor: String?
    // 文本背景色 token
    var textBgColorToken: String?
    //文本对齐
    let align: String?
    // 文本最大行数
    let maxLines: Int?
    /**
     * 文本样式,可以是几种组合
     * strikethrough：删除线
     * underline：下划线
     * bold 粗体
     * italic 斜体
     */
    let textDecoration: [TextDeciration]?
    
    // Native 根据 attachment 计算出来的人名
    var content: String?
    
    let userId: String?
}

struct LinkProps: TextProtocol {
    //文字大小，默认14sp，Lynx前端要注意，注意button的字号
    let textSize: CGFloat?
    //文本颜色
    let textColor: String?
    // 文本颜色 token
    var textColorToken: String?
    //文本背景色
    let textBgColor: String?
    // 文本背景色 token
    var textBgColorToken: String?
    //文本对齐
    let align: String?
    // 文本最大行数
    let maxLines: Int?
    /**
     * 文本样式,可以是几种组合
     * strikethrough：删除线
     * underline：下划线
     * bold 粗体
     * italic 斜体
     */
    let textDecoration: [TextDeciration]?
    
    // URL 链接的文本
    var content: String?
    
    // URL 链接地址
    let url: String?
    
    // iOS链接，在iOS Native侧，如果此字段不为空，使用此字段，否则使用href,Android平台不用关心
    let iosUrl: String?
}

struct EmojProps: Decodable {
    let key: String?
}

struct TextTagProps: TextProtocol {
    enum TagStyle: String, Decodable {
        case `default` = "default"
        case table = "table"
    }
    //文字大小，默认14sp，Lynx前端要注意，注意button的字号
    let textSize: CGFloat?
    //文本颜色
    let textColor: String?
    // 文本颜色 token
    var textColorToken: String?
    //文本背景色
    let textBgColor: String?
    // 文本背景色 token
    var textBgColorToken: String?
    //文本对齐
    let align: String?
    // 文本最大行数
    let maxLines: Int?
    /**
     * 文本样式,可以是几种组合
     * strikethrough：删除线
     * underline：下划线
     * bold 粗体
     * italic 斜体
     */
    let textDecoration: [TextDeciration]?
    
    // tag 内容
    var content: String?
    // tag 背景色 Token
    let tagBGColorToken: String?
    // tag 样式类型
    let tagStyle: TagStyle?
}

struct BrProps: Decodable {}

struct HrProps: Decodable {}

struct ListItemProps: Decodable {
    let level: Int?
    let type: ListType?
    let order: Int?
    let items: [ContentProps]?
}

struct ListItemImageProps: Decodable {
    let image_id: String?
    let previewImages: [String]?
}
