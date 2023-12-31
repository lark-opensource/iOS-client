//
//  AIAvatarPickerView.swift
//  LarkAI
//
//  Created by Hayden on 2023/5/26.
//

import UIKit
import FigmaKit

class AIAvatarPickerView: UIView, WheeledCollectionDataDelegate {

    var presetAvatars: [AvatarInfo]

    var currentSelectedIndex: Int = 0

    func reloadData() {
        avatarScrollView.reloadData()
    }

    func playInitAnimation(completion: ((Bool) -> Void)? = nil) {
        if let defaultCell = avatarScrollView.cellForItem(at: IndexPath(item: 0, section: 0)) as? AvatarPickerCell {
            defaultCell.avatarView.playIntroDefault(completion: completion)
        }
    }

    var currentAvatarImage: UIImage? {
        guard let avatarCell = avatarScrollView.cellForItem(at: IndexPath(item: currentSelectedIndex, section: 0)) as? AvatarPickerCell else {
            return nil
        }
        return avatarCell.avatarView.avatarImage
    }

    private lazy var container = UIView()

    private lazy var titleLabel: UILabel = {
        let view = UILabel()
        view.text = BundleI18n.LarkAI.MyAI_IM_Onboarding_ChooseAvatar_Text
        view.font = Cons.labelFont
        view.textColor = .ud.textCaption
        view.textAlignment = .center
        return view
    }()

    private var dataSource: WheeledCollectionDataSource<AvatarPickerCell>?

    private lazy var avatarScrollView: UICollectionView = {
        // 无法设定 Cell 间距，所以要把间距算进 Cell 里
        let cellSize = WheeledCollectionCellSize(
            normalWidth: Cons.avatarSmallSize + Cons.avatarCellSpacing,
            centerWidth: Cons.avatarMiddleSize + Cons.avatarCellSpacing,
            normalHeight: Cons.avatarSmallSize,
            centerHeight: Cons.avatarMiddleSize
        )
        let layout = WheeledCollectionFlowLayout(cellSize: cellSize)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        let dataSource = WheeledCollectionDataSource<AvatarPickerCell>(collectionView: collectionView, cellSize: cellSize)
        dataSource.items = presetAvatars
        dataSource.delegate = self
        collectionView.register(AvatarPickerCell.self, forCellWithReuseIdentifier: String(describing: AvatarPickerCell.self))
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.decelerationRate = .fast
        collectionView.backgroundColor = .clear
        collectionView.delegate = dataSource
        collectionView.dataSource = dataSource
        self.dataSource = dataSource
        return collectionView
    }()

    //头像选择组件下面的阴影
    lazy var shadowView: UIView = {
        let view = RadialGradientView()
        view.colors = shadowColors
        return view
    }()

    init(presetAvatars: [AvatarInfo]) {
        self.presetAvatars = presetAvatars
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        addSubview(container)
        container.addSubview(titleLabel)
        container.addSubview(avatarScrollView)
        container.addSubview(shadowView)
        container.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.trailing.equalToSuperview()
            make.top.greaterThanOrEqualToSuperview()
            make.bottom.lessThanOrEqualToSuperview()
        }
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Cons.vMargin)
            make.left.equalToSuperview().offset(Cons.hMargin)
            make.right.equalToSuperview().offset(-Cons.hMargin)
            make.height.greaterThanOrEqualTo(Cons.labelHeight)
        }
        avatarScrollView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Cons.labelAvatarSpacing)
            make.left.right.equalToSuperview()
            make.height.equalTo(Cons.avatarMiddleSize)
        }
        shadowView.snp.makeConstraints { make in
            make.top.equalTo(avatarScrollView.snp.bottom).offset(Cons.shadowAvatarSpacing)
            make.centerX.equalToSuperview()
            make.width.equalTo(Cons.shadowMiddleWidth)
            make.height.equalTo(Cons.shadowMiddleHeight)
            make.bottom.equalToSuperview().offset(-Cons.vMargin)
        }
        avatarScrollView.reloadData()
    }

    func cellSelected(_ index: Int) {
        self.currentSelectedIndex = index
    }

    func setSelectedItem(_ index: Int, animated: Bool) {
        if animated {
            dataSource?.selectItem(atIndex: index)
        } else {
            avatarScrollView.selectItem(at: IndexPath(item: index, section: 0), animated: false, scrollPosition: .centeredHorizontally)
            dataSource?.selectItem(atIndex: index)
        }
    }
}

class AvatarPickerCell: UICollectionViewCell, WheeledCollectionCell {

    var item: AvatarInfo? {
        didSet {
            guard let item = item else { return }
            setAvatarInfo(item)
        }
    }

    let avatarView = AIAnimatedAvatarView(avatarInfo: nil, isDynamic: false)

    func setAvatarInfo(_ value: AvatarInfo?) {
        avatarView.setData(avatarInfo: value, isDynamic: false)
        if value == .default {
            avatarView.setToDefaultAvatarHalo()
        } else {
            avatarView.setToPortraitAvatarHalo()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(avatarView)
        avatarView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            // 无法设定 Cell 间距，所以要把间距算进 Cell 里
            make.left.equalToSuperview().offset(AIAvatarPickerView.Cons.avatarCellSpacing / 2)
            make.right.equalToSuperview().offset(-AIAvatarPickerView.Cons.avatarCellSpacing / 2)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        avatarView.stopAnimation()
    }
}

extension AIAvatarPickerView {
    enum Cons {
        static let vMargin: CGFloat = 12    // UI 元素离组件边缘的垂直距离
        static let hMargin: CGFloat = 16    // UI 元素离组件边缘的水平距离

        static let avatarPickerCenterYOffsetWhenKeyboardFold: CGFloat = 131

        static let labelHeight: CGFloat = 20
        static var labelFont: UIFont { UIFont.ud.body2(.fixed) }
        static let labelAvatarSpacing: CGFloat = 24

        static let avatarCellSpacing: CGFloat = 16  // 头像之间的间距
        static let avatarSmallSize: CGFloat = 72    // 头像未选中时的 size
        static let avatarMiddleSize: CGFloat = 120  // 头像选中放大状态的 size
        static let avatarLargeSize: CGFloat = 200   // 头像选中并放大后的 size

        static let shadowAvatarSpacing: CGFloat = 24
        static let shadowMiddleWidth: CGFloat = 120
        static let shadowMiddleHeight: CGFloat = 20
        static let shadowLargeWidth: CGFloat = 200
        static let shadowLargeHeight: CGFloat = 20
    }
}
