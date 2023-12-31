//
//  SearchIntentionCapsuleView.swift
//  LarkSearch
//
//  Created by ByteDance on 2023/7/10.
//

import LarkSearchFilter
import RxSwift
import RxCocoa
import LarkSearchCore
import LarkSDKInterface
import LarkMessengerInterface
import EENavigator
import LarkUIKit
import UIKit
import Homeric
import UniverseDesignIcon

final class SearchIntentionCapsuleView: UIView {
    static let minimumLineSpacing: CGFloat = 8
    var rightInsetValue: CGFloat = 12
    var leftInsetValue: CGFloat = 12
    let viewModel: SearchIntentionCapsuleViewModel
    let capsuleCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = SearchIntentionCapsuleView.minimumLineSpacing
        layout.minimumInteritemSpacing = SearchIntentionCapsuleView.minimumLineSpacing
        let capsuleCollectionView = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        capsuleCollectionView.backgroundColor = .clear
        capsuleCollectionView.showsVerticalScrollIndicator = false
        capsuleCollectionView.showsHorizontalScrollIndicator = false
        capsuleCollectionView.scrollsToTop = false
        capsuleCollectionView.bounces = true
        capsuleCollectionView.alwaysBounceHorizontal = true
        capsuleCollectionView.register(SearchIntentionCapsuleCell.self, forCellWithReuseIdentifier: SearchIntentionCapsuleCell.identifier)
        if #available(iOS 10.0, *) {
            capsuleCollectionView.isPrefetchingEnabled = false
        }
        if #available(iOS 11.0, *) {
            capsuleCollectionView.contentInsetAdjustmentBehavior = .never
        }
        if #available(iOS 13.0, *) {
            capsuleCollectionView.automaticallyAdjustsScrollIndicatorInsets = false
        }
        return capsuleCollectionView
    }()

    private let disposeBag = DisposeBag()

    public init(withViewModel viewModel: SearchIntentionCapsuleViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        viewModel.capsuleView = self
        addSubview(capsuleCollectionView)
        capsuleCollectionView.delegate = self
        capsuleCollectionView.dataSource = self
        capsuleCollectionView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview().offset(8)
            make.bottom.equalToSuperview().offset(-8)
            make.height.equalTo(SearchIntentionCapsuleCell.viewHeight)
        }
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        capsuleCollectionView.reloadData()
    }

    func capsuleCollectionViewReload(shouldScrollToFocus: Bool = false, focusIndex: Int? = nil, showUnselectedAnimated: Bool = false) {
        UIView.setAnimationsEnabled(false)
        capsuleCollectionView.reloadData()
        capsuleCollectionView.setNeedsLayout()
        capsuleCollectionView.layoutIfNeeded()
        UIView.setAnimationsEnabled(true)
        guard !viewModel.capsuleModels.isEmpty else { return }

        UIView.setAnimationsEnabled(false)
        if shouldScrollToFocus {
            if let _focusIndex = focusIndex, _focusIndex > 0, _focusIndex < viewModel.capsuleModels.count {
                // UICollectionView的复用和回收会导致有时候拿不到cell，算出的偏移量不准确
                capsuleCollectionView.scrollToItem(at: IndexPath(row: _focusIndex, section: 0), at: .left, animated: false)
                capsuleCollectionView.setNeedsLayout()
                capsuleCollectionView.layoutIfNeeded()
                if let cell = capsuleCollectionView.cellForItem(at: IndexPath(row: _focusIndex, section: 0)) {
                    capsuleCollectionView.setContentOffset(CGPoint(x: cell.frame.minX - 24 - Self.minimumLineSpacing, y: 0), animated: false)
                }
            } else {
                capsuleCollectionView.setContentOffset(CGPoint.zero, animated: false)
            }
            capsuleCollectionView.setNeedsLayout()
            capsuleCollectionView.layoutIfNeeded()
        }
        UIView.setAnimationsEnabled(true)

        if showUnselectedAnimated {
            for cell in capsuleCollectionView.visibleCells {
                if let _cell = cell as? SearchIntentionCapsuleCell, let isSelected = _cell.capsuleModel?.isSelected, !isSelected {
                    _cell.alpha = 0
                    UIView.animate(withDuration: 0.3, animations: {
                        _cell.alpha = 1
                    }, completion: { _ in
                        _cell.alpha = 1
                    })
                }
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SearchIntentionCapsuleView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        if let _cell = cell as? SearchIntentionCapsuleCell, let cellModel = _cell.capsuleModel {
            viewModel.clickCell(withCapsuleModel: cellModel, indexPath: indexPath)
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.capsuleModels.count
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if let cellViewModel = viewModel.capsuleModels[safe: indexPath.row] {
            return SearchIntentionCapsuleCell.cellSize(withViewModel: cellViewModel)
        }
        return CGSize(width: SearchIntentionCapsuleCell.viewDefaultWidth, height: SearchIntentionCapsuleCell.viewHeight)
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SearchIntentionCapsuleCell.identifier, for: indexPath)
        if let _cell = cell as? SearchIntentionCapsuleCell,
           let cellViewModel = viewModel.capsuleModels[safe: indexPath.row] {
            _cell.updateCapsuleModel(model: cellViewModel)
            _cell.onLongPressCell = { [weak self] capsuleModel, contentView in
                guard let self = self else { return }
                self.viewModel.longPressCell(withCapsuleModel: capsuleModel, sourceView: contentView)
            }
            _cell.onClickExpandView = { [weak self] capsuleModel in
                guard let self = self else { return }
                self.viewModel.clickCellExpandView(withCapsuleModel: capsuleModel)
            }
            return _cell
        } else {
            return cell
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: leftInsetValue, bottom: 0, right: rightInsetValue)
    }
}
