//
//  ListSectionReorderViewController.swift
//  Todo
//
//  Created by wangwanxin on 2023/1/29.
//

import CTFoundation
import LarkUIKit
import UniverseDesignColor

final class ListSectionReorderViewController: BaseUIViewController,
        UICollectionViewDelegate,
        UICollectionViewDataSource,
        UICollectionViewDelegateFlowLayout {

    private let originalSections: [V3ListSectionData]
    private var sections: [V3ListSectionData]
    private let onChanged: ([V3ListSectionData]) -> Void
    private let onConfirm: ([V3ListSectionData], [V3ListSectionData]) -> Void
    private let onCancel: ([V3ListSectionData]) -> Void

    private lazy var headerView = ActionPanelHeaderView()
    // 是否被重新排序
    private var isReordered = false
    // 事件是否被处理
    private var isEventHandled = false

    private lazy var collectionView: UICollectionView = {
        let layout = ListSectionReorderCellFlowLayout()
        layout.minimumLineSpacing = 0
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.dataSource = self
        cv.delegate = self
        cv.backgroundColor = UIColor.ud.bgFloatBase
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.clipsToBounds = true
        cv.bounces = false
        cv.alwaysBounceVertical = true
        cv.ctf.register(cellType: ListSectionReorderCell.self)
        let longPress = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(gesture:)))
        cv.addGestureRecognizer(longPress)
        return cv
    }()

    init(sections: [V3ListSectionData],
         changed: @escaping ([V3ListSectionData]) -> Void,
         cancel: @escaping ([V3ListSectionData]) -> Void,
         confirm: @escaping ([V3ListSectionData], [V3ListSectionData]) -> Void) {
        self.originalSections = sections
        self.sections = sections
        self.onChanged = changed
        self.onConfirm = confirm
        self.onCancel = cancel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(Config.HeaderHeight)
        }
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        headerView.title = ActionPanelHeaderView.Title(
            center: I18N.Todo_SectionSorting_Title,
            right: I18N.Todo_SectionSortingSave_Button
        )
        headerView.onCloseHander = { [weak self] in
            guard let self = self else { return }
            if self.isReordered {
                self.onCancel(self.originalSections)
                self.isEventHandled = true
            }
            self.dismiss(animated: true)
        }
        headerView.onSaveHandler = { [weak self] in
            guard let self = self else { return }
            if self.isReordered {
                self.onConfirm(self.sections, self.originalSections)
                self.isEventHandled = true
            }
            self.dismiss(animated: true)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // 侧滑或者下拉返回的时候,并且没有进行点选操作
        if (isMovingFromParent || navigationController?.isBeingDismissed == true) && isReordered && !isEventHandled {
            onCancel(originalSections)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.layoutIfNeeded()
        collectionView.reloadData()
    }

    func height(bottomInset: CGFloat) -> CGFloat {
        return Config.HeaderHeight + Config.TopInset + Config.BottomInset + CGFloat(sections.count) * Config.CellHeight + bottomInset
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return sections.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.ctf.dequeueReusableCell(ListSectionReorderCell.self, for: indexPath),
              let row = safeCheckRows(indexPath)
        else {
            return UICollectionViewCell()
        }
        cell.text = sections[row].header?.titleInfo?.text
        cell.showSeparateLine = true
        let numberOfRows = collectionView.numberOfItems(inSection: indexPath.section)
        if numberOfRows - 1 == indexPath.row {
            cell.showSeparateLine = false
        }
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let numberOfRows = collectionView.numberOfItems(inSection: indexPath.section)
        switch indexPath.row {
        case 0:
            var corners: CACornerMask = []
            corners.insert([.layerMinXMinYCorner, .layerMaxXMinYCorner])
            // 有且只有一个cell的时候需要处理左下、右下
            if numberOfRows - 1 == 0 {
                corners.insert([.layerMinXMaxYCorner, .layerMaxXMaxYCorner])
            }
            cell.lu.addCorner(
                corners: corners,
                cornerSize: corners.isEmpty ? .zero : CGSize(width: 10, height: 10)
            )
        case numberOfRows - 1:
            let corners: CACornerMask = [.layerMinXMaxYCorner, .layerMaxXMaxYCorner]
            cell.lu.addCorner(
                corners: corners,
                cornerSize: corners.isEmpty ? .zero : CGSize(width: 10, height: 10)
            )
        default:
            cell.lu.addCorner(
                corners: [],
                cornerSize: .zero
            )
        }
        cell.clipsToBounds = true
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        return CGSize(width: collectionView.frame.width - 16 * 2, height: Config.CellHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: Config.TopInset, left: 0, bottom: Config.BottomInset, right: 0)
    }

    private func safeCheckRows(_ indexPath: IndexPath) -> Int? {
        return V3ListSectionData.safeCheckRows(indexPath, from: sections)
    }

    func collectionView(_ collectionView: UICollectionView, canMoveItemAt indexPath: IndexPath) -> Bool {
        return true
    }

    func collectionView(_ collectionView: UICollectionView, moveItemAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let changed = updateSections(from: sourceIndexPath, to: destinationIndexPath)
        guard changed else {
            return
        }
        isReordered = true
        onChanged(sections)
        collectionView.performBatchUpdates(nil) { _ in
            DispatchQueue.main.async {
                collectionView.reloadData()
            }
        }
    }

    private func updateSections(from: IndexPath, to: IndexPath) -> Bool {
        guard let fromRow = safeCheckRows(from), let toRow = safeCheckRows(to) else {
            return false
        }
        let itemToMove = sections.remove(at: fromRow)
        sections.insert(itemToMove, at: toRow)
        return true
    }

    @objc
    private func handleLongPress(gesture: UILongPressGestureRecognizer) {
        switch gesture.state {
        case .began:
            guard let indexPath = collectionView.indexPathForItem(at: gesture.location(in: collectionView)) else {
                return
            }
            guard let cell = collectionView.cellForItem(at: indexPath) else {
                return
            }
            collectionView.beginInteractiveMovementForItem(at: indexPath)
        case .changed:
            var point = gesture.location(in: collectionView)
            point.x = collectionView.bounds.width / 2
            collectionView.updateInteractiveMovementTargetPosition(point)
        case .ended:
            collectionView.endInteractiveMovement()
        default:
            collectionView.cancelInteractiveMovement()
        }
    }
}

extension ListSectionReorderViewController {

    struct Config {
        static let CellHeight = 48.0
        static let HeaderHeight = 48.0
        static let BottomInset = 8.0
        static let TopInset = 16.0
    }

}
