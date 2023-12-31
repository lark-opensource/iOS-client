//
//  AddChatterPicker.swift
//  LarkSearchCore
//
//  Created by SolaWing on 2021/1/25.
//

import Foundation
import LarkSDKInterface
import LarkContainer

/// 通过人群部门等各种方式拉人的chatter picker
public class AddChatterPicker: ChatterPicker {
    public class InitParam: ChatterPicker.InitParam {
        // 是否根据拉人场景，对数据进行权限过滤
        public var includeChatForAddChatter = false
        public var includeDepartmentForAddChatter = false
        // 是否在搜索群的时候包含外部租户（因为之前有特化逻辑，在 includeDepartmentForAddChatter 为 true 的时候会过滤外部群，现在增加开关来区别是否需要过滤外部群)
        // Notice: 只有在设置了 includeDepartmentForAddChatter 为 true 以后 includeOuterGroupForChat 才会生效
        public var includeOuterGroupForChat = false
        // 是否可以选群
        public var includeChat = true
        // 是否可以选部门
        public var includeDepartment = true
        // 是否选择可以选人
        public var includeChatter = true
        // 是否可以搜到密盾聊
        public var includeShieldGroup = false
        // 是否可以搜索到全部类型的群组
        public var includeAllChat: Bool?
    }
    @objc public let includeChatForAddChatter: Bool
    @objc public let includeDepartmentForAddChatter: Bool
    @objc public let includeOuterGroupForChat: Bool
    @objc public let includeShieldGroup: Bool
    @objc public var includeChatter: Bool {
        didSet { toggleTypes(type: .chatter, value: includeChatter) }
    }
    @objc public dynamic var includeChat: Bool {
        didSet { toggleTypes(type: .chat, value: includeChat) }
    }
    @objc public dynamic var includeDepartment: Bool {
        didSet { toggleTypes(type: .department, value: includeDepartment) }
    }
    public init(resolver: LarkContainer.UserResolver, frame: CGRect, params: InitParam) {
        includeChatForAddChatter = params.includeChatForAddChatter
        includeDepartmentForAddChatter = params.includeDepartmentForAddChatter
        includeChat = params.includeChat
        includeDepartment = params.includeDepartment
        includeOuterGroupForChat = params.includeOuterGroupForChat
        includeChatter = params.includeChatter
        includeShieldGroup = params.includeShieldGroup
        super.init(resolver: resolver, frame: frame, params: params)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    // MARK: Bind
    public override var searchLocation: String { "AddChatterPicker" }
    override func configure(vm: SearchSimpleVM<Item>) {
        super.configure(vm: vm)
        var context = vm.query.context.value
        context[SearchRequestExcludeTypes.chat] = !includeChat
        context[SearchRequestExcludeTypes.department] = !includeDepartment
        vm.query.context.accept(context)
    }
    override func makeSource() -> SearchSource {
        // note subclass override
        var maker = RustSearchSourceMaker(resolver: self.userResolver, scene: .rustScene(.addChatChatters))
        maker.doNotSearchResignedUser = true // 测试发现这个scene不会返回离职人员，这里设置上方便后续v2兼容
        // 默认选中群里的所有人。使用场景为：群添加人，能搜索到这个人，但已经选中在群里，不需要再添加了
        // Rust会返回meta.inChatIds来标记这个人在哪些群里
        if let chatID = forceSelectedInChatId { maker.inChatID = chatID }
        // 群和部门的配置始终包含，再通过动态context进行开关
        maker.includeChat = true
        maker.includeDepartment = true
        maker.includeChatForAddChatter = includeChatForAddChatter
        maker.includeDepartmentForAddChatter = includeDepartmentForAddChatter
        maker.includeOuterGroupForChat = includeOuterGroupForChat
        maker.includeChatter = includeChatter
        maker.incluedOuterChat = params.includeOuterChat
        maker.includeShieldGroup = includeShieldGroup
        maker.userGroupSceneType = params.userGroupSceneType
        maker.includeUserGroup = includeUserGroup
        maker.configs = contentConfigrations
        let addChatterParams = params as? AddChatterPicker.InitParam
        maker.includeAllChat = addChatterParams?.includeAllChat
        maker.userResignFilter = addChatterParams?.userResignFilter
        maker.includeMyAi = params.includeMyAi
        maker.myAiMustTalked = params.myAiMustTalked
        Self.logger.info("Picker.AddChatter: config: \(contentConfigrations)")
        return maker.makeAndReturnProtocol()
    }
}
