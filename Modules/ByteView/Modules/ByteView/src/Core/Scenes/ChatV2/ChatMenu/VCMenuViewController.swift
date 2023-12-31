//
//  VCMenuViewController.swift
//  ByteView
//
//  Created by chenyizhuo on 2022/2/8.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import UIKit

protocol VCMenuViewControllerDelegate: AnyObject {
    func menuViewDidDismiss(isSelected: Bool)
    func shouldDismissMenuOnTap(in view: UIView, location: CGPoint) -> Bool
}

class VCMenuViewController: AlwaysPortraitViewController {
    private static let cellID = "VCMenuCell"

    weak var delegate: VCMenuViewControllerDelegate?
    var menuLayout: VCMenuLayoutDelegate?
    private var addedToParent = false
    private lazy var tap: UITapGestureRecognizer = {
        let gesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        gesture.delegate = self
        return gesture
    }()

    fileprivate enum Layout {
        static let itemMinimumLineSpacing: CGFloat = 10
        static let itemMinimumInteritemSpacing: CGFloat = 0
        static let menuMargin: CGFloat = 4
        static let itemSize = CGSize(width: 55, height: 72)
    }

    private var items: [VCMenuItem] = []
    private let itemCountPerLine = 5

    private var isHidden = true
    private var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.itemSize = Layout.itemSize
        layout.minimumLineSpacing = Layout.itemMinimumLineSpacing
        layout.minimumInteritemSpacing = Layout.itemMinimumInteritemSpacing
        return layout
    }()

    private(set) lazy var collectionView: UICollectionView = {
        let collection = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.layout)
        collection.backgroundColor = UIColor.ud.bgFloat
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        collection.register(VCMenuCell.self, forCellWithReuseIdentifier: Self.cellID)
        collection.delegate = self
        collection.dataSource = self
        collection.isScrollEnabled = false
        collection.accessibilityIdentifier = "vc.menu.collection"
        return collection
    }()

    private var wrapperView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        return view
    }()

    fileprivate var menuSize: CGSize {
        let width = CGFloat(items.count) * Layout.itemSize.width + 2 * Layout.menuMargin
        let height = CGFloat((items.count + itemCountPerLine - 1) / itemCountPerLine) * Layout.itemSize.height
        return CGSize(width: width, height: height)
    }

    override func loadView() {
        let menuView = VCMenuView()
        menuView.delegate = self
        view = menuView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }

    private func setupSubviews() {
        view.backgroundColor = .clear
        wrapperView.layer.cornerRadius = 10
        wrapperView.layer.shadowOpacity = 1.0
        wrapperView.layer.masksToBounds = true
        wrapperView.layer.shadowOffset = CGSize(width: 0, height: 5)
        wrapperView.layer.shadowRadius = 5
        wrapperView.layer.borderWidth = 1
        wrapperView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        wrapperView.layer.ud.setShadow(type: .s4Down)
        view.addSubview(wrapperView)

        wrapperView.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(4)
        }
    }

    private func layoutMenu() {
        let size = menuSize
        let origin = menuLayout?.layoutMenu(on: self, menuSize: size) ?? .zero
        let frame = CGRect(origin: origin, size: size)
        wrapperView.frame = frame
    }

    private func addGestures() {
        if let parent = parent {
            parent.view.addGestureRecognizer(tap)
        } else {
            view.addGestureRecognizer(tap)
        }
    }

    @objc
    private func handleTap(_ tap: UITapGestureRecognizer) {
        if let view = tap.view, let delegate = delegate, !delegate.shouldDismissMenuOnTap(in: view, location: tap.location(in: view)) {
            return
        }
        dismiss(isSelected: false)
    }
}

extension VCMenuViewController {
    func add(to parent: UIViewController) {
        parent.addChild(self)
        parent.view.addSubview(view)
        didMove(toParent: parent)
        addGestures()
        view.frame = CGRect(x: 0, y: 0, width: parent.view.frame.width, height: parent.view.frame.height)
        show(animated: true)
        addedToParent = true
    }

    // 对外暴露的方法调用的 dismiss 不再回调给调用方，避免逻辑重复
    func dismiss() {
        if let parent = parent {
            parent.view.removeGestureRecognizer(tap)
            self.vc.removeFromParent()
        } else if presentationController != nil {
            super.dismiss(animated: false, completion: nil)
        }
        addedToParent = false
    }

    // 内部 dismiss 需要回调给调用方，以便做一些 cleanup 处理
    private func dismiss(isSelected: Bool) {
        dismiss()
        delegate?.menuViewDidDismiss(isSelected: isSelected)
    }

    func show(animated: Bool) {
        if !isHidden { return }
        isHidden = false
        layoutMenu()
        if animated {
            wrapperView.alpha = 0
            wrapperView.isHidden = false
            wrapperView.layer.removeAllAnimations()
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.15, animations: {
                self.wrapperView.alpha = 1
            })
        } else {
            wrapperView.alpha = 1
            wrapperView.isHidden = false
        }
    }

    func hide(animated: Bool) {
        if isHidden { return }
        isHidden = true
        if !animated {
            wrapperView.isHidden = true
        } else {
            wrapperView.layer.removeAllAnimations()
            // nolint-next-line: magic number
            UIView.animate(withDuration: 0.15, animations: {
                self.wrapperView.alpha = 0
            }, completion: { (_) in
                self.wrapperView.isHidden = self.isHidden
            })
        }
    }

    func updateItems(_ items: [VCMenuItem]) {
        self.items = items
        if addedToParent {
            layoutMenu()
        }
        collectionView.reloadData()
    }
}

extension VCMenuViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let location = gestureRecognizer.location(in: gestureRecognizer.view)
        return !wrapperView.frame.contains(location)
    }
}

extension VCMenuViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.cellID, for: indexPath) as? VCMenuCell else {
            return UICollectionViewCell()
        }
        cell.config(with: items[indexPath.row])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let menuItem = items[indexPath.row]
        menuItem.menuItemDidClick()
        dismiss(isSelected: true)
    }
    func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.ud.fillPressed
    }

    func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.backgroundColor = UIColor.clear
    }
}

extension VCMenuViewController: VCMenuViewDelegate {
    func menuView(_ menu: VCMenuView, shouldRespondTouchAt point: CGPoint) -> VCMenuViewHitTestResult {
        let wrapperViewPoint = menu.convert(point, to: wrapperView)
        if wrapperView.hitTest(wrapperViewPoint, with: nil) != nil {
            return .default
        }
        // 有Menu的时候，建立黑名单屏蔽系统控件的响应
        let controlSet: [AnyClass] = [UIButton.self, UITextView.self, UIImageView.self]
        if let superview = menu.superview {
            let superPoint = menu.convert(point, to: superview)
            if let hitView = superview.hitTest(superPoint, with: nil), controlSet.contains(where: { hitView.isKind(of: $0) }) {
                return .default
            }
        }
        return .ignore
    }
}
