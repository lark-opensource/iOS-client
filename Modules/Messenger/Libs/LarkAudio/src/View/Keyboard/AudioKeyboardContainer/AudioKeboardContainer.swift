//
//  AudioKeboardContainer.swift
//  LarkAudio
//
//  Created by 李晨 on 2019/5/29.
//

import UIKit
import Foundation
import LarkUIKit
import LarkKeyboardView

protocol AudioKeyboardItemViewDelegate: AnyObject {
    var title: String { get }
    var recognitionType: RecognizeLanguageManager.RecognizeType { get }
    var keyboardView: UIView { get }
    var keyboardFocusBlock: ((Bool) -> Void)? { get set }
    func resetKeyboardView()
}

protocol AudioCollectionContainerView: UIView {
    var keyboardHeight: Float? { get set }
    func resetKeyboardView()
}

final class AudioKeyboardContainer: UIView, AudioCollectionContainerView {
    var keyboardHeight: Float?
    private let items: [AudioKeyboardItemViewDelegate]

    private var didMovedToWindowFlag: Bool = false
    private var originSize: CGSize = .zero

    private var smalleCellDic: [Int: (Range<CGFloat>, CGFloat)] = [:]
    private var minRange: CGFloat?
    private var maxRange: CGFloat?
    private var selectIndex: Int = 0
    private var getKeyboardHeight: Float {
        self.keyboardHeight ?? AudioKeyboard.keyboard(iconColor: nil).height
    }

    private lazy var contentCollection: UICollectionView = {
        let collection = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collection.backgroundColor = UIColor.clear
        collection.isPagingEnabled = true
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        return collection
    }()

    private lazy var flowLayout: UICollectionViewFlowLayout = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        flowLayout.scrollDirection = .horizontal
        return flowLayout
    }()

    private lazy var titleCollection: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 20
        flowLayout.minimumInteritemSpacing = 20
        let collection = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collection.backgroundColor = UIColor.clear
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        collection.contentInset = UIEdgeInsets(top: 0, left: self.bounds.width, bottom: 0, right: self.bounds.width)
        return collection
    }()

    // MARK: init
    init(items: [AudioKeyboardItemViewDelegate]) {
        self.items = items
        super.init(frame: .zero)

        self.backgroundColor = UIColor.ud.bgBodyOverlay
        self.contentCollection.delegate = self
        self.contentCollection.dataSource = self
        let contentIdentifier = String(describing: AudioKeyboardContentCell.self)
        self.contentCollection.register(AudioKeyboardContentCell.self, forCellWithReuseIdentifier: contentIdentifier)
        self.addSubview(self.contentCollection)
        self.contentCollection.snp.makeConstraints { (maker) in
            maker.left.right.top.equalToSuperview()
            maker.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom)
        }

        self.titleCollection.delegate = self
        self.titleCollection.dataSource = self
        let titleIdentifier = String(describing: AudioKeboardTitleCell.self)
        self.titleCollection.register(AudioKeboardTitleCell.self, forCellWithReuseIdentifier: titleIdentifier)
        self.addSubview(self.titleCollection)
        self.titleCollection.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.height.equalTo(34)
            maker.bottom.equalTo(self.safeAreaLayoutGuide.snp.bottom).offset(-19)
        }

        self.items.forEach { (item) in
            item.keyboardFocusBlock = { [weak self] (focus) in
                self?.contentCollection.isScrollEnabled = !focus
                self?.titleCollection.isHidden = focus
            }
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: override func
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.bounds.size != self.originSize {
            self.originSize = self.bounds.size

            self.titleCollection.contentInset = UIEdgeInsets(top: 0, left: self.bounds.width, bottom: 0, right: self.bounds.width)
            self.flowLayout.itemSize = CGSize(width: self.bounds.width, height: CGFloat(self.getKeyboardHeight))
            self.flowLayout.invalidateLayout()
            self.contentCollection.reloadData()
            updateSelectIndex(selectIndex, changeKVStore: false, animated: false)
        }
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.items.forEach({ $0.resetKeyboardView() })
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        guard self.window != nil, !self.didMovedToWindowFlag else { return }
        self.didMovedToWindowFlag = true
        DispatchQueue.main.async { [weak self] in
            self?.items.forEach({ $0.resetKeyboardView() })
            let recognitionType = RecognizeLanguageManager.shared.recognitionType
            if let itemEnumerated = self?.items.enumerated().first(where: {
                return $1.recognitionType == recognitionType
            }) {
                self?.updateSelectIndex(itemEnumerated.offset, animated: false)
            }
        }
    }

    // MARK: Public func
    func resetKeyboardView() {
        self.items.forEach({ $0.resetKeyboardView() })
    }

    // MARK: update point
    func updateSelectIndex(_ index: Int, changeKVStore: Bool = true, animated: Bool = true) {
        guard index >= 0, index < items.count else { return }
        if changeKVStore {
            let item = items[index]
            /// 埋点
            let clickTo: AudioTracker.VoiceMsgClickFrom
            switch item.recognitionType {
            case .audio: clickTo = .recordingView
            case .text: clickTo = .speechToText
            case .audioWithText: clickTo = .speechPlusText
            }
            AudioTracker.imChatVoiceMsgClick(click: clickTo, viewType: RecognizeLanguageManager.shared.recognitionType)
            RecognizeLanguageManager.shared.recognitionType = item.recognitionType
        }

        selectIndex = index
        updateTitlePoint(index: index, animated: animated)
        updateContentPoint(index: index)
    }
    func updateContentPoint(index: Int) {
        let point = CGPoint(x: Int(self.bounds.width) * index, y: 0)
        self.contentCollection.setContentOffset(point, animated: false)
    }

    func updateTitlePoint(index: Int, animated: Bool = true) {
        guard let centerX = smalleCellDic[index]?.1 ?? titleCollection.layoutAttributesForItem(at: IndexPath(row: index, section: 0))?.center.x else { return }
        let point = CGPoint(x: centerX - self.bounds.width / 2, y: 0)
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.titleCollection.setContentOffset(point, animated: false)
            }, completion: {_ in
                self.titleCollection.reloadData()
            })
        } else {
            self.titleCollection.setContentOffset(point, animated: false)
            self.titleCollection.reloadData()
        }
    }

    // MARK: calculate func
    func calculateContentWillIndex() -> Int? {
        if self.contentCollection.bounds.width <= 0 { return nil }
        let index = Int(self.contentCollection.contentOffset.x / self.contentCollection.bounds.width)
        return index
    }

    func calculateTitleIndex() -> Int? {
        let center = self.titleCollection.contentOffset.x + self.bounds.width / 2

        if let minRange, center < minRange { return 0 }
        if let maxRange, center > maxRange { return items.count - 1 }

        // 在当前的区域内
        if let value = smalleCellDic[selectIndex], value.0.contains(center) {
            return selectIndex
        }

        // 在其他查找
        if let index = smalleCellDic.first(where: { return $0 != selectIndex && $1.0.contains(center) }) {
            return index.key
        }

        return nil
    }

    // MARK: update Dic
    private func updataCellDicWithIndex(_ indexPath: IndexPath) {
        let i = indexPath.row
        if let attributes = titleCollection.layoutAttributesForItem(at: indexPath) {
            let center = attributes.center.x
            smalleCellDic[i] = (center - 40 ..< center + 40, center)
            if i == 0 { minRange = center - 40 }
            if i == items.count - 1 { maxRange = center + 40 }
        } else {
            smalleCellDic[i] = (-25 ..< 55, 15)
        }
    }
}

// MARK: collection delegate
extension AudioKeyboardContainer: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == self.titleCollection {
            let title = self.items[indexPath.row].title
            let rect = NSString(string: title).boundingRect(
                with: CGSize(width: 1000, height: CGFloat(MAXFLOAT)),
                options: .usesLineFragmentOrigin,
                attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)], context: nil)
            return CGSize(width: ceil(rect.width), height: 34)
        }

        let keyboardHeight = self.getKeyboardHeight
        let containerHeight = keyboardHeight
        let itemSize = CGSize(width: self.bounds.width, height: CGFloat(containerHeight))
        return itemSize
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        updataCellDicWithIndex(indexPath)
        if collectionView == self.contentCollection {
            let contentIdentifier = String(describing: AudioKeyboardContentCell.self)
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: contentIdentifier, for: indexPath) as? AudioKeyboardContentCell {
                cell.set(keyboardView: self.items[indexPath.row].keyboardView)
                return cell
            }
        } else {
            let titleIdentifier = String(describing: AudioKeboardTitleCell.self)
            if let cell = collectionView.dequeueReusableCell(withReuseIdentifier: titleIdentifier, for: indexPath) as? AudioKeboardTitleCell {
                cell.set(
                    title: self.items[indexPath.row].title,
                    isSelectedKeyboard: indexPath.row == self.selectIndex,
                    showSelectedLine: indexPath.row == self.selectIndex && self.items.count > 1
                )
                return cell
            }
        }
        return UICollectionViewCell(frame: .zero)
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: false)
        if collectionView == titleCollection {
            updateSelectIndex(indexPath.row, animated: true)
        }
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        if scrollView == titleCollection, let newIndex = calculateTitleIndex() {
            updateSelectIndex(newIndex)
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == contentCollection, let newIndex = calculateContentWillIndex() {
            updateSelectIndex(newIndex)
        }
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate, scrollView == titleCollection, let newIndex = calculateTitleIndex() else { return }
        updateSelectIndex(newIndex)
    }
}
