//
//  WebExtensionController.swift
//  Lark
//
//  Created by lichen on 2017/4/26.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import LarkBadge
import SnapKit
import UIKit
import FigmaKit

public final class WebExtensionController: UIViewController {

    class ContainerView: UIView {
        
        private lazy var shape: CAShapeLayer = {
            let shape = CAShapeLayer()
            return shape
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            
            layer.mask = shape
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()

            shape.bounds = bounds
            shape.position = bounds.center
            shape.path = UIBezierPath(roundedRect: bounds, byRoundingCorners: [.topLeft, .topRight], cornerRadii: CGSize(width: 10, height: 10)).cgPath
        }
    }
    
    public var items: [WebExtensionItem] = [] {
        didSet {
            self.collection.reloadData()
        }
    }
    
    private struct Layout {
        static let height: CGFloat = 128
        static let itemWidth: CGFloat = 64
        static let itemHeight: CGFloat = 84
    }

    private let layout = UICollectionViewFlowLayout()
    private lazy var collection: UICollectionView = {
        let collection = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
        collection.backgroundColor = UIColor.clear
        collection.showsHorizontalScrollIndicator = false
        collection.showsVerticalScrollIndicator = false
        collection.register(WebExtensionCell.self, forCellWithReuseIdentifier: String(describing: WebExtensionCell.self))
        collection.delegate = self
        collection.dataSource = self
        collection.bounces = false
        return collection
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(BundleI18n.LarkLive.Common_G_FromView_CancelButton, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 16)
        button.setTitleColor(UIColor.ud.N950, for: .normal)
        button.addTarget(self, action: #selector(objc_dismissAnimate), for: .touchUpInside)
        return button
    }()
    
    let containerView = ContainerView()
    private lazy var blurView: VisualBlurView = {
        let blurView = VisualBlurView()
        blurView.blurRadius = 54
        blurView.fillColor = UIColor.ud.bgFloatBase
        blurView.fillOpacity = 0.85
        return blurView
    }()
    
    private lazy var bottomBgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.clear
        view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { maker in
            maker.top.left.right.equalToSuperview()
            maker.height.equalTo(48)
        }
        return view
    }()
    
    private lazy var lineSep: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault.withAlphaComponent(0.15)
        return view
    }()
    
    private lazy var bgView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgMask
        return view
    }()

    public init(items: [WebExtensionItem]) {
        self.items = items
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIApplication.shared.statusBarOrientation.isLandscape ? .landscapeRight : .portrait
    }

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.clear
        view.addSubview(bgView)
        view.addSubview(containerView)
        containerView.addSubview(blurView)
        containerView.addSubview(collection)
        containerView.addSubview(bottomBgView)
        containerView.addSubview(lineSep)
        
        bgView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        blurView.snp.makeConstraints { maker in
            maker.edges.equalToSuperview()
        }
        collection.snp.remakeConstraints { make in
            make.left.right.top.equalToSuperview()
            make.height.equalTo(WebExtensionController.Layout.height)
        }
        lineSep.snp.makeConstraints { maker in
            maker.height.equalTo(0.5)
            maker.top.equalTo(collection.snp.bottom)
            maker.left.right.equalToSuperview()
        }
        bottomBgView.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(collection.snp.bottom)
            maker.height.equalTo(82)
            maker.bottom.equalToSuperview()
        }
        layoutSubviewsToBottomState()
        
        
        let itemSize = CGSize(width: WebExtensionController.Layout.itemWidth, height: WebExtensionController.Layout.itemHeight)
        var sectionInset = UIEdgeInsets(top: 32, left: 12, bottom: 12, right: -12)
//        if UIApplication.shared.statusBarOrientation.isLandscape {
//            sectionInset = UIEdgeInsets(top: 0, left: 62, bottom: 0, right: -62)
//        }
        layout.minimumLineSpacing = UIApplication.shared.statusBarOrientation.isLandscape ? 16: 6
        layout.scrollDirection = .horizontal
        layout.sectionInset = sectionInset
        layout.itemSize = itemSize

        
        let tap = UITapGestureRecognizer(target: self, action: #selector(objc_dismissAnimate))
        tap.delegate = self
        view.addGestureRecognizer(tap)
    }
    
    public func show(animated: Bool = true, completion: (() -> Void)? = nil) {
        if animated {
            UIView.animate(withDuration: 0.25, animations: {
                self.layoutSubviewsToNormalState()
                self.view.layoutIfNeeded()
            }, completion: { _ in
                completion?()
            })
        } else {
            layoutSubviewsToNormalState()
            completion?()
        }
    }

    @objc
    func objc_dismissAnimate() {
        dismissAnimate(completion: nil)
    }

    func dismissAnimate(completion: (() -> Void)?) {
        UIView.animate(withDuration: 0.25, animations: {
            self.layoutSubviewsToBottomState()
            self.view.layoutIfNeeded()
        }, completion: { _ in
            self.dismiss(animated: false, completion: completion)
        })
    }

    private func layoutSubviewsToBottomState() {
        bgView.alpha = 0
        containerView.snp.remakeConstraints { maker in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(view.snp.bottom)
        }
    }
    
    private func layoutSubviewsToNormalState() {
        bgView.alpha = 1
        containerView.snp.remakeConstraints { maker in
            maker.left.right.bottom.equalToSuperview()
        }
    }
}

extension WebExtensionController: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.location(in: view)
        if view.convert(collection.bounds, from: collection).contains(point) {
            return false
//        } else if view.convert(cancelButton.bounds, from: cancelButton).contains(point) {
//            return false
        }
        return true
    }
}

extension WebExtensionController: UICollectionViewDelegate, UICollectionViewDataSource {
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        dismissAnimate {
            let item = self.items[indexPath.row]
            item.clickCallback()
        }
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let item = self.items[indexPath.row]

        let name = String(describing: WebExtensionCell.self)
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: name, for: indexPath)
        if let collectionCell = cell as? WebExtensionCell {
            collectionCell.item = item
        }
        return cell
    }
    
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
//        var sectionInset = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: -18)
//        if UIApplication.shared.statusBarOrientation.isLandscape {
//            sectionInset = UIEdgeInsets(top: 0, left: 62, bottom: 0, right: -62)
//        }
//        return sectionInset
//    }
}
