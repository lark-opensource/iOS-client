//
//  RecommendedSection.swift
//  SKSpace
//
//  Created by yinyuan on 2023/4/10.
//
// disable-lint: magic number

import UIKit
import RxSwift
import RxRelay
import RxCocoa
import SKFoundation
import SKUIKit
import SKCommon
import UniverseDesignIcon
import LarkUIKit
import LarkContainer

private extension RecommendedSection {
    struct Layout {
        static let sectionHorizontalInset: CGFloat = 16
        static let minimumLineSpacing: CGFloat = 20
        static let minimumInteritemSpacing: CGFloat = 13

        static let itemPerLine = 3
    }
}

public final class RecommendedSection: SpaceSection {
    static let sectionIdentifier: String = "recommended"
    public var identifier: String { Self.sectionIdentifier }

    private let reloadInput = PublishRelay<ReloadAction>()
    public var reloadSignal: Signal<ReloadAction> {
        reloadInput.asSignal()
    }

    private let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }

    private var layout: Layout
    private let disposeBag = DisposeBag()
    
    private var hasReportView = false
    
    private let dataModel: RecommendedDataModel
    private let homeType: SpaceHomeType
    private let headerSection: HeaderSection

    public let userResolver: UserResolver
    public init(userResolver: UserResolver,
                dataModel: RecommendedDataModel,
                homeType: SpaceHomeType,
                headerSection: HeaderSection) {
        self.userResolver = userResolver
        self.dataModel = dataModel
        self.homeType = homeType
        self.headerSection = headerSection
        layout = Layout()
        
        dataModel.dataUpdatedCallback = { [weak self] _ in
            self?.reportView()
            self?.reloadInput.accept(.reloadSection(animated: false))
            self?.updateHeader()
        }
    }
    
    private func updateHeader() {
        var headerInfo: SectionHeaderInfo? = nil
        if let bannerTitle = dataModel.banner?.bannerTitle {
            headerInfo = SectionHeaderInfo(title: bannerTitle)
            if let moreBtn = dataModel.banner?.moreBtn, let info = moreBtn.text {
                headerInfo?.info = info
                headerInfo?.rightIcon = UDIcon.rightOutlined
                if let url = URL(string: moreBtn.url ?? "") {
                    headerInfo?.rightClickHandler = { [weak self] _ in
                        guard let url = self?.transformURL(urlStr: moreBtn.url) else {
                            DocsLogger.info("url is invalid")
                            return
                        }
                        self?.actionInput.accept(.openURL(url: url, context: nil))
                        if case let .baseHomeType(context) = self?.homeType {
                            DocsTracker.reportBitableHomePageEvent(enumEvent: .baseHomepageBannerClick, parameters: [
                                "click": "open_all"
                            ], context: context)
                        }
                    }
                }
            }
        }
        headerSection.headerInfo = headerInfo
    }

    public func prepare() {
        updateHeader()
    }

    public func notifyPullToRefresh() {}
    public func notifyPullToLoadMore() {}

    public func notifySectionDidAppear() {
        hasReportView = false   // 再次显示再次上报
        self.reportView()
    }
    
    public func notifySectionWillDisappear() {
        
    }
    
    private func reportView() {
        guard !hasReportView else {
            return
        }
        guard let cards = dataModel.banner?.cards, cards.count > 0 else {
            return
        }
        if case let .baseHomeType(context) = homeType {
            DocsTracker.reportBitableHomePageEvent(enumEvent: .baseHomepageBannerView, parameters: nil, context: context)
            for index in 0..<cards.count {
                let card = cards[index]
                let token = URL(string: card.redirectUrl ?? "")?.pathComponents.last
                DocsTracker.reportBitableHomePageEvent(enumEvent: .baseHomepageBannerClick, parameters: [
                    "click": "single_template_show",
                    "template_token": token ?? "",  // 官方模板token，明文上报
                    "template_name": card.title ?? "",
                    "position_index": (index + 1)
                ], context: context)
            }
            hasReportView = true
        }
    }
}

extension RecommendedSection: SpaceSectionLayout {
    
    public func itemSize(at index: Int, containerWidth: CGFloat) -> CGSize {
        let cellWidth = floor((containerWidth - Layout.sectionHorizontalInset * 2 - Layout.minimumInteritemSpacing * CGFloat(Layout.itemPerLine - 1)) / CGFloat(Layout.itemPerLine))
        let imageHeight = cellWidth * RecommendedCell.imageWidthHeightRatio
        var maxTitleHeight: CGFloat = 18
        if !UserScopeNoChangeFG.YY.bitableBannerTitleMultiLineDisable {
            // 获取当前行的最大高度
            let line = Int(index / Layout.itemPerLine)   // 第几行
            for i in 0..<Layout.itemPerLine {
                let index = line * 3 + i
                if let cards = dataModel.banner?.cards, index < cards.count {
                    let card = cards[index]
                    let title = card.title ?? "      "
                    let height = RecommendedCell.titleLabelHeight(title, cellWidth: cellWidth)
                    if height > maxTitleHeight {
                        maxTitleHeight = height
                    }
                }
            }
        }
        let height = imageHeight + maxTitleHeight + RecommendedCell.titleLabelTopMargin
        return CGSize(width: cellWidth, height: height)
    }

    public func sectionInsets(for containerWidth: CGFloat) -> UIEdgeInsets {
        return UIEdgeInsets(top: 4,
                            left: Layout.sectionHorizontalInset,
                            bottom: 4,
                            right: Layout.sectionHorizontalInset)
    }

    public func minimumLineSpacing(for containerWidth: CGFloat) -> CGFloat {
        Layout.minimumLineSpacing
    }

    public func minimumInteritemSpacing(for containerWidth: CGFloat) -> CGFloat {
        Layout.minimumInteritemSpacing
    }

    public func headerHeight(for containerWidth: CGFloat) -> CGFloat {
        0
    }

    public func footerHeight(for containerWidth: CGFloat) -> CGFloat {
        12
    }
}

extension RecommendedSection: SpaceSectionDataSource {
    public var numberOfItems: Int {
        dataModel.banner?.cards.count ?? 6
    }

    public func setup(collectionView: UICollectionView) {
        collectionView.register(RecommendedCell.self,
                                forCellWithReuseIdentifier: RecommendedCell.reuseIdentifier)
        collectionView.register(RecommendedFooterView.self,
                                forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                                withReuseIdentifier: RecommendedFooterView.reuseIdentifier)
    }

    public func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: RecommendedCell.reuseIdentifier, for: indexPath)
        guard let entranceCell = cell as? RecommendedCell else {
            assertionFailure()
            return cell
        }
        
        let index = indexPath.item
        if let cards = dataModel.banner?.cards {
            guard index < cards.count else {
                assertionFailure("entrance cell index out of bounds")
                return entranceCell
            }
            entranceCell.configure(with: cards[index])
        } else {
            entranceCell.configure(with: nil)
        }
        return entranceCell
    }

    public func supplymentaryElementView(kind: String, indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionReusableView {
        switch kind {
        case UICollectionView.elementKindSectionFooter:
            return collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: RecommendedFooterView.reuseIdentifier, for: indexPath)
        default:
            assertionFailure()
            return UICollectionReusableView()
        }
    }

    public func dragItem(at indexPath: IndexPath,
                         sceneSourceID: String?,
                         collectionView: UICollectionView) -> [UIDragItem] {
        return []
    }
}

extension RecommendedSection: SpaceSectionDelegate {
    public func didSelectItem(at indexPath: IndexPath, collectionView: UICollectionView) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let index = indexPath.item
        guard let cards = dataModel.banner?.cards else {
           return
        }
        guard index < cards.count else {
            assertionFailure("entrance cell index out of bounds when selected")
            return
        }
        let card = cards[index]
        guard let url = transformURL(urlStr: card.redirectUrl) else {
            DocsLogger.info("redirectUrl is invalid", extraInfo: ["index": index])
            return
        }
        actionInput.accept(.openURL(url: url, context: nil))
        
        if case let .baseHomeType(context) = homeType {
            let token = URL(string: card.redirectUrl ?? "")?.pathComponents.last
            DocsTracker.reportBitableHomePageEvent(enumEvent: .baseHomepageBannerClick, parameters: [
                "click": "preview_click",
                "template_token": token ?? "",  // 官方模板token，明文上报
                "template_name": card.title ?? "",
                "position_index": (index + 1)
            ], context: context)
        }
        
    }

    @available(iOS 13.0, *)
    public func contextMenuConfig(at indexPath: IndexPath,
                                  sceneSourceID: String?,
                                  collectionView: UICollectionView) -> UIContextMenuConfiguration? {
        return nil
    }
}

extension RecommendedSection {
    
    private func transformURL(urlStr: String?) -> URL? {
        guard let urlStr = urlStr, var urlComponents = URLComponents(string: urlStr) else {
            return nil
        }
        
        let queryItems: [URLQueryItem]? = urlComponents.queryItems?.compactMap({ item in
            if item.name == "enterSource", let value = item.value, case let .baseHomeType(context) = homeType {
                return URLQueryItem(name: item.name, value: value + "_" + context.containerEnv.rawValue)
            }
            return item
        })
        urlComponents.queryItems = queryItems
        return urlComponents.url
    }
}
