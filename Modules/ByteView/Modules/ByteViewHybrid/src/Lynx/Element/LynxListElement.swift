//
// Created by maozhixiang.lip on 2022/11/10.
//

import Foundation
import Lynx

class LynxListElement: LynxUI<UIView> {
    static let name: String = "vc-list"
    override var name: String { Self.name }

    private var draggable: Bool = false
    private var isDragging: Bool = false
    private var srcDragIndex: Int = 0
    private var dstDragIndex: Int = 0
    private var indexMap: [Int]?
    private var isReloading: Bool = false

    @objc
    static func propSetterLookUp() -> [[String]] {
        [
            ["draggable", NSStringFromSelector(#selector(setDraggable(value:requestReset:)))]
        ]
    }

    @objc
    func setDraggable(value: NSNumber, requestReset: Bool) {
        self.draggable = value.boolValue
    }

    private lazy var list: List = {
        let view = List()
        view.delegate = self
        view.dataSource = self
        view.dragDelegate = self
        view.dropDelegate = self
        return view
    }()

    override func createView() -> UIView? {
        self.list
    }

    override func insertChild(_ child: LynxUI<UIView>, at index: Int) {
        super.insertChild(child, at: index)
        self.isReloading = true
        self.list.reloadData()
        self.isReloading = false
    }

    override func removeChild(_ child: LynxUI<UIView>, at index: Int) {
        super.removeChild(child, at: index)
        self.isReloading = true
        self.list.reloadData()
        self.isReloading = false
    }

    private var canPerformBatchUpdates = true
    override func layoutDidFinished() {
        super.layoutDidFinished()
        if !isReloading {
            UIView.performWithoutAnimation {
                self.list.performBatchUpdates {
                    self.foreachChild { item in
                        item.view().frame = .init(origin: .zero, size: item.view().frame.size)
                    }
                }
            }
        } else {
            Logger.lynx.info("skip performBatchUpdates because the list is reloading")
        }
    }

    private func child(at: Int) -> LynxUI<UIView>? {
        guard at >= 0 && at < self.children.count else { return nil }
        return self.children[at] as? LynxUI<UIView>
    }

    private func foreachChild(_ fn: (LynxUI<UIView>) -> Void) {
        self.children.forEach { child in
            guard let ui = child as? LynxUI<UIView> else { return }
            fn(ui)
        }
    }

    private func dragBegin(srcIndx: Int) {
        let event = LynxDetailEvent(name: "DragBegin", targetSign: sign, detail: ["srcIndex": srcIndx])
        self.context?.eventEmitter?.send(event)
        self.isDragging = true
    }

    private func dragEnd(srcIndex: Int, dstIndex: Int) {
        guard self.isDragging else { return }
        let event = LynxDetailEvent(name: "DragEnd", targetSign: sign, detail: [
            "srcIndex": srcIndex,
            "dstIndex": dstIndex
        ])
        self.context?.eventEmitter?.send(event)
        self.isDragging = false
    }

    class List: UITableView {
        required init?(coder: NSCoder) { super.init(coder: coder) }

        override init(frame: CGRect, style: Style) {
            super.init(frame: frame, style: style)
            self.separatorStyle = .none
            self.isScrollEnabled = false
            self.allowsSelection = false
            self.dragInteractionEnabled = true
            self.register(ListRow.self, forCellReuseIdentifier: ListRow.reuseIdentifier)
        }
    }

    class ListRow: UITableViewCell {
        static let reuseIdentifier = "Lynx.DraggableList.Cell"
        private var lynxView: LynxUI<UIView>?

        required init?(coder: NSCoder) { fatalError() }

        override init(style: CellStyle, reuseIdentifier: String?) {
            super.init(style: style, reuseIdentifier: reuseIdentifier)
        }

        func removeLynxView() {
            self.lynxView?.view().removeFromSuperview()
            self.lynxView = nil
        }

        // ref : template-assembler/Darwin/iOS/Lynx/UI/List/LynxCollection/LynxCollectionViewCell.m
        func addLynxView(_ lynxView: LynxUI<UIView>) {
            if lynxView.view().superview != nil {
                let prevRow = lynxView.view().superview?.superview as? ListRow
                prevRow?.removeLynxView()
            }
            self.removeLynxView()
            self.lynxView = lynxView
            self.contentView.addSubview(lynxView.view())
            self.adjustLynxFrame()
            if let backgroundManager = lynxView.backgroundManager {
                if let borderLayer = backgroundManager.borderLayer {
                    borderLayer.removeFromSuperlayer()
                    self.contentView.layer.insertSublayer(borderLayer, above: lynxView.view().layer)
                }
                if let backgroundLayer = backgroundManager.backgroundLayer {
                    backgroundLayer.removeFromSuperlayer()
                    self.contentView.layer.insertSublayer(backgroundLayer, above: lynxView.view().layer)
                }
            }
        }

        func adjustLynxFrame() {
            guard let view = self.lynxView?.view() else { return }
            view.frame = .init(origin: .zero, size: view.frame.size)
        }
    }
}

extension LynxListElement: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var childIndex = indexPath.row
        if let indexMap = self.indexMap { childIndex = indexMap[childIndex] }
        let height = self.child(at: childIndex)?.frame.height
        return height ?? 44.0
    }
}

extension LynxListElement: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.children.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = self.child(at: indexPath.row) else { return ListRow() }
        guard let cell = tableView.dequeueReusableCell(withIdentifier: ListRow.reuseIdentifier) as? ListRow else { return ListRow() }
        cell.addLynxView(item)
        return cell
    }
}


extension LynxListElement: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        guard self.draggable else { return [] }
        guard let item = self.child(at: indexPath.row) else { return [] }
        let dragItem = UIDragItem(itemProvider: .init(object: "" as NSString))
        dragItem.localObject = item
        self.srcDragIndex = indexPath.row
        self.dstDragIndex = indexPath.row
        return [dragItem]
    }

    func tableView(_ tableView: UITableView, dragPreviewParametersForRowAt indexPath: IndexPath) -> UIDragPreviewParameters? {
        guard let cell = tableView.cellForRow(at: indexPath) else { return nil }
        let params = UIDragPreviewParameters()
        let visibleRect = cell.contentView.bounds.insetBy(dx: 0, dy: 0.5)
        params.visiblePath = UIBezierPath(roundedRect: visibleRect, cornerRadius: 12.0)
        return params
    }

    func tableView(_ tableView: UITableView, dragSessionWillBegin session: UIDragSession) {
        self.dragBegin(srcIndx: self.srcDragIndex)
    }

    func tableView(_ tableView: UITableView, dragSessionDidEnd session: UIDragSession) {
        self.dragEnd(srcIndex: self.srcDragIndex, dstIndex: self.dstDragIndex)
    }
}

extension LynxListElement: UITableViewDropDelegate {
    func tableView(_ tableView: UITableView, dropSessionDidUpdate session: UIDropSession,
                   withDestinationIndexPath destinationIndexPath: IndexPath?) -> UITableViewDropProposal {
        .init(operation: .move, intent: .insertAtDestinationIndexPath)
    }

    func tableView(_ tableView: UITableView, performDropWith coordinator: UITableViewDropCoordinator) {
        guard coordinator.proposal.operation == .move else { return }
        guard let item = coordinator.items.first else { return }
        guard let srcIndexPath = item.sourceIndexPath else { return }
        let dstIndexPath = coordinator.destinationIndexPath ?? IndexPath(row: self.children.count - 1, section: 0)
        // - 这里不能更新DataSource，前端收到DragEnd事件后会更新LynxUI.view()，
        //   这里更新DataSource移动srcIndexPath到dstIndexPath会和前端的更新冲突
        // - 调coordinator.drop()之前需要更新CellHeight，否则srcIndexCellHeight和
        //   dstIndexHeight不同时动画会很奇怪。由于不能更新DataSource，这里记录了Reorder
        //   之后的Indexes，以便在调heightForRowAt时能够拿到Reorder之后Cell的高度。
        self.list.performBatchUpdates {
            self.indexMap = Array(0..<self.children.count)
            self.indexMap?.remove(at: srcIndexPath.row)
            self.indexMap?.insert(srcIndexPath.row, at: dstIndexPath.row)
        }
        coordinator.drop(item.dragItem, toRowAt: dstIndexPath)
        self.indexMap = nil
        self.srcDragIndex = srcIndexPath.row
        self.dstDragIndex = dstIndexPath.row
    }
}
