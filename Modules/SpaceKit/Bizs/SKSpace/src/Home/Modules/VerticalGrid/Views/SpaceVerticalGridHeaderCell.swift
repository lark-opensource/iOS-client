//
//  SpaceVerticalGridHeaderCell.swift
//  SKECM
//
//  Created by Weston Wu on 2020/12/21.
//

import UIKit
import UniverseDesignColor
import UniverseDesignIcon
import SKResource
import RxSwift
import SKUIKit
import RxCocoa

extension SpaceVerticalGridHeaderCell {
    enum Layout {
        static let headerHeight: CGFloat = 44
    }
}

// 写成 cell 不写成 header 是因为不要 header 的吸顶效果，UICollectionView 不支持配置单个 header 的吸顶效果，所以用 cell 来实现
class SpaceVerticalGridHeaderCell: UICollectionViewCell {

    // 实际布局的容器，实际尺寸会比 cell 更大
    private lazy var container: UIView = {
        let view = UIView()
        return view
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .medium)
        return label
    }()

    private lazy var moreImageView: UIImageView = {
        let arrowImageView = UIImageView()
        arrowImageView.image = UDIcon.rightOutlined.withRenderingMode(.alwaysTemplate)
        arrowImageView.tintColor = UDColor.primaryContentDefault
        arrowImageView.contentMode = .scaleAspectFit
        return arrowImageView
    }()

    private lazy var moreLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = UDColor.primaryContentDefault
        label.text = BundleI18n.SKResource.Doc_List_All
        return label
    }()

    private lazy var moreControl: UIControl = {
        let control = UIControl()
        return control
    }()

    private var reuseBag = DisposeBag()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {
        contentView.addSubview(container)
        container.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(Layout.headerHeight)
        }

        container.addSubview(titleLabel)
        container.addSubview(moreControl)

        titleLabel.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
            make.right.equalTo(moreControl.snp.left).offset(-16)
        }

        container.addSubview(moreControl)
        moreControl.snp.makeConstraints { make in
            make.top.bottom.right.equalToSuperview()
        }
        setupMoreControl()

        titleLabel.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        moreControl.setContentCompressionResistancePriority(.required, for: .horizontal)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        moreControl.setContentHuggingPriority(.required, for: .horizontal)
    }

    private func setupMoreControl() {
        moreControl.hitTestEdgeInsets = UIEdgeInsets(top: 0, left: -16, bottom: 0, right: -16)
        moreControl.addSubview(moreImageView)
        moreImageView.snp.makeConstraints { make in
            make.right.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.height.equalTo(16)
        }
        moreControl.addSubview(moreLabel)
        moreLabel.snp.makeConstraints { make in
            make.right.equalTo(moreImageView.snp.left)
            make.left.equalToSuperview()
            make.centerY.equalToSuperview()
        }

        moreLabel.setContentHuggingPriority(.required, for: .horizontal)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        reuseBag = DisposeBag()
    }

    func update(title: String, moreHandler: (() -> Void)?) {
        titleLabel.text = title
        guard let moreHandler = moreHandler else {
            moreControl.isHidden = true
            return
        }
        moreControl.isHidden = false
        moreControl.rx.controlEvent(.touchUpInside).subscribe(onNext: moreHandler).disposed(by: reuseBag)
    }
}
