//
//  GadgetGroupHeaderView.swift
//  LarkWorkplace
//
//  Created by  bytedance on 2020/5/9.
//

import LarkUIKit
import RxSwift
import LarkBadge
import LarkInteraction
import UniverseDesignIcon
/// 分组的组名header
final class GadgetGroupHeaderView: UICollectionReusableView, BadgeUpdateProtocol {
    var disposeBag: DisposeBag = DisposeBag()
    /// badgekey
    var badgeKey: WorkPlaceBadgeKey? {
        didSet {
            onBadgeUpdate()
        }
    }
    /// 分组标题
    private lazy var titleLabel: UILabel = {
        let headerLabel = UILabel()
        headerLabel.font = .systemFont(ofSize: 16, weight: .medium)
        headerLabel.textColor = UIColor.ud.textTitle
        headerLabel.numberOfLines = 1
        headerLabel.textAlignment = .left
        return headerLabel
    }()

    /// 分组折叠展开容器
    private lazy var foldContainer: UIView = {
        UIView()
    }()

    /// 分组折叠图标
    private lazy var foldIcon: UIImageView = {
        UIImageView()
    }()

    /// 分组折叠文案
    private lazy var foldLabel: UILabel = {
        let foldLabel = UILabel()
        foldLabel.font = .systemFont(ofSize: 12)
        foldLabel.textColor = UIColor.ud.primaryContentDefault
        foldLabel.numberOfLines = 1
        foldLabel.textAlignment = .center
        return foldLabel
    }()
    /// badge
    private lazy var badgeView: UIView = {
        let badge = UIView()
        badge.backgroundColor = UIColor.ud.colorfulRed
        badge.layer.cornerRadius = 4
        badge.clipsToBounds = true
        badge.alpha = 0
        return badge
    }()
    /// 折叠点击事件
    var foldCallback: (() -> Void)?

    // MARK: view initial
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        observeBadgeUpdate()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(titleLabel)
        addSubview(foldContainer)
        foldContainer.addSubview(foldLabel)
        foldContainer.addSubview(foldIcon)
        addSubview(badgeView)
        self.backgroundColor = UIColor.ud.bgBody
        setGestureRecognizer()
        setConstraint()
        foldContainer.addPointer(
            .init(
                effect: .highlight,
                shape: { (size) -> PointerInfo.ShapeSizeInfo in
                    return (CGSize(width: size.width, height: 36), highLightCorner)
                }
            )
        )
    }

    private func setGestureRecognizer() {
        foldContainer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handClick)))
    }

    private func setConstraint() {
        foldContainer.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-4)
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
        }
        foldIcon.snp.makeConstraints { (make) in
            make.right.equalToSuperview().offset(-12)
            make.centerY.equalToSuperview()
            make.height.width.equalTo(14)
        }
        foldLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(12)
            make.right.equalTo(foldIcon.snp.left).offset(-8)
            make.centerY.equalToSuperview()
            make.height.equalTo(20)
        }
        badgeView.snp.makeConstraints { (make) in
            make.centerX.equalTo(foldLabel.snp.right)
            make.centerY.equalTo(foldLabel.snp.top)
            make.size.equalTo(CGSize(width: 8, height: 8))
        }
        titleLabel.snp.makeConstraints { (make) in
            make.left.equalToSuperview().inset(16)
            make.right.lessThanOrEqualTo(foldLabel.snp.left).offset(-12)
            make.centerY.equalToSuperview()
        }
        foldLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    @objc
    private func handClick() {
        foldCallback?()
    }

    /// 更新headerView折叠状态
    /// - Parameter state: 状态值
    private func updateStateView(to state: SectionState) {
        switch state {
        case .fold(let count):
            foldLabel.isHidden = false
            foldIcon.isHidden = false
            foldLabel.text = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_ViewAll(count)
            foldIcon.image = UDIcon.downOutlined.ud.withTintColor(UIColor.ud.primaryContentDefault)
        case .unfold:
            foldLabel.isHidden = false
            foldIcon.isHidden = false
            foldLabel.text = BundleI18n.LarkWorkplace.OpenPlatform_AppCenter_CollapseBttn
            foldIcon.image = UDIcon.upOutlined.ud.withTintColor(UIColor.ud.primaryContentDefault)
        case .none:
            foldLabel.isHidden = true
            foldIcon.isHidden = true
            foldLabel.text = nil
            foldIcon.image = nil
        }
        badgeView.isHidden = (foldLabel.text == nil)
    }

    func updateData(groupTitle: String, state: SectionState, foldClick: @escaping () -> Void) {
        titleLabel.text = groupTitle
        updateStateView(to: state)
        self.foldCallback = foldClick
    }
    func onBadgeUpdate() {
        DispatchQueue.main.async {
            if let badge = self.getBadge(), badge > 0 {
                // 存在basge的信息
                self.badgeView.alpha = 1
            } else {
                // 不存在badge
                self.badgeView.alpha = 0
            }
        }
    }
}
