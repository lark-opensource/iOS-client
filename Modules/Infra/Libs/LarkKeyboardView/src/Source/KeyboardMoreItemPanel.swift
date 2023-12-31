//
//  KeyboardMoreItemPanel.swift
//  Lark
//
//  Created by lichen on 2018/7/27.
//  Copyright © 2018年 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import SnapKit
import LarkUIKit
import RxSwift
import RxCocoa
import LarkContainer
import LarkBadge
import FigmaKit
import UniverseDesignBadge
import UniverseDesignColor

public struct BaseKeyboardMoreItem {
    public let customViewBlock: ((UIView) -> Void)?
    public let icon: UIImage
    public let selectIcon: UIImage?
    public let tapped: () -> Void
    public let text: String
    public let badgeText: String?
    public let showDotBadge: Bool
    public let isDynamic: Bool

    public init(
        text: String,
        icon: UIImage,
        selectIcon: UIImage?,
        badgeText: String?,
        showDotBadge: Bool,
        isDynamic: Bool,
        customViewBlock: ((UIView) -> Void)?,
        tapped: @escaping () -> Void) {
        self.text = text
        self.showDotBadge = showDotBadge
        self.isDynamic = isDynamic
        self.selectIcon = selectIcon
        self.icon = icon
        self.tapped = tapped
        self.badgeText = badgeText
        self.customViewBlock = customViewBlock
    }
}


final class PanelButton: UIButton {
    override func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        return self.bounds
    }
}

public final class KeyboardMorePanelCell: UICollectionViewCell {
    public var item: BaseKeyboardMoreItem? {
        didSet {
            if item?.isDynamic == true {
                button.snp.remakeConstraints { (make) in
                    make.edges.equalToSuperview()
                }
            } else {
                button.snp.remakeConstraints { (make) in
                    make.center.equalToSuperview()
                    make.size.equalTo(CGSize(width: 24, height: 24))
                }
            }
            button.setImage(item?.icon, for: .normal)
            button.addTarget(self, action: #selector(btnTapped), for: .touchUpInside)
            label.text = item?.text

            if let badgeText = item?.badgeText, !badgeText.isEmpty {
                textBadge.isHidden = false
                textBadge.config.text = badgeText
            } else {
                textBadge.isHidden = true
            }
            if let showDotBadge = item?.showDotBadge {
                dotBadge.isHidden = !showDotBadge
            } else {
                dotBadge.isHidden = true
            }

            self.customView.subviews.forEach { $0.removeFromSuperview() }
            if let customViewBlock = item?.customViewBlock {
                customViewBlock(self.customView)
            }
        }
    }

    lazy var button: PanelButton = {
        let btn = PanelButton(type: .custom)
        return btn
    }()

    lazy var label: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 12)
        label.textColor = UIColor.ud.textCaption
        label.numberOfLines = 2
        label.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(btnTapped))
        label.addGestureRecognizer(tap)
        return label
    }()

    private lazy var smoothRectView: SquircleView = {
        let smoothRectView: SquircleView = SquircleView()
        smoothRectView.backgroundColor = UIColor.ud.bgFloat & UIColor.ud.bgFloatOverlay
        smoothRectView.cornerRadius = 12
        let tap = UITapGestureRecognizer(target: self, action: #selector(btnTapped))
        smoothRectView.addGestureRecognizer(tap)
        return smoothRectView
    }()

    private lazy var dotBadge: UDBadge = {
        let dotBadge = UDBadge(config: .dot)
        dotBadge.config.dotSize = .large
        dotBadge.config.style = .dotBGRed
        return dotBadge
    }()

    private lazy var textBadge: UDBadge = {
        let textBadge = UDBadge(config: .text)
        return textBadge
    }()

    var customView: UIView = UIView()

    override public init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(smoothRectView)
        smoothRectView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview()
            make.width.height.equalTo(52)
        }
        smoothRectView.addSubview(button)

        contentView.addSubview(label)
        label.snp.makeConstraints { (make) in
            make.centerX.equalTo(button)
            make.left.equalTo(self.contentView).offset(5)
            make.right.equalTo(self.contentView).offset(-5)
            make.top.equalTo(smoothRectView.snp.bottom).offset(6)
        }

        self.contentView.addSubview(self.customView)
        self.customView.isUserInteractionEnabled = false
        self.customView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        self.contentView.addSubview(dotBadge)
        dotBadge.isHidden = true
        dotBadge.snp.makeConstraints { make in
            make.centerX.equalTo(smoothRectView.snp.right)
            make.centerY.equalTo(smoothRectView.snp.top)
        }

        self.contentView.addSubview(textBadge)
        textBadge.isHidden = true
        textBadge.snp.makeConstraints { (make) in
            make.centerX.equalTo(smoothRectView.snp.right)
            make.centerY.equalTo(smoothRectView.snp.top)
        }
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    func btnTapped() {
        item?.tapped()
    }
}

public final class KeyboardMoreItemPanel: UIView, UICollectionViewDelegate, UICollectionViewDataSource {

    let identifyStr: String = "more.keyboard.identifyStr"

    private var items: [BaseKeyboardMoreItem] = []
    private let bag = DisposeBag()

    private var originSize: CGSize = .zero

    public override var bounds: CGRect {
        didSet {
            self.updateCollectionLayout()
        }
    }

    fileprivate var collection: UICollectionView = .init(frame: .zero, collectionViewLayout: .init())
    fileprivate var layout: UICollectionViewFlowLayout!
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        self.collection.reloadData()
    }

    public init(observableItems: Driver<[BaseKeyboardMoreItem]>) {
        super.init(frame: .zero)
        self.setupViews()
        observableItems
            .drive(onNext: { [weak self] items in
                guard let self = self else { return }
                self.items = items
                self.collection.reloadData()
            }).disposed(by: bag)

    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        self.updateCollectionLayout()
    }
    func updateCollectionLayout()  {
        if self.frame.size != self.originSize {
            self.layout.itemSize = self.itemSizeForItem()
            self.layout.invalidateLayout()
            self.collection.reloadData()
            self.originSize = self.frame.size
        }
    }

    public func setupViews() {
        self.backgroundColor = UIColor.ud.bgBodyOverlay
        self.lu.addTopBorder(color: UIColor.ud.N300)

        self.layout = UICollectionViewFlowLayout()
        self.layout.itemSize = self.itemSizeForItem()
        self.layout.sectionInset = UIEdgeInsets(top: 20, left: 12, bottom: 20, right: 12)
        self.layout.minimumLineSpacing = 0
        self.layout.minimumInteritemSpacing = 0
        let collection = UICollectionView(frame: CGRect.zero, collectionViewLayout: self.layout)
        collection.backgroundColor = UIColor.clear
        collection.showsVerticalScrollIndicator = false
        collection.showsHorizontalScrollIndicator = false
        collection.dataSource = self
        collection.delegate = self
        collection.register(KeyboardMorePanelCell.self, forCellWithReuseIdentifier: self.identifyStr)
        self.addSubview(collection)
        collection.snp.makeConstraints({ make in
            make.edges.equalToSuperview()
        })
        self.collection = collection
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func itemSizeForItem() -> CGSize {
        let padding: CGFloat = 16
        let itemWidth = (self.bounds.width - padding * 2 ) / 4
        let itemHeight: CGFloat = 96
        return CGSize(width: itemWidth, height: itemHeight)
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let collectionViewCell: KeyboardMorePanelCell = collectionView.dequeueReusableCell(withReuseIdentifier: self.identifyStr, for: indexPath) as? KeyboardMorePanelCell else {
            return UICollectionViewCell(frame: CGRect.zero)
        }
        let item = self.items[indexPath.row]
        collectionViewCell.item = item
        return collectionViewCell
    }
}
extension KeyboardMoreItemPanel {
    public static func keyboard(iconColor: UIColor?) -> KeyboardInfo {
        return KeyboardInfo(
            icon: Resources.others_plus,
            selectedIcon: Resources.others_close,
            unenableIcon: nil,
            tintColor: iconColor ?? UIColor.ud.N500
        )
    }
}
