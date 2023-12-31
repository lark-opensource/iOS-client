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
import SKFoundation
import UniverseDesignColor
import SpaceInterface

/// Pressent类型，R视图下是popover，其他normal
public enum PresentType: Int {
    case normal = 0
    case popover = 1
}

/// 搜索时，需要传入的参数
@objc
class SearchParams: NSObject {
    var keyword: String?
    var filter: Set<AtDataSource.RequestType>?
    var animated: Bool = false

    func reset() {
        keyword = nil
        filter = nil
    }
}

public typealias SelectAction = (_ at: AtInfo?, _ info: [String: Any]?, _ index: Int) -> Void
public typealias CancelAction = () -> Void
public typealias DidInvalidLayout = () -> Void

// MARK: -
public final class AtListView: UIView {
    // MARK: - view properties
    public lazy var atTypeSelectView: AtTypeSelectView = {
        let requestType = defaultFilterTypeForIndex(0)
        let view = AtTypeSelectView(type: type, requestType: requestType)
        return view
    }()

    public static let shadowHeight: CGFloat = 10
    // 弹出类型
    private var presentType: PresentType = .normal
    private var pageViews = [ATListPageView]()
    private var shadowEdgeViews = [ShadowEdgeView]()
    private let scrollContentView = UIView()
    /// 竖屏下的约束
    private var portraitScreenConstraints: [SnapKit.Constraint] = []
    /// 横屏下的约束
    private var landscapeScreenConstraints: [SnapKit.Constraint] = []
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
        didSet {
            pageViews.forEach { $0.selectAction = selectAction }
        }
    }

    /// 退出时，执行的操作，仅用在文档中评论
    public var cancelAction: CancelAction?
    public var invalidLayoutAction: DidInvalidLayout?

    // MARK: - state properties
    /// reset 之后，不要更新listData的数据
    private var hasBeenReset = false

    private var showCancel = true
    
    public private(set) var dataSource: AtDataSource
    private let type: AtViewType

    private var currentSearchParams = SearchParams()

    /// checkboxData 是为了支持任务添加的，头部会变成转换为头部
    public init(_ dataSource: AtDataSource, type: AtViewType, presentType: PresentType = .normal, showCancel: Bool = true) {
        self.dataSource = dataSource
        self.type = type
        self.presentType = presentType
        self.showCancel = showCancel
        super.init(frame: .zero)
        setup()
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        self.backgroundColor = .clear
        atTypeSelectView.selectDelegate = self
        atTypeSelectView.backgroundColor = presentType == PresentType.popover ? UDColor.bgFloat : UDColor.bgBody
        configLayout()
    }

    private func configLayout() {
        scrollView.delegate = self
        scrollView.layer.masksToBounds = false
        addSubview(scrollView)
        scrollView.addSubview(scrollContentView)
        // 添加阴影
        if DocsType.commentSupportLandscapaeFg {
            scrollContentView.layer.shadowColor = UIColor.ud.N1000.cgColor
            scrollContentView.layer.shadowOpacity = 0.2
            scrollContentView.layer.masksToBounds = false
            scrollContentView.layer.shadowRadius = 5
            scrollContentView.layer.shadowOffset = CGSize(width: 0, height: 0)
        }
        (0..<pageViewCount).forEach {index in
            let pageView = ATListPageView(dataSource: dataSource.clone(), defaultFilterType: defaultFilterTypeForIndex(index))
            if !showCancel {
                pageView.hideCancelButton()
            }
            pageView.backgroundColor = presentType == PresentType.popover ? UDColor.bgFloat : UDColor.bgBody
            pageViews.append(pageView)
            pageView.maxVisuableItems = hasTypeSelectView ? Int.max : 3
            scrollContentView.addSubview(pageView)
            pageView.accessibilityIdentifier = "\(index) pageview"
            pageView.delegate = self
            pageView.setup()
            if !DocsType.commentSupportLandscapaeFg {
                let rect = CGRect(x: 0, y: 0, width: 1, height: AtListView.shadowHeight)
                let shadowEdgeView = ShadowEdgeView(frame: rect, color: UDColor.shadowDefaultLg)
                shadowEdgeViews.append(shadowEdgeView)
                scrollContentView.insertSubview(shadowEdgeView, belowSubview: pageView)
                shadowEdgeView.snp.makeConstraints({ (make) in
                    make.leading.trailing.equalTo(pageView)
                    make.bottom.equalTo(pageView.snp.top)
                    make.height.equalTo(0)
                })
            }
        }
        addSubview(atTypeSelectView)
        atTypeSelectView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalToSuperview().labeled("底部对齐")
            make.height.equalTo(hasTypeSelectView ? 44 : 0).labeled("指定高度")
        }
        atTypeSelectView.isHidden = !hasTypeSelectView

        scrollView.snp.makeConstraints { (make) in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(atTypeSelectView.snp.top).labeled("和选择框底部对齐")
            make.top.equalToSuperview()
        }
        scrollContentView.snp.makeConstraints { (make) in
//            make.leading.trailing.bottom.equalToSuperview().labeled("四周对齐")
            make.bottom.equalToSuperview().labeled("surrounding alignment")
            portraitScreenConstraints.append(make.left.trailing.equalToSuperview().constraint)
            landscapeScreenConstraints.append(make.leading.equalToSuperview().offset(AtListView.shadowHeight).constraint)
            landscapeScreenConstraints.append(make.trailing.equalToSuperview().offset(-AtListView.shadowHeight).constraint)
            make.top.equalToSuperview().offset(presentType == .popover ? 0 : AtListView.shadowHeight)
            make.bottom.equalTo(atTypeSelectView.snp.top).labeled("和选择框底部对齐")
            make.top.equalTo(self).offset(presentType == .popover ? 0 : AtListView.shadowHeight).labeled("和顶部对齐")
        }
        pageViews.forEach { (pageView) in
            pageView.snp.makeConstraints({ (make) in
                if presentType == .popover {
                    make.top.equalToSuperview()
                }
                make.bottom.equalToSuperview()
                make.width.equalTo(self).labeled("宽度和父view对齐")
                make.height.equalToSuperview()
            })
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
    
    func configCheckboxData(_ checkboxData: AtCheckboxData?, contentWidth: CGFloat) {
        pageViews.forEach { pageView in
            if pageView.requestType.contains(.user) {
                pageView.updateCheckboxData(checkboxData, contentWidth: contentWidth)
            }
        }
    }

    func reset() {
        spaceAssert(Thread.isMainThread)
        currentSearchParams.reset()
        atTypeSelectView.reset()
        pageViews.forEach { $0.reset() }
        scrollView.setContentOffset(.zero, animated: false)
    }

    // MARK: - layout
    override public var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize

        size.height = pageViews.compactMap({ $0.intrinsicContentSize.height }).max()! + atTypeSelectView.bounds.height
        return size
    }

    private func dismissSelf() {
        cancelAction?()
        reset()
    }

    private var pageViewCount: Int {
        switch type {
        case .docs: return 3
        case .mindnote: return 2
        case .larkDocs: return 2
        case .syncedBlock: return 2
        default: return 1
        }
    }

    private func defaultFilterTypeForIndex(_ index: Int) -> Set<AtDataSource.RequestType> {
        guard hasTypeSelectView, index >= 0, index < pageViewCount else {
            return AtDataSource.RequestType.currentAllTypeSet
        }
        let types: [Set<AtDataSource.RequestType>] = [AtDataSource.RequestType.userTypeSet, AtDataSource.RequestType.fileTypeSet, AtDataSource.RequestType.chatTypeSet]
        return types.safe(index: index) ?? Set()
    }

    private var currentPageView: ATListPageView {
        guard hasTypeSelectView, bounds.width > 0 else { return pageViews.first! }
        let index = Int(floor(scrollView.contentOffset.x / bounds.width))
        return pageViews[index]
    }
    
    public func updateScrollViewRequestType(to newType: Set<AtDataSource.RequestType>) {
        scrollView.setContentOffset(contentOffsetForRequestType(newType), animated: true)
    }
    
    public func refreshCurrentCollectionViewLayout() {
        currentPageView.refreshCollectionViewLayout()
    }
}

// MARK: - 搜索逻辑
extension AtListView {
    public func refresh(with keyword: String, filter: Set<AtDataSource.RequestType>, animated: Bool = false) {
        NSObject.cancelPreviousPerformRequests(withTarget: self)
        hasBeenReset = false
        currentSearchParams.keyword = keyword
        currentSearchParams.animated = animated
        currentSearchParams.filter = hasTypeSelectView ? nil : filter
        self.perform(#selector(delayRefresh(params:)), with: currentSearchParams, afterDelay: 0.25)
    }

    @objc
    private func delayRefresh(params: SearchParams) {
        guard hasBeenReset == false else { return }
        pageViews.forEach { pageView in
            pageView.refresh(with: currentSearchParams.keyword ?? "", newFilter: currentSearchParams.filter)
        }
    }
}

extension AtListView: AtTypeSelectViewProtocol {
    internal func didClickCancel(_ selectView: AtTypeSelectView) {
        spaceAssert(selectView == self.atTypeSelectView)
        dismissSelf()
    }

    internal func selectView(_ selectView: AtTypeSelectView, requestTypeUpdateTo newType: Set<AtDataSource.RequestType>) {
        spaceAssert(selectView == self.atTypeSelectView)
        scrollView.setContentOffset(contentOffsetForRequestType(newType), animated: true)
    }

    /// 底部是否有选择类型的view
    private var hasTypeSelectView: Bool {
        return type == .docs || type == .mindnote || type == .syncedBlock
    }

    private func contentOffsetForRequestType(_ requestType: Set<AtDataSource.RequestType>) -> CGPoint {
        switch requestType {
        case AtDataSource.RequestType.userTypeSet:
            return CGPoint(x: 0, y: 0)
        case AtDataSource.RequestType.fileTypeSet:
            let offsetX = (presentType == .popover) ? 375 : bounds.width
            return CGPoint(x: offsetX, y: 0)
        case AtDataSource.RequestType.chatTypeSet:
            let offsetX = (presentType == .popover) ? 375 : bounds.width
            return CGPoint(x: offsetX * 2, y: 0)
        default:
            spaceAssertionFailure("not support")
            return .zero
        }
    }
}

extension AtListView: AtListPageViewDelegate {
    func atListPageViewDidInvalidLayout(_ pageView: ATListPageView, animated: Bool) {
        guard currentPageView == pageView else { return }
        invalidateIntrinsicContentSize()
        if self.bounds.height == 0 || hasTypeSelectView == false {
            // 第一次，不要做动画。否则，frame会从0跳到很大的值
            self.superview?.setNeedsLayout()
            self.superview?.layoutIfNeeded()
            self.invalidLayoutAction?()
        } else {
            UIView.animate(withDuration: 0.2, animations: {
                //如果已经展示过了，要调用superview 的layout，否则自己的frame会跳动
                self.superview?.setNeedsLayout()
                self.superview?.layoutIfNeeded()
            }, completion: { (_) in
                self.invalidLayoutAction?()
            })
        }
    }
    func atListPageViewDismiss(_ pageView: ATListPageView) {
        if hasTypeSelectView && currentPageView == pageView {
            dismissSelf()
        }
    }
    
    func atListPageViewDidClickCancel(_ pageView: ATListPageView) {
        dismissSelf()
    }
}

extension AtListView: UIScrollViewDelegate {
    public func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard scrollView == self.scrollView else { return }
        let targetX = targetContentOffset.pointee.x
        let index = Int(floor(targetX / bounds.width))
        let requesetType = defaultFilterTypeForIndex(index)
        atTypeSelectView.updateRequestType(to: requesetType)
    }
}

extension AtListView {
    public func updateSession(_ session: Any) {
        self.dataSource.update(minaSession: session)
        pageViews.forEach { $0.dataSource.update(minaSession: session) }
    }
    
    public func updateDocsInfo(_ docsInfo: DocsInfo) {
        pageViews.forEach {
            $0.dataSource.update(token: docsInfo.objToken, sourceFileType: docsInfo.type)
        }
    }
    
    public func update(useOpenID: Bool) {
        self.dataSource.update(useOpenID: useOpenID)
        pageViews.forEach { $0.dataSource.update(useOpenID: useOpenID) }
    }
}

extension AtListView {
    public func handleMagicKeyboardTabAction() {
        let curIndex = curIndeForRequestType(self.atTypeSelectView.requestType)
        guard pageViewCount > 0, curIndex < pageViewCount else {
            return
        }
        
        let nextIndex = (curIndex + 1) % pageViewCount
        let requesetType = defaultFilterTypeForIndex(nextIndex)
        atTypeSelectView.updateRequestType(to: requesetType)
        scrollView.setContentOffset(contentOffsetForRequestType(requesetType), animated: true)
    }

    private func curIndeForRequestType(_ requestType: Set<AtDataSource.RequestType>) -> Int {
        var curIndex = 0
        switch requestType {
        case AtDataSource.RequestType.userTypeSet:
            curIndex = 0
        case AtDataSource.RequestType.fileTypeSet:
            curIndex = 1
        case AtDataSource.RequestType.chatTypeSet:
            curIndex = 2
        default:
            spaceAssertionFailure("not support")
            curIndex = 0
        }
        return curIndex
    }
}

extension AtListView {
    /// 根据是否支持横屏下评论和当前设备横竖屏状态更改
    public func updateConstraintsWhenOrientationChangeIfNeed(isChangeLandscape: Bool) {
        if isChangeLandscape {
            portraitScreenConstraints.forEach { $0.deactivate() }
            landscapeScreenConstraints.forEach { $0.activate() }
        } else {
            landscapeScreenConstraints.forEach { $0.deactivate() }
            portraitScreenConstraints.forEach { $0.activate() }
        }
        pageViews.forEach {
            $0.updateConstraintsWhenOrientationChangeIfNeed(isChangeLandscape: isChangeLandscape)
        }
    }
}
