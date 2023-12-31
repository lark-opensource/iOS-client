//
//  MentionPageView.swift
//  SpaceKit
//
//  Created by chenjiahao.gill on 2019/6/26.
//  

import UIKit
import SnapKit
import SKUIKit
import UniverseDesignColor
import SpaceInterface

protocol MentionPageViewDelegate: AnyObject {
    func atListPageViewDidInvalidLayout(_ pageView: MentionPageView)
    func atListPageViewDismiss(_ pageView: MentionPageView)
}

class MentionPageView: UIView {

    /// 业务方回吐的数据
    private var resultList = [MentionInfo]()

    let mentionHandler: MentionCard

    var selectAction: MentionPanel.SelectAction?
    private var hasBeenReset = false
    /// 第一次没有搜索结果时，搜索的字符串是什么
    private var noAtStr: String?
    /// 上次后台返回列表是否是空
    private var hadResult: Bool = true

    var maxVisuableItems = Int.max
    weak var delegate: MentionPageViewDelegate?

    private var currentKeyword: String = ""
    // MARK: - subview
    private lazy var noticeLabel: UILabel = {
        let label = UILabel()
        label.text = self.mentionHandler.headerTips
        label.font = UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.regular)
        label.textColor = UDColor.textCaption
        return label
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.alwaysBounceVertical = true
        view.backgroundColor = .clear
        view.register(MentionPageCell.self, forCellWithReuseIdentifier: "MentionPageCell")
        view.dataSource = self
        view.delegate = self
        return view
    }()
//    private var loadingView: DocsAnimationViews?

    init(handler: MentionCard) {
        self.mentionHandler = handler
        super.init(frame: .zero)
        backgroundColor = UDColor.bgBody
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setup() {
        layer.cornerRadius = 6
        layer.maskedCorners = .top

        addSubview(noticeLabel)
        addSubview(collectionView)
        noticeLabel.snp.makeConstraints { (make) in
            make.top.equalToSuperview().labeled("和顶部对齐")
            make.trailing.equalToSuperview()
            make.height.equalTo(50).labeled("初始高度50")
            make.leading.equalToSuperview().offset(16)
        }
        collectionView.snp.makeConstraints { (make) in
            make.top.equalTo(noticeLabel.snp.bottom).labeled("和lable底部对齐")
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.bottom.equalToSuperview().priority(999).labeled("和底部选择器对齐")
        }
    }

//    func showLoading () {
////        spaceAssert(Thread.isMainThread)
//        if loadingView == nil {
//            let loadingView = DocsAnimationViews()
//            loadingView.layer.zPosition = CGFloat.greatestFiniteMagnitude
//            addSubview(loadingView)
//            loadingView.snp.makeConstraints { make in
//                make.edges.equalTo(collectionView)
//            }
//            self.loadingView = loadingView
//        }
//        loadingView?.play(mask: true)
//    }

    func updateList(_ list: [MentionInfo]) {
        resultList = list
        updateLayout()
        collectionView.reloadData()
    }

    func reset() {
        guard hasBeenReset == false else { return }
//        spaceAssert(Thread.isMainThread)
        resultList.removeAll()
        hasBeenReset = true
        updateLayout()
        collectionView.reloadData()
    }

    private func updateLayout() {
        let listHeight = self.listHeigtWith(itemsCount: resultList.count)
        var noticeLableHeight: CGFloat = 50
        if resultList.isEmpty && hadResult {
            noAtStr = currentKeyword
        }
        // 隐藏掉「找不到结果」的label
        if resultList.isEmpty,
            let noDataStr = noAtStr,
            currentKeyword.count > noDataStr.count + 1 {
            noticeLableHeight = 0
            delegate?.atListPageViewDismiss(self)
        }

        noticeLabel.snp.updateConstraints { (make) in
            make.height.equalTo(noticeLableHeight).labeled("更新后的高度")
        }
        hadResult = !resultList.isEmpty
        noticeLabel.text = noticeText
        currentHeight = listHeight + noticeLableHeight
    }

    private func listHeigtWith(itemsCount: Int) -> CGFloat {
        let maxItemCountShow = min(maxVisuableItems, itemsCount)
        return CGFloat(maxItemCountShow) * 65
    }

    private var currentHeight: CGFloat = 0 {
        didSet {
            if currentHeight != oldValue {
                invalidateIntrinsicContentSize()
                delegate?.atListPageViewDidInvalidLayout(self)
            }
        }
    }

    override var intrinsicContentSize: CGSize {
        var size = super.intrinsicContentSize
        size.height = currentHeight
        return size
    }

    private var noticeText: String {
        if hadResult == false, currentKeyword.isEmpty == false {
            return mentionHandler.emptyTips
        }
        return mentionHandler.headerTips
    }
}

extension MentionPageView: UICollectionViewDelegateFlowLayout & UICollectionViewDataSource & UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return resultList.count
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell1 = collectionView.dequeueReusableCell(withReuseIdentifier: "MentionPageCell", for: indexPath)
        guard let cell = cell1 as? MentionPageCell else {
//            spaceAssertionFailure("create cell fail")
            return cell1
        }

        guard indexPath.row < resultList.count else {
//            spaceAssertionFailure("数组越界")
            return cell
        }

        let mentionInfo = resultList[indexPath.row]
        cell.mentionInfo = mentionInfo

        _setupAccessibilityIdentifier(for: cell, mentionInfo: mentionInfo)

        return cell
    }

    private func _setupAccessibilityIdentifier(for cell: UICollectionViewCell, mentionInfo: MentionInfo) {
        let id: String = mentionInfo.token
        cell.accessibilityIdentifier =  "docs.at.click." + id
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let row = indexPath.row
        let mentionInfo = resultList[row]
        selectAction?(mentionInfo)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let object = resultList[indexPath.row]
        let height = MentionPageCell.textHeight(String(describing: object.name))
        return CGSize(width: collectionView.frame.width, height: CGFloat(50 + height))
    }
}

// MARK: - 搜索逻辑
extension MentionPageView {
    func refresh(with keyword: String) {
        hasBeenReset = false
        currentKeyword = keyword
        mentionHandler.onSearch(keyword, mentionHandler.searchType, { [weak self] infos in
            self?.updateList(infos)
        })
    }
}
