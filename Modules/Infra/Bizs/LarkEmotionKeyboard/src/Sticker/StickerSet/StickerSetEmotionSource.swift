//
//  StickerSetEmotionSource.swift
//  LarkKeyboardView
//
//  Created by 李晨 on 2019/8/28.
//

import UIKit
import Foundation
import SnapKit
import RxSwift
import RxCocoa
import LarkUIKit
import LarkModel
import RustPB
import ByteWebImage

public protocol StickerSetEmotionSourceDelegate: AnyObject {
    func allStickerSetItems() -> [RustPB.Im_V1_StickerSet]
    func stickerSetReloadDriver() -> Driver<Void>
    func sendSticker(_ sticker: RustPB.Im_V1_Sticker, stickersCount: Int)
    func clickStickerSetting()
}

final public class StickerSetEmotionSource: EmotionItemDataSourceSet, StickerSetItemEmotionSourceDelegate {

    private let disposeBag = DisposeBag()

    weak var keyboard: EmotionKeyboardView?

    var items: [StickerSetItemSource] = []

    public var identifier: String {
        return "stickerSet"
    }

    public init() {}

    public weak var delegate: StickerSetEmotionSourceDelegate? {
        didSet {
            self.updateItems()
            self.delegate?
                .stickerSetReloadDriver()
                .drive(onNext: { [weak self] (_) in
                    self?.updateItems()
                    self?.keyboard?.reloadEmotionKeyboard()
                }).disposed(by: self.disposeBag)
        }
    }

    public func setupEmotion(keyboard: EmotionKeyboardView) {
        self.keyboard = keyboard
    }

    public func sourceItems() -> [EmotionItemDataSource] {
        return items
    }

    func updateItems() {
        self.items = self.delegate?.allStickerSetItems().map({ (set) -> StickerSetItemSource in
            let source = StickerSetItemSource(stickerSet: set)
            source.delegate = self
            return source
        }) ?? []
    }

    func sendSticker(_ sticker: RustPB.Im_V1_Sticker, stickersCount: Int) {
        self.delegate?.sendSticker(sticker, stickersCount: stickersCount)
    }

    func clickStickerSetting() {
        self.delegate?.clickStickerSetting()
    }
}

protocol StickerSetItemEmotionSourceDelegate: AnyObject {
    func sendSticker(_ sticker: RustPB.Im_V1_Sticker, stickersCount: Int)
    func clickStickerSetting()
}

final class StickerSetItemSource: EmotionItemDataSource {

    func longPressedAt(indexPath: IndexPath, cell: UICollectionViewCell) {
        guard let cell = cell as? StickerSetEmotionCell else {
            return
        }
        self.lastShowFloatViewCell?.removeFloatView()
        self.lastShowFloatViewCell = cell
        cell.showFloatView()
    }

    func longPressedEnd(indexPath: IndexPath, cell: UICollectionViewCell) {
        guard let cell = cell as? StickerSetEmotionCell else {
            return
        }
        self.lastShowFloatViewCell?.removeFloatView()
        cell.removeFloatView()
    }

    func didHighlightItemAt(indexPath: IndexPath, cell: UICollectionViewCell?) {}

    func didUnHighlightItemAt(indexPath: IndexPath, cell: UICollectionViewCell?) {}

    var identifier: String {
        return "stickerSet-\(self.stickerSet.stickerSetID)"
    }

    weak var delegate: StickerSetItemEmotionSourceDelegate?

    weak var collection: UICollectionView?

    var stickerSet: RustPB.Im_V1_StickerSet

    var iconImageView = UIImageView()

    /// 上一次展示floatView的cell
    private var lastShowFloatViewCell: StickerSetEmotionCell?

    fileprivate lazy var actionView: UIView = {
        let actionView = UIView()
        actionView.backgroundColor = UIColor.ud.bgBody
        actionView.layer.ud.setShadowColor(UIColor.ud.shadowDefaultLg)
        actionView.layer.shadowOpacity = 0.1
        actionView.layer.shadowOffset = CGSize(width: -2, height: 0)
        actionView.layer.shadowRadius = 2
        return actionView
    }()

    lazy var actionButton: UIButton = {
        let actionButton = UIButton()
        actionButton.backgroundColor = UIColor.clear
        actionButton.setImage(Resources.emotion_setting.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        return actionButton
    }()

    private lazy var trackKit = StickerTrackKit(identifier: self.stickerSet.stickerSetID)

    init(stickerSet: RustPB.Im_V1_StickerSet) {
        self.stickerSet = stickerSet
        self.actionView.addSubview(self.actionButton)
        actionButton.snp.makeConstraints({ make in
            make.centerY.equalToSuperview()
            make.height.equalTo(24)
            make.width.equalTo(24)
            make.right.equalToSuperview().offset(-15)
        })
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
    }

    func emotionInsets() -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 15, bottom: 15, right: 16)
    }

    func numberOfOneRow() -> Int {
        if !Display.pad { return 5 }
        let minNumber: Int = 5
        let maxNumber: Int = 13
        let minSpace: CGFloat = 12
        let itemSize = emotionItemDefaultSize()
        guard let collectionView = self.collection,
            collectionView.bounds.width > 0 else {
                return minNumber
        }
        let width = collectionView.bounds.width
        var number: Int = Int((width - minSpace) / (itemSize.width + minSpace))
        number = min(max(minNumber, number), maxNumber)
        return number
    }

    func emotionLineSpacing() -> CGFloat {
        return Const.emotionLineSpacing
    }
    
    public func emotionMinimumInteritemSpacing(section: Int) -> CGFloat {
        guard let collectionView = self.collection, collectionView.bounds.width > 0 else {
            return 0
        }
        
        let size = self.emotionItemDefaultSize()
        let number = self.numberOfOneRow()
        let insets = self.emotionInsets()
        
        let space = CGFloat(
            (collectionView.bounds.width -
                size.width * CGFloat(number) -
                insets.left -
                insets.right) /
                CGFloat(number - 1)
            )
        return space
    }

    func emotionItemDefaultSize() -> CGSize {
        return CGSize(width: 64, height: 70)
    }
    
    /// 每个表情的具体size：具体到某行某列，引入LarkValue后表情就不是等宽的了
    func emotionItemSize(indexPath: IndexPath) -> CGSize {
        return self.emotionItemDefaultSize()
    }

    func headerReferenceSize() -> CGSize {
        return .zero
    }

    func needAddEmptyView() -> Bool {
        return self.stickerSet.stickers.isEmpty
    }

    func didSelect() {}

    func didSwitch() {}

    func numberOfSections() -> Int {
        return 1
    }

    func numberOfEmotions(section: Int) -> Int {
        return self.stickerSet.stickers.count
    }

    func didSelectEmotion(indexPath: IndexPath) {
        let sticker = self.stickerSet.stickers[indexPath.row]
        self.delegate?.sendSticker(sticker, stickersCount: self.stickerSet.stickers.count)
    }

    func collectionView(collectionView: UICollectionView, insetForSectionAt section: Int, bottomBarHeight: CGFloat) -> UIEdgeInsets {
        var edgeInsets = self.emotionInsets()
        edgeInsets.bottom += bottomBarHeight
        return edgeInsets
    }

    func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let name = String(describing: StickerSetEmotionHeaderView.self)
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                       withReuseIdentifier: name,
                                                                       for: indexPath)
            return cell
        }
        return UICollectionReusableView()
    }

    func collectionCell(collection: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        let name = String(describing: StickerSetEmotionCell.self)
        let sticker = self.stickerSet.stickers[indexPath.row]
        let cell = collection.dequeueReusableCell(withReuseIdentifier: name, for: indexPath)
        if let collectionCell = cell as? StickerSetEmotionCell {
            collectionCell.imageLoadCallBack = { [weak self] (sticker, result) in
                if let sticker = sticker {
                    self?.trackKit.set(stickerID: sticker.stickerID, state: result)
                }
            }
            collectionCell.sticker = sticker
        }
        return cell
    }

    public func setupCollectionView(containerView: EmotionKeyboardItemView, collection: UICollectionView) {
        self.collection = collection
        var name = String(describing: StickerSetEmotionCell.self)
        collection.register(StickerSetEmotionCell.self, forCellWithReuseIdentifier: name)
        name = String(describing: StickerSetEmotionHeaderView.self)
        collection.register(StickerSetEmotionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: name)
    }

    func setupSourceIconImage(_ callback: @escaping (UIImage) -> Void) {
        callback(UIImage())
        iconImageView.bt.setLarkImage(with: .sticker(key: self.stickerSet.icon.key, stickerSetID: self.stickerSet.stickerSetID),
                                      trackStart: {
                                        return TrackInfo(scene: .Chat, fromType: .sticker)
                                      },
                                      completion: { result in
                                        if let icon = try? result.get().image {
                                            callback(icon)
                                        }
                                      })
    }

    func updateActionBtnIfNeeded() {}

    public func emotionActionViewWidth() -> CGFloat {
        return Const.emotionActionViewWidth
    }

    func emotionActionView(excludeSendBtn: Bool) -> UIView? {
        return self.actionView
    }

    func emotionEmptyView() -> UIView? {
        return nil
    }

    @objc
    fileprivate func actionButtonTapped() {
        self.delegate?.clickStickerSetting()
    }
    func onKeyboardStatusChange(isFold: Bool) {}
}

extension StickerSetItemSource {
    enum Const {
        public static let emotionLineSpacing: CGFloat = 16
        public static let emotionActionViewWidth: CGFloat = 52
    }
}
