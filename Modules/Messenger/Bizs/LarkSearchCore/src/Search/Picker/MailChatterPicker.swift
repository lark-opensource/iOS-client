//
//  MailChatterPicker.swift
//  LarkSearchCore
//
//  Created by tefeng liu on 2021/8/21.
//

import Foundation
import LarkContainer

public final class MailChatterPicker: AddChatterPicker {
    override var needShowMail: Bool { true }
    public final class InitParam: AddChatterPicker.InitParam {
        // 是否可选邮件联系人
        public var includeMailContact = true
    }

    @objc public dynamic var includeMailContact: Bool {
        didSet { toggleTypes(type: .mailContact, value: includeMailContact) }
    }

    public init(resolver: LarkContainer.UserResolver, frame: CGRect, params: InitParam) {
        includeMailContact = params.includeMailContact
        super.init(resolver: resolver, frame: frame, params: params)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func makeSource() -> SearchSource {
        // note subclass override
        var maker = RustSearchSourceMaker(resolver: self.userResolver, scene: .rustScene(.addChatChatters))
        maker.doNotSearchResignedUser = true // 测试发现这个scene不会返回离职人员，这里设置上方便后续v2兼容
        if let chatID = forceSelectedInChatId { maker.inChatID = chatID }
        maker.includeChat = includeChat
        maker.includeDepartment = includeDepartment
        maker.includeChatForAddChatter = includeChatForAddChatter
        maker.includeDepartmentForAddChatter = includeDepartmentForAddChatter
        maker.includeOuterGroupForChat = includeOuterGroupForChat
        maker.includeChatter = includeChatter
        maker.includeMailContact = includeMailContact
        let addChatterParams = params as? AddChatterPicker.InitParam
        maker.includeAllChat = addChatterParams?.includeAllChat
        return maker.makeAndReturnProtocol()
    }
}
