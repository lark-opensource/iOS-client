//
//  PushCardCollectionView.swift
//  LarkPushCard
//
//  Created by 白镜吾 on 2022/8/25.
//

import Foundation
import UIKit

protocol PushCardCollectionViewDelegate: AnyObject {
    func pushCardCollectionViewClickSpace()
    func pushCardCollectionViewClickItem(at index: Int)
}

// swiftlint:disable all
final class PushCardCollectionView: UICollectionView {
    weak var clickDelegate: PushCardCollectionViewDelegate?
    init(delegate: UICollectionViewDelegate,
         dateSource: UICollectionViewDataSource,
         clickDelegate: PushCardCollectionViewDelegate,
         layout: UICollectionViewLayout) {

        super.init(frame: .zero, collectionViewLayout: layout)

        self.delegate = delegate
        self.dataSource = dateSource
        self.clickDelegate = clickDelegate
        self.backgroundColor = .clear
        self.backgroundView?.backgroundColor = .clear
        self.showsVerticalScrollIndicator = false
        self.showsHorizontalScrollIndicator = false
        self.clipsToBounds = false
        self.isScrollEnabled = true
        self.contentInsetAdjustmentBehavior = .never
        self.bounces = false
        self.register(PushCardHeaderView.self,
                      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                      withReuseIdentifier: PushCardHeaderView.identifier)
        self.register(PushCardBaseCell.self,
                      forCellWithReuseIdentifier: PushCardBaseCell.identifier)
        self.register(PushCardFooterView.self,
                      forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                      withReuseIdentifier: PushCardFooterView.identifier)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        self.addGestureRecognizer(tapRecognizer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard self.superview != nil else { return }
        remakeConstraintsTo(.stacked)
    }

    func remakeConstraintsTo(_ nextState: PushCardState) {
        guard let superview = self.superview else { return }
        switch nextState {
        case .stacked:
            self.snp.remakeConstraints { make in
                make.width.equalTo(Cons.cardWidth)
                make.top.equalToSuperview().offset(Cons.cardStackedTopMargin)
                make.bottom.equalToSuperview()

                if Helper.isInCompact || Helper.isShowInWindowCenterX || Helper.isInPhoneLandscape {
                    make.centerX.equalToSuperview()
                } else {
                    make.trailing.equalToSuperview().offset(-Cons.cardContainerPadding)
                }
            }
        case .expanded:
            self.snp.remakeConstraints { make in
                make.width.equalTo(Cons.cardWidth)
                make.top.equalToSuperview()
                make.bottom.equalTo(superview.safeAreaLayoutGuide)
                if Helper.isInCompact || Helper.isShowInWindowCenterX || Helper.isInPhoneLandscape {
                    make.centerX.equalToSuperview()
                } else {
                    make.trailing.equalToSuperview().offset(-Cons.cardContainerPadding)
                }
            }
        case .hidden:
            return
        }
    }

    /// 判断当前是否可以一屏幕展示，控制 footerView 的显示隐藏
    var isShowInOneScreen: Bool = true

    override var contentSize: CGSize {
        willSet {
            guard newValue != contentSize else { return }
            DispatchQueue.main.async {
                if newValue.height <= UIScreen.main.bounds.height {
                    self.isShowInOneScreen = true
                    self.collectionViewLayout.invalidateLayout()
                } else {
                    self.isShowInOneScreen = false
                }
            }
        }
    }
}

extension PushCardCollectionView {
    /// 点击空白收起卡片
    @objc
    func handleTap(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else { return }

        let tapPoint = sender.location(in: self)

        guard let index = self.indexPathForItem(at: tapPoint) else {
            self.clickDelegate?.pushCardCollectionViewClickSpace()
            return
        }

        self.clickDelegate?.pushCardCollectionViewClickItem(at: index.item)
    }
}
