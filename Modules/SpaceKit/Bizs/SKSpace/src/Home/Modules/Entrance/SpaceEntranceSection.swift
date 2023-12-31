//
//  SpaceEntranceSection.swift
//  SKECM
//
//  Created by Weston Wu on 2020/11/25.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa
import SKFoundation
import SKUIKit
import SKCommon
import LarkContainer

public extension SpaceEntranceSection {
    enum EntranceIdentifier {
        public static var cloudDrive: String { "cloud-drive" }
        public static var myLibrary: String { "my-library" }
        
        public static var ipadHome: String { "home" }
        public static var ipadCloudDriver: String { "ipad_cloud_driver" }
        public static var ipadWiki: String { "ipad_wiki" }
        public static var ipadOffline: String { "ipad_offline" }
    }
}

/// 金刚位模块
public final class SpaceEntranceSection: SpaceSection {
    static let sectionIdentifier: String = "entrance"
    public var identifier: String { Self.sectionIdentifier }

    private let reloadInput = PublishRelay<ReloadAction>()
    public var reloadSignal: Signal<ReloadAction> {
        reloadInput.asSignal()
    }

    private let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }

    private var entrances: [SpaceEntrance]

    private let tracker: SpaceEntranceTracker
    private var layout: SpaceEntranceLayoutType
    private let cellType: SpaceEntranceCellType.Type
    private let disposeBag = DisposeBag()
    
    public let userResolver: UserResolver
    
    private var highlightIdentifierMap = [String: Bool]()

    public init(userResolver: UserResolver,
                layoutType: SpaceEntranceLayoutType.Type = SpaceEntranceLayout.self,
                cellType: SpaceEntranceCellType.Type = SpaceEntranceCell.self,
                @SpaceEntranceBuilder entrances: () -> [SpaceEntrance]) {
        self.userResolver = userResolver
        let items = entrances()
        self.entrances = items
        layout = layoutType.init(itemCount: self.entrances.count)
        self.cellType = cellType
        tracker = SpaceEntranceTracker(bizParameter: SpaceBizParameter(module: .home(.recent)), entranceIDs: self.entrances.map(\.identifier))
    }

    public func prepare() {
        NotificationCenter.default.rx.notification(.Docs.notifySelectedSpaceEntarnce)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] notification in
                guard let identifier = notification.object as? (String, Bool) else {
                    return
                }
                let entranceIdentifier = identifier.0
                let isSelected = identifier.1
                if isSelected {
                    // 选中后清除目录树上的选中态
                    NotificationCenter.default.post(name: .Docs.spaceHomeTabSelectedTokenChanged, object: "")
                }
                self?.highlightIdentifierMap[entranceIdentifier] = isSelected
                self?.reloadInput.accept(.reloadSection(animated: false))
            })
            .disposed(by: disposeBag)
        
        openHomeEntranceInIpad()
    }

    public func notifyPullToRefresh() {}
    public func notifyPullToLoadMore() {}

    public func notifySectionDidAppear() {
        tracker.reportShow()

        if UserScopeNoChangeFG.WWJ.cloudDriveEnabled || UserScopeNoChangeFG.WWJ.newSpaceTabEnable {
            actionInput.accept(.startCloudDriveOnboarding)
        }
    }

    func entranceIndex(for entranceIdentifier: String) -> Int? {
        entrances.firstIndex { $0.identifier == entranceIdentifier }
    }
    
    private func openHomeEntranceInIpad() {
        guard let homeEntrance = entrances.first(where: { $0.identifier == EntranceIdentifier.ipadHome }),
              let action = homeEntrance.clickHandler?(homeEntrance) else {
            return
        }
        actionInput.accept(action.asSectionAction)
    }
}

extension SpaceEntranceSection: SpaceSectionLayout {
    
    public func itemSize(at index: Int, containerWidth: CGFloat) -> CGSize {
        layout.update(containerWidth: containerWidth)
        return layout.itemSize
    }

    public func sectionInsets(for containerWidth: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: 4,
                            left: layout.sectionHorizontalInset,
                            bottom: 4,
                            right: layout.sectionHorizontalInset)
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
        layout.footerHeight
    }
}

extension SpaceEntranceSection: SpaceSectionDataSource {
    public var numberOfItems: Int {
        entrances.count
    }

    public func setup(collectionView: UICollectionView) {
        collectionView.register(cellType,
                                forCellWithReuseIdentifier: cellType.reuseIdentifier)
        collectionView.register(SpaceEntranceFooterView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: SpaceEntranceFooterView.reuseIdentifier)
    }

    public func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellType.reuseIdentifier, for: indexPath)
        guard let entranceCell = cell as? SpaceEntranceCellType else {
            assertionFailure()
            return cell
        }
        let index = indexPath.item
        guard index < entrances.count else {
            assertionFailure("entrance cell index out of bounds")
            return entranceCell
        }
        let entrance = entrances[index]
        entranceCell.update(entrance: entrance)
        entranceCell.update(needHighlight: highlightIdentifierMap[entrance.identifier] ?? false)
        return entranceCell
    }

    public func supplymentaryElementView(kind: String, indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionReusableView {
        guard case UICollectionView.elementKindSectionFooter = kind else {
            assertionFailure()
            return UICollectionReusableView()
        }
        let view = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: SpaceEntranceFooterView.reuseIdentifier, for: indexPath)
        view.backgroundColor = layout.footerColor
        return view
    }

    public func dragItem(at indexPath: IndexPath,
                         sceneSourceID: String?,
                         collectionView: UICollectionView) -> [UIDragItem] {
        return []
    }
}

extension SpaceEntranceSection: SpaceSectionDelegate {
    public func didSelectItem(at indexPath: IndexPath, collectionView: UICollectionView) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let index = indexPath.item
        guard index < entrances.count else {
            assertionFailure("entrance cell index out of bounds when selected")
            return
        }
        let entrance = entrances[index]
        let isSelected = highlightIdentifierMap[entrance.identifier] ?? false
        guard !isSelected else {
            // 忽略重复点击
            return
        }
        guard let action = entrance.clickHandler?(entrance) else {
            DocsLogger.info("space.entrance.section --- unable to retrive action from entrance",
                            extraInfo: ["index": index, "id": entrance.identifier])
            return
        }
        
        actionInput.accept(action.asSectionAction)
        tracker.reportClick(index: index)
    }

    @available(iOS 13.0, *)
    public func contextMenuConfig(at indexPath: IndexPath,
                                  sceneSourceID: String?,
                                  collectionView: UICollectionView) -> UIContextMenuConfiguration? {
        return nil
    }
}

private extension SpaceEntrance.Action {
    var asSectionAction: SpaceSectionAction {
        switch self {
        case let .push(viewController):
            return .push(viewController: viewController)
        case let .presentOrPush(viewController, popoverConfiguration):
            return .presentOrPush(viewController: viewController, popoverConfiguration: popoverConfiguration)
        case let .showDetail(viewController):
            return .showDetail(viewController: viewController)
        }
    }
}
