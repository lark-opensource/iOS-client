//
//  AtToolbar.swift
//  Alamofire
//
//  Created by nine on 2018/3/6.
//
import Foundation
import UIKit
import SwiftyJSON
import SnapKit
import SKUIKit
import SKFoundation
import SpaceInterface

/// 用来管理文档中@人时，@的结果列表与@类型选择器的关系
// ----DocsInputAccessoryView 作为整体，在键盘上面
//        |
//        |---listContainerView 包在scrollview上面，实现点击收起功能
//        |       |
//        |       |
//        |       |--- scrollview 包含三个list，实现左右滑动。高度固定。
//        |       |       |
//        |       |       |- ATListPageView
//        |       |       |       |
//        |       |       |       |-- UILable 你可能想提及。。。
//        |       |       |       |
//        |       |       |       |-- UICollectionView 真正展示的列表
//        |       |       |
//        |       |       |- ATListPageView
//        |       |       |       |
//        |       |       |       |-- UILable
//        |       |       |       |
//        |       |       |       |-- UICollectionView
//        |       |       |       |
//        |       |       |- ATListPageView
//        |       |       |       |
//        |       |       |       |-- UILable
//        |       |       |       |
//        |       |       |       |-- UICollectionView
//        |
//        |--- AtTypeSelectView 底部的@类型选择器，以及返回按钮

// MARK: -
public final class SeperateAtlistManager: NSObject {

    /// list上方阴影的默认高度
    public static let shadowHeight: CGFloat = 20

    // MARK: - view properties
    public private(set) lazy var atTypeSelectView: AtTypeSelectView = {
        let view = AtTypeSelectView(type: type, requestType: requestType)
        return view
    }()
    private let animateDuration: Double = 0.3
    private var pageViewCount: Int {
        switch type {
        case .docs: return 3
        case .mindnote: return 2
        case .larkDocs: return 2
        case .syncedBlock: return 2
        default: return 1
        }
    }

    /// 列表的高度为0对应的约束，用来实现列表整体缓慢升起的动画
    private var pageViewZeroConstraints = [SnapKit.Constraint]()

    /// 整体View高度为0的约束。列表收起时，这个约束生效
    private var containerViewZeroHeightConstraints = [SnapKit.Constraint]()

    private var pageViews = [ATListPageView]()

    /// 每一个list上方的阴影
    private var shadowEdgeViews = [ShadowEdgeView]()
    private let scrollContentView = UIView()
    public lazy var listContainerView: UIView = {
        let view = UIView(frame: .zero)
        view.backgroundColor = .clear
        view.clipsToBounds = true
        return view
    }()

    private let scrollView: UIScrollView = {
        let view = UIScrollView()
        view.backgroundColor = .clear
        view.isPagingEnabled = true
        view.showsHorizontalScrollIndicator = false
        view.showsVerticalScrollIndicator = false
        view.isDirectionalLockEnabled = true
        view.bounces = false
        return view
    }()

    // MARK: - action properties
    /// 选中列表项，执行的操作
    public var selectAction: SelectAction? {
        didSet { pageViews.forEach { $0.selectAction = selectAction } }
    }

    /// 退出时，执行的操作
    public var cancelAction: CancelAction?

    // MARK: - state properties
    private var hasConfigSelectView = false
    private var hasConfigScrollView = false

    var currentSearchWord: String? {
        return currentSearchParams.keyword
    }

    public private(set) var dataSource: AtDataSource
    private let requestType: Set<AtDataSource.RequestType>
    private let type: AtViewType
    private var contentWidth: CGFloat

    private var currentSearchParams = SearchParams()
    
    public var scrollViewHeight: CGFloat!

    public init(_ dataSource: AtDataSource, type: AtViewType, requestType: Set<AtDataSource.RequestType>, width: CGFloat) {
        self.dataSource = dataSource
        self.requestType = requestType
        self.type = type
        self.contentWidth = width
        super.init()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setupAtSelectTypeView() {
        guard !hasConfigSelectView else { return }
        hasConfigSelectView = true
        atTypeSelectView.selectDelegate = self
        atTypeSelectView.snp.makeConstraints { (make) in
            make.height.equalTo(44).labeled("指定高度")
        }
    }

    public func configScrollViewLayout(contentWidth: CGFloat?) {
        if let realWidth = contentWidth {
            self.contentWidth = realWidth
        }
        //因为  listContainerView 可能进行了removefromsuperview，所以每次都要remake
        containerViewZeroHeightConstraints.forEach { $0.deactivate() }
        containerViewZeroHeightConstraints.removeAll()
        listContainerView.snp.remakeConstraints { (make) in
            make.bottom.left.equalToSuperview()
            make.width.equalTo(self.contentWidth).labeled("与 WebView 等宽")
            make.height.equalToSuperview().priority(999).labeled("等高")
            containerViewZeroHeightConstraints.append(make.height.equalTo(0).labeled("高度是0").constraint)
        }

        if scrollView.superview == nil {
            listContainerView.addSubview(scrollView)
        }

        scrollView.snp.remakeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(atTypeSelectView.snp.top).labeled("和选择框底部对齐")
            make.height.equalTo(scrollViewHeight).priority(999)
        }
        
        guard !hasConfigScrollView else {
            scrollContentView.snp.updateConstraints { (make) in
                 make.height.equalTo(scrollViewHeight - AtListView.shadowHeight).labeled("和顶部对齐")
            }
            //更新当前pageViews's Width
            pageViews.forEach { (pageView) in
                pageView.snp.updateConstraints { (make) in
                    make.width.equalTo(self.contentWidth).labeled("宽度和父view对齐")
                }
            }
            return

        }
        hasConfigScrollView = true

        let recognizer = UITapGestureRecognizer(target: self, action: #selector(onScrollViewTap))
        recognizer.delegate = self
        listContainerView.addGestureRecognizer(recognizer)

        scrollView.delegate = self
        scrollView.addSubview(scrollContentView)

        (0..<pageViewCount).forEach { index in
            let pageView = ATListPageView(dataSource: dataSource.clone(), defaultFilterType: defaultFilterTypeForIndex(index))
            pageViews.append(pageView)
            pageView.maxVisuableItems = Int.max
            scrollContentView.addSubview(pageView)
            pageView.accessibilityIdentifier = "\(index) pageview"
            pageView.delegate = self
            pageView.setup()
            let shadowEdgeView = ShadowEdgeView(frame: .zero)
            shadowEdgeViews.append(shadowEdgeView)
            scrollContentView.insertSubview(shadowEdgeView, belowSubview: pageView)
            shadowEdgeView.snp.makeConstraints { (make) in
                make.leading.trailing.equalTo(pageView)
                make.bottom.equalTo(pageView.snp.top)
                make.height.equalTo(0)
            }
        }
        scrollContentView.snp.makeConstraints { (make) in
            make.leading.trailing.bottom.equalToSuperview().labeled("四周对齐")
            make.top.equalToSuperview().offset(AtListView.shadowHeight)
            make.height.equalTo(scrollViewHeight - AtListView.shadowHeight).labeled("和顶部对齐")
        }
        pageViews.forEach { (pageView) in
            pageView.snp.makeConstraints { (make) in
                make.bottom.equalToSuperview()
                make.width.equalTo(self.contentWidth).labeled("宽度和父view对齐")
                make.height.lessThanOrEqualToSuperview()
                pageViewZeroConstraints.append(make.height.equalTo(0).labeled("默认是0").constraint)
            }
        }
        pageViews.last?.snp.makeConstraints({ (make) in
            make.trailing.equalToSuperview().labeled("最后一个右对齐")
        })
        for (right, left) in zip(pageViews[1...], pageViews[..<(pageViewCount - 1)]) {
            right.snp.makeConstraints { (make) in
                make.leading.equalTo(left.snp.trailing).labeled("各个page之间没有间距")
            }
        }
        pageViews.first?.snp.makeConstraints({ (make) in
            make.leading.equalToSuperview().labeled("第一个左对齐")
        })
    }

    public func updateScrollViewLayout(height: CGFloat) {
        scrollViewHeight = height >= 135 ? height : 135
        guard hasConfigScrollView, scrollView.superview != nil else {
            DocsLogger.info("at list scrollview 不存在，不用刷新 Layout")
            return
        }
        scrollView.snp.remakeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(atTypeSelectView.snp.top).labeled("和选择框底部对齐")
            make.height.equalTo(scrollViewHeight).priority(999)
        }
        
        if scrollContentView.superview != nil {
            scrollContentView.snp.updateConstraints { (make) in
                 make.height.equalTo(scrollViewHeight - AtListView.shadowHeight).labeled("和顶部对齐")
            }
        }
        
        listContainerView.layoutIfNeeded()
    }
    
    public func configCheckboxData(_ data: AtCheckboxData?) {
        let userPageView = pageViews.first(where: { $0.requestType.contains(.user) })
        userPageView?.updateCheckboxData(data, contentWidth: contentWidth)
    }

    func reset() {
        spaceAssert(Thread.isMainThread)
        currentSearchParams.reset()
        atTypeSelectView.reset()
        pageViews.forEach { $0.reset() }
        scrollView.setContentOffset(.zero, animated: false)
    }

    public func updateAtDataSourceByDocInfo(_ docsInfo: DocsInfo) {
        dataSource.update(token: docsInfo.objToken, sourceFileType: docsInfo.type)
        pageViews.forEach {
            $0.updateAtDataSourceByDocInfo(docsInfo)
        }
    }

    public func updateScrollViewRequestType(to newType: Set<AtDataSource.RequestType>) {
        scrollView.setContentOffset(contentOffsetForRequestType(newType), animated: true)
    }
    public func downAnimate() {
        pageViewZeroConstraints.forEach { $0.activate() }

        UIView.animate(withDuration: animateDuration, animations: {
            self.scrollView.setNeedsLayout()
            self.scrollView.layoutIfNeeded()
        }, completion: { _ in
            self.reset()
            self.containerViewZeroHeightConstraints.forEach { $0.activate() }
        })
    }

    private func dismissSelf() {
        cancelAction?()
    }

    private func defaultFilterTypeForIndex(_ index: Int) -> Set<AtDataSource.RequestType> {
        guard index >= 0, index < pageViewCount else {
            return AtDataSource.RequestType.currentAllTypeSet
        }
        if index == 0 {
            return AtDataSource.RequestType.userTypeSet
        } else if index == 1 {
            return AtDataSource.RequestType.fileTypeSet
        } else {
            return AtDataSource.RequestType.chatTypeSet
        }
    }

    private var currentPageView: ATListPageView {
        let index = Int(floor(scrollView.contentOffset.x / contentWidth))
        return pageViews[index]
    }
}

// MARK: - 搜索逻辑
extension SeperateAtlistManager {
    public func refresh(with keyword: String, filter: Set<AtDataSource.RequestType>, animated: Bool = false) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        currentSearchParams.keyword = keyword
        currentSearchParams.animated = animated
        self.perform(#selector(delayRefresh(params:)), with: currentSearchParams, afterDelay: 0.25)
    }

    @objc
    private func delayRefresh(params: SearchParams) {
        pageViews.forEach { pageView in
            // 这里 currentSearchParams.filter 为 nil，不用传 filter 进去，所有的 pageView 都使用初始化时传入的 type。
            pageView.refresh(with: currentSearchParams.keyword ?? "", newFilter: currentSearchParams.filter)
        }
    }
}

extension SeperateAtlistManager: UIGestureRecognizerDelegate {
    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        let point = gestureRecognizer.location(in: listContainerView)
        let pointInCurrent = listContainerView.convert(point, to: currentPageView)
        return (currentPageView.hitTest(pointInCurrent, with: nil) == nil)
    }

    @objc
    func onScrollViewTap() {
        dismissSelf()
    }
}

extension SeperateAtlistManager: AtTypeSelectViewProtocol {
    internal func didClickCancel(_ selectView: AtTypeSelectView) {
        spaceAssert(selectView == self.atTypeSelectView)
        dismissSelf()
    }

    internal func selectView(_ selectView: AtTypeSelectView, requestTypeUpdateTo newType: Set<AtDataSource.RequestType>) {
        spaceAssert(selectView == self.atTypeSelectView)
        updateScrollViewRequestType(to: newType)
    }

    private func contentOffsetForRequestType(_ requestType: Set<AtDataSource.RequestType>) -> CGPoint {
        switch requestType {
        case AtDataSource.RequestType.userTypeSet:
            return CGPoint(x: 0, y: 0)
        case AtDataSource.RequestType.fileTypeSet:
            return CGPoint(x: contentWidth, y: 0)
        case AtDataSource.RequestType.chatTypeSet:
            return CGPoint(x: contentWidth * 2, y: 0)
        default:
            spaceAssertionFailure("not support")
            return .zero
        }
    }
}

extension SeperateAtlistManager: AtListPageViewDelegate {
    func atListPageViewDidInvalidLayout(_ pageView: ATListPageView, animated: Bool) {
        let action = {
            self.pageViewZeroConstraints.forEach { $0.deactivate() }
            self.containerViewZeroHeightConstraints.forEach { $0.deactivate() }
            self.listContainerView.superview?.setNeedsLayout()
            self.listContainerView.superview?.layoutIfNeeded()
        }
        if animated {
            UIView.animate(withDuration: animateDuration, animations: action)
        } else {
            action()
        }
    }
    func atListPageViewDismiss(_ pageView: ATListPageView) {
        if currentPageView == pageView {
            dismissSelf()
        }
    }
    
    func atListPageViewDidClickCancel(_ pageView: ATListPageView) {
        dismissSelf()
    }
}

extension SeperateAtlistManager: UIScrollViewDelegate {
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView == self.scrollView else { return }
        let targetX = targetContentOffset.pointee.x
        let index = Int(floor(targetX / contentWidth))
        let requesetType = defaultFilterTypeForIndex(index)
        atTypeSelectView.updateRequestType(to: requesetType)
    }
}
