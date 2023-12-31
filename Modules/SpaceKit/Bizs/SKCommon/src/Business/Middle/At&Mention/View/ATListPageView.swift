//
//  ATListPageView.swift
//  SpaceKit
//
//  Created by huahuahu on 2018/12/24.
//

import UIKit
import SnapKit
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignColor
import UniverseDesignLoading
import SpaceInterface

//文档中@，要分类型，一页一页。这个表示某一页

protocol AtListPageViewDelegate: AnyObject {
    func atListPageViewDidInvalidLayout(_ pageView: ATListPageView, animated: Bool)
    func atListPageViewDismiss(_ pageView: ATListPageView)
    func atListPageViewDidClickCancel(_ pageView: ATListPageView)
}

class ATListPageView: UIView {


    /// 后台返回的列表
    private var listData = [RecommendData]()
    var selectAction: SelectAction?
    private var hasBeenReset = false
    /// 第一次没有搜索结果时，搜索的字符串是什么
    private var noAtStr: String?
    /// 上次后台返回列表是否是空
    private var hadResult: Bool = true
    var maxVisuableItems = Int.max
    weak var delegate: AtListPageViewDelegate?

    private(set) var dataSource: AtDataSource
    private(set) var requestType: Set<AtDataSource.RequestType>
    private var currentKeyword: String = ""
    
    private var checkboxData: AtCheckboxData?
    /// 外部指定内容高度，因为要算 headerView 的高度，所以需要提前外部指定。只有在有 AtCheckboxData 时有影响。
    private var checkboxDataWidth: CGFloat?
    /// 是否横屏显示
    private var isChangeLandscape: Bool = false
    private lazy var headerView: AtListPageHeaderView = {
        let headerView = AtListPageHeaderView()
        headerView.cancelActionWhenInNormal = {[weak self] in
            guard let self = self else { return }
            self.delegate?.atListPageViewDidClickCancel(self)
        }
        headerView.checkboxActionWhenInCheckbox = {[weak self] isSelected in
            self?.checkboxData?.isSelected = isSelected
        }
        return headerView
    }()
    
    let layout: UICollectionViewFlowLayout = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        return layout
    }()

    private lazy var collectionView: UICollectionView = {
        let view = UICollectionView(frame: .zero, collectionViewLayout: self.layout)
        view.alwaysBounceVertical = true
        view.backgroundColor = .clear
        view.register(AtCell.self, forCellWithReuseIdentifier: "AtCell")
        view.dataSource = self
        view.delegate = self
        return view
    }()

    private var udloadingView = UDLoading.loadingImageView()
    private var loadingMaskView = UIView()
    
    private let mentionUserOpt: Bool
    
    func refreshCollectionViewLayout() {
        collectionView.collectionViewLayout.invalidateLayout()
    }
    
    func setup() {
        layer.cornerRadius = 12
        layer.maskedCorners = .top

        addSubview(headerView)
        addSubview(collectionView)
  
        let pageType: ATPageHeaderType = .normal(title: noticeText)
        headerView.changeHeaderType(pageType)
        let height = AtListPageHeaderView.Metric.normalHeaderHeight
        headerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(height)
        }
        
        collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(headerView.snp.bottom).labeled("和 headerView 底部对齐")
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().priority(999).labeled("和底部选择器对齐")
        }
    }

    init(dataSource: AtDataSource, defaultFilterType: Set<AtDataSource.RequestType>) {
        self.mentionUserOpt = UserScopeNoChangeFG.CS.mentionUserRecommendationOpt
        self.dataSource = dataSource
        requestType = defaultFilterType
        super.init(frame: .zero)
        backgroundColor = UDColor.bgBody
    }

    /// 旋转屏幕时，刷新布局
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        orientationDidChange()
    }

    @objc
    private func orientationDidChange() {
        /// 为什么是 reloadData？ 因为 cell 的高度需要根据业务情况布局😯
        collectionView.reloadData()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func showLoading () {
        spaceAssert(Thread.isMainThread)
        if udloadingView.superview == nil {
            udloadingView.layer.zPosition = CGFloat.greatestFiniteMagnitude
            loadingMaskView.backgroundColor = UDColor.bgBody
            addSubview(loadingMaskView)
            addSubview(udloadingView)
            //横屏下 at人列表太矮，修改成布局loading显示距离顶部
            if DocsType.commentSupportLandscapaeFg && self.isChangeLandscape {
                // 横屏下让load加个圆角
                loadingMaskView.layer.cornerRadius = 12
                loadingMaskView.layer.masksToBounds = true
                udloadingView.layer.cornerRadius = 12
                udloadingView.layer.masksToBounds = true
                udloadingView.snp.makeConstraints { make in
                    make.top.equalToSuperview().offset(-5)
                    make.centerX.equalTo(collectionView)
                }
            } else {
                udloadingView.snp.makeConstraints { make in
                    make.center.equalTo(collectionView)
                }
            }
            
            loadingMaskView.snp.makeConstraints { make in
                make.edges.equalTo(collectionView)
            }
        }
        udloadingView.isHidden = false
        loadingMaskView.isHidden = false
    }
    private func hideLoading () {
        spaceAssert(Thread.isMainThread)
        udloadingView.isHidden = true
        loadingMaskView.isHidden = true
    }

    func updateAtDataSourceByDocInfo(_ docsInfo: DocsInfo) {
        dataSource.update(token: docsInfo.objToken, sourceFileType: docsInfo.type)
    }

    func reset() {
        guard hasBeenReset == false else { return }
        spaceAssert(Thread.isMainThread)
        listData.removeAll()
        hasBeenReset = true
        checkboxData = nil
        self.updateLayout()
        collectionView.reloadData()
    }

    private func updateLayout() {
        // list 部分
        let listHeight = self.listHeigtWith(itemsCount: listData.count)
        if listData.isEmpty && hadResult {
            noAtStr = dataSource.currentKeyword
        }
        hadResult = !listData.isEmpty
        let headerHeight = updateHeaderView()
        currentHeight = listHeight + headerHeight
        invalidateIntrinsicContentSize()
        delegate?.atListPageViewDidInvalidLayout(self, animated: true)
    }
    
    /// 更新 headerView
    /// - Returns: 返回 headerView 的高度
    @discardableResult
    private func updateHeaderView() -> CGFloat {

        let pageType: ATPageHeaderType
        if hadResult, let checkboxData = checkboxData {
            pageType = .checkbox(data: checkboxData)
        } else {
            pageType = .normal(title: noticeText)
        }
        headerView.changeHeaderType(pageType)
        let headerHeight = AtListPageHeaderView.getHeaderHeight(pageType, headerWidth: checkboxDataWidth ?? self.frame.width)
        // header 部分
        if isChangeLandscape && DocsType.commentSupportLandscapaeFg {
            headerView.snp.updateConstraints {(make) in
                make.height.equalTo(0).labeled("更新后的高度")
            }
        } else {
            headerView.snp.updateConstraints {(make) in
                make.height.equalTo(headerHeight).labeled("更新后的高度")
            }
        }
        
        return headerHeight
    }

    private func listHeigtWith(itemsCount: Int) -> CGFloat {
        let maxItemCountShow = min(maxVisuableItems, itemsCount)
        return CGFloat(maxItemCountShow) * 65
    }

    private var currentHeight: CGFloat = 0

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = currentHeight
        return size
    }

    /// 应该出现的提示文字
    private var noticeText: String {
        if hadResult == false {
            return BundleI18n.SKResource.Doc_At_NothingFound
        }
        switch requestType {
        case AtDataSource.RequestType.fileTypeSet:
            if DocsSDK.isInLarkDocsApp {
                return BundleI18n.SKResource.Doc_At_MentionLarkDocsTip
            }
            return BundleI18n.SKResource.Doc_At_MentionDocTip
        case AtDataSource.RequestType.chatTypeSet: return BundleI18n.SKResource.Doc_At_MentionGroupTip
        case AtDataSource.RequestType.userTypeSet: return BundleI18n.SKResource.Doc_At_MentionUserTip
        default: return BundleI18n.SKResource.Doc_At_MentionTip
        }
    }
}

extension ATListPageView: UICollectionViewDelegateFlowLayout & UICollectionViewDataSource & UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return listData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell1 = collectionView.dequeueReusableCell(withReuseIdentifier: "AtCell", for: indexPath)
        guard let cell = cell1 as? AtCell else {
            spaceAssertionFailure("create cell fail")
            return cell1
        }
        guard indexPath.row < listData.count else {
            spaceAssertionFailure("数组越界")
            return cell
        }

        let cellData = listData[indexPath.row]
        cell.cellData = cellData
        _setupAccessibilityIdentifier(for: cell, cellData: cellData)
        return cell
    }

    private func _setupAccessibilityIdentifier(for cell: UICollectionViewCell, cellData: RecommendData) {
        cell.accessibilityIdentifier =  "docs.at.click." + cellData.contentForMainTitle
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let row = indexPath.row
        let recommentData = listData[row]
        var response: [String: Any] = ["data": ["result_list": [recommentData.dictionaryForJSCallback]], "canceled": false]
        if let _checkboxData = checkboxData {
            response.updateValue(_checkboxData.isSelected, forKey: "isCheckboxSelected")
        }
        selectAction?(recommentData.derivedAtInfo, response, row)
        
        if let atInfo = recommentData.derivedAtInfo, atInfo.type == .user, self.mentionUserOpt {
            let userID = atInfo.token
            dataSource.reportMentionFinish(userID: userID)
        }
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let object = listData[indexPath.row]
        let height = AtCell.textHeight(String(describing: object.contentToShow))
        if self.isChangeLandscape {
            return CGSize(width: 570, height: CGFloat(50 + height))
        } else {
            let width = SKDisplay.phone ? self.window?.frame.width ?? 570 : collectionView.frame.width
            return CGSize(width: width, height: CGFloat(50 + height))
        }
    }
}

// MARK: - 搜索逻辑
extension ATListPageView {

    func refresh(with keyword: String, newFilter: Set<AtDataSource.RequestType>?) {
        hasBeenReset = false
        let loadingHeight = udloadingView.frame.height
        if loadingHeight > 0, !hadResult {
            currentHeight = updateHeaderView() + loadingHeight // 避免loading动画与title重叠
            invalidateIntrinsicContentSize()
            delegate?.atListPageViewDidInvalidLayout(self, animated: false)
        }
        showLoading()
        if newFilter != nil {
            requestType = newFilter!
        }
        currentKeyword = keyword
        self.dataSource.getData(with: keyword, filter: requestType.joinedType) { [weak self] (list, _) in
            self?.hideLoading()
            guard let self = self, self.hasBeenReset == false else { return }
            self.listData = list
            self.updateLayout()
            self.collectionView.reloadData()
        }
    }
    
    func updateCheckboxData(_ checkboxData: AtCheckboxData?, contentWidth: CGFloat) {
        self.checkboxDataWidth = contentWidth
        self.checkboxData = checkboxData
        self.updateHeaderView()
    }
}


extension ATListPageView {
    public func hideCancelButton() {
        self.headerView.isSetCancelButtonHiddenWhenInNormal = true
    }
    
    /// 根据是否支持横屏下评论和当前设备横竖屏状态更改
    public func updateConstraintsWhenOrientationChangeIfNeed(isChangeLandscape: Bool) {
        self.isChangeLandscape = isChangeLandscape
        if isChangeLandscape {
            headerView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
            if udloadingView.superview != nil {
                udloadingView.snp.remakeConstraints { make in
                    make.top.equalToSuperview().offset(-5)
                    make.centerX.equalTo(collectionView)
                }
            }
            
        } else {
            let height = AtListPageHeaderView.Metric.normalHeaderHeight
            headerView.snp.updateConstraints { make in
                make.height.equalTo(height)
            }
            if udloadingView.superview != nil {
                udloadingView.snp.remakeConstraints { make in
                    make.center.equalTo(collectionView)
                }
            }
        }
        collectionView.reloadData()
    }
    
}
