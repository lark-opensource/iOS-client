//
//  PushCardViewController.swift
//  LarkPushCard
//
//  Created by 白镜吾 on 2022/8/26.
//

import Foundation
import UIKit
import UniverseDesignShadow
import UniverseDesignTheme
import LKCommonsLogging
import LKWindowManager
import FigmaKit

// swiftlint:disable all
// MARK: API
extension PushCardViewController {

    /// 弹出卡片
    func post(_ models: [Cardable]) {
        for (i, model) in models.enumerated() {
            guard !self.cardModels.contains(where: { $0.id == model.id }) else {
                Self.logger.warn("LarkPushCard post model \(model.id) is Exist")
                assertionFailure("This card id \(model.id) is Exist")
                continue
            }
            Self.logger.info("LarkPushCard post model id: \(model.id), priority: \(model.priority)")
            let indexPath = self.calculateIndex(of: model)
            if self.cardCurrentState == .stacked, self.collectionView != nil {
                self.collectionView?.removeFromSuperview()
                self.collectionView = nil
            }
            self.cardModels.insert(model, at: indexPath.item)
            self.cardStackView.addCardModel(model, at: indexPath.item)
            self.cardStackView.addShowCard(model, at: indexPath.item, index: i, modelCounts: models.count)

            // performBatchUpdates 在 iOS 12、iOS 14、iOS 15 中的实现均有所不同，需要分别特殊处理
            // iOS 12: 完成回调可能不会被调用
            // iOS 14: cell 的重用机制有问题
            if #available(iOS 13.0, *) {
                if #available(iOS 15.0, *) {
                    self.collectionView?.performBatchUpdates({ [weak self] () -> Void in
                        guard let self = self else { return }
                        if self.cardModels.count == 1 ||
                            (self.collectionView?.numberOfItems(inSection: 0) ?? 0) == self.cardModels.count {
                            self.collectionView?.reloadSections(IndexSet(integer: 0))
                        } else {
                            self.collectionView?.insertItems(at: [indexPath])
                        }
                    })
                } else {
                    self.collectionView?.reloadSections(IndexSet(integer: 0))
                }
            } else {
                self.collectionView?.performBatchUpdates({ [weak self] () -> Void in
                    guard let self = self else { return }
                    if self.cardModels.count == 1 ||
                        (self.collectionView?.numberOfItems(inSection: 0) ?? 0) == self.cardModels.count {
                        self.collectionView?.reloadSections(IndexSet(integer: 0))
                    } else {
                        self.collectionView?.insertItems(at: [indexPath])
                    }
                }, completion: { [weak self] _ in
                    guard let self = self else { return }
                    self.collectionView?.performBatchUpdates({ [weak self] () -> Void in
                        guard let self = self else { return }
                        self.collectionView?.reloadData()
                    })
                })
            }

            if self.cardCurrentState == .expanded, self.collectionView?.contentOffset.y ?? 0 > 0 {
                self.collectionView?.setContentOffset(CGPoint(x: 0, y: 0), animated: true)
            }
            Self.logger.info("LarkPushCard has card number \(self.cardModels.count)")

            if let duration = model.duration, duration > 0 {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: {
                    Self.logger.info("LarkPushCard remove model id: \(model.id), \(duration.description) when time is up")
                    model.timedDisappearHandler?(model)
                    self.remove(with: model.id)
                })
            }
        }
    }

    /// 移除卡片
    func remove(with id: String, changeToStack: Bool = false) {
        guard let item = self.cardModels.firstIndex(where: { $0.id == id }) else {
            Self.logger.warn("LarkPushCard remove model \(id) is not exist")
            return
        }
        Self.logger.info("LarkPushCard remove model \(id), changeToStack \(changeToStack)")
        let indexPath = IndexPath(item: item, section: 0)
        self.cardStackView.removeCard(at: indexPath.item)
        self.cardModels.remove(at: indexPath.item)
        if #available(iOS 13.0, *) {
            if #available(iOS 15.0, *) {
                self.collectionView?.performBatchUpdates({ [weak self] () -> Void in
                    guard let self = self else { return }
                    if self.collectionView?.numberOfItems(inSection: 0) == self.cardModels.count {
                        self.collectionView?.reloadSections(IndexSet(integer: 0))
                    } else {
                        self.collectionView?.deleteItems(at: [indexPath])
                    }
                })
            } else {
                self.collectionView?.reloadSections(IndexSet(integer: 0))
            }
        } else {
            self.collectionView?.performBatchUpdates({ [weak self] () -> Void in
                guard let self = self else { return }
                if self.collectionView?.numberOfItems(inSection: 0) == self.cardModels.count {
                    self.collectionView?.reloadSections(IndexSet(integer: 0))
                } else {
                    self.collectionView?.deleteItems(at: [indexPath])
                }
            }, completion: { [weak self] _ in
                guard let self = self else { return }
                self.collectionView?.performBatchUpdates({ [weak self] () -> Void in
                    guard let self = self else { return }
                    self.collectionView?.reloadData()
                })
            })
        }

        self.collectionView?.remakeConstraintsTo(self.cardCurrentState)
        self.cardStackView.resetConstraints()
        self.changeSingleExpandedCardToSingleStackedCard(with: id, changeToStack)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
            if self.cardModels.isEmpty {
                Self.logger.info("LarkPushCard remove, cardModels is Empty, hide window")
                PushCardManager.shared.removeAll()
            }
        })
    }

    func resetConstraints() {
        self.cardStackView.resetConstraints()
        self.collectionView?.remakeConstraintsTo(self.cardCurrentState)
    }

    func update(with id: String) {
        guard let item = self.cardModels.firstIndex(where: { $0.id == id }) else {
            Self.logger.warn("LarkPushCard update model \(id) is not exist")
            return
        }
        if let showIndex = self.cardStackView.shownCardBuffer.firstIndex(where: { $0.model.id == id }) {
            self.cardStackView.shownCardBuffer[showIndex].updateCardSize()
        }
        let indexPath = IndexPath(item: item, section: 0)
        if item < 3 {
            self.cardStackView.remakeCardsConstraints(animated: false)
        }
        self.collectionView?.performBatchUpdates({ () -> Void in
            collectionView?.reloadItems(at: [indexPath])
        })
    }
}

// MARK: Init
final class PushCardViewController: LKWindowRootController {
    lazy var cardModels: [Cardable] = []
    lazy var cardCurrentState: PushCardState = .stacked
    lazy var cardStackView = CardStackView(delegate: self)
    lazy var blurView = PushCardTopBlurView()
    lazy var isInAnimation: Bool = true
    var collectionView: PushCardCollectionView?

    private static let logger = Logger.log(PushCardManager.self, category: "PushCardViewController")

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(cardStackView)
        self.view.addSubview(blurView)
        let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        let swipeHRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        let swipeVRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeHRecognizer.direction = [.left, .right]
        swipeVRecognizer.direction = [.down, .up]
        self.view.addGestureRecognizer(tapRecognizer)
        self.view.addGestureRecognizer(swipeHRecognizer)
        self.view.addGestureRecognizer(swipeVRecognizer)
    }

    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        guard self.isViewLoaded else { return }
        coordinator.animate { _ in
            self.cardCurrentState = .hidden
            self.changeStateToStacked(animated: false)
        }
        super.willTransition(to: newCollection, with: coordinator)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        guard self.isViewLoaded else { return }
        coordinator.animate { _ in
            self.cardCurrentState = .hidden
            self.changeStateToStacked(animated: false)
        }
        super.viewWillTransition(to: size, with: coordinator)
    }

    /// 点击折叠
    func pushCardHeaderClickToStack() {
        Self.logger.info("LarkPushCard pushCardHeaderClickToStack, click on stack button")
        self.changeStateToStacked()
    }

    /// 点击展开
    func cardStackClickBody() {
        guard self.cardModels.count > 1 else { return }
        Self.logger.info("LarkPushCard cardStackClickBody, click on card and will expand soon, cardCounts: \(self.cardModels.count)")
        self.changeStateToExpanded()
    }

    /// 点击空白关闭展开的卡片列表
    func pushCardCollectionViewClickSpace() {
        guard cardCurrentState == .expanded else { return }
        self.changeStateToStacked()
    }

    /// 点击卡片跳转对应功能
    func pushCardCollectionViewClickItem(at index: Int) {
        guard cardCurrentState == .expanded else { return }
        let card = cardModels[index]
        Self.logger.info("LarkPushCard pushCardCollectionViewClickItem, click card: \(card.id) at: \(index)")
        card.bodyTapHandler?(card)
    }

    /// 点击清除
    func pushCardHeaderClickClear() {
        Self.logger.info("LarkPushCard pushCardHeaderClickClear, click on clear button")
        let highModels = cardModels.filter({ $0.priority == .high })
        let mediumModels = cardModels.filter({ $0.priority == .medium })
        let normalModels = cardModels.filter({ $0.priority == .normal })

        self.collectionView?.isHidden = true
        self.collectionView?.removeFromSuperview()
        self.collectionView = nil
        self.cardStackView.isHidden = false
        self.cardStackView.removeAll()
        self.cardModels = []
        self.cardCurrentState = .stacked

        for normalModel in normalModels {
            Self.logger.info("LarkPushCard pushCardHeaderClickClear, remove normalModel: \(normalModel.id)")
            normalModel.removeHandler?(normalModel)
        }

        if highModels.isEmpty {
            PushCardManager.shared.removeAll()
        }

        PushCardManager.shared.post(highModels + mediumModels.reversed())
    }

    /// 上推隐藏动画
    func cardStackPanGesture(_ sender: UIPanGestureRecognizer) {
        guard let view = sender.view else { return }
        switch sender.state {
        case .changed, .began, .possible:
            let point = sender.translation(in: view)
            guard point.y < 0 else { return }
            view.transform = CGAffineTransform(translationX: 0, y: point.y)
            sender.translation(in: view)
            self.cardCurrentState = .hidden
        case .ended, .cancelled, .failed:
            UIView.animate(withDuration: 0.5, delay: 0, options: []) {
                view.transform = .identity
                sender.translation(in: view)
            } completion: { done in
                if done {
                    self.cardCurrentState = .stacked
                }
            }
        default: return
        }
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        /// 如果卡片数量超过 15，有限以 15个进行加载。加载完成后，加载全部数据。
        if self.cardModels.count >= 15, self.isInAnimation {
            return 15
        } else {
            return cardModels.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard isIndexLegal(indexPath: indexPath) else {
            Self.logger.error("LarkPushCard cellForItemAt outOfIndex indexpath: \(indexPath.item), count: \(cardModels.count)")
            return UICollectionViewCell()
        }
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: PushCardBaseCell.identifier, for: indexPath) as! PushCardBaseCell
        cell.configure(model: cardModels[indexPath.item])
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard isIndexLegal(indexPath: indexPath) else {
            Self.logger.error("LarkPushCard willDisplay outOfIndex indexpath: \(indexPath.item), count: \(cardModels.count)")
            return
        }
        (cell as! PushCardBaseCell).updateShadow(pushCardState: self.cardCurrentState, index: indexPath.item)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard isIndexLegal(indexPath: indexPath) else {
            Self.logger.error("LarkPushCard sizeForItemAt outOfIndex indexpath: \(indexPath.item), count: \(cardModels.count)")
            return .zero
        }
        return cardStackView.cardBuffer[indexPath.item].cardSize
    }

    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        if kind == UICollectionView.elementKindSectionHeader {
            let headerView: PushCardHeaderView =
            collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader,
                                                            withReuseIdentifier: PushCardHeaderView.identifier,
                                                            for: indexPath) as! PushCardHeaderView
            headerView.delegate = self
            return headerView
        } else if kind == UICollectionView.elementKindSectionFooter {
            let footerView: PushCardFooterView =
            collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter,
                                                            withReuseIdentifier: PushCardFooterView.identifier,
                                                            for: indexPath) as! PushCardFooterView
            footerView.delegate = self
            return footerView
        }
        return UICollectionReusableView()
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: Cons.cardWidth, height: Cons.cardStackedTopMargin + Cons.cardHeaderHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        if StaticFunc.isShowBottomButton(collectionView: collectionView) {
            return CGSize(width: Cons.cardWidth, height: Cons.cardBottomTotalHeight)
        } else {
            self.blurView.isHidden = true
            collectionView.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: IndexPath(item: 0, section: 0))?.isHidden = true
            return .zero
        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if self.cardCurrentState == .expanded, (self.collectionView?.contentOffset.y ?? 0) > 0 {
            self.blurView.isHidden = false
            if self.view.subviews.last != self.blurView {
                self.view.bringSubviewToFront(self.blurView)
            }
        } else {
            self.blurView.isHidden = true
        }
    }

    /// 进入折叠态
    func changeStateToStacked(animated: Bool = true) {
        guard self.cardCurrentState != .stacked else { return }
        self.cardCurrentState = .stacked
        guard !self.cardModels.isEmpty else { return }

        Self.logger.info("LarkPushCard changeStateToStacked, animated : \(animated)")

        StaticFunc.execInMainThread {
            if animated {
                let stackLayout = StackedCollectionViewLayout(itemSize: CGSize(width: Cons.cardWidth,
                                                                               height: self.cardStackView.shownCardBuffer.first?.cardSize.height ?? Cons.cardDefaultHeight))
                self.collectionView?.setContentOffset(CGPoint(x: 0, y: 0), animated: false)
                self.view.layoutIfNeeded()
                if let collectionViewLayout = self.collectionView?.collectionViewLayout,
                   collectionViewLayout.isKind(of: ExpandedCollectionViewLayout.self) {
                    (collectionViewLayout as? ExpandedCollectionViewLayout)?.isCardShowInSameLevel = false
                    self.isInAnimation = true
                    self.collectionView?.reloadData()
                    self.collectionView?.layoutIfNeeded()
                }
                UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
                    self.collectionView?.remakeConstraintsTo(self.cardCurrentState)
                    self.view.layoutIfNeeded()
                }
                self.collectionView?.setCollectionViewLayout(stackLayout, animated: true, completion: { done in
                    self.removeCollectionViewAndRemakeCardView()
                })
            } else {
                self.removeCollectionViewAndRemakeCardView()
            }
        }

        if let headerView = (self.collectionView?.supplementaryView(forElementKind: UICollectionView.elementKindSectionHeader, at: IndexPath(item: 0, section: 0)) as? PushCardHeaderView) {
            headerView.changeToStack()
        }

        if let footerView = (self.collectionView?.supplementaryView(forElementKind: UICollectionView.elementKindSectionFooter, at: IndexPath(item: 0, section: 0)) as? PushCardFooterView) {
            footerView.changeToStack()
        }
    }

    /// 进入展开态
    func changeStateToExpanded() {
        guard self.cardCurrentState == .stacked else { return }
        self.cardCurrentState = .expanded
        self.isInAnimation = true

        Self.logger.info("LarkPushCard changeStateToStacked")

        let stackLayout = StackedCollectionViewLayout(itemSize: CGSize(width: Cons.cardWidth,
                                                                       height: cardStackView.shownCardBuffer.first?.cardSize.height ?? Cons.cardDefaultHeight))

        let expandedLayout = ExpandedCollectionViewLayout()

        let cardCollectionView = PushCardCollectionView(delegate: self, dateSource: self, clickDelegate: self, layout: stackLayout)
        self.collectionView = cardCollectionView
        self.view.addSubview(collectionView!)
        self.cardStackView.isHidden = true
        self.collectionView?.isHidden = false
        self.view.layoutIfNeeded()
        UIView.animate(withDuration: 0.3, delay: 0, options: [.curveEaseInOut]) {
            self.collectionView?.remakeConstraintsTo(self.cardCurrentState)
            expandedLayout.isCardShowInSameLevel = false
            self.view.layoutIfNeeded()
        }
        self.collectionView?.setCollectionViewLayout(expandedLayout,
                                                     animated: true,
                                                     completion: { done in
            if done {
                expandedLayout.isCardShowInSameLevel = true
                self.isInAnimation = false
                self.collectionView?.reloadData()
                self.collectionView?.layoutIfNeeded()
            }
        })
    }

    /// 点击空白收起卡片
    @objc
    func handleTap(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else { return }
        self.pushCardCollectionViewClickSpace()
    }

    @objc
    func handleSwipe(_ sender: UITapGestureRecognizer) {
        guard UIDevice.current.userInterfaceIdiom == .pad else { return }
        self.pushCardCollectionViewClickSpace()
    }

    func isIndexLegal(indexPath: IndexPath) -> Bool {
        return indexPath.item >= 0 && indexPath.item < cardModels.count && indexPath.item < cardStackView.cardBuffer.count
    }

    func changeSingleExpandedCardToSingleStackedCard(with id: String, _ changeToStack: Bool) {
        if self.cardModels.count == 1,
           self.cardCurrentState == .expanded {
            Self.logger.info("LarkPushCard remove card \(id), and there is one card left, change to stack state")
            self.changeStateToStacked()
        }

        if changeToStack {
            self.changeStateToStacked()
        }
    }

    func checkVisiableArea(_ point: CGPoint) -> Bool {
        let pointInsideStack = self.view.convert(point, to: self.cardStackView.containerView)
        if (self.cardStackView.shownCardBuffer.first?.frame.contains(pointInsideStack) ?? false) { return true }
        if self.view.frame.contains(point), self.cardCurrentState == .expanded  { return true }
        return false
    }

    func removeCollectionViewAndRemakeCardView() {
        self.collectionView?.removeFromSuperview()
        self.collectionView = nil
        self.cardStackView.isHidden = false
        self.collectionView?.isHidden = true
        for (index, model) in self.cardModels.enumerated() {
            guard index >= 0, index < self.cardStackView.shownCardBuffer.count, model.customView != nil else { return }
            self.cardStackView.shownCardBuffer[index].resetCardCustomView()
            self.cardStackView.resetConstraints()
        }
    }

    func calculateIndex(of model: Cardable) -> IndexPath {
        var index = 0
        var indexPath: IndexPath
        switch model.priority {
        case .high:
            indexPath = IndexPath(item: index, section: 0)
        case .normal, .medium:
            if let item = self.cardModels.lastIndex(where: { $0.priority == .high }) {
                index = item + 1
            } else {
                index = 0
            }
            indexPath = IndexPath(item: index, section: 0)
        }
        return indexPath
    }
}

extension PushCardViewController: PushCardCenterService,
                                  CardStackViewDelegate,
                                  PushCardTopBottonButtonDelegate,
                                  PushCardCollectionViewDelegate,
                                  UICollectionViewDelegate,
                                  UICollectionViewDataSource,
                                  UICollectionViewDelegateFlowLayout {}
