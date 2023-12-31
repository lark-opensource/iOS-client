//
//  ChatCardOwnerComponent.swift
//  Todo
//
//  Created by 迟宇航 on 2022/7/19.
//

import AsyncComponent
import EEFlexiable
import RichLabel
import UniverseDesignIcon
import LarkBizAvatar
import UIKit
import UniverseDesignFont

/// Bot 卡片 - 负责人模块

// nolint: magic number
final class ChatCardOwnerComponentProps: ASComponentProps {
    var owner: ChatCardOwnerData? {
        get {
            pthread_rwlock_rdlock(&rwLock)
            defer {
                pthread_rwlock_unlock(&rwLock)
            }
            return _owner
        }
        set {
            pthread_rwlock_wrlock(&rwLock)
            defer {
                pthread_rwlock_unlock(&rwLock)
            }
            _owner = newValue
        }

    }

    var rwLock = pthread_rwlock_t()
    var _owner: ChatCardOwnerData?
    override init(key: String? = nil, children: [Component] = []) {
        pthread_rwlock_init(&rwLock, nil)
        super.init()
    }
}

final class ChatCardOwnerComponent<C: Context>: ASComponent<ChatCardOwnerComponentProps, EmptyState, UIView, C> {

    private let iconComponent: UIImageViewComponent<C> = {
        let props = UIImageViewComponentProps()
        let icon = UDIcon.memberOutlined.ud.resized(to: CGSize(width: 14, height: 14))
        props.setImage = { task in
            task.set(image: icon.ud.withTintColor(UIColor.ud.iconN2))
        }
        let style = ASComponentStyle()
        style.width = 16.auto()
        style.height = 16.auto()
        style.marginTop = 14
        style.marginRight = 8
        style.flexShrink = 0
        return UIImageViewComponent(props: props, style: style)
    }()

    private let ownerItemComponent: ChatCardOwnerItemComponent<C> = {
        let style = ASComponentStyle()
        style.height = 24.auto()
        style.marginTop = 10
        return ChatCardOwnerItemComponent(props: .init(), style: style)
    }()

    override init(props: ChatCardOwnerComponentProps, style: ASComponentStyle, context: C? = nil) {
        style.alignContent = .stretch
        style.flexDirection = .row
        super.init(props: props, style: style, context: context)
        setSubComponents([iconComponent, ownerItemComponent])
    }

    override func willReceiveProps(
        _ old: ChatCardOwnerComponentProps,
        _ new: ChatCardOwnerComponentProps
    ) -> Bool {
        guard let owner = new.owner else {
            return true
        }
        let props = old
        props.owner = new.owner
        ownerItemComponent.preferMaxLayoutWidth = preferMaxLayoutWidth
        ownerItemComponent.props = props
        let width = ChatCardOwnerView.viewSize(
            text: new.owner?.name,
            avatarNum: props.owner?.avatarData?.avatars.count ?? 0
        )
        let preferMaxLayoutWidth = preferMaxLayoutWidth ?? 250
        ownerItemComponent.style.width = CSSValue(cgfloat: min(width, preferMaxLayoutWidth))
        return true
    }
}

struct ChatCardOwnerData {
    var avatarData: AvatarGroupViewData?
    var name: String
    var onTap: (() -> Void)?
}

final class ChatCardOwnerItemComponent<C: Context>: ASComponent<ChatCardOwnerComponentProps, EmptyState, ChatCardOwnerView, C> {

    override func create(_ rect: CGRect) -> ChatCardOwnerView {
        return ChatCardOwnerView()
    }

    override func update(view: ChatCardOwnerView) {
        super.update(view: view)
        guard let owner = props.owner else {
            return
        }
        view.viewData = owner
        // 复合子组件的背景色需要在这里设置，在view内部设置无效
        view.backgroundColor = UIColor.ud.bgBodyOverlay
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
    }

    override public var isComplex: Bool { return true }
}

/// 负责人View
final class ChatCardOwnerView: UIView {

    var viewData: ChatCardOwnerData? {
        didSet {
            if let viewData = viewData {
                if let avatarsData = viewData.avatarData {
                    avatarContainer.viewData = avatarsData
                }
                nameLabel.text = viewData.name
                if let ownerTap = viewData.onTap {
                    onTap = ownerTap
                    addGestureRecognizer(tap)
                } else {
                    onTap = nil
                    removeGestureRecognizer(tap)
                }
            }
        }
    }

    var onTap: (() -> Void)?

    private lazy var avatarContainer: AvatarGroupView = {
        return AvatarGroupView(style: style)
    }()
    private lazy var nameLabel: UILabel = {
        let nameLabel = UILabel()
        nameLabel.font = UDFont.systemFont(ofSize: 12)
        nameLabel.textColor = UIColor.ud.textTitle
        nameLabel.numberOfLines = 1
        return nameLabel
    }()
    private lazy var tap: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(onClick))
    }()

    private let style: CheckedAvatarView.Style
    override init(frame: CGRect) {
        self.style = .normal
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(avatarContainer)
        addSubview(nameLabel)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard let count = viewData?.avatarData?.avatars.count else { return }
        let avatarContainerWidth = count > 1 ? 20 + (count - 1) * 18 : 20
        avatarContainer.frame = CGRect(x: 2, y: (bounds.height - 20.0) / 2.0, width: CGFloat(avatarContainerWidth), height: 20.0)
        nameLabel.frame = CGRect(
            x: avatarContainer.frame.maxX + 8,
            y: (bounds.height - 24.0) / 2.0,
            width: bounds.width - avatarContainer.frame.maxX - 16,
            height: 24.0
        )
    }

    @objc
    func onClick() {
        onTap?()
    }
}

extension ChatCardOwnerView {

    /// 通过Label的string计算View的width
    static func viewSize(text: String?, avatarNum: Int) -> CGFloat {
        guard let text = text else { return .zero }
        let nameLabelWidth = (text.size(withAttributes: [.font: UDFont.systemFont(ofSize: 12)])).width
        let avatarContainerWidth = avatarNum > 1 ? 20 + (avatarNum - 1) * 18 : 20
        // 2 + avatarContainerWidth 长度 + 8 + label 长度 + 8
        return ceil(nameLabelWidth) + CGFloat(avatarContainerWidth) + 18
    }
}
