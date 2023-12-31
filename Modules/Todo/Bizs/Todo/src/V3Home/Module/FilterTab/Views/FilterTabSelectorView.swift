//
//  FilterTabSelectorView.swift
//  Todo
//
//  Created by baiyantao on 2022/8/22.
//

import Foundation
import UIKit
import UniverseDesignIcon
import RxSwift
import RxCocoa
import LarkUIKit
import UniverseDesignFont
import UniverseDesignTabs

struct FilterTabContaienrViewData {

    var container: FilterTabSelectorViewData?

    var taskLists: Rust.TaskListTabFilter?

}

final class FilterTabContaienrView: UIView {

    var viewData: FilterTabContaienrViewData? {
        didSet {
            guard let viewData = viewData else { return }
            if let container = viewData.container {
                containerSelector.isHidden = false
                containerSelector.viewData = container
            } else {
                containerSelector.isHidden = true
            }

            if let taskLists = viewData.taskLists {
                taskListsSelector.isHidden = false
                taskListsSelector.selectedTab = taskLists
            } else {
                taskListsSelector.isHidden = true
            }
        }
    }

    private(set) lazy var containerSelector = FilterTabSelectorView()

    private(set) lazy var taskListsSelector = FilterTabTasklistsSelectorView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(containerSelector)
        addSubview(taskListsSelector)
        containerSelector.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        taskListsSelector.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

struct FilterTabSelectorViewData {
    enum UpdateType {
        case all
        case status
        case group
        case sorting
    }

    var statusBtnInfo: (title: String, isSeleted: Bool)?
    var groupBtnInfo: (title: String, isSeleted: Bool)?
    var sortingBtnInfo: (title: String, isSeleted: Bool)?

    var updateType: UpdateType = .all

    var isEmpty: Bool { statusBtnInfo == nil && groupBtnInfo == nil && sortingBtnInfo == nil }
}

final class FilterTabSelectorView: UIView {

    var viewData: FilterTabSelectorViewData? {
        didSet {
            guard let data = viewData, !data.isEmpty else {
                isHidden = true
                return
            }
            isHidden = false
            switch data.updateType {
            case .all:
                collectionView.reloadData()
            case .status:
                if let cell = collectionView.cellForItem(at: IndexPath(row: 0, section: 0)),
                   let contentCell = cell as? SelectorCell,
                   let info = viewData?.statusBtnInfo {
                    contentCell.update(title: info.title, isSeleted: info.isSeleted)
                }
            case .group:
                if let cell = collectionView.cellForItem(at: IndexPath(row: 1, section: 0)),
                   let contentCell = cell as? SelectorCell,
                   let info = viewData?.groupBtnInfo {
                    contentCell.update(title: info.title, isSeleted: info.isSeleted)
                }
            case .sorting:
                if let cell = collectionView.cellForItem(at: IndexPath(row: 2, section: 0)),
                   let contentCell = cell as? SelectorCell,
                   let info = viewData?.sortingBtnInfo {
                    contentCell.update(title: info.title, isSeleted: info.isSeleted)
                }
            }
        }
    }

    var itemBtnHandler: ((_ type: FilterTabSelectorViewData.UpdateType, _ sourceView: UIView) -> Void)?

    private lazy var collectionView = initCollectionView()
    private lazy var gradientLayer = initGradientLayer()

    private let disposeBag = DisposeBag()

    init() {
        super.init(frame: .zero)

        addSubview(collectionView)
        collectionView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
        layer.addSublayer(gradientLayer)
        gradientLayer.ud.setColors(
            [UIColor.ud.bgBody.withAlphaComponent(0.0),
             UIColor.ud.bgBody.withAlphaComponent(1.0)]
        )
        addViewObserver()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = CGRect(
            x: collectionView.frame.maxX - 87,
            y: collectionView.frame.minY,
            width: 87,
            height: collectionView.frame.height
        )
    }

    private func addViewObserver() {
        collectionView.rx.contentOffset
            .subscribe(onNext: { [weak self] (contentOffset) in
                guard let self = self else { return }
                self.handleGradientHidden(
                    contentSize: self.collectionView.contentSize,
                    contentoffset: contentOffset,
                    viewSize: self.collectionView.frame.size
                )
            })
            .disposed(by: disposeBag)
        collectionView.rx.observe(CGSize.self, #keyPath(UIScrollView.contentSize))
            .asObservable()
            .subscribe(onNext: { [weak self] (contentSize) in
                guard let self = self, let contentSize = contentSize else { return }
                self.handleGradientHidden(
                    contentSize: contentSize,
                    contentoffset: self.collectionView.contentOffset,
                    viewSize: self.collectionView.frame.size
                )
            })
            .disposed(by: disposeBag)
    }

    private func handleGradientHidden(
        contentSize: CGSize,
        contentoffset: CGPoint,
        viewSize: CGSize
    ) {
        let contentWidth = contentSize.width
        let contentOffsetX = contentoffset.x
        let viewWidth = viewSize.width

        if contentWidth <= viewWidth {
            gradientLayer.isHidden = true
        } else {
            gradientLayer.isHidden = false
        }

        if contentOffsetX + viewWidth < contentWidth {
            gradientLayer.isHidden = false
        } else {
            gradientLayer.isHidden = true
        }
    }

    private func initCollectionView() -> UICollectionView {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 24
        layout.headerReferenceSize = CGSize(width: 16, height: 0)
        layout.footerReferenceSize = CGSize(width: 46, height: 0)
        // iOS11 设置estimatedItemSize = .automaticSize 有bug,换下面方式写
        layout.estimatedItemSize = CGSize(width: 1, height: 1)
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.ud.bgBody
        collectionView.ctf.register(cellType: SelectorCell.self)
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }

    private func initGradientLayer() -> CAGradientLayer {
        let layer = CAGradientLayer()
        layer.startPoint = CGPoint(x: 0, y: 0.5)
        layer.endPoint = CGPoint(x: 1.0, y: 0.5)
        layer.isHidden = false
        return layer
    }
}

extension FilterTabSelectorView: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        3
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.ctf.dequeueReusableCell(SelectorCell.self, for: indexPath) else {
            return UICollectionViewCell()
        }
        switch indexPath.row {
        case 0:
            if let info = viewData?.statusBtnInfo {
                cell.update(title: info.title, isSeleted: info.isSeleted)
            }
        case 1:
            if let info = viewData?.groupBtnInfo {
                cell.update(title: info.title, isSeleted: info.isSeleted)
            }
        case 2:
            if let info = viewData?.sortingBtnInfo {
                cell.update(title: info.title, isSeleted: info.isSeleted)
            }
        default:
            break
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let cell = collectionView.cellForItem(at: indexPath) else { return }
        switch indexPath.row {
        case 0:
            itemBtnHandler?(.status, cell)
        case 1:
            itemBtnHandler?(.group, cell)
        case 2:
            itemBtnHandler?(.sorting, cell)
        default:
            break
        }
    }
}

private final class SelectorCell: UICollectionViewCell {

    private lazy var titleLabel = initTitleLabel()
    private lazy var arrowBtn = initArrowBtn()

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.addSubview(arrowBtn)
        arrowBtn.snp.makeConstraints {
            $0.right.top.bottom.equalToSuperview()
                .inset(UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0))
            $0.width.height.equalTo(12)
        }

        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints {
            $0.centerY.equalTo(arrowBtn)
            $0.left.equalToSuperview()
            $0.right.equalTo(arrowBtn.snp.left).offset(-4)
            $0.width.lessThanOrEqualTo(170)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(title: String, isSeleted: Bool) {
        arrowBtn.isHidden = false
        titleLabel.text = title
        titleLabel.textColor = isSeleted ? UIColor.ud.primaryContentDefault : UIColor.ud.iconN2
        arrowBtn.isSelected = isSeleted
    }

    private func initTitleLabel() -> UILabel {
        let label = UILabel()
        label.font = UDFont.systemFont(ofSize: 14)
        return label
    }

    private func initArrowBtn() -> UIButton {
        let button = UIButton()
        button.setImage(UDIcon.downOutlined.ud.withTintColor(UIColor.ud.iconN2), for: .normal)
        button.setImage(UDIcon.upOutlined.ud.withTintColor(UIColor.ud.primaryContentDefault), for: .selected)
        button.isUserInteractionEnabled = false
        button.isHidden = true
        return button
    }
}


final class FilterTabTasklistsSelectorView: UIView, UDTabsViewDelegate {

    var selectedTab: Rust.TaskListTabFilter? {
        didSet {
            guard let selectedTab = selectedTab else {
                isHidden = true
                return
            }
            isHidden = false
            let index = tabs.firstIndex(where: { $0.rawValue == selectedTab.rawValue }) ?? 0
            tabesView.defaultSelectedIndex = index
            // 动画需要做完
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) { [weak self] in
                self?.tabesView.reloadData()
            }
        }
    }

    var tabHandler: ((_ tab:Rust.TaskListTabFilter) -> Void)?

    private let tabs: [Rust.TaskListTabFilter] = [
        .taskContainerAll,
        .taskContainerCreatedByMe,
        .taskContainerCollaboratedWithMe,
        .taskContainerFromDoc,
        .taskContainerFromChat
    ]

    private lazy var tabesView: UDSegmentedControl = {
        var config = UDSegmentedControl.Configuration()
        config.titleLineBreakMode = .byTruncatingTail
        config.titleFont = UIFont.ud.body2(.fixed)
        config.titleSelectedColor = UIColor.ud.primaryContentDefault
        config.titleHorizontalMargin = 22
        config.contentEdgeInset = 0
        config.itemSpacing = 8
        config.preferredHeight = 28
        config.backgroundColor = UIColor.ud.bgBody
        config.indicatorColor = UIColor.ud.fillActive
        config.itemDistributionStyle = .automatic
        config.isScrollEnabled = true
        config.isBounceEnabled = true
        config.cornerStyle = .fixedRadius(6.0)
        let view = UDSegmentedControl(configuration: config)
        view.delegate = self
        view.titles = tabs.map(\.title)
        return view
    }()

    private lazy var dividingLine: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.lineDividerDefault
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(dividingLine)
        dividingLine.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(CGFloat(1.0 / UIScreen.main.scale))
        }
        addSubview(tabesView)
        tabesView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(horizontal: 16, vertical: 8))
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // UDTabsViewDelegate
    func tabsView(_ tabsView: UDTabsView, didSelectedItemAt index: Int) {
        tabHandler?(tabs[index])
    }

}

extension Rust.TaskListTabFilter {
    
    var title: String {
        switch self {
        case .taskContainerAll: return I18N.Todo_TaskListPage_All_Tab
        case .taskContainerCreatedByMe: return I18N.Todo_TaskListPage_Created_Tab
        case .taskContainerCollaboratedWithMe: return I18N.Todo_TaskListPage_Collaborated_Tab
        case .taskContainerFromDoc: return I18N.Todo_TaskListPage_FromDocs_Tab
        case .taskContainerFromChat: return I18N.Todo_TaskListPage_FromChat_Tab
        default: return I18N.Todo_TaskListPage_All_Tab
        }
    }

    var emptyText: String {
        switch self {
        case .taskContainerCollaboratedWithMe: return I18N.Todo_TaskListPage_Collaborated_EmptyState
        case .taskContainerFromDoc: return I18N.Todo_TaskListPage_FromDocs_EmptyState
        case .taskContainerFromChat: return I18N.Todo_TaskListPage_FromChats_EmptyState
        default: return I18N.Todo_TaskListPage_AllandCreated_EmptyState
        }
    }

    var tracker: String {
        switch self {
        case .taskContainerAll: return "all"
        case .taskContainerCreatedByMe: return "created"
        case .taskContainerCollaboratedWithMe: return "collaborated"
        case .taskContainerFromDoc: return "from_doc"
        case .taskContainerFromChat: return "from_chat"
        default: return ""
        }
    }
}
