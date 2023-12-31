//
//  RecentsListView.swift
//  AnimatedTabBar
//
//  Created by Hayden on 2023/5/11.
//

import UIKit
import LarkTab
import FigmaKit
import UniverseDesignIcon
import UniverseDesignMenu
import UniverseDesignColor
import LKCommonsTracker
import Homeric

/// iPhone 上的 “最近打开” 列表视图，iPad 上可以使用其他的实现。
final class RecentListView: UIView {

    private lazy var parentMaskView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.2)
        return view
    }()

    private lazy var blurView: VisualBlurView = {
        let blurView = VisualBlurView()
        blurView.fillColor = UIColor.ud.bgFloat
        blurView.blurRadius = 40.0
        blurView.fillOpacity = 0.85
        return blurView
    }()

    private lazy var auroraView = QuickLaunchAuroraView()

    private lazy var navigationBar = UIView()

    private lazy var backButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.getIconByKey(.leftOutlined, iconColor: UIColor.ud.iconN1), for: .normal)
        return button
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.ud.title3(.fixed)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .vertical
        flowLayout.sectionInset = .zero
        flowLayout.minimumLineSpacing = 0
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.scrollDirection = .vertical

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.bounces = true
        collectionView.alwaysBounceVertical = true
        collectionView.showsVerticalScrollIndicator = true
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: MainTabBar.Layout.stackHeight * 2, right: 0)
        collectionView.lu.register(cellWithClass: RecentsListCell.self)
        return collectionView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubviews() {
        addSubview(parentMaskView)
        addSubview(blurView)
        addSubview(auroraView)
        addSubview(navigationBar)
        addSubview(collectionView)
        navigationBar.addSubview(backButton)
        navigationBar.addSubview(titleLabel)
    }

    private func setupConstraints() {
        parentMaskView.snp.makeConstraints { make in
            make.trailing.equalTo(self.snp.leading)
            make.top.bottom.width.equalToSuperview()
        }
        blurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        auroraView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        navigationBar.snp.makeConstraints { make in
            make.top.equalTo(safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(48)
        }
        collectionView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom)
        }
        backButton.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.leading.equalToSuperview().offset(24)
            make.width.height.equalTo(24)
        }
        titleLabel.snp.makeConstraints { make in
            make.leading.greaterThanOrEqualTo(backButton.snp.trailing).offset(12)
            make.center.equalToSuperview()
        }
    }

    private func setupAppearance() {
        titleLabel.text = BundleI18n.AnimatedTabBar.Lark_SuperApp_More_Recents_Title
        backButton.addTarget(self, action: #selector(dismiss), for: .touchUpInside)
        let edgePan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(screenEdgeSwiped))
        edgePan.edges = .left
        addGestureRecognizer(edgePan)
    }

    func show(in parentView: UIView, belowView: UIView? = nil) {
        Tracker.post(TeaEvent(Homeric.NAVIGATION_RECENT_LIST_VIEW))
        if let belowView = belowView {
            parentView.insertSubview(self, belowSubview: belowView)
        } else {
            parentView.addSubview(self)
        }
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.layoutIfNeeded()
        self.parentMaskView.alpha = 0
        self.transform = CGAffineTransform(translationX: parentView.bounds.width, y: 0)
        UIView.animate(withDuration: animationDuration, animations: {
            self.transform = .identity
            self.parentMaskView.alpha = 1
        })
    }

    @objc
    private func dismiss() {
        UIView.animate(withDuration: animationDuration, animations: { [weak self] in
            guard let self = self else { return }
            self.processDismiss(progress: 1.0)
        }, completion: { [weak self] _ in
            self?.removeFromSuperview()
        })
    }

    /// 打开、关闭的动画时间
    private var animationDuration: TimeInterval { 0.25 }

    @objc
    private func screenEdgeSwiped(_ gesture: UIScreenEdgePanGestureRecognizer) {
        // 计算滑动进度
        var progress: CGFloat = 0
        switch gesture.state {
        case .began:
            break
        default:
            let translation = gesture.translation(in: self)
            progress = min(1, max(0, (translation.x / bounds.width)))
        }

        // 根据进度处理滑动动画
        switch gesture.state {
        case .began:
            break
        case .changed:
            processDismiss(progress: progress)
        case .ended:
            let velocity = gesture.velocity(in: self).x
            if progress >= 0.2 || velocity > 1_000 {
                finishDismiss(from: progress)
            } else {
                cancelDismiss(from: progress)
            }
        case .cancelled, .failed:
            let translation = gesture.translation(in: self)
            let progress = translation.x / bounds.width
            cancelDismiss(from: progress)
        default:
            break
        }
    }

    private func processDismiss(progress: CGFloat) {
        let transform = CGAffineTransform(
            translationX: bounds.width * progress,
            y: 0
        )
        self.transform = transform
        self.parentMaskView.alpha = 1 - progress
    }

    private func finishDismiss(from progress: CGFloat) {
        let remainingTime = animationDuration * TimeInterval(1 - progress)
        UIView.animate(withDuration: remainingTime, animations: {
            self.processDismiss(progress: 1.0)
        }, completion: { _ in
            self.dismiss()
        })
    }

    private func cancelDismiss(from progress: CGFloat) {
        let remainingTime = animationDuration * TimeInterval(progress)
        UIView.animate(withDuration: remainingTime, animations: {
            self.processDismiss(progress: 0)
        })
    }
}
