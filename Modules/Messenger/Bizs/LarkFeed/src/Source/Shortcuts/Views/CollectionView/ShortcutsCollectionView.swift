//
//  ShortcutsCollectionView.swift
//  LarkFeed
//
//  Created by 夏汝震 on 2020/6/15
//

import Foundation
import UIKit
import SnapKit
import RxDataSources
import Differentiator
import RxCocoa
import RxSwift
import LarkUIKit
import LKCommonsLogging

final class ShortcutsCollectionView: UICollectionView {

    let disposeBag = DisposeBag()

    // viewModel
    var viewModel: ShortcutsViewModel

    var moveLayout: InteractiveMovementCollectionViewLayout

    // MARK: subviews
    // 展开更多的按钮
    lazy var expandMoreView: ShortcutExpandMoreView = {
        ShortcutExpandMoreView(frame: .zero, viewModel: viewModel.expandMoreViewModel)
    }()

    // 三个灰色的点，置顶区域下拉的时候有动态效果
    lazy var loadingView: ShortcutsLoadingView = {
        let view = ShortcutsLoadingView()
        view.isUserInteractionEnabled = false
        view.clipsToBounds = true
        return view
    }()

    required init?(coder: NSCoder) {
        fatalError("Not supported")
    }

    init(viewModel: ShortcutsViewModel) {
        self.viewModel = viewModel
        let moveLayout = InteractiveMovementCollectionViewLayout()
        self.moveLayout = moveLayout
        moveLayout.sectionInset = ShortcutLayout.edgeInset
        moveLayout.itemSize = CGSize(width: ShortcutLayout.itemWidth, height: ShortcutLayout.itemHeight)
        moveLayout.scrollDirection = .vertical
        moveLayout.minimumLineSpacing = 0
        moveLayout.minimumInteritemSpacing = ShortcutLayout.minItemSpace

        super.init(frame: .zero, collectionViewLayout: moveLayout)
        setupViews()
        bind()
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        initializeSubviews()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let x = bounds.width - ShortcutLayout.edgeInset.right - ShortcutLayout.itemWidth
        expandMoreView.frame = CGRect(x: x,
                                      y: ShortcutLayout.edgeInset.top,
                                      width: ShortcutLayout.itemWidth,
                                      height: ShortcutLayout.itemHeight)
        viewModel.containerWidth = bounds.width

        var loadingViewRect = loadingView.frame
        loadingViewRect.size.width = bounds.size.width
        loadingView.frame = loadingViewRect
    }

    private func setupViews() {
        self.delegate = self
        self.dataSource = self
        self.backgroundColor = UIColor.ud.bgBody
        self.isScrollEnabled = false  // 如果items间的尺寸得当，可以用这样的方式来控制shortcuts的展示，只需要调整collectionView的frame就可以了
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false

        // 注册cell
        self.register(UICollectionViewCell.self, forCellWithReuseIdentifier: Self.spareCell)
        self.register(ShortcutCollectionCell.self, forCellWithReuseIdentifier: ShortcutCollectionCell.reuseIdentifier)

        // 添加expandMoreView
        self.addSubview(expandMoreView)
        let tapExpandMore = UITapGestureRecognizer(target: self, action: #selector(tapExpandMoreHandler))
        expandMoreView.addGestureRecognizer(tapExpandMore)// 添加点击more的手势

        // 添加拖拽手势
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress))
        self.addGestureRecognizer(longPress)
    }

    private func initializeSubviews() {
        // 添加 loading
        self.superview?.addSubview(loadingView)
        self.superview?.bringSubviewToFront(self)
    }

    deinit {
        loadingView.removeFromSuperview()
    }
}
