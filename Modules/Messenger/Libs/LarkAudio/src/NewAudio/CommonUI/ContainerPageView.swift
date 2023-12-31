//
//  ContainerCollectionView.swift
//  LarkAudio
//
//  Created by kangkang on 2023/9/26.
//

import Foundation
import UniverseDesignColor

class ContainerPageView: UIView, AudioCollectionContainerView {
    enum Cons {
        static let collectionHeight: CGFloat = 36
        static let collectionTopOffset: CGFloat = 10
        static let pageSumHeight: CGFloat = collectionHeight + collectionTopOffset
    }
    var keyboardHeight: Float?
    private var originSize: CGSize = .zero
    private var didMovedToWindowFlag: Bool = false
    private var items: [(item: AudioKeyboardItemViewDelegate, center: CGFloat?)]
    private var selectIndex: Int = 0
    private let titleCollection: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.scrollDirection = .horizontal
        flowLayout.minimumLineSpacing = 50
        let collection = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        collection.backgroundColor = .clear
        return collection
    }()
    private let bigScrollView: UIScrollView = {
        let view = UIScrollView()
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.isPagingEnabled = true
        return view
    }()

    init(items: [AudioKeyboardItemViewDelegate]) {
        self.items = items.map({ ($0, nil) })
        super.init(frame: .zero)
        titleCollection.delegate = self
        titleCollection.dataSource = self
        self.addSubview(titleCollection)
        titleCollection.register(TitleCell.self, forCellWithReuseIdentifier: "title_cell")
        titleCollection.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.height.equalTo(Cons.collectionHeight)
            make.top.equalToSuperview().offset(Cons.collectionTopOffset)
        }

        self.addSubview(bigScrollView)
        items.forEach { view in
            bigScrollView.addSubview(view.keyboardView)
        }
        bigScrollView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(titleCollection.snp.bottom)
        }
        bigScrollView.delegate = self

        items.forEach { item in
            item.keyboardFocusBlock = { [weak self] (focus) in
                self?.bigScrollView.isScrollEnabled = !focus
                self?.titleCollection.isHidden = focus
            }
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        if self.bounds.size != self.originSize {
            originSize = self.bounds.size
            titleCollection.contentInset = UIEdgeInsets(top: 0, left: self.bounds.width, bottom: 0, right: self.bounds.width)
            let height = CGFloat(keyboardHeight ?? NewAudioKeyboard.keyboard(iconColor: nil).height) - Cons.pageSumHeight
            bigScrollView.contentSize = CGSize(width: self.bounds.width * CGFloat(items.count), height: height)
            for (i, s) in items.enumerated() {
                s.item.keyboardView.frame = CGRect(x: bounds.width * CGFloat(i) + 5, y: 0, width: bounds.width - 10, height: height)
            }
            setIndex(selectIndex, animation: false, changeKVStore: false)
        }
    }

    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.resetKeyboardView()
    }

    override func didMoveToWindow() {
        super.didMoveToWindow()
        if self.window != nil {
            guard !didMovedToWindowFlag else { return }
            didMovedToWindowFlag = true
            self.resetKeyboardView()
            let recognitionType = RecognizeLanguageManager.shared.recognitionType
            if let itemEnumerated = self.items.enumerated().first(where: {
                return $1.item.recognitionType == recognitionType
            }) {
                self.setIndex(itemEnumerated.offset, animation: false, changeKVStore: false)
            }
        } else {
            didMovedToWindowFlag = false
        }
    }

    public func resetKeyboardView() {
        self.items.forEach({ $0.item.resetKeyboardView() })
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setIndex(_ index: Int, animation: Bool = true, changeKVStore: Bool = true) {
        guard index >= 0, index < items.count else { return }
        self.selectIndex = index
        updateCollectionOffset(index: selectIndex, animation: animation)
        updateScrollOffset(index: selectIndex, animation: false)

        if changeKVStore {
            let item = items[index].item
            let clickTo: AudioTracker.VoiceMsgClickFrom
            switch item.recognitionType {
            case .audio: clickTo = .recordingView
            case .text: clickTo = .speechToText
            case .audioWithText: clickTo = .speechPlusText
            }
            AudioTracker.imChatVoiceMsgClick(click: clickTo, viewType: RecognizeLanguageManager.shared.recognitionType)
            RecognizeLanguageManager.shared.recognitionType = item.recognitionType
        }
    }

    private func updateCollectionOffset(index: Int, animation: Bool) {
        if let centerX = titleCollection.layoutAttributesForItem(at: IndexPath(row: index, section: 0))?.center.x {
            let offset = centerX - self.bounds.width / 2
            if animation {
                UIView.animate(withDuration: 0.2, animations: {
                    self.titleCollection.setContentOffset(CGPoint(x: offset, y: 0), animated: false)
                }) { (_) in
                    self.titleCollection.reloadData()
                }
            } else {
                self.titleCollection.setContentOffset(CGPoint(x: offset, y: 0), animated: false)
                self.titleCollection.reloadData()
            }
        }
    }

    private func updateScrollOffset(index: Int, animation: Bool) {
        let offset = self.bounds.width * CGFloat(index)
        bigScrollView.setContentOffset(CGPoint(x: offset, y: 0), animated: animation)
    }

    private func updateCellDicWithIndex(_ indexPath: IndexPath) {
        let i = indexPath.row
        if let attributes = titleCollection.layoutAttributesForItem(at: indexPath) {
            let center = attributes.center.x
            if items.count > i {
                var item = items[i]
                item.center = center
                items[i] = item
            }
        }
    }

    // 计算当前最接近的index
    private func calculateSmallIndex() -> Int? {
        guard !items.isEmpty else { return nil }
        let center = self.titleCollection.contentOffset.x + self.bounds.width / 2

        if let min = items[0].center, center <= min { return 0 } //超出最小
        if let max = items[items.count - 1].center, center >= max { return items.count - 1 } //超出最大

        var lastCenter: CGFloat?
        for (offset, item) in items.enumerated() {
            if let last = lastCenter, let cur = item.center {
                if center > last, center <= cur {
                    if (center - last) > (cur - center) {
                        return offset
                    } else {
                        return offset - 1
                    }
                }
            }
            lastCenter = item.center
        }
        return nil
    }

    // 计算当前最接近的index
    private func calculateBigWillIndex() -> Int? {
        if self.bigScrollView.bounds.width <= 0 { return nil }
        let index = Int(self.bigScrollView.contentOffset.x / self.bigScrollView.bounds.width + 0.5)
        return index
    }
}

// MARK: PageView Extension
extension ContainerPageView: UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let title = items[indexPath.row].item.title
        let rect = NSString(string: title).boundingRect(
            with: CGSize(width: 1000, height: CGFloat(MAXFLOAT)),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16)], context: nil)
        return CGSize(width: ceil(rect.width) + 20, height: 34)
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        updateCellDicWithIndex(indexPath)
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "title_cell", for: indexPath) as? TitleCell else { return UICollectionViewCell() }
        cell.setValue(text: items[indexPath.row].item.title, isHighlight: selectIndex == indexPath.row)
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        setIndex(indexPath.row)
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        guard !decelerate else { return }
        if scrollView == titleCollection {
            if let i = calculateSmallIndex() { setIndex(i) }
        }
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        if scrollView == titleCollection {
            if let i = calculateSmallIndex() { setIndex(i) }
        }
    }

    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == bigScrollView {
            if let i = calculateBigWillIndex() { setIndex(i) }
        }
    }
}

class TitleCell: UICollectionViewCell {
    let label = UILabel()
    let backView = UIView()
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(backView)
        self.addSubview(label)

        backView.layer.cornerRadius = 15
        backView.layer.shadowRadius = 2
        backView.backgroundColor = UDColor.bgBody

        backView.snp.makeConstraints { make in
            make.height.equalTo(30)
            make.left.equalTo(label.snp.left).offset(-5)
            make.right.equalTo(label.snp.right).offset(5)
            make.center.equalToSuperview()
        }
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }

    func setValue(text: String, isHighlight: Bool) {
        label.text = " " + text + " "
        if isHighlight {
            label.font = UIFont.boldSystemFont(ofSize: 16)
            label.textColor = UDColor.textTitle
            backView.isHidden = false
        } else {
            label.font = UIFont.systemFont(ofSize: 14)
            label.textColor = UDColor.textCaption
            backView.isHidden = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
