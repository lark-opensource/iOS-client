//
//  AvatarView.swift
//  ByteViewUI
//
//  Created by kiri on 2023/2/21.
//

import Foundation
import SnapKit
import ByteViewCommon

public final class AvatarView: UIView {
    private var view: AvatarViewProtocol?

    public convenience init(style: AvatarStyle) {
        self.init(frame: .zero)
        self.updateStyle(style)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
        self.view = UIDependencyManager.dependency?.createAvatarView()
        if let view = self.view {
            addSubview(view)
            view.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        } else {
            fatalError("avatar view has not been implemented")
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 根据图片设置头像
    public func setAvatarInfo(_ avatarInfo: AvatarInfo, size: AvatarSize = .medium) {
        view?.setAvatarInfo(avatarInfo, size: size)
    }

    // 参会人头像设置接口，默认大小40
    public func setTinyAvatar(_ avatarInfo: AvatarInfo) {
        setAvatarInfo(avatarInfo, size: .size(40))
    }

    /// 设置头像样式（圆的还是方的）
    public func updateStyle(_ style: AvatarStyle) {
        view?.updateStyle(style)
    }

    /// for dm in LarkBizAvatar
    public func removeMaskView() {
        view?.removeMaskView()
    }

    /// 设置点击事件
    public func setTapAction(_ action: (() -> Void)?) {
        isUserInteractionEnabled = action != nil
        view?.setTapAction(action)
    }
}
