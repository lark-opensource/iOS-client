//
// Created by maozhixiang.lip on 2022/11/3.
//

import Foundation
import Lynx
import ByteViewUI
import ByteViewCommon

typealias LarkAvatarView = AvatarViewProtocol

class LynxAvatarElement: LynxUI<UIView> {
    static let name = "vc-avatar"

    private var avatarKey: String?
    private var avatarEntityId: String?
    private lazy var avatarView: AvatarView = {
        let view = AvatarView()
        view.isUserInteractionEnabled = true
        return view
    }()

    override var name: String { Self.name }
    override func createView() -> UIView? { avatarView }

    override func frameDidChange() {
        self.avatarView.frame = self.frame
        self.updateAvatar()
    }

    @objc
    static func propSetterLookUp() -> [[String]] {
        [
            ["key", NSStringFromSelector(#selector(setKey(value:requestReset:)))],
            ["entity-id", NSStringFromSelector(#selector(setEntityId(value:requestReset:)))]
        ]
    }


    @objc
    func setKey(value: String, requestReset: Bool) {
        self.avatarKey = value
        self.updateAvatar()
    }

    @objc
    func setEntityId(value: String, requestReset: Bool) {
        self.avatarEntityId = value
        self.updateAvatar()
    }

    func updateAvatar() {
        guard let key = self.avatarKey else { return }
        guard let entityId = self.avatarEntityId else { return }
        self.avatarView.setAvatarInfo(.remote(key: key, entityId: entityId), size: .size(self.frameSize.width))
    }
}
