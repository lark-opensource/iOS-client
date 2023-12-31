//
//  AsideCommentView.swift
//  SKCommon
//
//  Created by huayufan on 2022/9/26.
//
// swiftlint:disable line_length file_length

import SKFoundation
import RxSwift
import RxRelay
import RxCocoa
import SKUIKit
import Photos
import Differentiator
import UniverseDesignToast
import UIKit
import SKResource
import UniverseDesignIcon
import SpaceInterface
import SKCommon
import SKInfra

class AsideCommentView: UIView {
    
    struct Layout {
        static let sectionHeaderHeight: CGFloat = 0
        static let sectionFooterHeight: CGFloat = 20
        static let topHeaderHeight: CGFloat = 40
    }
    
    class AsideCommentTableView: UITableView {

        var renderEnd: (() -> Void)?

        override func layoutIfNeeded() {
            DocsLogger.info("layout if need", component: LogComponents.comment)
            super.layoutIfNeeded()
        }
        
        override func setContentOffset(_ contentOffset: CGPoint, animated: Bool) {
            DocsLogger.info("contentOffset:\(contentOffset) animated:\(animated)", component: LogComponents.comment)
            super.setContentOffset(contentOffset, animated: animated)
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            if numberOfSections > 0 {
                renderEnd?()
            }
        }

    }
    
    class HeaderView: UIView {

        lazy var commentLabel: UILabel = {
            let view = UILabel(frame: .zero)
            view.textColor = UIColor.ud.N800
            view.font = UIFont.systemFont(ofSize: 14.0, weight: .medium)
            return view
        }()
        
        lazy var sperationLine: UIView = {
            let view = UIView(frame: .zero)
            view.backgroundColor = UIColor.ud.N300
            return view
        }()
        
        lazy var closeButton: DocsButton = {
            let view = DocsButton(frame: .zero)
            view.widthInset = -8
            view.heightInset = -8
            view.setTitleColor(UIColor.ud.N800, for: .normal)
            let icon = UDIcon.getIconByKey(.closeOutlined, renderingMode: .alwaysOriginal, size: .init(width: 16, height: 16))
            view.setImage(icon.ud.withTintColor(UIColor.ud.iconN1), for: .normal)
            view.docs.addHighlight(with: UIEdgeInsets(top: -2, left: -4, bottom: -2, right: -4), radius: 4)
            return view
        }()
        
        override init(frame: CGRect) {
            super.init(frame: frame)
            setupLayout()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        func setupLayout() {
            addSubview(commentLabel)
            addSubview(closeButton)
            addSubview(sperationLine)

            commentLabel.snp.makeConstraints { (make) in
                make.left.equalTo(17)
                make.centerY.equalToSuperview()
                make.height.equalTo(20)
            }
            closeButton.snp.makeConstraints { (make) in
                make.width.height.equalTo(24)
                make.right.equalToSuperview().offset(-16)
                make.centerY.equalTo(commentLabel)
            }
    
            sperationLine.snp.makeConstraints { (make) in
                make.bottom.equalToSuperview()
                make.height.equalTo(1)
                make.left.right.equalToSuperview()
            }
        }
    }
    
    static var ipadHeadCellId = "CommentTableViewHeadCellPad"
    static var ipadFooterCellId = "CommentTableViewFooterCellPad"
    static var ipadBodyCellId = "CommentTableViewBodyCellPad"

    enum ScrollStatus {
        case idle
        case scrolling
    }

    var commentSections = [CommentSection]()

    var docsInfo: DocsInfo?
    
    var commentPermission: CommentPermission?

    /// 记住当前评论的位置，防止刷新之后UI跳动
    var preReference: (String?, CGFloat)?

    private let disposeBag = DisposeBag()
    
    ///如果定位时没有position默认定位到哪
    let ratioAnchorPosition: CGFloat = 0.3

    /// 初始化ContentOffsetY高度
    let initContentOffsetY: CGFloat = 12
    
    var copyAnchorLinkEnable = false
    
    var translateConfig: CommentTranslateConfig?

    private var heightCacheBody: [String: (CGFloat, CommentItem)] = [:]
    private var heightCacheHeader: [String: CGFloat] = [:]
    private var heightCacheFooter: [String: (CGFloat, Bool)] = [:]
    
    var newHeightCacheKey: [String: CGFloat] = [:]
   
    private lazy var viewCapturePreventer: ViewCapturePreventable = {
        let preventer = ViewCapturePreventer()
        preventer.notifyContainer = []
        return preventer
    }()
    

    private var loadingIndicatorView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView(style: .gray)
        view.hidesWhenStopped = true
        view.transform = CGAffineTransform(scaleX: 1.4, y: 1.4)
        return view
    }()
    
    lazy var leftSperationLine: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = UIColor.ud.N300
        return view
    }()

    lazy var keyboardBlankView: UIView = {
        let blankView = UIView()
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapBlankView(_:)))
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(panBlankView(_:)))
        blankView.addGestureRecognizer(tapGesture)
        blankView.addGestureRecognizer(panGesture)
        return blankView
    }()
    
    /// 正则reload过程中，会触发textview的textViewDidChange，会导致beginUpdate时crash
    var tvReloading: Bool = false
    
#if BETA || ALPHA || DEBUG
    lazy var debugView: UIView = {
        let db = UIView()
        db.backgroundColor = UIColor.red
        db.isUserInteractionEnabled = false
        return db
    }()
#endif
    ///  锚点距离容器底部的高度，nil表示当前无激活评论
    var lastCallBackHeight: CGFloat? {
        didSet {
#if BETA || ALPHA || DEBUG
            if CommentDebugModule.canDebug {
                if debugView.superview == nil {
                    addSubview(debugView)
                }
                var y = self.anchorPointHeightFromTop + Layout.topHeaderHeight
                if lastCallBackHeight == nil {
                    y = Layout.topHeaderHeight
                }
                bringSubviewToFront(debugView)
                debugView.frame = CGRect(x: 0, y: y, width: bounds.size.width, height: 2)
            }
#endif
        }
    }

    var scrollViewDidDragged: Bool = false
    
    var fontZoomable = false
    
    var scrollStatus: ScrollStatus = .idle
    
    lazy var debounce: DebounceProcesser = {
        return DebounceProcesser()
    }()

    lazy var foucusTipsView: CommentFoucusTipsView = {
        let tipsView = CommentFoucusTipsView()
        return tipsView
    }()

    private(set) lazy var cancelHightLightTap: UITapGestureRecognizer = { // 点击空白取消高亮
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(type(of: self).cancelHightLightFromNative))
        singleTap.delegate = self
        return singleTap
    }()

    lazy var headerView: HeaderView = {
        let header = HeaderView()
        header.backgroundColor = UIColor.ud.bgBody
        header.closeButton.addTarget(self, action: #selector(didHideCommentView), for: .touchUpInside)
        return header
    }()
    
    lazy var tableView: UITableView = {
        let tv = AsideCommentTableView(frame: .zero, style: .plain)
        tv.disableCacheOrientation = true
        tv.clipsToBounds = false
        tv.allowsSelection = false
        tv.showsVerticalScrollIndicator = false
        tv.showsHorizontalScrollIndicator = false
        tv.separatorStyle = .none
        tv.contentInsetAdjustmentBehavior = .never
        tv.estimatedSectionHeaderHeight = 0
        tv.estimatedSectionFooterHeight = 0
        tv.register(CommentQuoteAndReplyCellPad.self, forCellReuseIdentifier: AsideCommentView.ipadHeadCellId)
        tv.register(CommentTableViewCellPad.self, forCellReuseIdentifier: AsideCommentView.ipadBodyCellId)
        tv.register(ContentReactionPadCell.self, forCellReuseIdentifier: ContentReactionPadCell.cellId)
        tv.register(CommentFootViewCell.self, forCellReuseIdentifier: AsideCommentView.ipadFooterCellId)
        tv.register(CommentUnsupportedCell.self, forCellReuseIdentifier: CommentUnsupportedCell.reusePadIdentifier)
        tv.contentInset = UIEdgeInsets(top: initContentOffsetY, left: 0, bottom: 0, right: 0)
        tv.contentOffset = CGPoint(x: 0, y: -initContentOffsetY)
        // 预留一些位置在底部可以防止评论无法对齐，出现乱滚动的现象
        // 使用footer代替，而不是去设置contentInset.bottom
        let footer = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 300))
        footer.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(cancelHightLightFromNative)))
        footer.backgroundColor = .clear
        tv.tableFooterView = footer
        tv.renderEnd = { [weak self] in
            self?.viewInteraction?.emit(action: .renderEnd)
        }
        return tv
    }()


    var scrollFollowHandler: CommentScrollFollowHandler?
   
    weak var viewInteraction: CommentViewInteractionType?
    
    weak var textViewDependency: AtInputTextViewDependency?
    
    weak var cellDelegate: CommentTableViewCellDelegate?

    weak var dependency: DocsCommentDependency?

    /// 初始化Aside comment UI视图
    /// - Parameters:
    ///   - viewInteraction: 传递UI事件给plugin
    ///   - textViewDependency: 接收和配置输入框事件
    ///   - cellDelegate: 传递Cell事件给plugin
    init(viewInteraction: CommentViewInteractionType?,
         textViewDependency: AtInputTextViewDependency?,
         cellDelegate: CommentTableViewCellDelegate?,
         dependency: DocsCommentDependency?) {
        super.init(frame: .zero)
        self.dependency = dependency
        self.viewInteraction = viewInteraction
        self.textViewDependency = textViewDependency
        self.cellDelegate = cellDelegate
        self.scrollFollowHandler = CommentScrollFollowHandler(commentView: self, commentScrollDelegate: self)
        setupUI()
        setupBinds()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    
    public override var keyCommands: [UIKeyCommand]? {
        guard self.isFirstResponder else {
            return []
        }
        let commands = [UIKeyCommand(input: UIKeyCommand.inputUpArrow, modifierFlags: [], action: #selector(handleShortcutCommand(_:))),
                        UIKeyCommand(input: UIKeyCommand.inputDownArrow, modifierFlags: [], action: #selector(handleShortcutCommand(_:))),
                        UIKeyCommand(input: UIKeyCommand.inputLeftArrow, modifierFlags: [], action: #selector(handleShortcutCommand(_:))),
                        UIKeyCommand(input: UIKeyCommand.inputRightArrow, modifierFlags: [], action: #selector(handleShortcutCommand(_:)))
        ]
        // https://developer.apple.com/forums/thread/687666
        if #available(iOS 15.0, *) {
            for command in commands {
                command.wantsPriorityOverSystemBehavior = true
            }
        }
        return commands
    }
    
    public override var canBecomeFirstResponder: Bool {
        return true
    }
    
    @objc
    func handleShortcutCommand(_ command: UIKeyCommand) {
        if conferenceInfo?.inConference == true,
           conferenceInfo?.followRole == .follower {
            // follow场景不支持键盘，否则follow状态会不一致
            return
        }
        if command.input == UIKeyCommand.inputDownArrow ||
            command.input == UIKeyCommand.inputRightArrow {
            viewInteraction?.emit(action: .keyCommandDown)
        } else if command.input == UIKeyCommand.inputUpArrow ||
                    command.input == UIKeyCommand.inputLeftArrow {
            viewInteraction?.emit(action: .keyCommandUp)
        } else {
            DocsLogger.error("unsupport this keyCommand: \(String(describing: command.input))")
        }
    }

    @objc
    func cancelHightLightFromNative() {
        viewInteraction?.emit(action: .tapBlank)
    }
    
    @objc
    func didHideCommentView() {
        viewInteraction?.emit(action: .clickClose)
    }
    
    lazy var containerView: UIView = {
        let result: UIView
        if ViewCapturePreventer.isFeatureEnable {
            result = viewCapturePreventer.contentView
        } else {
            result = UIView()
        }
        return result
    }()

    private func setupUI() {
        backgroundColor = UIColor.ud.bgBody
        self.clipsToBounds = true
        addSubview(containerView)
        setCapturePreventNotify(type: [])
        containerView.addSubview(tableView)
        containerView.addSubview(headerView)
        containerView.addSubview(leftSperationLine)
        containerView.addSubview(foucusTipsView)
        containerView.addSubview(loadingIndicatorView)
        
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        headerView.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(Layout.topHeaderHeight)
        }
        
        loadingIndicatorView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }

        leftSperationLine.snp.makeConstraints { (make) in
            make.top.bottom.equalToSuperview()
            make.width.equalTo(1)
            make.left.equalToSuperview()
        }
        
        tableView.construct {
            $0.dataSource = self
            $0.delegate = self
            $0.backgroundColor = UIColor.clear
        }
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(headerView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        foucusTipsView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(headerView.snp.bottom).offset(6)
        }
    }

    func showLoading(show: Bool) {
        if show {
            loadingIndicatorView.startAnimating()
            loadingIndicatorView.isHidden = false
        } else {
            loadingIndicatorView.stopAnimating()
            loadingIndicatorView.isHidden = true
        }
    }

    private func setupBinds() {
        self.addGestureRecognizer(cancelHightLightTap)
        scrollFollowHandler?.showNotice.distinctUntilChanged().bind(to: rx.showFoucusTips).disposed(by: disposeBag)
    }

    func converTopPosition(bottom: CGFloat?) -> CGFloat? {
        guard self.bounds.height > 0, let height = bottom else {
            return nil
        }
        return max(0, self.bounds.height - height)
    }
    
}

// MARK: - update
extension AsideCommentView {

    func vcFollowOnRoleChange(role: FollowRole) {
        scrollFollowHandler?.vcFollowOnRoleChange(role: role)
    }

}


// MARK: - UITableViewDataSource
extension AsideCommentView: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return commentSections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section < commentSections.count {
            return commentSections[section].items.count
        }
        return  0
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Layout.sectionHeaderHeight
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return Layout.sectionFooterHeight
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        return view
    }

    var commentHeightOptimize: Bool {
        return UserScopeNoChangeFG.HYF.asideCommentHeightOptimize
    }

    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if commentHeightOptimize { // GA之后estimatedHeightForRowAt这个方法可以删掉
            return UITableView.automaticDimension
        } else {
            return self.heightFortableView(tableView, heightForRowAt: indexPath)
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if commentHeightOptimize,
           let item = commentSections[indexPath], 
            let height = self.newHeightCacheKey[item.heightCacheKey] {
            // footer在高亮状态下，可能在输入，不需要使用缓存
            let isActive = commentSections[CommentIndex(indexPath.section)]?.isActive ?? false
            return isActive ? UITableView.automaticDimension : height
        }
        return UITableView.automaticDimension
    }


    func heightFortableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var resultHeight: CGFloat = 0
        guard let item = commentSections[indexPath] else { return 0.1 }
        let identify = item.uiType.padUIIdentify
        let cacheKey = item.heightCacheKey
        let caculeHeightBlock: () -> CGFloat = {
            return CGFloat(tableView.getHeightForCell(cellId: identify, cacheKey: cacheKey, configBlock: { (cell) in
                self.configDataWithCell(cell, indexPath: indexPath, estimated: true)
            }))
        }
        if identify == AsideCommentView.ipadHeadCellId {
            if let height = self.heightCacheHeader[cacheKey] {
                resultHeight = height
            } else {
                resultHeight = caculeHeightBlock()
                self.heightCacheHeader[cacheKey] = resultHeight
            }
        } else if identify == AsideCommentView.ipadFooterCellId {
            let curNeedHL = commentSections[CommentIndex(indexPath.section)]?.isActive ?? false
            var needCaculate: Bool = true
            if let (height, lastNeedInput) = self.heightCacheFooter[cacheKey] {
                if curNeedHL || curNeedHL != lastNeedInput {
                    needCaculate = true
                } else {
                    needCaculate = false
                    resultHeight = height
                }
            }
            if needCaculate {
                resultHeight = caculeHeightBlock()
                self.heightCacheFooter[cacheKey] = (resultHeight, curNeedHL)
            }
        } else {
            let item = commentSections[indexPath]
            guard let currentItem = item else { return 0 }
            var needCaculate: Bool = true
            if let (height, lastItem) = self.heightCacheBody[cacheKey] {
                // 内容发生改变需要重新计算行高，但是如果正在编辑，不需要计算行高
                let editingReplyID = commentSections.modifiableItem?.item.replyID ?? ""
                if currentItem.replyID != lastItem.replyID, editingReplyID != currentItem.replyID {
                    needCaculate = true
                } else {
                    needCaculate = false
                    resultHeight = height
                }
            }
            if needCaculate {
                resultHeight = caculeHeightBlock()
                self.heightCacheBody[cacheKey] = (resultHeight, currentItem)
            }
        }
        return resultHeight
    }

    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let item = commentSections[indexPath] else {
            DocsLogger.error("can not find item at: \(indexPath)", component: LogComponents.comment)
            return
        }
        if commentHeightOptimize {
            if !item.heightCacheKey.isEmpty {
                self.newHeightCacheKey[item.heightCacheKey] = cell.bounds.height
            }
        }

        if let cell = cell as? CommentTableViewCell {
            viewInteraction?.emit(action: .didShowAtInfo(item: item, atInfos: cell.contentAtInfos))
        }
        viewInteraction?.emit(action: .willDisplay(item))
        let cellReuseId = item.uiType.padUIIdentify
        let validCellIds = [AsideCommentView.ipadBodyCellId, ContentReactionPadCell.cellId]
        guard validCellIds.contains(cellReuseId), let item = commentSections[indexPath] else {
            return
        }
        guard item.status == .unread else {
            return
        }
        viewInteraction?.emit(action: .willDisplayUnread(item))
        item.status = .read
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = commentSections[indexPath] else {
            return UITableViewCell()
        }
        let cell = tableView.dequeueReusableCell(withIdentifier: item.uiType.padUIIdentify) ?? UITableViewCell()
        configDataWithCell(cell, indexPath: indexPath, estimated: false)
        return cell
    }
    
    func configDataWithCell(_ cell: UITableViewCell, indexPath: IndexPath, estimated: Bool) {
        guard let item = commentSections[indexPath], let comment = commentSections[CommentIndex(indexPath.section)] else {
            return
        }
        let identify = item.uiType.padUIIdentify
        let isActive = item.isActive
        let fontZoomable = comment.docsInfo?.fontZoomable ?? false
        if identify == AsideCommentView.ipadHeadCellId, let cell = cell as? CommentQuoteAndReplyCellPad {
            // 引用cell

            cell.delegate = self
            cell.highLightDelegate = self
            cell.highLighted = isActive
            cell.curCommment = comment
            cell.updateWithQuoteText(text: item.quote ?? "", fontZoomable: fontZoomable)
            cell.canResolve = comment.showResolve
            cell.addHightLight(show: isActive)
            cell.addRoundCornerToBgView(position: .top, shadow: isActive)
            if copyAnchorLinkEnable {
                if comment.showResolve {
                    cell.updateResolveStyle(.coexist)
                } else {
                    cell.updateResolveStyle(.onlyMore)
                }
            } else {
                cell.updateResolveStyle(.onlyResolve)
            }
        } else if identify == AsideCommentView.ipadFooterCellId, let cell = cell as? CommentFootViewCell {
            // 回复输入框cell
            cell.highLightDelegate = self
            cell.curCommment = comment
            cell.highLighted = isActive
            cell.textViewDependency = textViewDependency
            cell.addRoundCornerToBgView(position: .bottom, shadow: isActive)
            cell.update(item: item,
                        textDelegate: self)
            cell.update(wrapper: CommentWrapper(commentItem: item, comment: comment))
            if estimated {
                cell.update(wrapper: nil)
            }
        } else if identify == CommentUnsupportedCell.reusePadIdentifier, let cell = cell as? CommentUnsupportedCell {
            let count = comment.commentList.count
            if indexPath.row == count - 1 {
                cell.addRoundCornerToBgView(position: .bottom, shadow: isActive)
            } else {
                cell.addRoundCornerToBgView(position: .middle, shadow: isActive)
            }
            cell.curCommment = comment
            cell.highLightDelegate = self
        } else if identify == ContentReactionPadCell.cellId, let cell = cell as? ContentReactionPadCell {
            cell.delegate = cellDelegate
            cell.highLightDelegate = self
            cell.highLighted = isActive
            cell.curCommment = comment
            cell.setCanTriggerReaction(commentPermission?.contains(.canComment) ?? false)
            cell.cellWidth = frame.width > 0 ? frame.width : nil
            cell.updateCommentItem(item)
            cell.addRoundCornerToBgView(position: .middle, shadow: isActive)
        } else if let cell = cell as? CommentTableViewCellPad {
            // 评论回复cell
            cell.estimated = estimated
            cell.translateConfig = translateConfig
            cell.textViewDependency = textViewDependency
            cell.delegate = cellDelegate
            cell.zoomable = fontZoomable
            //cell.inputViewEditingDelegate = self
            cell.highLightDelegate = self
            cell.highLighted = isActive
            cell.curCommment = comment
            cell.cellWidth = self.frame.size.width > 0 ? self.frame.size.width : nil
            cell.permission = comment.permission
            cell.atInfoPermissionBlock = self.getPermssionQueryBlock()
            let isEdit = item.viewStatus.isEdit
            cell.canShowMoreActionButton = item.showMore && !isEdit
            cell.canShowReactionView = item.showReaction
            cell.textDelegate = self
            cell.configCellData(item, isFailState: comment.isUnsummit || item.errorCode != 0, isLoadingState: item.isSending)
            cell.update(wrapper: CommentWrapper(commentItem: item, comment: comment))
            cell.addRoundCornerToBgView(position: .middle, shadow: isActive)
            if estimated {
                cell.update(wrapper: nil)
            }
        }
    }

    func getPermssionQueryBlock() -> PermissionQuerryBlock? {
        
        //不显示灰色名字，则不用读取权限，默认就是现实蓝色
        if dependency?.businessConfig.canShowDarkName == false {
            return nil
        }
        
        let block: PermissionQuerryBlock? = { atInfo in
            guard atInfo.type == .user, let docsinfo = self.docsInfo else {
                return nil
            }
            let uid = atInfo.token
            let docsKey = AtUserDocsKey(token: docsinfo.token, type: docsinfo.type)
            return AtPermissionManager.shared.hasPermission(uid, docsKey: docsKey)
        }
        return block
    }

    func tableViewUpdates() {
        guard self.tvReloading == false else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
        CATransaction.commit()
    }
}


extension AsideCommentView: CommentQuoteAndResolveViewDelegate {
    func didClickResolveBtn(from: UIView, comment: Comment?) {
        guard let comment = comment else { return }
        viewInteraction?.emit(action: .clickResolve(comment: comment, trigerView: from))
    }
    func didClickMoreBtn(from: UIView, comment: Comment?) {
        guard let comment = comment else { return }
        viewInteraction?.emit(action: .clickQuoteMore(comment: comment, trigerView: from))
    }
}

extension AsideCommentView: CommentHighLightDelegate {
    func didHighLightTap(comment: Comment, cell: UITableViewCell) {
        viewInteraction?.emit(action: .didSelect(comment))
    }

}

// MARK: - CommentTextViewTextChangeDelegate

extension AsideCommentView: CommentTextViewTextChangeDelegate {
    
    func commentTextView(textView: UITextView, didMention atInfo: AtInfo) {
        viewInteraction?.emit(action: .didMention(atInfo))
    }
    
    func textViewDidChange(_ textView: UITextView) {
        tableViewUpdates()
    }

    func imagePreviewDidChange() {
        tableViewUpdates()
    }
    
    func textViewDidTriggerAtAction(_ textView: AtInputTextView, at rect: CGRect) {
        viewInteraction?.emit(action: .mention(atInputTextView: textView, rect: rect))
    }
    
    func atListViewShouldRefresh(_ keyword: String) {
        viewInteraction?.emit(action: .mentionKeywordChange(keyword: keyword))
        
    }
    
    func hideAtListView() {
        viewInteraction?.emit(action: .hideMention)
    }
    
    func textViewDidTriggerInsertImageAction(maxCount: Int, _ callback: @escaping (CommentImagePickerResult) -> Void) {
        viewInteraction?.emit(action: .insertInputImage(maxCount: maxCount, callback: callback))
    }
    
    func textViewShouldBeginEditing(_ textView: AtInputTextView) -> Bool {
        if let dependency = self.dependency {
            let canBegin = dependency.textViewShouldBeginEditing
            if !canBegin {
                DocsLogger.warning("textView editing is baned", component: LogComponents.comment)
            }
            return canBegin
        } else {
            return true
        }
    }

}

// MARK: - 手势冲突处理
extension AsideCommentView: UIGestureRecognizerDelegate {
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer == cancelHightLightTap {
            if touch.view == self.tableView {
                return true
            } else {
                return false
            }
        }
        return true
    }
}


// MARK: - 对齐逻辑

extension AsideCommentView {



    /// 根据键盘的高度，滚动正在输入的内容到键盘上的可视范围
    /// - Parameters:
    ///   - toIndexPath: 输入框所在位置
    ///   - options: 当前键盘信息
    ///   - success: 实际调整才会返回的closure，不调整不返回
    private func scrollTabaleView(toIndexPath: IndexPath, with options: Keyboard.KeyboardOptions, animated: Bool = true, success: () -> Void) {
        let pointKeyboardInWindow = CGPoint(x: options.endFrame.origin.x, y: options.endFrame.origin.y)
        let pointInSelfView = self.convert(pointKeyboardInWindow, from: self.window)
        let rectOfPath = self.tableView.rectForRow(at: toIndexPath)
        let rectOfPathInSelf = self.tableView.convert(rectOfPath, to: self)
        DocsLogger.info("scrollFocusCellToBottom, toIndexPath =\(toIndexPath), options.event=\(options.event), endFrame:\(options.endFrame) pointInSelfView=\(pointInSelfView), rectOfPathInSelf=\(rectOfPathInSelf)", component: LogComponents.comment)
        let cellAndKeyBoardDistance = pointInSelfView.y - rectOfPathInSelf.maxY
        DocsLogger.info("curOffset:\(self.tableView.contentOffset.y) cellAndKeyBoardDistance: \(cellAndKeyBoardDistance)", component: LogComponents.comment)
        if cellAndKeyBoardDistance > 10, rectOfPathInSelf.minY > 10 {
            // 不需要处理
        } else {
            // 激活的cell超出顶部过多
            self.tableView.scrollToRow(at: toIndexPath, at: .bottom, animated: false)
            DocsLogger.info("scrollTabaleView setOffset:\(self.tableView.contentOffset.y)", component: LogComponents.comment)
            success()
        }
    }
    
    /// 返回第session组在相对容器底部的高度
    func converCellBottom(session: Int) -> CGFloat {
        // 分组在tableview中的frame
        let groupCellRect = tableView.rect(forSection: session)
        // 相对tableview的位置
        let convertFrame = tableView.convert(groupCellRect, to: self)
        // 距离屏幕底部的位置
        return self.bounds.size.height - convertFrame.minY
    }
    

    /// 找到视图上的用户定位参考的评论id和位置信息，
    /// 保证刷新后当前显示的评论不会被挤出屏幕外
    /// - Returns: (commentId, cell顶部距离容器底部的高度)
    func findReferenceVisibleRow() -> (String?, CGFloat) {
        let indexPaths = self.tableView.indexPathsForVisibleRows ?? []
        var descIndexPath: IndexPath?
        // 优先找激活的评论
        let highLightedIndex = indexPaths.first(where: {
            return self.commentSections[CommentIndex($0.section)]?.isActive == true
        })
        if let index = highLightedIndex {
            descIndexPath = IndexPath(row: 0, section: index.section)
            DocsLogger.info("[reset position] find active comment", component: LogComponents.comment)
        } else { // 无激活评论则找第一条作为参考
            descIndexPath = indexPaths.first
        }
        guard let indexPath = descIndexPath else {
            DocsLogger.info("[reset position] can not find reference indexPath", component: LogComponents.comment)
            return (nil, 0)
        }
        guard let commentId = commentSections[CommentIndex(indexPath.section)]?.commentID else {
            DocsLogger.error("[reset position] no commentId found at:\(indexPath)", component: LogComponents.comment)
            return (nil, 0)
        }
        let height = converCellBottom(session: indexPath.section)
        let contentHeight = self.tableView.contentSize.height
        DocsLogger.info("[reset position] find reference indexPath:\(indexPath) bottom:\(height) contentHeight:\(contentHeight)", component: LogComponents.comment)
        return (commentId, height)
    }
    
    ///  将commentId的评论ell滚动到距离容器底部bottom的位置
    func resetCellPosition(commentId: String?, bottom: CGFloat) {
        guard let id = commentId else { return }
        guard let indexPath = commentSections[id, nil] else {
            // 参考的评论被删除/解决了
            DocsLogger.error("[reset position] reference data has been delete", component: LogComponents.comment)
            return
        }
        DocsLogger.info("[reset position] path:\(indexPath) id:\(id) bottom:\(bottom)", component: LogComponents.comment)
        alignCommentCell(indexPath: indexPath, bottom: bottom)
    }
    
    
    ///  将indexPath位置的cell滚动到距离容器底部bottom的位置
    /// - Returns: 返回调整的offset，-1表示调整失败
    @discardableResult
    func alignCommentCell(indexPath: IndexPath, bottom: CGFloat) -> CGFloat {
        let cellFrame = self.tableView.rectForRow(at: indexPath)
        guard cellFrame.size.height > 0, self.tableView.frame.height > 0 else {
            DocsLogger.error("alignCommentCell fail cellFrame:\(cellFrame) selfHeight:\(self.tableView.frame.height)", component: LogComponents.comment)
            return -1
        }
        let positionFromTop = self.frame.height - bottom - Layout.topHeaderHeight
        let destOffset = cellFrame.origin.y - positionFromTop
        let contentHeight = tableView.contentSize.height
        let maxOffset = contentHeight - tableView.bounds.height
        DocsLogger.info("alignCommentCell cellFrame:\(cellFrame) indexPath:\(indexPath)  selfHeight:\(self.tableView.frame.height) contentHeight:\(contentHeight)", component: LogComponents.comment)
        if destOffset >= 0 && destOffset <= maxOffset {
            debounce.endDebounce()
            self.tableView.setContentOffset(CGPoint(x: 0, y: destOffset), animated: false)
            DocsLogger.info("[set contentOffset] alignCommentCell bottom:\(bottom) contentHeight:\(contentHeight) cellFrame:\(cellFrame) selfHeight:\(frame.height) tbHeight:\(tableView.bounds.height) destOffset:\(destOffset) maxOffset:\(maxOffset)", component: LogComponents.comment)
            return destOffset
        } else {
            DocsLogger.error("alignCommentCell fail destOffset:\(destOffset) maxOffset:\(maxOffset)", component: LogComponents.comment)
            return -1
        }
    }
}

extension AsideCommentView {

    func updateDiff(_ data: [CommentSection], _ updateIndexPaths: [IndexPath]?) {
        self.commentSections = data
        self.tvReloading = true
        if let indexPaths = updateIndexPaths { // 清除行高缓存
            clearCellCache(indexPaths: indexPaths)
        }
    }
    
    func clearCellCache(indexPaths: [IndexPath]) {
        DocsLogger.debug("clean cache indexPaths:\(indexPaths)", component: LogComponents.comment)
        let keys: [String] = indexPaths.compactMap {
            let key = commentSections[$0]?.heightCacheKey ?? ""
            return !key.isEmpty ? key : nil
        }
        if !keys.isEmpty {
            keys.forEach { 
                self.heightCacheBody.removeValue(forKey: $0)
                if commentHeightOptimize {
                    newHeightCacheKey.removeValue(forKey: $0)
                }
            }
            tableView.clearHeightCacheFor(cacheKeys: keys)
        }
    }
    
    func clearCellCache(sections: [Int]) {
        DocsLogger.debug("clean cache sections:\(sections)", component: LogComponents.comment)
        for section in sections {
            let rows = self.tableView(tableView, numberOfRowsInSection: section)
            var indexPaths: [IndexPath] = []
            for row in 0..<rows {
                indexPaths.append(IndexPath(row: row, section: section))
            }
            clearCellCache(indexPaths: indexPaths)
        }
    }
}

// MARK: - MS滚动
extension AsideCommentView: ScrollableCommentViewType, UITableViewDelegate {
    
    var highLightPageIndex: Int? {
        return commentSections.modifiableItem?.index.section
    }
    
    func getCurrentItemFor(indexPath: IndexPath) -> CommentItem? {
        return commentSections[indexPath]
    }
    
    
    var docCommentScrollEnable: Bool {
        guard let type = docsInfo?.inherentType else {
            DocsLogger.error("[comment scroll] docs type is nil", component: LogComponents.comment)
            return false
        }
        if type == .bitable || type == .sheet {
            return true
        } else if type == .doc || type == .docX {
            return true
        }
        return false
    }
    
    var anchorFromBottom: CGFloat {
        return lastCallBackHeight ?? self.tableView.bounds.height
    }
    
    /// 锚点距离面板顶部的距离
    var anchorPointHeightFromTop: CGFloat {
        return tableView.bounds.height - anchorFromBottom
    }
    
    var conferenceInfo: CommentConference? {
        return dependency?.commentConference
    }
    
    var detectOffScreen: Bool {
        return true
    }
    
    var checkNotice: Bool {
        return true
    }
    
    var commentCount: Int {
        return commentSections.count
    }
    
    /// 滚动某个item的n%到锚点（过评论模式）
    func handleScrollToItem(_ indexPath: IndexPath, _ percent: CGFloat) {
        guard commentSections[indexPath] != nil, percent >= 0 && percent <= 1 else {
            skAssertionFailure()
            return
        }
        let isReadyForAnimate = scrollFollowHandler?.isReadyForAnimate ?? true
        if !isReadyForAnimate {
            DocsLogger.info("[set contentOffset] isReadyForAnimate false", component: LogComponents.comment)
            self.tableView.reloadData()
            self.tableView.layoutIfNeeded()
        }
        let cellIndex = IndexPath(item: indexPath.row, section: indexPath.section)
        let cellRect = self.tableView.rectForRow(at: cellIndex)
        let adjustPercentY = cellRect.height * percent
        let anchorFromTop = anchorPointHeightFromTop
        let cellY = cellRect.origin.y
        let destOffset = cellY - anchorFromTop + adjustPercentY
        DocsLogger.info("[set contentOffset] scroll,COF=\(tableView.contentOffset),CY=\(cellY),PC=\(percent), CH=\(cellRect.height) bottom:\(anchorFromBottom) top:\(anchorFromTop) DOF:\(destOffset) animate:\(isReadyForAnimate)", component: LogComponents.comment)

        if isReadyForAnimate {
            self.tableView.setContentOffset(CGPoint(x: 0, y: destOffset), animated: true)
        } else {
            debounce.debounce(DispatchQueueConst.MilliSeconds_250) { [weak self] in
                guard let self = self else { return }
                self.tableView.setContentOffset(CGPoint(x: 0, y: destOffset), animated: false)
                self.tableView.layoutIfNeeded()
            }
        }
    }


    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        var items: [CommentItem] = []
        if SettingConfig.commentPerformanceConfig?.fpsEnable == true {
            if let visibleRows = tableView.indexPathsForVisibleRows {
                items = visibleRows.compactMap { commentSections[$0] }
                           .filter { $0.interactionType == .comment || $0.interactionType == .reaction }
            }
        }
        viewInteraction?.emit(action: .willBeginDragging(items: items))
        scrollViewDidDragged = true
        scrollStatus = .scrolling
        scrollFollowHandler?.beginMonitoring()
        scrollFollowHandler?.commentViewWillBeginDragging()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        scrollFollowHandler?.commentViewDidScroll()
    }
    
    // 惯性滚动停止
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        viewInteraction?.emit(action: .didEndDecelerating)
        scrollStatus = .idle
        scrollFollowHandler?.commentViewDidEndScrolling()
    }
    
    // 手离开屏幕，没有惯性滚动
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            viewInteraction?.emit(action: .didEndDragging)
            scrollStatus = .idle
            scrollFollowHandler?.commentViewDidEndScrolling()
        }
    }

    // 手动触发滚动动画停止
    func scrollViewDidEndScrollingAnimation(_ scrollView: UIScrollView) {
        scrollStatus = .idle
    }
    
    func getCurrentCommentId(at section: Int) -> String? {
        return commentSections[CommentIndex(section)]?.commentID
    }
    
    var footerSectionHeight: CGFloat {
        return Layout.sectionFooterHeight
    }
    
    var tableViewContentOffset: CGPoint {
        tableView.contentOffset
    }
    
    var tableViewBounds: CGRect {
        tableView.bounds
    }
    
    ///  根据indexPath的到对应cell在tableView的位置
    func commentRectForRow(at indexPath: IndexPath) -> CGRect {
        tableView.rectForRow(at: indexPath)
    }
    
    ///  根据section的到对应section cell在tableView的位置
    func commentRect(forSection section: Int) -> CGRect {
        tableView.rect(forSection: section)
    }
    
    /// 根据point得到对应tableViewCell的indexPath
    func commentIndexPathForRow(at point: CGPoint) -> IndexPath? {
        tableView.indexPathForRow(at: point)
    }
    
    /// tabelViewCell rect转换到评论容器的坐标
    func convertToContent(_ rect: CGRect) -> CGRect {
        let contentRect = tableView.convert(rect, to: self)
        return CGRect(origin: CGPoint(x: contentRect.origin.x,
                                      y: contentRect.origin.y - Layout.topHeaderHeight),
                      size: contentRect.size)
    }
}

// MARK: - CommentScrollDelegate
extension AsideCommentView: CommentScrollDelegate {
    /// iPad高亮评论滚出评论外
    func highlightedCommentBecomeInvisibale(info: CommentScrollInfo) {
        viewInteraction?.emit(action: .contentBecomeInvisibale(info))
    }
    
    func commentViewDidScroll(info: CommentScrollInfo) {
        viewInteraction?.emit(action: .magicShareScroll(info))
    }
}

extension Reactive where Base: AsideCommentView {
    var showFoucusTips: Binder<Bool> {
        return Binder(base) { (target, show) in
            target.foucusTipsView.update(isHidden: !show)
        }
    }
}


// MARK: - capturePrevent

extension AsideCommentView {

    public func setCapturePreventNotify(type: ViewCaptureNotifyContainer) {
        viewCapturePreventer.notifyContainer = type
    }
    
    public func setCaptureAllowed(_ allow: Bool) {
        viewCapturePreventer.isCaptureAllowed = allow
    }
}
