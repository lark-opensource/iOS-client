////
////  ThreadPreviewNavigationBarRightSubModule.swift
////  LarkMessageCore
////
////  Created by ByteDance on 2022/10/13.
////

import UIKit
import Foundation
import LarkOpenChat
import LarkOpenIM
import LarkUIKit
import UniverseDesignColor
import LarkMessengerInterface
import LarkInteraction
import EENavigator
import RxSwift
import RxCocoa
import LarkCore
import LarkAccountInterface
import LarkContainer
import LarkBadge
import LarkSDKInterface
import UniverseDesignToast
import RustPB
import LarkModel
import LKCommonsLogging

final class ThreadPreviewNavigationBarRightSubModule: BaseNavigationBarItemSubModule {
    //右侧区域
    public override var items: [ChatNavigationExtendItem] {
        return _rightItems
    }
    private var _rightItems: [ChatNavigationExtendItem] = []
    private var metaModel: ChatNavigationBarMetaModel?
    private let disposeBag: DisposeBag = DisposeBag()
    private lazy var chatMorePath: Path = {
        return self.context.chatRootPath.chat_more
    }()
    private static let logger = Logger.log(ThreadPreviewNavigationBarRightSubModule.self, category: "ThreadPreviewNavigationBarRightSubModule")

    public override class func canInitialize(context: ChatNavgationBarContext) -> Bool {
        return true
    }

    public override func canHandle(model: ChatNavigationBarMetaModel) -> Bool {
        return true
    }

    public override func handler(model: ChatNavigationBarMetaModel) -> [Module<ChatNavgationBarContext, ChatNavigationBarMetaModel>] {
        return [self]
    }

    public override func modelDidChange(model: ChatNavigationBarMetaModel) {
        self.metaModel = model
    }

    public override func createItems(metaModel: ChatNavigationBarMetaModel) {
        let chat = metaModel.chat
        var items: [ChatNavigationExtendItem] = []
        self.metaModel = metaModel
        self._rightItems = self.buildRigthItems(metaModel: metaModel)
    }

    private func buildRigthItems(metaModel: ChatNavigationBarMetaModel) -> [ChatNavigationExtendItem] {
        var items: [ChatNavigationExtendItem] = []
        let chat = metaModel.chat
        items.append(self.groupMemberItem)
        return items
    }

    lazy private var groupMemberItem: ChatNavigationExtendItem = {
        let addNewBtn = UIButton()
        addNewBtn.addPointerStyle()
        let image = ChatNavigationBarItemTintColor.tintColorFor(image: Resources.icon_group,
                                                                style: self.context.navigationBarDisplayStyle())
        addNewBtn.setImage(image, for: .normal)
        addNewBtn.addTarget(self, action: #selector(groupMemberItemClicked(sender:)), for: .touchUpInside)
        return ChatNavigationExtendItem(type: .groupMember, view: addNewBtn)
    }()

    @objc
    private func groupMemberItemClicked(sender: UIButton) {
        guard let metaModel = self.metaModel else {
            return
        }
        let vc = self.context.chatVC()
        let chat = metaModel.chat
        let body = GroupChatterDetailBody(chatId: chat.id,
                                          isShowMulti: false,
                                          isAccessToAddMember: false,
                                          isAbleToSearch: false,
                                          useLeanCell: true)
        self.context.nav.push(body: body, from: vc)
    }
}
