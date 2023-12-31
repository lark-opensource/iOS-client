//
//  SpaceNoticeSection.swift
//  SKECM
//
//  Created by Weston Wu on 2020/11/25.
//

import UIKit
import RxSwift
import RxCocoa
import RxRelay
import SKUIKit
import SKCommon
import LarkContainer
import SKFoundation

private extension SpaceNoticeSection {
    enum Constants {
        static let noticeCellIdentifier = "space-notice-cell"
    }
    // 为了解决在 sizeForItem 内解析 attributedString 导致 crash 的问题，在 reload 前提前生成 attrbutedString
    enum NoticeItem {
        case networkUnreachable
        case serverBulletin(info: BulletinInfo, attributedString: NSAttributedString)
        case historyFolder
        case folderVerify(type: ComplaintState, tips: NSAttributedString, token: String)
    }
}

/// 公告模块，包括无网提醒、后台公告
public final class SpaceNoticeSection: SpaceSection {
    static let sectionIdentifier: String = "notice"
    public var identifier: String { Self.sectionIdentifier }

    private let viewModel: SpaceNoticeViewModel
    private var notices = [NoticeItem]()
    private let disposeBag = DisposeBag()

    private let reloadInput = PublishRelay<ReloadAction>()
    public var reloadSignal: Signal<ReloadAction> {
        reloadInput.asSignal()
    }

    private let actionInput = PublishRelay<Action>()
    public var actionSignal: Signal<Action> {
        actionInput.asSignal()
    }
    
    public let userResolver: UserResolver

    public init(userResolver: UserResolver,
                viewModel: SpaceNoticeViewModel) {
        self.userResolver = userResolver
        self.viewModel = viewModel
    }

    public func prepare() {
        viewModel.noticesUpdated.drive(onNext: { [weak self] notices in
            // 在 reload 前提前解析 attributedString，否则在 sizeForItem 内会 crash
            self?.update(notices: notices)
            self?.reloadInput.accept(.reloadSection(animated: true))
        }).disposed(by: disposeBag)
        viewModel.actionSignal.emit(to: actionInput).disposed(by: disposeBag)
        viewModel.prepare()
    }

    private func update(notices: [SpaceNoticeType]) {
        self.notices = notices.map { noticeType -> NoticeItem in
            switch noticeType {
            case .historyFolder:
                return .historyFolder
            case .networkUnreachable:
                return .networkUnreachable
            case let .serverBulletin(info):
                let attributedString = BulletinView.generateAttributedString(for: info) ?? NSAttributedString(string: "")
                return .serverBulletin(info: info, attributedString: attributedString)
            case let .folderVerify(type, tips, token):
                return .folderVerify(type: type, tips: tips, token: token)
            }
        }
    }

    public func notifyPullToRefresh() {
        viewModel.bannerRefresh()
    }
    public func notifyPullToLoadMore() {}
    public func notifySectionDidAppear() {
        viewModel.bannerRefresh()
    }
}

extension SpaceNoticeSection: SpaceSectionLayout {

    public func itemSize(at index: Int, containerWidth: CGFloat) -> CGSize {
        guard index < notices.count else { return .zero }
        let notice = notices[index]
        switch notice {
        case .networkUnreachable:
            let size = CGSize(width: containerWidth, height: .infinity)
            let noticeHeight = NetInterruptTipView.defaultView().sizeThatFits(size).height
            return CGSize(width: containerWidth, height: noticeHeight)
        case let .serverBulletin(_, attributedString):
            let noticeHeight = BulletinView.calculateEstimateHeight(for: attributedString, containerWidth: containerWidth)
            return CGSize(width: containerWidth, height: noticeHeight)
        case .historyFolder:
            let noticeHeight: CGFloat = 70.0
            return CGSize(width: containerWidth, height: noticeHeight)
        case let .folderVerify(_, tips, _):
            let noticeHeight = SKComplaintNoticeView.calculateHeight(text: tips, width: containerWidth)
            return CGSize(width: containerWidth, height: noticeHeight)
        }
    }

    public func sectionInsets(for containerWidth: CGFloat) -> UIEdgeInsets {
        if numberOfItems != 0 {
            return UIEdgeInsets(top: 0, left: 0, bottom: 4, right: 0)
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

extension SpaceNoticeSection: SpaceSectionDataSource {
    public var numberOfItems: Int {
        notices.count
    }

    public func setup(collectionView: UICollectionView) {
        collectionView.register(SpaceNoticeCell.self, forCellWithReuseIdentifier: Constants.noticeCellIdentifier)
    }

    public func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.noticeCellIdentifier, for: indexPath)
        guard let noticeCell = cell as? SpaceNoticeCell else {
            assertionFailure()
            return cell
        }
        guard indexPath.item < notices.count else {
            assertionFailure()
            return noticeCell
        }
        let noticeContentView = generateContentView(for: notices[indexPath.item])
        noticeCell.update(noticeContentView: noticeContentView)
        return noticeCell
    }

    private func generateContentView(for notice: NoticeItem) -> UIView {
        switch notice {
        case .networkUnreachable:
            return setupUnreachableContentView()
        case let .serverBulletin(info, _):
            return setupBulletinContentView(info: info)
        case .historyFolder:
            return setupHistoryFolderContentView()
        case let .folderVerify(type, _, token):
            if UserScopeNoChangeFG.PLF.appealV2Enable {
                return setupFolderAppealView(type: type, token: token)
            } else {
                return setupFolderVerifyView(type: type)
            }
        }
    }

    private func setupUnreachableContentView() -> UIView {
        let unreachableContentView = NetInterruptTipView.defaultView()
        return unreachableContentView
    }

    private func setupBulletinContentView(info: BulletinInfo) -> UIView {
        let bulletinContentView = BulletinView()
        bulletinContentView.info = info
        bulletinContentView.delegate = viewModel
        return bulletinContentView
    }

    private func setupHistoryFolderContentView() -> UIView {
        let historyFolderContentView = SpaceHistoryFolderView()
        historyFolderContentView.delegate = viewModel
        return historyFolderContentView
    }
    
    private func setupFolderVerifyView(type: ComplaintState) -> UIView {
        let folderVerifyView = SKComplaintNoticeView()
        folderVerifyView.update(complaintState: type)
        folderVerifyView.clickLabelHandler = { [weak self] state in
            guard let viewModel = self?.viewModel as? VerifyNoticeViewModel else { return }
            viewModel.shouldOpenVerifyURL(type: state)
        }
        return folderVerifyView
    }

    private func setupFolderAppealView(type: ComplaintState, token: String) -> UIView {
        let folderVerifyView = SKAppealBanner()
        let entityId = "\(token):0"
        folderVerifyView.update(complaintState: type, entityId: entityId, isFolder: true)
        folderVerifyView.clickCallback = { [weak self] url in
            guard let viewModel = self?.viewModel as? VerifyNoticeViewModel else { return }
            viewModel.openURL(url: url)
        }
        return folderVerifyView
    }
    
    public func supplymentaryElementView(kind: String, indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionReusableView {
        assertionFailure()
        return UICollectionReusableView()
    }

    public func dragItem(at indexPath: IndexPath,
                         sceneSourceID: String?,
                         collectionView: UICollectionView) -> [UIDragItem] {
        return []
    }
}

extension SpaceNoticeSection: SpaceSectionDelegate {
    public func didSelectItem(at indexPath: IndexPath, collectionView: UICollectionView) {
        collectionView.deselectItem(at: indexPath, animated: true)
    }

    @available(iOS 13.0, *)
    public func contextMenuConfig(at indexPath: IndexPath,
                                  sceneSourceID: String?,
                                  collectionView: UICollectionView) -> UIContextMenuConfiguration? {
        return nil
    }
}
