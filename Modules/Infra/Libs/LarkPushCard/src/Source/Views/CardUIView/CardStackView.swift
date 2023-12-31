//
//  PushCardCollectionView.swift
//  LarkPushCard
//
//  Created by 白镜吾 on 2022/8/26.
//

import Foundation
import UIKit

protocol CardStackViewDelegate: AnyObject {
    func cardStackClickBody()
    func cardStackPanGesture(_ sender: UIPanGestureRecognizer)
}

// swiftlint:disable all
final class CardStackView: UIView, UIGestureRecognizerDelegate {
    weak var delegate: CardStackViewDelegate?

    lazy var tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))

    private var maxViewNumber = 3

    private var cacheViewNumber = 7

    /// 存储数据
    private var buffer: [Cardable] = []

    /// 存储所有的卡片 UI
    var cardBuffer: [CardView] = []

    /// 存储展示出来的卡片 UI
    var shownCardBuffer: [CardView] = []

    var topSize: CGSize = .zero

    var containerView: UIView = UIView()

    init(delegate: CardStackViewDelegate) {
        self.delegate = delegate
        super.init(frame: .zero)
        self.clipsToBounds = false
        self.layer.masksToBounds = false
        self.addSubview(containerView)
        self.setContainerConstraints()
        self.layoutIfNeeded()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 添加所有的 model 和 cardView
    func addCardModel(_ model: Cardable, at index: Int) {
        let card = CardView(model: model)
        cardBuffer.insert(card, at: index)
        buffer.insert(model, at: index)
    }

    /// 上屏的卡片，如果是很多很多，则只展示最后三个，但是预加载 7 张
    func addShowCard(_ model: Cardable, at index: Int, index i: Int, modelCounts: Int) {
        /// 预加载最后 cacheViewNumber 个 会上屏的卡片大小，但只展示 3个
        guard (i + cacheViewNumber + 1) > modelCounts, index < cardBuffer.count else { return }
        let card = cardBuffer[index]
        shownCardBuffer.insert(card, at: index)
        if shownCardBuffer.count > cacheViewNumber, let removeCard = containerView.subviews.first  {
            removeCard.removeFromSuperview()
            shownCardBuffer.removeLast()
        }
        self.containerView.insertSubview(card, at: containerView.subviews.count - index)
        card.resetCardCustomView()
        self.remakeCardsConstraints()
    }

    func removeAll() {
        self.buffer.removeAll()
        for subView in containerView.subviews {
            subView.removeFromSuperview()
        }
        self.cardBuffer.removeAll()
        self.shownCardBuffer.removeAll()
        self.topSize = .zero
    }

    func removeCard(at item: Int) {
        guard item >= 0, item < self.buffer.count else { return }
        self.buffer.remove(at: item)
        self.cardBuffer.remove(at: item)

        guard item >= 0, item < self.shownCardBuffer.count else { return }
        let card = self.shownCardBuffer[item]
        self.shownCardBuffer.remove(at: item)

        switch item {
        case 0:
            UIView.animate(withDuration: 0.25, delay: 0, options: [.curveEaseInOut]) {
                card.transform = CGAffineTransform(translationX: 0, y: -(Cons.cardStackedTopMargin + card.cardSize.height))
                self.layoutIfNeeded()
            } completion: { _ in
                card.removeFromSuperview()
                if self.shownCardBuffer.count < self.cardBuffer.count, !self.cardBuffer.isEmpty {
                    let card = self.cardBuffer[self.shownCardBuffer.count]
                    self.shownCardBuffer.append(card)
                    self.containerView.insertSubview(card, at: self.containerView.subviews.count - self.shownCardBuffer.count + 1)
                    card.resetCardCustomView()
                    self.remakeCardsConstraints(animated: false)
                }
            }
        default:
            card.removeFromSuperview()
            if item < maxViewNumber {
                if self.shownCardBuffer.count < self.cardBuffer.count, !self.cardBuffer.isEmpty  {
                    let card = self.cardBuffer[self.shownCardBuffer.count]
                    self.shownCardBuffer.append(card)
                    self.containerView.insertSubview(card, at: self.containerView.subviews.count - self.shownCardBuffer.count + 1)
                    card.resetCardCustomView()
                }
                self.remakeCardsConstraints(animated: false)
            }
        }
    }

    func remakeCardsConstraints(animated: Bool = true) {
        self.layoutIfNeeded()
        UIView.animate(withDuration: animated ? 0.5 : 0,
                       delay: 0,
                       usingSpringWithDamping: 0.8,
                       initialSpringVelocity: 1.0,
                       options: [.curveEaseInOut]) {
            self.topSize = self.shownCardBuffer.first?.cardSize ?? .zero
            for (index, cardView) in self.shownCardBuffer.enumerated() {
                guard cardView.superview != nil else { return }
                let centerYOffset = Cons.cardDefaultTopMargin + ((self.shownCardBuffer.first?.cardSize.height ?? 0) / 2)
                if index < self.maxViewNumber {
                    cardView.alpha = 1
                    cardView.isHidden = false
                    cardView.snp.remakeConstraints { make in
                        make.width.equalTo(Cons.cardWidth - Cons.stackWidthDiff * CGFloat(index))
                        make.height.equalTo(self.topSize.height).priority(.required)
                        make.centerY.equalTo(self.containerView.snp.top).offset(centerYOffset + Cons.stackHeightDiff * CGFloat(index))
                        make.centerX.equalToSuperview()
                    }
                    if index == 0 {
                        cardView.layoutIfNeeded()
                    }
                } else {
                    cardView.alpha = 0
                    cardView.isHidden = true
                    cardView.snp.remakeConstraints { make in
                        make.width.equalTo(Cons.cardWidth - Cons.stackWidthDiff * 2)
                        make.height.equalTo(self.topSize.height)
                        make.centerY.equalTo(self.containerView.snp.top).offset(centerYOffset + Cons.stackHeightDiff * 2)
                        make.centerX.equalToSuperview()
                    }
                }
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }
        }
    }
}

extension CardStackView {
    func resetConstraints() {
        self.setContainerConstraints()
        self.remakeCardsConstraints()
    }

    func setContainerConstraints() {
        self.containerView.layoutIfNeeded()
        containerView.snp.remakeConstraints { make in
            make.width.equalTo(Cons.cardWidth)
            make.top.bottom.equalToSuperview()
            if Helper.isInCompact || Helper.isShowInWindowCenterX || Helper.isInPhoneLandscape {
                make.centerX.equalToSuperview()
            } else {
                make.trailing.equalToSuperview().offset(-Cons.cardContainerPadding)
            }
        }
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard let superview = self.superview else { return }
        self.snp.remakeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(superview.safeAreaLayoutGuide)
        }

        let panRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        self.addGestureRecognizer(tapRecognizer)
        self.addGestureRecognizer(panRecognizer)
        panRecognizer.delegate = self
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled, !isHidden, alpha > 0.01 else { return nil }

        guard self.point(inside: point, with: event) else { return nil }

        for subview in subviews.reversed() {
            let insidePoint = convert(point, to: subview)
            if let hitView = subview.hitTest(insidePoint, with: event) { return hitView }
        }
        return self
    }

    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {

        guard let firstCard = shownCardBuffer.first else { return false }

        let insidePoint = convert(point, to: firstCard)

        guard firstCard.frame.contains(insidePoint) else { return false }

        return true
    }

    /// 点击手势响应
    @objc
    func handleTap(_ sender: UITapGestureRecognizer) {
        guard sender.state == .ended else { return }

        guard self.buffer.count > 0 else { return }

        switch self.buffer.count {
        case 1:
            if let model = buffer.first {
                model.bodyTapHandler?(model)
            }
        default:
            /// 多张卡片时，点击卡片展开列表
            self.delegate?.cardStackClickBody()
        }
    }

    /// 滑动手势
    @objc
    func handlePan(_ sender: UIPanGestureRecognizer) {
        self.delegate?.cardStackPanGesture(sender)
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if let scollView = touch.view as? UIScrollView {
            return !scollView.isScrollEnabled
        }
        return true
    }
  
}
