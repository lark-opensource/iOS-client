//
//  QuickCreateOwnerView.swift
//  Todo
//
//  Created by wangwanxin on 2022/7/29.
//

import CTFoundation
import UniverseDesignIcon
import LarkBizAvatar

protocol QuickCreateOwnerViewDataType {
    var avatars: [AvatarSeed]? { get }
    var text: String? { get }
    var hasClearBtn: Bool { get }
    var hasIcon: Bool { get }
}

final class QuickCreateOwnerView: UIView, ViewDataConvertible {

    var viewData: QuickCreateOwnerViewDataType? {
        didSet {
            guard let viewData = viewData, let avatars = viewData.avatars, let text = viewData.text else {
                isHidden = true
                return
            }
            isHidden = false

            var icon = viewData.hasIcon ? UDIcon.rightOutlined.ud.resized(to: CGSize(width: 14, height: 14)) : nil
            if viewData.hasClearBtn {
                icon = UDIcon.closeOutlined.ud.resized(to: CGSize(width: 14, height: 14))
            }
            let seeds = avatars.map { seed in
                return CheckedAvatarViewData(icon: .avatar(seed))
            }
            let data = AvatarGroupViewData(avatars: seeds, style: .normal)
            ownerConetntView.viewData = DetailUserViewData(avatarData: data, content: text, icon: icon)
            invalidateIntrinsicContentSize()
        }
    }

    var onClearHandler: (() -> Void)? {
        didSet {
            ownerConetntView.onTapIconHandler = { [weak self] in
                guard let self = self, let viewData = self.viewData, viewData.hasClearBtn else {
                    return
                }
                self.onClearHandler?()
            }
        }
    }
    var onContentHandler: (() -> Void)? {
        didSet {
            ownerConetntView.onTapContentHandler = onContentHandler
        }
    }

    private lazy var ownerConetntView = DetailUserContentView(style: .normal)

    override init(frame: CGRect) {
        super.init(frame: .zero)
        addSubview(ownerConetntView)
        ownerConetntView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override var intrinsicContentSize: CGSize {
        guard viewData != nil else { return .zero }
        return ownerConetntView.intrinsicContentSize
    }

}
