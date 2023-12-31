//
//  StickerEmotionSource.swift
//  Lark
//
//  Created by lichen on 2017/11/15.
//  Copyright © 2017年 Bytedance.Inc. All rights reserved.
//

import UIKit
import Foundation
import SnapKit
import RxSwift
import RxCocoa
import LarkUIKit
import LarkModel
import RustPB

public protocol StickerEmotionSourceDelegate: AnyObject {
    func sendSticker(_ sticker: RustPB.Im_V1_Sticker, stickersCount: Int)
    func clickNewStickersButton()
    func clickStickerSetting()
    func allStickerItems() -> [RustPB.Im_V1_Sticker]
    func stickerReloadDriver() -> Driver<Void>
    /// 成功切换到当前视图
    func switchStickerSuccess()
}

final public class StickerEmotionV2Source: EmotionItemDataSource {

    public func longPressedAt(indexPath: IndexPath, cell: UICollectionViewCell) {
        guard let cell = cell as? StickerEmotionCell else {
            return
        }
        self.lastShowFloatViewCell?.removeFloatView()

        cell.showFloatView()
        self.lastShowFloatViewCell = cell
    }

    public func longPressedEnd(indexPath: IndexPath, cell: UICollectionViewCell) {
        guard let cell = cell as? StickerEmotionCell else {
            return
        }
        self.lastShowFloatViewCell?.removeFloatView()
        cell.removeFloatView()
    }

    public func didHighlightItemAt(indexPath: IndexPath, cell: UICollectionViewCell?) {}

    public func didUnHighlightItemAt(indexPath: IndexPath, cell: UICollectionViewCell?) {}

    public var identifier: String {
        return "customSticker"
    }

    weak var collection: UICollectionView?
    private var stickers: [RustPB.Im_V1_Sticker] = []

    lazy var actionView: UIView = {
        let actionView = UIView()
        actionView.backgroundColor = UIColor.ud.bgBody
        actionView.layer.ud.setShadowColor(UIColor.ud.shadowDefaultLg)
        actionView.layer.shadowOpacity = 0.1
        actionView.layer.shadowOffset = CGSize(width: -2, height: 0)
        actionView.layer.shadowRadius = 2
        return actionView
    }()

    var actionButton: UIButton = UIButton()

    /// 上一次展示floatView的cell
    private var lastShowFloatViewCell: StickerEmotionCell?
    private let disposeBag = DisposeBag()

    private lazy var trackKit = StickerTrackKit(identifier: "favorite")

    public weak var delegate: StickerEmotionSourceDelegate? {
        didSet {
            self.updateStickerItems()
            self.delegate?
                .stickerReloadDriver()
                .drive(onNext: { [weak self] (_) in
                    self?.updateStickerItems()
                    self?.collection?.reloadData()
                }).disposed(by: self.disposeBag)
        }
    }

    public init() {
        actionButton.backgroundColor = UIColor.clear
        actionButton.setImage(Resources.emotion_setting.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
        actionView.addSubview(actionButton)
        actionButton.snp.makeConstraints({ make in
            make.centerY.equalToSuperview()
            make.height.equalTo(24)
            make.width.equalTo(24)
            make.right.equalToSuperview().offset(-15)
        })
        actionButton.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
    }

    private func updateStickerItems() {
        self.stickers = self.delegate?.allStickerItems() ?? []
    }

    public func emotionInsets() -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 15, bottom: 15, right: 16)
    }

    public func numberOfOneRow() -> Int {
        if !Display.pad { return 4 }
        let minNumber: Int = 4
        let maxNumber: Int = 13
        let minSpace: CGFloat = 12
        let itemSize = emotionItemDefaultSize()
        guard let collectionView = self.collection,
            collectionView.bounds.width > 0 else {
                return minNumber
        }
        let width = collectionView.bounds.width
        if width < Const.iPadHorizontalAndVerticalThreshold, Display.pad {
            // 适配iPad竖屏状态下分屏的情况
            return 3
        }
        var number: Int = Int((width - minSpace) / (itemSize.width + minSpace))
        number = min(max(minNumber, number), maxNumber)
        return number
    }

    public func emotionLineSpacing() -> CGFloat {
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

    public func emotionItemDefaultSize() -> CGSize {
        return CGSize(width: 74, height: 74)
    }
    
    /// 每个表情的具体size：具体到某行某列，引入LarkValue后表情就不是等宽的了
    public func emotionItemSize(indexPath: IndexPath) -> CGSize {
        return self.emotionItemDefaultSize()
    }

    public func headerReferenceSize() -> CGSize {
        return .zero
    }

    public func needAddEmptyView() -> Bool {
        return self.stickers.isEmpty
    }

    public func didSelect() {}

    public func didSwitch() {
        self.delegate?.switchStickerSuccess()
    }

    public func numberOfSections() -> Int {
        return 1
    }

    public func numberOfEmotions(section: Int) -> Int {
        //如果是空的话,返回0,这样可以触发emptyView的展示,否则则+1,为了展示AddStickerEmotionCell
        if self.stickers.isEmpty {
            return 0
        }
        return self.stickers.count + 1
    }

    public func didSelectEmotion(indexPath: IndexPath) {
        if indexPath.row == 0 {
            self.delegate?.clickNewStickersButton()
        } else {
            let sticker = self.stickers[indexPath.row - 1]
            self.delegate?.sendSticker(sticker, stickersCount: stickers.count)
        }
    }

    public func collectionView(collectionView: UICollectionView, insetForSectionAt section: Int, bottomBarHeight: CGFloat) -> UIEdgeInsets {
        var edgeInsets = self.emotionInsets()
        edgeInsets.bottom += bottomBarHeight
        return edgeInsets
    }

    public func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionView.elementKindSectionHeader {
            let name = String(describing: StickerEmotionHeaderView.self)
            let cell = collectionView.dequeueReusableSupplementaryView(ofKind: kind,
                                                                       withReuseIdentifier: name,
                                                                       for: indexPath)
            return cell
        }
        return UICollectionReusableView()
    }

    public func collectionCell(collection: UICollectionView, indexPath: IndexPath) -> UICollectionViewCell {
        if indexPath.row == 0 {
            let name = String(describing: AddStickerEmotionCell.self)
            let cell = collection.dequeueReusableCell(withReuseIdentifier: name, for: indexPath)
            return cell
        } else {
            let name = String(describing: StickerEmotionCell.self)
            let sticker = self.stickers[indexPath.row - 1]
            let cell = collection.dequeueReusableCell(withReuseIdentifier: name, for: indexPath)
            if let collectionCell = cell as? StickerEmotionCell {
                collectionCell.imageLoadCallBack = { [weak self] (sticker, result) in
                    if let sticker = sticker {
                        self?.trackKit.set(stickerID: sticker.stickerID, state: result)
                    }
                }
                collectionCell.sticker = sticker
            }
            return cell
        }
    }

    public func setupCollectionView(containerView: EmotionKeyboardItemView, collection: UICollectionView) {
        self.collection = collection
        var name = String(describing: StickerEmotionCell.self)
        collection.register(StickerEmotionCell.self, forCellWithReuseIdentifier: name)
        name = String(describing: AddStickerEmotionCell.self)
        collection.register(AddStickerEmotionCell.self, forCellWithReuseIdentifier: name)
        name = String(describing: StickerEmotionHeaderView.self)
        collection.register(StickerEmotionHeaderView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: name)
    }

    public func setupSourceIconImage(_ callback: @escaping (UIImage) -> Void) {
        callback(Resources.stickerEmoji)
    }

    public func updateActionBtnIfNeeded() {}

    public func emotionActionViewWidth() -> CGFloat {
        return Const.emotionActionViewWidth
    }

    public func emotionActionView(excludeSendBtn: Bool) -> UIView? {
        return self.actionView
    }

    public func emotionEmptyView() -> UIView? {
        let emptyView = UIView()

        let addButton = UIButton()
        addButton.setImage(Resources.addStickerIcon, for: .normal)
        emptyView.addSubview(addButton)
        addButton.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.height.width.equalTo(74)
            make.top.equalTo(Display.height >= 812 ? 81 : 60)
        }
        addButton.addTarget(self, action: #selector(addButtonClick), for: .touchUpInside)

        let label = UILabel()
        emptyView.addSubview(label)
        label.text = BundleI18n.LarkEmotionKeyboard.Lark_Legacy_ClickToAddStickers
        label.font = UIFont.systemFont(ofSize: 18)
        label.textColor = UIColor.ud.N500
        label.snp.makeConstraints { (make) in
            make.top.equalTo(addButton.snp.bottom).offset(10)
            make.centerX.equalToSuperview()
        }
        return emptyView
    }

    @objc
    fileprivate func actionButtonTapped() {
        self.delegate?.clickStickerSetting()
    }

    @objc
    private func addButtonClick() {
        self.delegate?.clickNewStickersButton()
    }

    public func onKeyboardStatusChange(isFold: Bool) {
        if isFold {
            StickerTrackKit.leaveStickerPanel()
        }
    }
}

extension StickerEmotionV2Source {
    enum Const {
        public static let iPadHorizontalAndVerticalThreshold: CGFloat = 340
        public static let emotionLineSpacing: CGFloat = 15
        public static let emotionActionViewWidth: CGFloat = 52
    }
}
