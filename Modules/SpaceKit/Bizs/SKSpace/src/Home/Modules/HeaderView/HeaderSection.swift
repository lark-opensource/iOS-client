//
//  HeaderSection.swift
//  SKSpace
//
//  Created by yinyuan on 2023/5/10.
//
import UIKit
import RxSwift
import RxRelay
import RxCocoa
import SKFoundation
import SKResource
import SKUIKit
import SKCommon
import UniverseDesignIcon
import LarkUIKit
import EENavigator
import LarkContainer

// Header 不需要贴顶，因此独立成 Section 而不是直接做成 UICollectionView.elementKindSectionHeader
public final class HeaderSection: SpaceSection {
    static let sectionIdentifier: String = "header"
    public var identifier: String { Self.sectionIdentifier }

    private let reloadInput = PublishRelay<ReloadAction>()
    public var reloadSignal: Signal<ReloadAction> {
        reloadInput.asSignal()
    }

    private let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }

    private let disposeBag = DisposeBag()
    
    public var headerInfo: SectionHeaderInfo? {
        didSet {
            self.reloadInput.accept(.reloadSection(animated: false))
        }
    }
    
    private let homeType: SpaceHomeType
        
    public let userResolver: UserResolver
    public init(userResolver: UserResolver,
                homeType: SpaceHomeType,
                headerInfo: SectionHeaderInfo? = nil) {
        self.userResolver = userResolver
        self.homeType = homeType
        self.headerInfo = headerInfo
    }

    public func prepare() {
    }

    public func notifyPullToRefresh() {
    }
    
    public func notifyPullToLoadMore() {
    }
}

extension HeaderSection: SpaceSectionLayout {
    
    public func itemSize(at index: Int, containerWidth: CGFloat) -> CGSize {
        return CGSize(width: containerWidth, height: headerInfo?.height ?? SectionHeaderView.height)
    }

    public func sectionInsets(for containerWidth: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0,
                            left: 0,
                            bottom: 0,
                            right: 0)
    }

    public func minimumLineSpacing(for containerWidth: CGFloat) -> CGFloat {
        0
    }

    public func minimumInteritemSpacing(for containerWidth: CGFloat) -> CGFloat {
        0
    }

    public func headerHeight(for containerWidth: CGFloat) -> CGFloat {
        0
    }

    public func footerHeight(for containerWidth: CGFloat) -> CGFloat {
        0
    }
}

extension HeaderSection: SpaceSectionDataSource {
    public var numberOfItems: Int {
        return 1
    }

    public func setup(collectionView: UICollectionView) {
        collectionView.register(SectionHeaderView.self,
                                forCellWithReuseIdentifier: SectionHeaderView.reuseIdentifier)
    }

    public func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SectionHeaderView.reuseIdentifier, for: indexPath)
        if let cell = cell as? SectionHeaderView {
            cell.update(headerInfo)
        }
        return cell
    }

    public func supplymentaryElementView(kind: String, indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionReusableView {
        return UICollectionReusableView()
    }

    public func dragItem(at indexPath: IndexPath,
                         sceneSourceID: String?,
                         collectionView: UICollectionView) -> [UIDragItem] {
        return []
    }
}

extension HeaderSection: SpaceSectionDelegate {
    public func didSelectItem(at indexPath: IndexPath, collectionView: UICollectionView) {
        DocsLogger.info("didSelectItem at\(indexPath.row)")
        collectionView.deselectItem(at: indexPath, animated: true)
        
        
    }

    @available(iOS 13.0, *)
    public func contextMenuConfig(at indexPath: IndexPath,
                                  sceneSourceID: String?,
                                  collectionView: UICollectionView) -> UIContextMenuConfiguration? {
        return nil
    }
}
