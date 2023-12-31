//
//  ChoicesCollectionView.swift
//  ByteView
//
//  Created by wulv on 2020/6/15.
//

import Foundation
import UIKit
import SnapKit
import RxSwift
import RxCocoa
import ByteViewNetwork
import UniverseDesignColor

extension LiveLayout: ChoiceCollectionItem {

    static var validCases: [LiveLayout] {
        return [.list, .gallery, .simple, .speaker]
    }

    var type: ChoiceCollectionType? {
        switch self {
        case .simple:
            return .fullscreen
        case .list:
            return .sidebar
        case .gallery:
            return .gallery
        case .speaker:
            return .pictureInPicture
        default:
            return nil
        }
    }
}

class SpeakerView: UIView {
    let shapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.black.cgColor
        return layer
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        layer.cornerRadius = 5
        backgroundColor = UDColor.N300
        layer.mask = shapeLayer
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        mask?.layer.frame = bounds
        let path = UIBezierPath(rect: bounds)
        let rect = CGRect(x: bounds.width * 0.72,
                          y: bounds.height * 0.0625,
                          width: bounds.width * 0.24,
                          height: bounds.height * 0.25)
        let rectPath = UIBezierPath(roundedRect: rect, cornerRadius: 2.7).reversing()
        rectPath.usesEvenOddFillRule = true
        path.append(rectPath)
        shapeLayer.path = path.cgPath
    }
}

enum ChoiceCollectionType: Equatable {
    case sidebar
    case gallery
    case fullscreen
    case pictureInPicture

    var content: String {
        switch self {
        case .sidebar:
            return I18n.View_M_Sidebar
        case .gallery:
            return I18n.View_M_Gallery
        case .fullscreen:
            return I18n.View_M_FullScreenLayout
        case .pictureInPicture:
            return I18n.View_M_SpeakerView_Desc
        }
    }

    func image(_ isSelected: Bool) -> UIImage? {
        switch self {
        case .sidebar:
            return BundleResources.ByteView.Live.ListViewUnselected
        case .gallery:
            return BundleResources.ByteView.Live.GalleryViewUnselected
        case .fullscreen:
            return BundleResources.ByteView.Live.FullScreenUnselected
        case .pictureInPicture:
            return nil
        }
    }

    var customView: UIView? {
        switch self {
        case .sidebar:
            return nil
        case .gallery:
            return nil
        case .fullscreen:
            return nil
        case .pictureInPicture:
            return SpeakerView()
        }
    }

    var order: Int {
        switch self {
        case .sidebar:
            return 0
        case .gallery:
            return 1
        case .fullscreen:
            return 2
        case .pictureInPicture:
            return 3
        }
    }
}

protocol ChoiceCollectionItem {
    var type: ChoiceCollectionType? { get }
}

struct AnyChoiceCollectionItem<T: ChoiceCollectionItem>: Equatable {

    static func == (lhs: AnyChoiceCollectionItem<T>, rhs: AnyChoiceCollectionItem<T>) -> Bool {
        return lhs.type == rhs.type
    }

    var base: T
    var isSelected: Bool
    var isEnable: Bool

    var type: ChoiceCollectionType? {
        return base.type
    }
}

class ChoiceCollectionViewCell: UICollectionViewCell {

    enum Layout {
        static let imageWidthHeightRatio = CGFloat(101.0 / 64.0)
        static let imageMaxWidth = CGFloat(114)
        static let titleTopToImage = CGFloat(8)
        static let titleBottom = CGFloat(0)
        static let titleFontSize = CGFloat(16)
        static let titleLineHeight = CGFloat(22)
    }

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: Layout.titleFontSize)
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private let imageContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.addInteraction(type: .hover)
        return view
    }()

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleToFill
        imageView.layer.cornerRadius = 4
        imageView.layer.masksToBounds = true
        return imageView
    }()

    private let selectedView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        view.layer.borderWidth = 2
        view.layer.ud.setBorderColor(UIColor.ud.primaryFillHover)
        view.isHidden = true
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        initialize()
    }

    private func initialize() {
        contentView.addSubview(imageContainer)
        imageContainer.addSubview(selectedView)
        imageContainer.addSubview(imageView)

        imageContainer.snp.makeConstraints { (make) in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(imageContainer.snp.width).dividedBy(Layout.imageWidthHeightRatio)
        }
        imageView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        selectedView.snp.makeConstraints { (make) in
            make.center.equalTo(imageContainer.snp.center)
            make.height.equalTo(imageContainer.snp.height).offset(6)
            make.width.equalTo(imageContainer.snp.width).offset(6)
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(imageContainer.snp.bottom).offset(Layout.titleTopToImage)
        }
    }

    var customSelected: Bool = false {
        didSet {
            selectedView.isHidden = !customSelected
        }
    }

    var isEnable: Bool = true {
        didSet {
            self.isUserInteractionEnabled = isEnable
        }
    }

    var customView: UIView?

    func setItem<T: ChoiceCollectionItem>(_ item: AnyChoiceCollectionItem<T>) {
        imageView.image = item.type?.image(item.isSelected)
        customView?.removeFromSuperview()
        if let customView = item.type?.customView {
            self.customView = customView
            imageContainer.addSubview(customView)
            customView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        customSelected = item.isSelected
        isEnable = item.isEnable
        guard let text = item.type?.content else { return }
        titleLabel.attributedText = NSAttributedString(string: text, config: .body, alignment: .center)
    }
}

class ChoicesCollectionView<T: ChoiceCollectionItem>: UIView, UICollectionViewDelegateFlowLayout {
    var disposeBag = DisposeBag()

    // 横竖屏大小一样且固定，其余间隔等间隔间距
    private let itemSize = CGSize(width: 90, height: 57)

    private lazy var layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumInteritemSpacing = self.itemSpacing
        layout.sectionInset = .zero
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.register(ChoiceCollectionViewCell.self,
                                forCellWithReuseIdentifier: NSStringFromClass(ChoiceCollectionViewCell.self))
        collectionView.rx
            .setDelegate(self)
            .disposed(by: disposeBag)
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.backgroundColor = .clear
        collectionView.layer.masksToBounds = false
        return collectionView
    }()

    private var items: [AnyChoiceCollectionItem<T>] = [] {
        didSet {
            updateCollectionViewAndItemHeight()
            itemsRelay.accept(items)
        }
    }
    private var itemsRelay = BehaviorRelay<[AnyChoiceCollectionItem<T>]>(value: [])

    private var itemSpacing: CGFloat = 0
    private var itemHeight: CGFloat = 0
    private var itemWidth: CGFloat = 0

    var handler: (([T]) -> Void)?

    private var selectedItems: [T] {
        return items
            .filter { $0.isSelected }
            .map { $0.base }
    }

    init(items: [AnyChoiceCollectionItem<T>], spacing: CGFloat = 0) {
        super.init(frame: .zero)
        self.itemSpacing = spacing
        initialize()
        self.items = items
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initialize() {
        addSubview(collectionView)
        var spacing: CGFloat = 0
        if bounds.width > 0 {
            let itemsCount = CGFloat(items.count)
            spacing = (bounds.width - itemSize.width * itemsCount) / (itemsCount + 1)
            if spacing > itemSpacing {
                itemSpacing = spacing
            }
        }
        collectionView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
            make.height.equalTo(0)
        }
        collectionView.contentInset.left = itemSpacing
        collectionView.contentInset.right = itemSpacing

        itemsRelay.asObservable()
            .observeOn(MainScheduler.instance)
            .bind(to: collectionView.rx.items(cellIdentifier: NSStringFromClass(ChoiceCollectionViewCell.self),
                                              cellType: ChoiceCollectionViewCell.self)) { (_, item, cell) in
                cell.setItem(item)
            }
            .disposed(by: disposeBag)

        collectionView.rx.itemSelected
            .subscribe(onNext: { [weak self] indexPath in
                guard let self = self else { return }
                var items: [AnyChoiceCollectionItem<T>] = []
                for (i, var item) in self.items.enumerated() {
                    item.isSelected = (i == indexPath.item)
                    items.append(item)
                }
                self.items = items
                self.handler?(self.selectedItems)
            })
            .disposed(by: rx.disposeBag)
    }

    func reload(with items: [AnyChoiceCollectionItem<T>]? = nil, spacing: CGFloat? = nil) {
        if let spacing = spacing {
            itemSpacing = spacing
        }
        var spacingInView: CGFloat = 0
        if let items = items {
            if bounds.width > 0 {
                let itemsCount = CGFloat(items.count)
                spacingInView = (bounds.width - itemSize.width * itemsCount) / (itemsCount + 1)
                if spacingInView > itemSpacing {
                    itemSpacing = spacingInView
                }
            }
            self.items = items
        }
        collectionView.contentInset.left = itemSpacing
        collectionView.contentInset.right = itemSpacing
        collectionView.reloadData()
    }

    private func updateCollectionViewAndItemHeight() {
        itemHeight = 0
        for item in items {
            let height = self.itemHeightFor(item: item,
                                            allCount: items.count,
                                            allWidth: collectionView.bounds.width)
            if itemHeight < height {
                itemHeight = height
            }
        }
        collectionView.snp.updateConstraints { (make) in
            make.height.equalTo(itemHeight)
        }
    }

    private func itemWidthFor(allCount: Int, allWidth: CGFloat) -> CGFloat {
        guard allCount > 0 else { return 0 }
        layout.minimumLineSpacing = itemSpacing
        return self.itemSize.width
    }

    private func itemHeightFor(item: AnyChoiceCollectionItem<T>, allCount: Int, allWidth: CGFloat) -> CGFloat {
        let itemWidth = itemWidthFor(allCount: allCount, allWidth: allWidth)
        let imageHeight = CGFloat(itemWidth / ChoiceCollectionViewCell.Layout.imageWidthHeightRatio)
        var titleHeight: CGFloat = 0
        if let title = item.type?.content, !title.isEmpty {
            let font = UIFont.systemFont(ofSize: ChoiceCollectionViewCell.Layout.titleFontSize)
            let width = title.vc.boundingWidth(height: ChoiceCollectionViewCell.Layout.titleLineHeight, font: font)
            let numberOfLines = ceil(width / itemWidth)
            titleHeight = ChoiceCollectionViewCell.Layout.titleLineHeight * numberOfLines
        }
        let itemHeight = imageHeight +
            ChoiceCollectionViewCell.Layout.titleTopToImage +
            titleHeight +
            ChoiceCollectionViewCell.Layout.titleBottom
        return itemHeight
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard indexPath.row < items.count else { return .zero }
        if indexPath.item == 0 {
            let width = collectionView.frame.size.width
            itemWidth = itemWidthFor(allCount: items.count, allWidth: CGFloat(width))
            updateCollectionViewAndItemHeight()
        }
        return CGSize(width: itemWidth, height: itemHeight)
    }
}
