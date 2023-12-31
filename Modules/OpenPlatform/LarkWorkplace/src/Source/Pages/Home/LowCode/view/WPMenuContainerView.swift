//
//  WPMenuContainerView.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2021/7/14.
//

import LarkUIKit
import LKCommonsLogging

private let kContainerRadius: CGFloat = 8

/// 操作菜单容器view
final class WPMenuContainerView: UIView {
    static let logger = Logger.log(WPMenuContainerView.self)

    var dismiss: (() -> Void)?
    weak var host: ActionMenuHost?
    /// 菜单选项数据
    private var options: [ActionMenuItem] = []
    /// 菜单选项宽度
    private let itemWidth: CGFloat
    /// 容器view
    private lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.clipsToBounds = true
        view.layer.cornerRadius = kContainerRadius
        view.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        view.layer.borderWidth = WPUIConst.BorderW.pt0_5
        return view
    }()

    /// 列表view
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .vertical
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.ud.bgFloat
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(ActionItemView.self, forCellWithReuseIdentifier: ActionItemView.cellID)
        collectionView.contentInset = UIEdgeInsets(
            top: WPMenuConfig.topInset,
            left: 0,
            bottom: WPMenuConfig.bottomInset,
            right: 0
        )
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.bounces = false
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()

    init(frame: CGRect, dismiss: (() -> Void)?) {
        self.itemWidth = frame.width
        self.dismiss = dismiss
        super.init(frame: frame)
        self.setupViews()
    }

    /// 设置数据
    func setData(options: [ActionMenuItem], host: ActionMenuHost?, isNeedScrollerBar: Bool, isNeedShadow: Bool) {
        self.options = options
        self.host = host
        self.collectionView.showsVerticalScrollIndicator = isNeedScrollerBar
        if isNeedShadow {
            self.layer.shadowOffset = CGSize(width: 0, height: 6)
            self.layer.shadowRadius = 16
            self.layer.shadowPath = CGPath(
                roundedRect: self.bounds,
                cornerWidth: kContainerRadius,
                cornerHeight: kContainerRadius,
                transform: nil
            )
            self.layer.ud.setShadowColor(UIColor.ud.shadowDefaultMd)
            self.layer.shadowOpacity = 1
        }
        // 如果展示滚动条，那视图上下有间距（sectionInset）
        refreshInset()
        self.collectionView.reloadData()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        self.clipsToBounds = false
        self.backgroundColor = .clear

        addSubview(containerView)
        containerView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        containerView.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    private func refreshInset() {
        if collectionView.showsVerticalScrollIndicator {
            collectionView.snp.remakeConstraints { (make) in
                make.top.equalToSuperview().offset(WPMenuConfig.topInset)
                make.bottom.equalToSuperview().offset(-WPMenuConfig.bottomInset)
                make.left.right.equalToSuperview()
            }
        } else {
            collectionView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }
}

extension WPMenuContainerView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return options.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: ActionItemView.cellID, for: indexPath)
        guard let menuCell = cell as? ActionItemView else {
            return cell
        }
        guard indexPath.row < options.count else {
            Self.logger.error("get menu item info failed with indexPath:\(indexPath)")
            return cell
        }
        let option = options[indexPath.row]
        menuCell.refresh(item: option, hideDivider: indexPath.row == 0)

        return menuCell
    }
}

extension WPMenuContainerView: UICollectionViewDelegateFlowLayout {
    /// 设置每个item大小
    func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: self.itemWidth, height: WPMenuConfig.MenuSolidHeight)
    }
}

extension WPMenuContainerView: UICollectionViewDelegate {
    /// item点击事件
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        Self.logger.info("user tap action item")
        collectionView.deselectItem(at: indexPath, animated: true)
        guard indexPath.row < options.count else {
            Self.logger.error("get menu item info failed with indexPath:\(indexPath)")
            return
        }
        host?.onMenuItemTap(item: options[indexPath.row])
        dismiss?()
    }
}

/// 操作选项view
final class ActionItemView: UICollectionViewCell {
    static let cellID: String = "actionCell"
    static let iconEdge: CGFloat = 20
    /// 图标
    private var iconView: UIImageView = {
        let iconView = UIImageView()
        iconView.clipsToBounds = true
        iconView.contentMode = .scaleAspectFit
        return iconView
    }()
    /// 文案
    private var labelView: UILabel = {
        let view = UILabel()
        view.textColor = UIColor.ud.textTitle
        view.font = .systemFont(ofSize: 16)
        return view
    }()
    private var disableHighlight = true

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        guard !disableHighlight else {
            return
        }
        backgroundColor = UIColor.ud.fillHover
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        guard !disableHighlight else {
            return
        }
        backgroundColor = UIColor.clear
    }

    private func setupViews() {
        addSubview(iconView)
        iconView.snp.makeConstraints { (make) in
            make.width.height.equalTo(Self.iconEdge)
            make.centerY.equalToSuperview()
            make.left.equalToSuperview().offset(16)
        }
        addSubview(labelView)
        labelView.snp.makeConstraints { (make) in
            make.centerY.equalToSuperview()
            make.left.equalTo(iconView.snp.right).offset(12)
            make.right.equalToSuperview().offset(-16)
        }
    }

    func refresh(item: ActionMenuItem, hideDivider: Bool) {

        let disable: Bool = item.disableTip != nil

        disableHighlight = disable

        labelView.text = item.name
        let tintColor = disable ? UIColor.ud.textDisabled : UIColor.ud.textTitle
        labelView.textColor = tintColor

        if !item.iconUrl.isEmpty {
            let imgUrl = item.iconUrl
            if (imgUrl.hasPrefix("https://") || imgUrl.hasPrefix("http://")), let url = URL(string: imgUrl) {
                // URL 格式图片
                iconView.kf.setImage(with: url)
            } else {
                iconView.bt.setLarkImage(with: .avatar(
                    key: imgUrl,
                    entityID: "",
                    params: .init(sizeType: .size(Self.iconEdge))
                ))
            }
        } else {
            let iconColor = disable ? UIColor.ud.iconDisabled : UIColor.ud.iconN2
            iconView.image = item.iconResource?.ud.withTintColor(iconColor)
        }
    }
}
