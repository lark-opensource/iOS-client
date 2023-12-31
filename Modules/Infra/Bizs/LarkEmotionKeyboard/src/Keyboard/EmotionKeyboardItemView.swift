//
//  EmotionKeyboardItemView.swift
//  LarkUIKit
//
//  Created by 李晨 on 2019/8/13.
//

import UIKit
import Foundation

public final class EmotionKeyboardItemView: UIView, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {
    var source: EmotionItemDataSource {
        didSet {
            if source !== oldValue {
                self.emotionCollection.reloadData()
            }
        }
    }

    fileprivate var itemWidth: CGFloat = 0
    fileprivate var layout: EmotionLeftAlignedFlowLayout = EmotionLeftAlignedFlowLayout()
    fileprivate lazy var emotionCollection = UICollectionView(frame: CGRect.zero, collectionViewLayout: layout)
    fileprivate var longPressGesture: UILongPressGestureRecognizer = UILongPressGestureRecognizer()

    fileprivate var emptyView: UIView?

    var bottomBarHeight: CGFloat = 0 {
        didSet {
            if bottomBarHeight != oldValue {
                self.emotionCollection.reloadData()
            }
        }
    }

    public init(source: EmotionItemDataSource) {
        self.source = source
        super.init(frame: .zero)
        self.updateCollectionView()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if self.bounds.width != self.itemWidth {
            self.itemWidth = self.bounds.width
            self.emotionCollection.frame = self.bounds
            self.layout.invalidateLayout()
            self.emotionCollection.reloadData()
        }
    }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        if superview != nil {
            EmojiTracker.trackerTea(event: Const.emojiPanelWidgetViewEvent, params: [:])
        }
    }

    func updateCollectionView() {
        layout.scrollDirection = .vertical
        emotionCollection.backgroundColor = UIColor.clear
        emotionCollection.showsVerticalScrollIndicator = false
        emotionCollection.showsHorizontalScrollIndicator = false
        emotionCollection.dataSource = self
        emotionCollection.delegate = self
        self.addSubview(emotionCollection)
        emotionCollection.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })

        self.source.setupCollectionView(containerView: self, collection: emotionCollection)
        longPressGesture.addTarget(self, action: #selector(longPress(gesture:)))
        longPressGesture.delegate = self
        emotionCollection.addGestureRecognizer(longPressGesture)
    }

    private func addEmptyViewIfNeeded() {
        let emptyView = self.source.emotionEmptyView()
        if self.emptyView != emptyView {
            self.emptyView?.removeFromSuperview()
        }
        self.emptyView = emptyView
        if let emptyView = self.emptyView, emptyView.superview != self {
            self.addSubview(emptyView)
            emptyView.snp.makeConstraints { (maker) in
                maker.edges.equalToSuperview()
            }
        }
    }

    var pressCell: UICollectionViewCell?
    var pressCellIndexPatch: IndexPath?
    @objc
    fileprivate func longPress(gesture: UILongPressGestureRecognizer) {
        /// end长按中的cell
        func endLastPressCellIfExist() {
            if let pressCell = pressCell, let pressCellIndexPatch = pressCellIndexPatch {
                self.source.longPressedEnd(indexPath: pressCellIndexPatch, cell: pressCell)
            }
            self.pressCell = nil
            self.pressCellIndexPatch = nil
        }

        switch gesture.state {
        case .began:
            break
        case .changed:
            let location = gesture.location(in: self.emotionCollection)
            if let indexPath = self.emotionCollection.indexPathForItem(at: location) {
                guard let cell = self.emotionCollection.cellForItem(at: indexPath) else {
                    break
                }
                // 同一个cell单次长按只会触发一次回调
                guard self.pressCell != cell else {
                    break
                }
                endLastPressCellIfExist()
                self.source.longPressedAt(indexPath: indexPath, cell: cell)
                self.pressCell = cell
                self.pressCellIndexPatch = indexPath
            } else {
                // 触摸点不在任意一个cell上
                endLastPressCellIfExist()
            }
        default:
            endLastPressCellIfExist()
        }
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return self.source.numberOfSections()
    }

    public func collectionView(_ collectionView: UICollectionView,
                               viewForSupplementaryElementOfKind kind: String,
                               at indexPath: IndexPath) -> UICollectionReusableView {
        return self.source.collectionView(collectionView: collectionView,
                                          viewForSupplementaryElementOfKind: kind,
                                          at: indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = self.source.numberOfEmotions(section: section)
        // 保持原来逻辑，在此回调中判断是否需要添加占位图，只在一次reload结束时判断即可
        if section == self.source.numberOfSections() - 1 {
            if self.source.needAddEmptyView() {
                self.addEmptyViewIfNeeded()
            } else {
                self.emptyView?.removeFromSuperview()
            }
        }
        return count
    }

    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        return self.source.collectionCell(collection: collectionView, indexPath: indexPath)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return self.source.emotionItemSize(indexPath: indexPath)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAt section: Int
    ) -> UIEdgeInsets {
        return self.source.collectionView(collectionView: collectionView,
                                          insetForSectionAt: section,
                                          bottomBarHeight: self.bottomBarHeight)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumLineSpacingForSectionAt section: Int
    ) -> CGFloat {
        return self.source.emotionLineSpacing()
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAt section: Int
    ) -> CGFloat {
        // 每个source分别计算各自的最小列间距
        return self.source.emotionMinimumInteritemSpacing(section: section)
    }

    public func collectionView(
        _ collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        referenceSizeForHeaderInSection section: Int
    ) -> CGSize {
        return self.source.headerReferenceSize()
    }

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.source.didSelectEmotion(indexPath: indexPath)
    }

    public func collectionView(_ collectionView: UICollectionView, didHighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        self.source.didHighlightItemAt(indexPath: indexPath, cell: cell)
    }

    public func collectionView(_ collectionView: UICollectionView, didUnhighlightItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        self.source.didUnHighlightItemAt(indexPath: indexPath, cell: cell)
    }
}
extension EmotionKeyboardItemView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer.name == emotionKeyboardHighPriorityGesture {
            return false
        }
       return true
   }

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
       if otherGestureRecognizer.name == emotionKeyboardHighPriorityGesture {
           return true
       }
       return false
   }
}

extension EmotionKeyboardItemView {
    enum Const {
        static let emojiPanelWidgetViewEvent: String = "public_emoji_panel_widget_view"
    }
}
