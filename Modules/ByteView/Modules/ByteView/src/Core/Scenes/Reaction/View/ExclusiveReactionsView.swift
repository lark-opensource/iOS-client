//
//  ExclusiveReactionsView.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/6/6.
//

import UIKit
import UniverseDesignIcon
import ByteViewSetting

protocol ExclusiveReactionsViewDelegate: AnyObject {
    func exclusiveReactionsView(_ view: ExclusiveReactionsView, didClickItemAt index: Int)
}

class ExclusiveReactionsView: UIView {
    let items: [String] = ExclusiveReactionResource.defaultKeys

    weak var delegate: ExclusiveReactionsViewDelegate?
    weak var longPressDelegate: ReactionCellDelegate?

    private let edgeInset = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)
    private let reactionSize = CGSize(width: 120, height: 30)
    private let maskWidth: CGFloat = 54

    static let cellID = "ExclusiveReactionsCellID"
    private lazy var layout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 16
        return flowLayout
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.isScrollEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(ReactionCell.self, forCellWithReuseIdentifier: Self.cellID)
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        return collectionView
    }()


    private lazy var scrollMaskLeftView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.isHidden = true

        let layer = CAGradientLayer()
        layer.ud.setColors([UIColor.ud.bgFloat, UIColor.ud.bgFloat.withAlphaComponent(0)], bindTo: view)
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 0)
        layer.frame = CGRect(x: 0, y: 0, width: maskWidth, height: reactionSize.height)
        view.layer.addSublayer(layer)
        return view
    }()

    private lazy var scrollMaskRightView: UIView = {
        let view = UIView()
        view.isUserInteractionEnabled = false
        view.isHidden = true

        let layer = CAGradientLayer()
        layer.ud.setColors([UIColor.ud.bgFloat.withAlphaComponent(0), UIColor.ud.bgFloat], bindTo: view)
        layer.startPoint = CGPoint(x: 0, y: 0)
        layer.endPoint = CGPoint(x: 1, y: 0)
        layer.frame = CGRect(x: 0, y: 0, width: maskWidth, height: reactionSize.height)
        view.layer.addSublayer(layer)
        return view
    }()

    private let emotion: EmotionDependency
    init(emotion: EmotionDependency) {
        self.emotion = emotion
        super.init(frame: .zero)
        setupSubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateGradientMaskView(_ scrollView: UIScrollView? = nil) {
        let scrollView = scrollView ?? collectionView
        let bounds = scrollView.bounds
        let contentSize = scrollView.contentSize
        let isLeftHidden = bounds.minX <= 0.1 // 0.1为误差
        let isRightHidden = bounds.minX + bounds.width + 0.1 >= contentSize.width
        if scrollMaskLeftView.isHidden != isLeftHidden {
            scrollMaskLeftView.isHidden = isLeftHidden
        }
        if scrollMaskRightView.isHidden != isRightHidden {
            scrollMaskRightView.isHidden = isRightHidden
        }
    }

    func resetScrollPosition() {
        collectionView.setContentOffset(.zero, animated: false)
    }

    // MARK: - Private
    private func setupSubviews() {
        addSubview(collectionView)
        addSubview(scrollMaskLeftView)
        addSubview(scrollMaskRightView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        scrollMaskLeftView.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
            make.height.equalTo(reactionSize.height)
            make.width.equalTo(maskWidth)
        }
        scrollMaskRightView.snp.makeConstraints { make in
            make.right.centerY.equalToSuperview()
            make.height.equalTo(reactionSize.height)
            make.width.equalTo(maskWidth)
        }
    }

    private func updateCollectionView() {
        layout.invalidateLayout()
        collectionView.reloadData()
    }
}

extension ExclusiveReactionsView: UICollectionViewDelegate, UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.cellID, for: indexPath)
        cell.accessibilityIdentifier = Self.cellID
        if let collectionCell = cell as? ReactionCell {
            collectionCell.emotion = self.emotion
            collectionCell.delegate = longPressDelegate
            collectionCell.reactionKey = items[indexPath.row]
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        delegate?.exclusiveReactionsView(self, didClickItemAt: indexPath.row)
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateGradientMaskView(collectionView)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        updateGradientMaskView(collectionView)
    }
}

extension ExclusiveReactionsView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let size = ExclusiveReactionResource.getExclusiveReaction(by: items[indexPath.row])?.size {
            return CGSize(width: reactionSize.height * size.width / size.height, height: reactionSize.height)
        } else {
            return reactionSize
        }
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        edgeInset
    }
}
