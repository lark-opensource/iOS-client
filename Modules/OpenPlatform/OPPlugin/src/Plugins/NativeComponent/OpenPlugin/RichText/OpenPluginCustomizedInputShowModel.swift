//
//  OpenPluginCustomizedInputShowModel.swift
//  LarkOpenApis
//
//  GENERATED BY ANYCODE. DO NOT MODIFY!!!
//  TICKETID: 27827
//
//  类型声明默认为internal, 如需被外部Module引用, 请在上行添加
//  /** anycode-lint-ignore */
//  public
//  /** anycode-lint-ignore */

import Foundation
import LarkOpenAPIModel


// MARK: - OpenPluginCustomizedInputShowRequest
final class OpenPluginCustomizedInputShowRequest: OpenAPIBaseParams {
    
    /// description: @选择联系人列表，为空时不显示
    @OpenAPIOptionalParam(
            jsonKey: "at")
    public var at: [AtItem]?
    
    /// description: 头像图片地址，为空时不显示，当userModelSelect为空时也不显示
    @OpenAPIOptionalParam(
            jsonKey: "avatar")
    public var avatar: String?
    
    /// description: 文本内容
    @OpenAPIOptionalParam(
            jsonKey: "content")
    public var content: String?
    
    /// description: 内容为空是否允许发送
    @OpenAPIRequiredParam(
            userOptionWithJsonKey: "enablesReturnKey",
            defaultValue: false)
    public var enablesReturnKey: Bool
    
    /// description: 图片地址列表，目前只支持传入一个图片
    @OpenAPIOptionalParam(
            jsonKey: "picture")
    public var picture: [String]?
    
    /// description: 描述文本内容预期值的提示信息
    @OpenAPIOptionalParam(
            jsonKey: "placeholder")
    public var placeholder: String?
    
    /// description: 是否显示表情面板
    @OpenAPIRequiredParam(
            userOptionWithJsonKey: "showEmoji",
            defaultValue: false)
    public var showEmoji: Bool
    
    /// description: 头像右侧pickerView，为空时不显示
    @OpenAPIOptionalParam(
            jsonKey: "userModelSelect")
    public var userModelSelect: UserModelSelectObject?
    
    /// description: 是否允许选择外部联系人
    @OpenAPIOptionalParam(
            jsonKey: "externalContact")
    public var externalContact: Bool?
    
    /// description: 事件回调的 eventName
    @OpenAPIOptionalParam(
            jsonKey: "eventName")
    public var eventName: String?
    
    public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
        return [_at, _avatar, _content, _enablesReturnKey, _picture, _placeholder, _showEmoji, _userModelSelect, _externalContact, _eventName]
    }

    // MARK: AtItem
    final class AtItem: OpenAPIBaseParams {

        /// description: 标识联系人的openID
        @OpenAPIOptionalParam(
            jsonKey: "id")
        public var id: String?

        /// description: @联系人 所占文本长度
        @OpenAPIOptionalParam(
            jsonKey: "length")
        public var length: Int?

        /// description: 联系人名字
        @OpenAPIOptionalParam(
            jsonKey: "name")
        public var name: String?

        /// description: @联系人所占文本在文本内容中的位置
        @OpenAPIOptionalParam(
            jsonKey: "offset")
        public var offset: Int?

        public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
            return [_id, _length, _name, _offset]
        }
    }

    // MARK: UserModelSelectObject
    final class UserModelSelectObject: OpenAPIBaseParams {

        /// description: pickerView选中的值
        @OpenAPIOptionalParam(
            jsonKey: "data")
        public var data: String?

        /// description: pickerView可选择的值
        @OpenAPIOptionalParam(
            jsonKey: "items")
        public var items: [String]?

        public override var autoCheckProperties: [OpenAPIParamPropertyProtocol] {
            return [_data, _items]
        }
    }
}
