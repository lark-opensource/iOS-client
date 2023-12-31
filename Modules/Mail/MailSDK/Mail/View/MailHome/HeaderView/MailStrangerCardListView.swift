//
//  MailStrangerCardListView.swift
//  MailSDK
//
//  Created by 龙伟伟 on 2023/6/26.
//

import UIKit
import UniverseDesignIcon
import SnapKit
import ESPullToRefresh
import RxRelay
import RxSwift

struct StrangerCardConst {
    static let cardWidth: CGFloat   = 278
    static let cardHeight: CGFloat  = 145
    static let itemPadding: CGFloat = 10
    static let horPadding: CGFloat  = 20
    static let cardListInsetPadding: CGFloat = 16
    static let cardListMoreItemInsetPadding: CGFloat = 12
    static let cardListHeight: CGFloat = 205
    static let moreActionWidthHeight: CGFloat = 36
    static let moreActionTitleWidth: CGFloat = 50
    static let marginTop: CGFloat = 8
    static let textMargin: CGFloat = 8
    static let iconWidth: CGFloat = 10
    static let iconMarginTop: CGFloat = 15
    static let footerWidth: CGFloat = 88
    static let moreItemArrowIconWidth: CGFloat = 8

    static let maxCardCount: Int = 10
    static let cacheCardCount: Int = 20
    static let maxThreadCount: Int = 99

    static let strangerInLabels = [Mail_LabelId_Important, Mail_LabelId_Inbox]
}

protocol MailStrangerCardListDelegate: AnyObject {
    func moreActionHandler(sender: UIControl)
    func cardItemHandler(index: Int, threadID: String)
    func moreCardItemHandler()
    func loadMoreIfNeeded()
}

protocol MailStrangerCardMoreItemDelegate: AnyObject {
    func moreItemHandler()
}

enum CardListDirection {
    case hori
    case vert
}

/// header
/// card collection view list
class MailStrangerCardListView: UIView, MailStrangerCardMoreItemDelegate {

    override var intrinsicContentSize: CGSize {
        return CGSize(width: bounds.width, height: StrangerCardConst.cardListHeight)
    }

    weak var delegate: MailStrangerCardListDelegate?
    weak var cellDelegate: MailStrangerThreadCellDelegate?

    var listDirection: CardListDirection = .hori

    private lazy var layout: StrangerFlowLayoutWithAnimation = { // UICollectionViewFlowLayout = { //
        let layout = StrangerFlowLayoutWithAnimation()
        if listDirection == .hori {
            layout.scrollDirection = .horizontal
            //layout.itemSize = CGSize(width: StrangerCardConst.cardWidth, height: StrangerCardConst.cardHeight)
            layout.sectionInset = UIEdgeInsets(top: 0, left: StrangerCardConst.cardListInsetPadding,
                                               bottom: 0, right: StrangerCardConst.cardListInsetPadding)
        } else {
            layout.scrollDirection = .vertical
            //layout.itemSize = CGSize(width: self.frame.size.width - StrangerCardConst.itemPadding * 2, height: StrangerCardConst.cardHeight)
            layout.sectionInset = UIEdgeInsets(top: StrangerCardConst.marginTop, left: StrangerCardConst.cardListInsetPadding,
                                               bottom: StrangerCardConst.itemPadding, right: StrangerCardConst.cardListInsetPadding)
        }
        layout.minimumInteritemSpacing = StrangerCardConst.itemPadding
        return layout
    }()

    private(set) lazy var collectionView: UICollectionView = {
        let frame = CGRect(origin: .zero, size: CGSize(width: self.frame.size.width, height: StrangerCardConst.cardHeight))
        let cv = UICollectionView(frame: frame, collectionViewLayout: layout)
        cv.delegate = self
        cv.dataSource = self
        cv.backgroundColor = UIColor.ud.bgBody
        cv.showsHorizontalScrollIndicator = false
        cv.register(MailStrangerThreadCell.self, forCellWithReuseIdentifier: "MailStrangerThreadCell")
        cv.register(MailStrangerCardMoreItemView.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter, withReuseIdentifier: "MailStrangerCardMoreItemView")
        cv.clipsToBounds = false
        return cv
    }()

    var cardCountLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = UIColor.ud.textCaption
        label.isUserInteractionEnabled = true
        return label
    }()

    var cardCountArrowIcon: UIImageView = {
        let icon = UIImageView()
        icon.image = UDIcon.rightBoldOutlined.withRenderingMode(.alwaysTemplate)
        icon.tintColor = .ud.iconN2
        return icon
    }()

    var moreActionButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.moreOutlined.withRenderingMode(.alwaysTemplate), for: .normal)
        button.tintColor = UIColor.ud.iconN2
        button.imageEdgeInsets = UIEdgeInsets(top: StrangerCardConst.marginTop, left: StrangerCardConst.marginTop,
                                              bottom: StrangerCardConst.marginTop, right: StrangerCardConst.marginTop)
        return button
    }()
    let footer = MailLoadMoreRefreshAnimator.init(frame: CGRect.zero)
    private let disposeBag = DisposeBag()

    var selectedIndex: IndexPath?
    var selectedThreadID: String? {
        didSet {
            if oldValue != selectedThreadID {
                selectedThreadIDObservable.accept(selectedThreadID)
            }
        }
    }
    let selectedThreadIDObservable = BehaviorRelay<String?>(value: nil)

    @objc
    func moreActionButtonClicked() {
        delegate?.moreActionHandler(sender: moreActionButton)
    }

    func moreItemHandler() {
        delegate?.moreCardItemHandler()
    }

    @objc func cardCountLabelHandler() {
        delegate?.moreCardItemHandler()
    }

    private var viewModel: MailThreadListViewModel
    private var label: MailClientLabel?

    func stopLoadMore() {
        if listDirection == .vert {
            if viewModel.isLastPage {
                collectionView.es.noticeNoMoreData()
            } else {
                collectionView.es.resetNoMoreData()
                collectionView.es.stopLoadingMore()
            }
        }
    }

    func upsetViewModel(viewModel: MailThreadListViewModel, selectedThreadId: String?) -> (String?, Bool) {
        MailLogger.info("[mail_stranger] upsetViewModel: \(viewModel.mailThreads.all.count) selectedThreadId: \(selectedThreadId) selectedThreadID: \(selectedThreadID)")
        self.viewModel = viewModel
        self.label = MailTagDataManager.shared.getFolderModel([Mail_LabelId_Stranger])
        if let text = label?.getStrangerListHeaderText() {
            cardCountLabel.text = text
        }
        stopLoadMore()
        guard let newSelectedThreadId = (selectedThreadId ?? selectedThreadID) else {
            selectedIndex = nil
            selectedThreadID = nil
            collectionView.reloadData()
            return (nil, false)
        }
        if let currentSelectedThreadID = selectedThreadID {
            if let currentSelectedIndex = viewModel.mailThreads.all.firstIndex(where: { $0.threadID == currentSelectedThreadID }) {
                let needRefresh = currentSelectedThreadID != selectedThreadId
                MailLogger.info("[mail_stranger] currentSelectedIndex: \(currentSelectedIndex) selectedIndex: \(selectedIndex?.row ?? -1) newSelectedThreadId: \(newSelectedThreadId)")
                if needRefresh {
                    selectedIndex = IndexPath(row: currentSelectedIndex, section: 0)
                }
                collectionView.reloadData()
                return (currentSelectedThreadID, true)
            } else if viewModel.mailThreads.all.count > (selectedIndex?.row ?? 0) {
                let nextThreadID = viewModel.mailThreads.all[selectedIndex?.row ?? 0].threadID
                selectedIndex = IndexPath(row: selectedIndex?.row ?? 0, section: 0)
                selectedThreadID = nextThreadID
                collectionView.reloadData()
                return (nextThreadID, true)
            } else {
                selectedIndex = nil
                collectionView.reloadData()
                return (nil, false)
            }
        } else if let selectedIndex = selectedIndex, selectedIndex.row < viewModel.mailThreads.all.count {
            let nextThreadID = viewModel.mailThreads.all[selectedIndex.row].threadID
            self.selectedIndex = IndexPath(row: selectedIndex.row, section: 0)
            selectedThreadID = nextThreadID
            collectionView.reloadData()
            return (nextThreadID, true)
        } else {
            collectionView.reloadData()
            return (nil, false)
        }
    }

    func clearSelectedStatus() {
        selectedIndex = nil
        selectedThreadID = nil
        collectionView.reloadData()
    }

    func updateSelectedStatus(index: IndexPath, threadID: String) {
        selectedIndex = index
        selectedThreadID = threadID
        collectionView.reloadData()
    }

    init(frame: CGRect, viewModel: MailThreadListViewModel, listDirection: CardListDirection = .hori) {
        self.viewModel = viewModel
        self.listDirection = listDirection
        self.label = MailTagDataManager.shared.getFolderModel([Mail_LabelId_Stranger])
        super.init(frame: frame)

        if listDirection == .hori {
            setupBanner()
        }

        backgroundColor = UIColor.ud.bgBody
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.width.left.equalToSuperview()
            if listDirection == .hori {
                make.top.equalTo(cardCountLabel.snp.bottom).offset(StrangerCardConst.textMargin)
                make.height.equalTo(StrangerCardConst.cardHeight)
            } else {
                make.top.equalToSuperview().offset(StrangerCardConst.marginTop)
                make.height.equalToSuperview()
            }
        }
        collectionView.reloadData()

        if listDirection == .vert {
            footer.titleText = BundleI18n.MailSDK.Mail_StrangerEmail_AllStrangersLoaded_Text
            footer.executeIncremental = 60
            footer.trigger = 60
            footer.topOffset = 15
            collectionView.es.addInfiniteScrolling(animator: footer) { [weak self] in
                self?.loadMoreIfNeeded()
            }
        }

        PushDispatcher
            .shared
            .mailChange
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (push) in
                switch push {
                case .updateLabelsChange(let change):
                    if let strangerLabel = change.labels.first(where: { $0.id == Mail_LabelId_Stranger }) {
                        self?.cardCountLabel.text = strangerLabel.getStrangerListHeaderText()
                    }
                default:
                    break
                }
        }).disposed(by: disposeBag)
    }

    func setupBanner() {
        moreActionButton.addTarget(self, action: #selector(moreActionButtonClicked), for: .touchUpInside)
        addSubview(moreActionButton)
        moreActionButton.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-7)
            make.top.equalToSuperview().offset(StrangerCardConst.marginTop)
            make.width.height.equalTo(StrangerCardConst.moreActionWidthHeight)
        }
        if let text = label?.getStrangerListHeaderText() {
            cardCountLabel.text = text
        }
        addSubview(cardCountLabel)
        cardCountLabel.snp.makeConstraints { make in
            make.left.equalTo(StrangerCardConst.marginTop * 2)
            make.centerY.equalTo(moreActionButton)
            make.height.equalTo(16)
        }
        cardCountLabel.sizeToFit()

        addSubview(cardCountArrowIcon)
        cardCountArrowIcon.snp.makeConstraints { make in
            make.left.equalTo(cardCountLabel.snp.right)
            make.width.height.equalTo(StrangerCardConst.iconWidth)
            make.centerY.equalTo(moreActionButton)
        }

        cardCountLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cardCountLabelHandler)))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UICollectionViewDelegate
extension MailStrangerCardListView: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        guard let footer =
                collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionFooter,
                                                                withReuseIdentifier: "MailStrangerCardMoreItemView",
                                                                for: indexPath) as? MailStrangerCardMoreItemView
        else {
            return UICollectionReusableView()
        }
        footer.delegate = self
        return footer
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if listDirection == .hori {
            return CGSize(width: StrangerCardConst.cardWidth, height: StrangerCardConst.cardHeight)
        } else {
            return CGSize(width: self.frame.size.width - StrangerCardConst.itemPadding * 2, height: StrangerCardConst.cardHeight)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        let moreCardCount = label?.getMoreStrangersCount() ?? 0
        if listDirection == .hori && moreCardCount > 0 {
            return CGSize(width: StrangerCardConst.footerWidth + StrangerCardConst.cardListInsetPadding,
                          height: StrangerCardConst.cardHeight)
        } else {
            return .zero
        }
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if listDirection == .hori {
            return min(viewModel.mailThreads.all.count, StrangerCardConst.maxCardCount)
        } else {
            return viewModel.mailThreads.all.count
        }
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cardCell = collectionView.dequeueReusableCell(withReuseIdentifier: "MailStrangerThreadCell",
                                                                for: indexPath) as? MailStrangerThreadCell,
              indexPath.row < viewModel.mailThreads.all.count else {
            return UICollectionViewCell()
        }
        let cellViewModel = viewModel.mailThreads.all[indexPath.row]
        cardCell.cellViewModel = cellViewModel
        if let selectedThreadID = selectedThreadID, cellViewModel.threadID == selectedThreadID {
            cardCell.isSelected = true
        } else {
            cardCell.isSelected = false
        }
        cardCell.indexPath = indexPath
        cardCell.selectedIndexPath = selectedIndex
        cardCell.showShadow = listDirection == .hori
        cardCell.delegate = cellDelegate
        cardCell.replyHandler = { [weak self] (status) in
            guard let self = self else { return }
            if let index = self.viewModel.mailThreads.all.firstIndex(where: { $0.threadID == cardCell.cellViewModel?.threadID }) {
                collectionView.performBatchUpdates {
                    var refreshThreads = self.viewModel.mailThreads.all
                    refreshThreads.remove(at: index)
                    self.viewModel.setThreadsListOfLabel(Mail_LabelId_Stranger, mailList: refreshThreads)
                    collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
                } completion: { _ in
                    collectionView.reloadData()
                }
                //self.cellReplyHandler(index, status: status)
            }
        }
        return cardCell
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        guard indexPath.row < viewModel.mailThreads.all.count else { return }
        let item = viewModel.mailThreads.all[indexPath.row]
        cell.isSelected = item.threadID == selectedThreadID
    }

    func cellReplyHandler(_ index: Int, status: Bool) {
        let deletedIndexPath = IndexPath(row: index, section: 0)
        let visibleIndexPaths = self.collectionView.indexPathsForVisibleItems
        let filteredIndexPaths = visibleIndexPaths.filter({$0.isEqualTo(deletedIndexPath)})
        if let deletedCell = self.collectionView.cellForItem(at: deletedIndexPath),
            !filteredIndexPaths.isEmpty {
            let animationTime: TimeInterval = 0.5
//            self.perform(#selector(deleteCell(atIndexPath:)), with: deletedIndexPath, afterDelay: animationTime)
            //self.perform(#selector(deleteCell(replyStatus:)), with: (deletedIndexPath,status), afterDelay: animationTime)

            DispatchQueue.main.asyncAfter(deadline: .now() + animationTime, execute: {
                self.deleteCell(replyStatus: (deletedIndexPath, status))
            })
        }
    }

    func deleteCell(replyStatus status: (IndexPath, Bool)) {
        let index = status.0.row
        guard viewModel.mailThreads.all.count > index else {
            return
        }
        guard let cell = collectionView.cellForItem(at: status.0) as? MailStrangerThreadCell else { return }
        let cellVM = viewModel.mailThreads.all[index]
        self.cellDelegate?.didClickStrangerReply(cell, cellModel: cellVM, status: status.1)
    }

    @objc func deleteCell(atIndexPath indexPath: IndexPath) {
        let index = indexPath.row
        guard viewModel.mailThreads.all.count > index else {
            return
        }
        guard let cell = collectionView.cellForItem(at: indexPath) as? MailStrangerThreadCell else { return }
        let cellVM = viewModel.mailThreads.all[index]

        collectionView.performBatchUpdates {
            var refreshThreads = self.viewModel.mailThreads.all
            refreshThreads.remove(at: index)
            self.viewModel.setThreadsListOfLabel(Mail_LabelId_Stranger, mailList: refreshThreads)
            collectionView.deleteItems(at: [IndexPath(row: index, section: 0)])
        } completion: { [weak self] _ in
            self?.collectionView.reloadData()
        }

//        UIView.animate(withDuration: 0.3) { [weak self] in
//            guard let self = self else { return }
////            var refreshThreads = self.viewModel.mailThreads.all
////            refreshThreads.remove(at: index)
////            self.viewModel.setThreadsListOfLabel(Mail_LabelId_Stranger, mailList: refreshThreads)
////            self.collectionView.deleteItems(at: [indexPath])
//        } completion: { [weak self] finish in
//            guard let self = self else { return }
////            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
////            })
//            var refreshThreads = self.viewModel.mailThreads.all
//            refreshThreads.remove(at: index)
//            self.viewModel.setThreadsListOfLabel(Mail_LabelId_Stranger, mailList: refreshThreads)
//            self.collectionView.deleteItems(at: [indexPath])
//            self.cellDelegate?.didClickStrangerReply(cell, cellModel: cellVM, status: status)
//        }

//        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
//            self.cellDelegate?.didClickStrangerReply(cell, cellModel: cellVM, status: status)
//        })

//        cellDelegate?.didClickStrangerReply(cell, cellModel: viewModel.mailThreads.all[indexPath.row], status: status)
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        checkNeedLoadMore(indexPath: indexPath)
    }

    private func checkNeedLoadMore(indexPath: IndexPath) {
        if listDirection == .vert, indexPath.row == viewModel.mailThreads.all.count - 5 {
            loadMoreIfNeeded()
        }
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if indexPath.row < viewModel.mailThreads.all.count {
            let threadID = viewModel.mailThreads.all[indexPath.row].threadID
            selectedIndex = indexPath
            selectedThreadID = threadID
            collectionView.reloadData()
            delegate?.cardItemHandler(index: indexPath.row, threadID: threadID)
        }
    }

    func loadMoreIfNeeded() {
        delegate?.loadMoreIfNeeded()
    }
}

extension IndexPath {
    func isEqualTo(_ indexPath: IndexPath) -> Bool {
        return self.section == indexPath.section && self.item == indexPath.item
    }
}

class StrangerFlowLayoutWithAnimation: UICollectionViewFlowLayout {

    var insertedItemsToAnimate: Set<IndexPath> = []
    var deletedItemsToAnimate: Set<IndexPath> = []
    //The default move animation is good, simple, refactor animation is not good for move, I recommend you use default move animation.
    var movedItemsToAnimate: Set<UICollectionViewUpdateItem> = []

    override func prepare(forCollectionViewUpdates updateItems: [UICollectionViewUpdateItem]) {
        super.prepare(forCollectionViewUpdates: updateItems)
        for updateItem in updateItems {
            switch updateItem.updateAction{
            case .insert:
                if let indexPath = updateItem.indexPathAfterUpdate {
                    insertedItemsToAnimate.insert(indexPath)
                } else {
                    break
                }
            case .delete:
                if let indexPath = updateItem.indexPathBeforeUpdate {
                    deletedItemsToAnimate.insert(indexPath)
                } else {
                    break
                }
            case .move:
                movedItemsToAnimate.insert(updateItem)
            default: break
            }
        }
    }

    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard itemIndexPath.row != 0 else { return nil }
        let attr = self.layoutAttributesForItem(at: itemIndexPath)
        //the follow code to reslove ths issue of delete the last cell in the section.
        if deletedItemsToAnimate.contains(itemIndexPath){
            attr?.alpha = 0
        }

        //If you don't want this mvoe effect, remove the code.
        if !movedItemsToAnimate.isEmpty && indexPathsBeforeUpdate(inMoveItemsSet: movedItemsToAnimate, containIndexPath: itemIndexPath){
            attr?.alpha = 0
        }

        return attr
    }

    func indexPathsBeforeUpdate(inMoveItemsSet moveSet: Set<UICollectionViewUpdateItem>, containIndexPath indexPath: IndexPath) -> Bool{
        let filteredResult = moveSet.filter({updateItem in
            let newIndexPath = updateItem.indexPathBeforeUpdate
            if let newIndex = newIndexPath {
                return newIndex.isEqualTo(indexPath)
            } else {
                return false
            }
        })

        return !filteredResult.isEmpty ? true : false
    }

    func indexPathsAfterUpdate(inMoveItemsSet moveSet: Set<UICollectionViewUpdateItem>, containIndexPath indexPath: IndexPath) -> Bool{
        let filteredResult = moveSet.filter({ updateItem in
            let newIndexPath = updateItem.indexPathAfterUpdate
            if let newIndex = newIndexPath {
                return newIndex.isEqualTo(indexPath)
            } else {
                return false
            }
        })

        return !filteredResult.isEmpty ? true : false
    }


    func oldIndexPathOf(indexPath: IndexPath, inMoveItemSet moveSet: Set<UICollectionViewUpdateItem>) -> IndexPath? {
        let filteredResult: [UICollectionViewUpdateItem] = moveSet.filter({ updateItem in
            let newIndexPath = updateItem.indexPathAfterUpdate
            if let newIndex = newIndexPath {
                return newIndex.isEqualTo(indexPath)
            } else {
                return false
            }
        })

        return filteredResult[0].indexPathBeforeUpdate

    }

    override func finalizeCollectionViewUpdates() {
        super.finalizeCollectionViewUpdates()
        insertedItemsToAnimate.removeAll()
        deletedItemsToAnimate.removeAll()
        movedItemsToAnimate.removeAll()
    }
}

class MailStrangerCardMoreItemView: UICollectionReusableView {

    weak var delegate: MailStrangerCardMoreItemDelegate?
    private lazy var contentView = UIView()
    private lazy var textContainer: UIStackView = {
        let textContainer = UIStackView()
        textContainer.axis = .horizontal
        textContainer.spacing = 1
        textContainer.alignment = .fill
        textContainer.distribution = .fillEqually
        return textContainer
    }()
    private lazy var moreCardLabel: UILabel = {
        let moreCardLabel = UILabel()
        moreCardLabel.textColor = UIColor.ud.textTitle
        moreCardLabel.font = UIFont.systemFont(ofSize: 12)
        moreCardLabel.textAlignment = .center
        moreCardLabel.text = BundleI18n.MailSDK.Mail_StrangerMail_IncompleteList_ViewAll_Button
        moreCardLabel.numberOfLines = 0
        return moreCardLabel
    }()
    private lazy var moreCardIcon: UIView = {
        let moreCardIcon = UIView()
        let icon = UIImageView()
        icon.image = UDIcon.rightBoldOutlined.withRenderingMode(.alwaysTemplate)
        icon.tintColor = .ud.iconN2
        moreCardIcon.addSubview(icon)
        icon.snp.makeConstraints { make in
            make.left.centerY.equalToSuperview()
            make.width.height.equalTo(8)
        }
        return moreCardIcon
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = false
        addSubview(contentView)
        contentView.snp.makeConstraints { (make) in
            make.left.top.height.equalToSuperview()
            make.width.equalToSuperview().offset(-StrangerCardConst.cardListMoreItemInsetPadding)
        }

        let viewFrame = CGRect(origin: CGPoint(x: 0.5, y: 0), size: CGSize(width: frame.size.width - StrangerCardConst.cardListMoreItemInsetPadding, height: frame.size.height))

        let view = UIView()
        view.frame = viewFrame
        view.layer.cornerRadius = 10
        let shadows = UIView()
        shadows.frame = viewFrame
        shadows.clipsToBounds = false
        view.addSubview(shadows)
        let shadowPath0 = UIBezierPath(roundedRect: shadows.bounds, cornerRadius: 8)
        let layer0 = CALayer()
        layer0.shadowPath = shadowPath0.cgPath
        layer0.shadowColor = UIColor(red: 0.122, green: 0.137, blue: 0.161, alpha: 0.08).cgColor
        layer0.shadowOpacity = 1
        layer0.shadowRadius = 6
        layer0.shadowOffset = CGSize(width: 0, height: 2)
        layer0.bounds = shadows.bounds
        layer0.position = shadows.center
        shadows.layer.addSublayer(layer0)
        let shapes = UIView()
        shapes.frame = view.frame
        shapes.clipsToBounds = true
        view.addSubview(shapes)
        let layer1 = CALayer()
        layer1.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        layer1.bounds = shapes.bounds
        layer1.position = shapes.center
        shapes.layer.addSublayer(layer1)
        shapes.layer.cornerRadius = 8
        let stroke = UIView()
        stroke.backgroundColor = UIColor.ud.bgFloat
        stroke.bounds = view.bounds.insetBy(dx: -0.5, dy: -0.5)
        stroke.center = view.center
        view.addSubview(stroke)
        stroke.layer.cornerRadius = 8.5
        view.bounds = view.bounds.insetBy(dx: -0.5, dy: -0.5)
        stroke.layer.borderWidth = 0.5
        stroke.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        addSubview(view)


//        let cornerLayer = CALayer()
//        cornerLayer.frame = CGRect(x: 0, y: 0, width: StrangerCardConst.footerWidth, height: StrangerCardConst.cardHeight)
//        cornerLayer.cornerRadius = 10
//        cornerLayer.borderWidth = 0.5
//        cornerLayer.shadowColor = UIColor.ud.rgb("1F2329").cgColor
//        cornerLayer.backgroundColor = UIColor.ud.rgb("1F2329").cgColor
//        cornerLayer.masksToBounds = false
//        cornerLayer.shadowOffset = CGSize(width: 0, height: 2)
//        cornerLayer.shadowRadius = 3
//        cornerLayer.shadowOpacity = 0.8
//        cornerLayer.ud.setShadow(type: .s2Down)
//        self.layer.insertSublayer(cornerLayer, below: contentView.layer)

        view.addSubview(moreCardLabel)
        moreCardLabel.snp.makeConstraints { make in
            make.left.equalTo(StrangerCardConst.cardListInsetPadding)
            make.width.equalTo(StrangerCardConst.moreActionTitleWidth)
            make.centerY.equalToSuperview()
        }
        moreCardLabel.sizeToFit()

        view.addSubview(moreCardIcon)
        moreCardIcon.snp.makeConstraints { make in
            make.left.equalTo(moreCardLabel.snp.right).offset(2)
            make.width.height.equalTo(StrangerCardConst.moreItemArrowIconWidth)
            make.centerY.equalToSuperview()
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapAction(_:)))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }

    @objc
    func tapAction(_ sender: UITapGestureRecognizer) {
        delegate?.moreItemHandler()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
