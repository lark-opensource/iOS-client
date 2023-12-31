//
//  SpaceBannerSection.swift
//  SKECM
//
//  Created by Weston Wu on 2020/11/25.
//

import UIKit
import RxSwift
import RxRelay
import RxCocoa
import SKFoundation
import SKResource
import SKCommon
import SKUIKit
import UGBanner
import EENavigator
import LarkUIKit
import SpaceInterface
import LarkContainer

extension SpaceBannerSection {
    enum BannerType {
        case homeGuide(isNewUser: Bool)
        case templateOnboarding(closeHandler: () -> Void)
        case templateCategory(categories: [TemplateCategoryBannerViewModel.Category])
        case newYearTemplate
        case larkBanner /// 接入LarkBanner之后，View层也由LarkBanner实现，定义一个通用的
    }
}

private extension SpaceBannerSection {
    struct BannerItem {
        let type: BannerType
        let contentView: SpaceBannerContentView
    }
}

/// banner 模块，包括Onboarding banner，后续的运营banner
public final class SpaceBannerSection: SpaceSection {
    static let sectionIdentifier: String = "banner"
    public var identifier: String { Self.sectionIdentifier }

    private let reloadInput = PublishRelay<ReloadAction>()
    public var reloadSignal: Signal<ReloadAction> {
        reloadInput.asSignal()
    }

    let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }

    private var showingBannerItem: BannerItem?
    private var contentHeight: CGFloat = 0.1
    private let disposeBag = DisposeBag()

    let viewModel: SpaceBannerViewModel
    private(set) var tracker = SpaceBannerTracker(bizParameter: SpaceBizParameter(module: .home(.recent)))
    private var handlers: [SpaceBannerHandler] = []

    public let userResolver: UserResolver
    
    public init(userResolver: UserResolver, viewModel: SpaceBannerViewModel) {
        self.userResolver = userResolver
        self.viewModel = viewModel
    }
    
    public func prepare() {
        viewModel.bannerReachPoint?.delegate = self
        viewModel.startPullUgBannerData()
    }

    func hideBanner() {
        guard showingBannerItem != nil else { return }
        showingBannerItem = nil
        reloadInput.accept(.reloadSection(animated: true))
    }

    public func notifyPullToRefresh() {}
    public func notifyPullToLoadMore() {}
    
    public func notifyViewDidLayoutSubviews(hostVCWidth: CGFloat) {
        if hostVCWidth > 0.001 {
            updateBannerViewFrame(with: hostVCWidth)
        }
    }
    
    private func updateBannerViewFrame(with hostVCWith: CGFloat) {
        if var frame = showingBannerItem?.contentView.frame {
            frame.size.width = hostVCWith
            showingBannerItem?.contentView.frame = frame
        }
    }
}

extension SpaceBannerSection: SpaceSectionLayout {

    public func itemSize(at index: Int, containerWidth: CGFloat) -> CGSize {
        guard let bannerItem = showingBannerItem else {
            DocsLogger.error("space.banner.section --- failed to calculate item size, bannerType not found")
            return .zero
        }
        let height = bannerItem.contentView.calculateEstimateHeight(containerWidth: containerWidth)
        return CGSize(width: containerWidth, height: height)
    }

    public func sectionInsets(for containerWidth: CGFloat) -> UIEdgeInsets {
        if numberOfItems != 0 {
            // TODO: 按照设计规范，这里top应该是8，但是 HomeGuideHeaderView 内部自己包含了8的top inset，导致顶部距离偏大
            // 为了兼容老的首页，不直接修改 HomeGuideHeaderView，新的 banner 也需要自己内部包含 8 top inset，等新首页GA后，再统一收敛到这里
            return UIEdgeInsets(top: 0, left: 0, bottom: 8, right: 0)
        } else {
            return .zero
        }
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

extension SpaceBannerSection: SpaceSectionDataSource {
    public func dragItem(at indexPath: IndexPath,
                         sceneSourceID: String?,
                         collectionView: UICollectionView) -> [UIDragItem] { [] }

    public var numberOfItems: Int {
        if showingBannerItem != nil {
            return 1
        } else {
            return 0
        }
    }

    public func setup(collectionView: UICollectionView) {
        collectionView.register(SpaceBannerContainerCell.self, forCellWithReuseIdentifier: SpaceBannerContainerCell.reuseIdentifier)
    }

    public func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: SpaceBannerContainerCell.reuseIdentifier, for: indexPath)
        guard let bannerCell = cell as? SpaceBannerContainerCell else {
            assertionFailure()
            return cell
        }
        guard let bannerItem = showingBannerItem else {
            spaceAssertionFailure("space.banner.vm --- failed to get banner item when configure banner cell")
            return bannerCell
        }
        bannerCell.update(bannerContentView: bannerItem.contentView)
        return bannerCell
    }

    public func supplymentaryElementView(kind: String, indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionReusableView {
        assertionFailure()
        return UICollectionReusableView()
    }
}

extension SpaceBannerSection: SpaceSectionDelegate {
    @available(iOS 13.0, *)
    public func contextMenuConfig(at indexPath: IndexPath,
                                  sceneSourceID: String?,
                                  collectionView: UICollectionView) -> UIContextMenuConfiguration? { return nil }

    public func didSelectItem(at indexPath: IndexPath, collectionView: UICollectionView) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }
}

extension SpaceBannerSection: BannerReachPointDelegate {
    public func onShow(bannerView: UIView, bannerData: UGBanner.BannerInfo, reachPoint: BannerReachPoint) {
        let lynxBannerView = SpaceLynxBannerView(
            frame: CGRect(x: 0, y: 0, width: 0, height: 0),
            bannerInfo: bannerData,
            delegate: self
        )
        let bannerHeaderView = SpaceBannerContainerView(contentView: lynxBannerView, contentHight: contentHeight)
        self.showingBannerItem = BannerItem(type: .larkBanner, contentView: bannerHeaderView)
        self.reloadInput.accept(.reloadSection(animated: true))
        self.viewModel.bannerReachPoint?.reportShow()
    }

    public func onHide(bannerView: UIView, bannerData: UGBanner.BannerInfo, reachPoint: BannerReachPoint) {
        self.hideBanner()
    }
}


extension SpaceBannerSection {
    public func didClickShowGuideButtonOfLarkBanner(completion: @escaping (() -> Void)) {
        actionInput.accept(.startSpaceUserGuide(tracker: tracker, completion: completion))
    }
}

extension SpaceBannerSection {
    func setupTracker(for module: SpaceBannerTracker.OnboardingModule?,
                      bannerType: SpaceBannerTracker.BannerType,
                      bannerID: SpaceBannerTracker.BannerID) {
        tracker.module = module
        tracker.bannerType = bannerType
        tracker.bannerID = bannerID
    }
}

extension SpaceBannerSection: SpaceLynxBannerViewDelegate {
    public func bannerView(_ view: SpaceLynxBannerView, didChangeIntrinsicContentHeight height: CGFloat) {
        contentHeight = height
        guard let containerView: SpaceBannerContainerView = self.showingBannerItem?.contentView as? SpaceBannerContainerView else {
            return
        }
        containerView.contentHeight = height
        self.reloadInput.accept(.reloadSection(animated: true))
    }
    public func bannerViewDidClick(_ view: SpaceLynxBannerView, params: [String: Any]?) {
        viewModel.bannerReachPoint?.reportClick()
        guard let name = params?["name"] as? String, let urlStr = params?["url"] as? String else {
            return
        }
        for handler in handlers {
            if handler.bannerKey.rawValue == name, handler.handleBannerClick(bannerView: view, url: urlStr) {
                return
            }
        }
        guard let url = URL(string: urlStr) else {
            return
        }
        if let type = DocsType(url: url), let objToken = DocsUrlUtil.getFileToken(from: url, with: type) {
            let file = SpaceEntryFactory.createEntry(type: type, nodeToken: "", objToken: objToken)
            file.updateShareURL(url.absoluteString)
            let body = SKEntryBody(file)
            actionInput.accept(.open(entry: body, context: [:]))
        } else {
            actionInput.accept(.openURL(url: url, context: nil))
        }
    }
    public func bannerViewDidShow(_ view: SpaceLynxBannerView) {
        viewModel.bannerReachPoint?.reportShow()
    }
    public func bannerViewDidClickClose(_ view: SpaceLynxBannerView) {
        viewModel.bannerReachPoint?.reportClosed()
        hideBanner()
    }
}
