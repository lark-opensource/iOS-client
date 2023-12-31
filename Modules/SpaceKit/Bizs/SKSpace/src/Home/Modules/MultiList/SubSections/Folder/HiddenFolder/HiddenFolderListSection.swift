//
//  HiddenFolderListSection.swift
//  SKSpace
//
//  Created by majie.7 on 2022/2/18.
//

import UIKit
import RxSwift
import RxCocoa
import RxRelay
import SKUIKit
import SKCommon
import SKFoundation
import LarkContainer

public final class HiddenFolderListSection: SpaceSection {
    static let sectionIdentifier: String = "hiddenFolder"
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
    private let viewModel: ShareFolderListViewModel
    private var haveHiddenFolder: Bool = false
    
    public let userResolver: UserResolver
    
    public let isShowInDetail: Bool
    public let subSectionIdentifierObservable: Observable<String>?
    
    init(userResolver: UserResolver,
         viewModel: ShareFolderListViewModel,
         subSectionIdentifierObservable: Observable<String>? = nil,
         isShowInDetail: Bool = false) {
        self.userResolver = userResolver
        self.viewModel = viewModel
        self.subSectionIdentifierObservable = subSectionIdentifierObservable
        self.isShowInDetail = isShowInDetail
    }
    
    public func prepare() {
        
        if let subSectionIdentifierObservable {
            let latestDriver = Signal.combineLatest(viewModel.hiddenFolderVisableRelay.asSignal(onErrorJustReturn: false).distinctUntilChanged(),
                                                    subSectionIdentifierObservable.asSignal(onErrorJustReturn: ""))
            latestDriver.delay(DispatchQueueConst.MilliSeconds_1000).emit(onNext: { [weak self] show, identifier in
                self?.haveHiddenFolder = show && identifier == "share-folder"
                self?.reloadInput.accept(.reloadSection(animated: true))
            }).disposed(by: disposeBag)
            
        } else {
            viewModel.hiddenFolderVisableRelay
                    .observeOn(MainScheduler.instance)
                    .distinctUntilChanged()
                    .subscribe(onNext: { [weak self] haveHiddenFolder in
                guard let self = self else { return }
                self.haveHiddenFolder = haveHiddenFolder
                self.reloadInput.accept(.reloadSection(animated: true))
            })
                .disposed(by: disposeBag)
        }
    }
    
    public func notifyPullToRefresh() {
        viewModel.dataModel.showHiddenFolderTabIfNeed()
    }
    
    public func notifyPullToLoadMore() {}
    
    public func itemSize(at index: Int, containerWidth: CGFloat) -> CGSize {
        if numberOfItems != 0 {
            return CGSize(width: containerWidth, height: 80)
        }
        return .zero
    }
    
    public func sectionInsets(for containerWidth: CGFloat) -> UIEdgeInsets {
        if numberOfItems != 0 {
            return UIEdgeInsets(top: 0, left: 0, bottom: 70, right: 0)
        }
        return .zero
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
    
    public var numberOfItems: Int {
        if haveHiddenFolder {
            return 1
        } else {
            return 0
        }
    }
    
    public func setup(collectionView: UICollectionView) {
        collectionView.register(SpaceHiddenFolderCell.self, forCellWithReuseIdentifier: "shared-folder-V2-hidden-cell")
    }
    
    public func cell(at indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "shared-folder-V2-hidden-cell", for: indexPath)
        guard let hiddencFolderCell = cell as? SpaceHiddenFolderCell else {
            assertionFailure()
            return cell
        }
        let contentView = HiddenFolderView()
        hiddencFolderCell.update(hiddenContentView: contentView)
        return cell
    }
    
    public func supplymentaryElementView(kind: String, indexPath: IndexPath, collectionView: UICollectionView) -> UICollectionReusableView {
        assertionFailure()
        return UICollectionReusableView()
    }
    
    public func dragItem(at indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> [UIDragItem] {
        return []
    }
    
    public func didSelectItem(at indexPath: IndexPath, collectionView: UICollectionView) {
        // 跳转到隐藏文件夹列表
        guard let userID = User.current.basicInfo?.userID else {
            spaceAssertionFailure("无法读取到 UserID")
            return
        }
        
        guard let vcFactory = try? userResolver.resolve(assert: SpaceVCFactory.self) else {
            DocsLogger.error("can not get SpaceVCFactory")
            return
        }

        let vc = vcFactory.makeShareFolderListController(apiType: .hiddenFolder, isShowInDetail: isShowInDetail)
        actionInput.accept(.push(viewController: vc))
    }
    
    @available(iOS 13.0, *)
    public func contextMenuConfig(at indexPath: IndexPath, sceneSourceID: String?, collectionView: UICollectionView) -> UIContextMenuConfiguration? {
        return nil
    }
}
