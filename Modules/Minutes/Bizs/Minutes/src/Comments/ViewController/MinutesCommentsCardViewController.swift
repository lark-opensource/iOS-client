//
//  MinutesCommentsCardViewController.swift
//  Minutes
//
//  Created by yangyao on 2021/1/31.
//

import UIKit
import MinutesFoundation
import MinutesNetwork
import UniverseDesignToast
import LarkAlertController
import UniverseDesignIcon
import LarkEMM
import LarkContainer
import LarkAccountInterface
import LarkUIKit
import LarkAssetsBrowser
import ByteWebImage

class MinutesCommentsCardViewController: UIViewController, UserResolverWrapper {
    let userResolver: LarkContainer.UserResolver
    @ScopedProvider var passportUserService: PassportUserService?
        
    let minutesCommentEnableHeight: CGFloat = 454
    let minutesCommentDisableHeight: CGFloat = 402

    var lastOffset: CGFloat = 0.0
    var isRightSwipe: Bool = true
    var swipeOffset: CGFloat = 0.0

    var currentIndexPath: IndexPath = IndexPath(item: 0, section: 0)
    var collectionHeight: CGFloat = 454

    var commentsViewModel: MinutesCommentsViewModel?
    var commentsInfo: ParagraphCommentsInfo?
    var commentsList: [Comment] = []

    var originalCommentsInfo: ParagraphCommentsInfo? {
        commentsViewModel?.originalCommentsInfo?[pid]
    }
    var originalCommentsList: [Comment] {
        originalCommentsInfo?.commentList ?? []
    }

    var isInTranslationMode: Bool {
        commentsViewModel?.isInTranslationMode == true
    }
    var isRecordingDetail: Bool = false

    var cardCount: Int = 0
    var currentCount: NSInteger = 0
    let minutes: Minutes
    let pid: String
    var needScrollToBottom: Bool = false
    var contentRow: NSInteger?
    var animated: Bool = true
    var canComment = true {
        didSet {
            collectionHeight = canComment ? minutesCommentEnableHeight : minutesCommentDisableHeight
        }
    }

    var currentHighlightedBlock: ((Comment) -> Void)?
    var dismissBlock: (() -> Void)?

    lazy var tracker: MinutesTracker = {
        return MinutesTracker(minutes: minutes)
    }()

    private var collectionLayout: UICollectionViewFlowLayout {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: view.bounds.width - 16 * 2, height: collectionHeight)
        layout.minimumLineSpacing = 8
        return layout
    }

    lazy var collectionView: UICollectionView = {
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: collectionLayout)
        collectionView.backgroundColor = .clear
        collectionView.register(MinutesCommentsCardCell.self, forCellWithReuseIdentifier: MinutesCommentsCardCell.description())
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.showsVerticalScrollIndicator = false
        return collectionView
    }()

    lazy var pageControl: MinutesCommentsPageControl = {
        let control = MinutesCommentsPageControl()
        return control
    }()

    init(resolver: UserResolver, minutes: Minutes, pid: String, commentsViewModel: MinutesCommentsViewModel?, currentCount: NSInteger = 0, contentRow: NSInteger? = nil, needScrollToBottom: Bool = false, animated: Bool = true) {
        self.userResolver = resolver
        self.minutes = minutes
        self.pid = pid
        self.commentsViewModel = commentsViewModel
        self.commentsInfo = commentsViewModel?.commentsInfo[pid]
        self.currentCount = currentCount
        self.contentRow = contentRow
        self.needScrollToBottom = needScrollToBottom
        self.animated = animated
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .overFullScreen
    }

    func configurePage(_ commentsInfo: ParagraphCommentsInfo?, originalCommentsInfo: ParagraphCommentsInfo? = nil) {
        commentsViewModel?.commentsInfo[pid] = commentsInfo
        self.commentsInfo = commentsInfo

        commentsList = commentsInfo?.commentList ?? []
        cardCount = commentsList.count

        // 重新布局，使其居中
        pageControl.totalCount = cardCount
        pageControl.setNeedsLayout()
        pageControl.layoutIfNeeded()
        let pageControlWidth = pageControl.collectionView.contentSize.width < MinutesCommentsPageControl.maxWidth ? pageControl.collectionView.contentSize.width : MinutesCommentsPageControl.maxWidth
        pageControl.snp.remakeConstraints { (maker) in
            maker.top.equalTo(collectionView.snp.bottom).offset(8)
            maker.centerX.equalToSuperview()
            maker.width.equalTo(pageControlWidth)
        }
        // 设置当前index
        configure(currentCount)

        collectionView.reloadData()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if self.collectionView.numberOfItems(inSection: 0) <= 0 {
                return
            }
            if self.currentCount >= self.collectionView.numberOfItems(inSection: 0) {
                return
            }
            self.collectionView.scrollToItem(at: IndexPath(item: self.currentCount, section: 0), at: .centeredHorizontally, animated: self.animated)
            // 等待动画结束
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                if let contentRow = self.contentRow {
                    self.scrollToBottomAction(contentRow)
                    self.needScrollToBottom = false
                    self.contentRow = nil
                } else if self.needScrollToBottom {
                    self.scrollToBottomAction()
                    self.needScrollToBottom = false
                    self.contentRow = nil
                }
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let containerView = UIView()
        view.addSubview(containerView)

        let tapGesture = UITapGestureRecognizer()
        tapGesture.addTarget(self, action: #selector(dismissSelf))
        containerView.addGestureRecognizer(tapGesture)
        view.backgroundColor = UIColor.ud.staticBlack.withAlphaComponent(0.35)
        view.addSubview(collectionView)
        view.addSubview(pageControl)

        containerView.snp.makeConstraints { (maker) in
            maker.top.left.right.equalToSuperview()
            maker.bottom.equalTo(collectionView.snp.top)
        }

        collectionView.snp.makeConstraints { (maker) in
            maker.bottom.equalToSuperview().offset(-56)
            maker.height.equalTo(collectionHeight)
            maker.left.equalToSuperview()
            maker.right.equalToSuperview()
        }
        pageControl.snp.makeConstraints { (maker) in
            maker.top.equalTo(collectionView.snp.bottom).offset(8)
            maker.centerX.equalToSuperview()
            maker.width.equalTo(MinutesCommentsPageControl.maxWidth)
        }

        configurePage(commentsInfo, originalCommentsInfo: originalCommentsInfo)

        minutes.data.listeners.addListener(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        guard Display.pad else { return }
        coordinator.animate { [weak self] _ in
            guard let self = self else { return }
            self.collectionView.reloadData()
        }
    }

    // 接收远端数据更新
    private func onCommentsUpdate(_ data: ([String], Bool)) {
        guard !isInTranslationMode else { return }
        let isFromPush = data.1
        if isFromPush {
            self.handleCommentUpdate(self.minutes.data.paragraphComments[self.pid])
        }
    }

    func scrollToBottomAction(_ contentRow: NSInteger? = nil) {
        // 滚动到底部
        if let cell = self.collectionView.cellForItem(at: currentIndexPath) as? MinutesCommentsCardCell {
            let comment = self.commentsList[currentIndexPath.item]
            let tableView = cell.commentsCardView.tableView
            if let contentRow = contentRow, contentRow < cell.commentsCardView.dataSource.count {
                let indexPath = IndexPath(row: contentRow, section: 0)
                if tableView.indexPathExists(indexPath: indexPath) {
                    tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                }
            } else {
                let indexPath = IndexPath(row: comment.contents.count - 1, section: 0)
                if tableView.indexPathExists(indexPath: indexPath) {
                    tableView.scrollToRow(at: indexPath, at: .bottom, animated: true)
                }
            }
        }
    }

    @objc func dismissSelf() {
        dismissBlock?()
        dismiss(animated: false, completion: nil)
    }
}

extension MinutesCommentsCardViewController: MinutesDataChangedListener {
    public func onMinutesCommentsUpdate(_ data: ([String], Bool)?) {
        if let data = data {
            onCommentsUpdate(data)
        }
    }
}

extension MinutesCommentsCardViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return commentsList.count
    }
}

extension MinutesCommentsCardViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: MinutesCommentsContentCell.LayoutContext.collectionInset, bottom: 0, right: MinutesCommentsContentCell.LayoutContext.collectionInset)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: view.bounds.width - 16 * 2, height: collectionHeight)
    }
}

extension MinutesCommentsCardViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: MinutesCommentsCardCell.description(), for: indexPath) as? MinutesCommentsCardCell else {
            return UICollectionViewCell()
        }
        let comment = commentsList[indexPath.item]

        var originalComment: Comment?
        if originalCommentsList.indices.contains(indexPath.item) {
            originalComment = originalCommentsList[indexPath.item]
        }

        let contentWidth: CGFloat = MinutesCommentsContentCell.getContentWidth(wholeWidth: self.view.bounds.width)

        cell.commentsCardView.configure(resolver: userResolver, contentWidth: contentWidth, comment: comment, originalComment: originalComment, isInTranslationMode: isInTranslationMode)
        cell.commentsCardView.addCommentsActionBlock = { [weak self, weak cell] in
            guard let self = self, let weakCell = cell else { return }
            self.addCommentsAction(comment, indexPath: indexPath, cell: weakCell)
        }
        cell.commentsCardView.sendCommentsBlock = { [weak self, weak cell] in
            guard let self = self, let weakCell = cell, let text = self.getTextViewContent(indexPath) else { return }
            self.sendCommentsAction(text, comment: comment, cell: weakCell, indexPath: indexPath)
        }
        cell.commentsCardView.textLongTapBlock = { [weak self, weak cell] commentContent, attributedText, point in
            guard let self = self, let weakCell = cell else { return }
            self.longTapAction(commentContent, attributedText: attributedText, point: point, cell: weakCell)
        }
        cell.commentsCardView.imageLongTapBlock = { [weak self, weak cell] commentContent, point in
            guard let self = self, let weakCell = cell else { return }
            self.longTapAction(commentContent, attributedText: NSAttributedString(), point: point, cell: weakCell)
        }
        cell.commentsCardView.didSelectAavtarBlock = { [weak self] userId in
            guard let self = self else { return }
            self.gotoProfile(userId: userId)
        }
        cell.commentsCardView.textTapBlock = { [weak self] userId in
            guard let self = self else { return }
            self.gotoProfile(userId: userId)
        }
        cell.commentsCardView.linkTapBlock = { [weak self] url in
            guard let self = self else { return }
            self.openUrl(url: url)
        }
        cell.commentsCardView.imageTapBlock = { [weak self] (imageItems:[ContentForIMItem], fromIndex:Int) in
            guard let self = self else { return }
            self.openImageBrowser(imageItems: imageItems, fromIndex: fromIndex)
        }
        return cell
    }
}

extension MinutesCommentsCardViewController {
    func longTapAction(_ commentContent: CommentContent, attributedText: NSAttributedString, point: CGPoint, cell: MinutesCommentsCardCell) {
        let menuVC = MinutesCommentsMenuController()

        var dataSource: [MinutesCommentsMenuItem] = []
        if attributedText.length > 0 {
            dataSource.append(
                MinutesCommentsMenuItem(title: BundleI18n.Minutes.MMWeb_G_Copy,
                                        icon: UDIcon.getIconByKey(.copyOutlined, iconColor: UIColor.ud.iconN1),
                                                      action: { [weak self, weak menuVC] _ in
                                                        guard let self = self, let weakMenuVC = menuVC else { return }
                                                        weakMenuVC.dismissSelf()
                                                        Device.pasteboard(token: DeviceToken.pasteboardComment, text: attributedText.string)
                                                        UDToast.showTips(with: BundleI18n.Minutes.MMWeb_G_CopiedSuccessfully, on: self.view)
                                                      }))
        }
        if passportUserService?.user.userID == commentContent.userID || minutes.basicInfo?.isOwner == true {
            let commentSource = passportUserService?.user.userID == commentContent.userID ? "self" : "others"

            dataSource.append(
                MinutesCommentsMenuItem(title: BundleI18n.Minutes.MMWeb_G_Delete,
                                        icon: UDIcon.getIconByKey(.deleteTrashOutlined, iconColor: UIColor.ud.iconN1),
                                        action: { [weak self, weak menuVC] _ in
                                            self?.tracker.tracker(name: .detailClick, params: ["click": "delete_comment", "target": "none", "comment_owner": commentSource])

                                            menuVC?.dismissSelf()

                                            let alertController: LarkAlertController = LarkAlertController()
                                            alertController.setTitle(text: BundleI18n.Minutes.MMWeb_G_DeleteComment, color: UIColor.ud.textTitle, font: UIFont.systemFont(ofSize: 17))
                                            alertController.addSecondaryButton(text: BundleI18n.Minutes.MMWeb_G_Cancel, dismissCompletion: nil)
                                            alertController.addDestructiveButton(text: BundleI18n.Minutes.MMWeb_G_Delete, dismissCompletion: { [weak self] in
                                                guard let self = self else { return }

                                                self.deleteComments(commentContent.id)
                                                self.tracker.tracker(name: .clickButton, params: ["action_name": "delete_comment", "comment_source": commentSource])
                                            })
                                            self?.present(alertController, animated: true)
                                        }))
        }
        if dataSource.isEmpty {
            return
        }
        menuVC.containerWidth = view.bounds.width
        menuVC.dataSource = dataSource

        menuVC.cardTopInWindow = view.convert(CGPoint(x: 0, y: collectionView.frame.minY), to: nil)
        menuVC.textFirstLineInWindow = cell.commentsCardView.convert(point, to: nil)
        present(menuVC, animated: false, completion: nil)
    }

    func addCommentsAction(_ comment: Comment, indexPath: IndexPath, cell: MinutesCommentsCardCell) {
        tracker.tracker(name: .clickButton, params: ["action_name": "create_comment", "route": "comment"])

        UIView.animate(withDuration: 0.15) {
            self.collectionView.alpha = 0.0
        }

        // 回复评论只需要两个参数即可
        let commentsVC = MinutesAddCommentsViewController(commentsViewModel: commentsViewModel, info: [AddCommentsVCParams.isNewComment: false, AddCommentsVCParams.quote: comment.quote, AddCommentsVCParams.fillText: getTextViewContent(indexPath)])

        commentsVC.sendCommentsBlock = { [weak self, weak commentsVC] text in
            guard let self = self, let weakCommentsVC = commentsVC else { return }
            weakCommentsVC.dismissSelf()
            // 发送评论后内容出现在卡片页面
            self.fillTextView(indexPath, text: text)

            self.sendCommentsAction(text, comment: comment, cell: cell, indexPath: indexPath)
        }
        commentsVC.dismissSelfBlock = { [weak self] text in
            // 点击空白将已输入的内容出现在卡片页面
            self?.fillTextView(indexPath, text: text)

            UIView.animate(withDuration: 0.15) {
                self?.collectionView.alpha = 1.0
            }
        }
        present(commentsVC, animated: false, completion: nil)
    }

    func sendCommentsAction(_ text: String, comment: Comment, cell: MinutesCommentsCardCell, indexPath: IndexPath) {
        cell.commentsCardView.showLoading(true)
        commentsViewModel?.sendCommentsAction(catchError: true, true, text: text, commentId: comment.id, success: { [weak self] response in
            guard let self = self else { return }
            // 先后顺序
            self.fillTextView(indexPath, text: "")
            cell.commentsCardView.showLoading(false)

            // 刷新下comments的个数
            self.needScrollToBottom = true
            self.configurePage(response.comments[self.pid])

            self.tracker.tracker(name: .recordingPage, params: ["action_name": "create_comment", "route": "comment"])
            self.tracker.tracker(name: .detailClick, params: ["click": "create_comment", "target": "none", "location": "comment"])
        }, fail: { [weak self] (_) in
            guard let self = self else { return }
            cell.commentsCardView.showLoading(false)
        })
    }

    func deleteComments(_ contentID: String) {
        if isRecordingDetail {
            tracker.tracker(name: .recordingPage, params: ["action_name": "delete_comment"])
        }

        commentsViewModel?.deleteComments(catchError: true, contentID, success: { [weak self] response in
            guard let self = self else { return }
            if self.isInTranslationMode {
                if var commentsInfo = self.commentsInfo {
                    var list: [Comment] = commentsInfo.commentList ?? []
                    guard list.isEmpty == false else { return }
                    var matchedIndex: Int?

                    var matchedComment: Comment?
                    for (idx, comment) in list.enumerated() {
                        if comment.contents.first(where: { $0.id == contentID }) != nil {
                            matchedComment = comment
                            matchedIndex = idx
                            break
                        }
                    }
                    if var matchedComment = matchedComment, let matchedIndex = matchedIndex {
                        var contents = matchedComment.contents
                        contents.removeAll(where: {$0.id == contentID })
                        matchedComment.contents = contents
                        if contents.isEmpty == false {
                            list[matchedIndex] = matchedComment
                        } else {
                            list.remove(at: matchedIndex)
                        }
                    }
                    commentsInfo.commentList = list
                    self.handleCommentUpdate(commentsInfo)
                }
            } else {
                self.handleCommentUpdate(response.comments[self.pid])
            }
        }, fail: { [weak self] (_) in
            guard let self = self else { return }
        })
    }

    func handleCommentUpdate(_ commentsInfo: ParagraphCommentsInfo?) {
        DispatchQueue.main.async {
            if commentsInfo?.commentList == nil {
                self.dismissSelf()
            } else if let list = commentsInfo?.commentList, list.isEmpty {
                self.dismissSelf()
            } else {
                self.configurePage(commentsInfo)
            }
        }
    }

    func getTextViewContent(_ indexPath: IndexPath) -> String? {
        if let cell = self.collectionView.cellForItem(at: indexPath) as? MinutesCommentsCardCell {
            return cell.commentsCardView.getText()
        }
        return nil
    }

    func fillTextView(_ indexPath: IndexPath, text: String) {
        if let cell = collectionView.cellForItem(at: indexPath) as? MinutesCommentsCardCell {
            cell.commentsCardView.fillText(text)
        }
    }
}

extension MinutesCommentsCardViewController: UIScrollViewDelegate {
    func configure(_ currentCount: NSInteger) {
        self.currentCount = currentCount
        if currentCount >= cardCount {
            if !commentsList.isEmpty {
                self.currentCount = 0
            } else {
                return
            }
        }

        currentIndexPath = IndexPath(item: self.currentCount, section: 0)
        pageControl.currentCount = self.currentCount

        let comment: Comment = commentsList[self.currentCount]
        currentHighlightedBlock?(comment)
    }

    func endScrolling() {
        let visibleRect = CGRect(origin: collectionView.contentOffset, size: collectionView.bounds.size)
        let visiblePoint = CGPoint(x: visibleRect.midX, y: visibleRect.midY)
        let visibleIndexPath = collectionView.indexPathForItem(at: visiblePoint)
        if let visibleIndexPath = visibleIndexPath {
            configure(visibleIndexPath.item)
        }
    }

    func scrollToIndexPath() {
        collectionView.isUserInteractionEnabled = false
        if !isRightSwipe { // 往左滑
            guard currentIndexPath.item != cardCount - 1 else {
                collectionView.scrollToItem(at: currentIndexPath, at: .centeredHorizontally, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.collectionView.isUserInteractionEnabled = true
                }
                return
            }
            if swipeOffset > 20 {
                collectionView.scrollToItem(at: IndexPath(item: currentIndexPath.item + 1, section: 0), at: .centeredHorizontally, animated: true)
            } else {
                collectionView.scrollToItem(at: currentIndexPath, at: .centeredHorizontally, animated: true)
            }

        } else if isRightSwipe {
            guard currentIndexPath.item != 0 else {
                collectionView.scrollToItem(at: currentIndexPath, at: .centeredHorizontally, animated: true)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.collectionView.isUserInteractionEnabled = true
                }
                return
            }

            if swipeOffset > 20 {
                collectionView.scrollToItem(at: IndexPath(item: currentIndexPath.item - 1, section: 0), at: .centeredHorizontally, animated: true)
            } else {
                collectionView.scrollToItem(at: currentIndexPath, at: .centeredHorizontally, animated: true)
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.collectionView.isUserInteractionEnabled = true
            self.endScrolling()
        }
    }

    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        lastOffset = scrollView.contentOffset.x
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        scrollToIndexPath()
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        swipeOffset = abs(lastOffset - scrollView.contentOffset.x)
        if lastOffset > scrollView.contentOffset.x {
            isRightSwipe = true
        } else if lastOffset < scrollView.contentOffset.x {
            isRightSwipe = false
        }
    }

    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        scrollToIndexPath()
    }
}

extension MinutesCommentsCardViewController {
    func gotoProfile(userId: String) {
        self.tracker.tracker(name: .clickButton, params: ["action_name": "profile_picture", "page_name": "detail_page", "from_source": " commentator_picture"])
        MinutesProfile.personProfile(chatterId: userId, from: self, resolver: userResolver)

        tracker.tracker(name: .detailClick, params: ["click": "profile", "location": "commentator_picture", "target": "none"])
    }
}

extension MinutesCommentsCardViewController {
    func openUrl(url: String) {
        if let urlPath = URL(string: url) {
            self.userResolver.navigator.present(urlPath, context: [:], wrap: LkNavigationController.self, from: self)
        }
    }
}

extension MinutesCommentsCardViewController {
    func openImageBrowser(imageItems:[ContentForIMItem], fromIndex: Int) {
        var assets: [LKDisplayAsset] = []
        for item in imageItems {
            let asset = buildAssetFromItem(item)
            assets.append(asset)
        }

        let controller = LKAssetBrowserViewController(
            assets: assets,
            pageIndex: fromIndex)
        controller.isPhotoIndexLabelHidden = false
        controller.isSavePhotoButtonHidden = true
        controller.prepareAssetInfo = { [weak self] (displayAsset) in
            guard let self = self else { return (LarkImageResource.default(key: displayAsset.key), nil, TrackInfo(scene: .MinutesDetail))}
            var passThrough: ImagePassThrough?
            let key = displayAsset.key
            if !displayAsset.fsUnit.isEmpty {
                passThrough = ImagePassThrough()
                passThrough?.key = key
                passThrough?.fsUnit = displayAsset.fsUnit
                passThrough?.crypto = self.getImageCrypto(imageItems, key)
                return (LarkImageResource.rustImage(key: displayAsset.key, fsUnit: passThrough?.fsUnit),
                        passThrough, TrackInfo(scene: .MinutesDetail))
            }
            return (LarkImageResource.default(key: key), nil, TrackInfo(scene: .MinutesDetail))
        }

        self.userResolver.navigator.present(controller, from: self)
        
    }
    
    func getImageCrypto(_ items : [ContentForIMItem], _ key : String) -> ImagePassThrough.SerCrypto {
        var ret = ImagePassThrough.SerCrypto()
        for item in items {
            guard let itemKey = item.attr?.key else { continue }
            if (itemKey == key) {
                let secretStr = item.attr?.crypto?.cipher.secret
                let nonceStr = item.attr?.crypto?.cipher.nonce
                let type = item.attr?.crypto?.type
                var cipher = ImagePassThrough.SerCrypto.Cipher()
                cipher.secret = Data(base64Encoded: secretStr ?? "") ?? Data()
                cipher.nonce = Data(base64Encoded: nonceStr ?? "") ?? Data()
                ret.type = ImagePassThrough.SerCrypto.TypeEnum(rawValue: Int(type ?? 0))
                ret.cipher = cipher
                break
            }
        }
        return ret
    }

        
    func buildAssetFromItem(_ item: ContentForIMItem) -> LKDisplayAsset {
        let asset = LKDisplayAsset()
        guard let key = item.attr?.origin?.key else { return asset }
        asset.key = key
        asset.originalImageKey = key
        return asset
    }
    
}




