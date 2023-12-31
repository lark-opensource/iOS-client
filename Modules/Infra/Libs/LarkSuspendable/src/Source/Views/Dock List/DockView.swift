//
//  DockView.swift
//  AnimatedTabBar
//
//  Created by Hayden on 2021/5/28.
//

import Foundation
import UIKit
import Homeric
import LKCommonsTracker
import FigmaKit
import UniverseDesignColor

protocol DockViewDelegate: AnyObject {
    func dockView(_ view: DockView, didDeleteItem item: SuspendPatch)
    func dockView(_ view: DockView, didSelectItem item: SuspendPatch)
    func dockViewDidDismiss(_ view: DockView)
    func dockViewDidClearItems(_ view: DockView)
}

final class DockView: UIView {

    enum Direction {
        case left, right
    }

    weak var delegate: DockViewDelegate?

    var direction: Direction = .right
    var dragDirection: Direction = .right

    private var animationDuration: TimeInterval = 0.2

    private var marginTop: CGFloat {
        if let keyWindow = UIApplication.shared.keyWindow {
            return keyWindow.safeAreaInsets.top == 0 ? 20 : keyWindow.safeAreaInsets.top
        } else {
            return 0
        }
    }

    private var marginBottom: CGFloat {
        if let keyWindow = UIApplication.shared.keyWindow {
            return keyWindow.safeAreaInsets.bottom
        } else {
            return 0
        }
    }

    private var contentHeight: CGFloat {
        var result: CGFloat = 0
        for section in dataSource {
            result += 20
            result += cellHeightForGroup(section.group) * CGFloat(section.items.count)
        }
        return result
    }

    private var tableHeight: CGFloat {
        return UIScreen.main.bounds.height - marginBottom - marginTop
    }

    typealias SuspendItemGroup = (group: SuspendGroup, items: [SuspendPatch])

    private lazy var dataSource = groupItems(SuspendManager.shared.suspendItems)

    /// 将多任务项目分组并排序
    private func groupItems(_ items: [SuspendPatch]) -> [SuspendItemGroup] {
        let groupedItems = items.grouped(by: { $0.group.priority })
        let result = groupedItems.map({ ($0.first!.group, $0) })
        return result.sorted(by: { $0.0.priority < $1.0.priority })
    }

    lazy var backgroundBlurView: VisualBlurView = {
        let blurView = VisualBlurView()
        blurView.blurRadius = Cons.blurRadius
        blurView.fillColor = Cons.blurColor
        blurView.fillOpacity = Cons.blurOpacity
        blurView.isUserInteractionEnabled = false
        return blurView
    }()

    private lazy var topMask = UIButton()

    private lazy var headerView = DockHeaderView()

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.alwaysBounceVertical = false
        tableView.tableFooterView = UIView()
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        return tableView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setup() {
        setupSubviews()
        setupConstraints()
        setupAppearance()
        handleEvents()
    }

    private func setupSubviews() {
        addSubview(backgroundBlurView)
        addSubview(tableView)
        addSubview(topMask)
    }

    private func setupConstraints() {
        backgroundBlurView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        topMask.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(safeAreaLayoutGuide.snp.top).offset(10)
        }
    }

    private func setupAppearance() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(BaseDockCell.self, forCellReuseIdentifier: String(describing: BaseDockCell.self))
        tableView.register(ChatDockCell.self, forCellReuseIdentifier: String(describing: ChatDockCell.self))
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Shadow 需要响应 DarkMode 变化，所以在此设置
        tableView.layer.dropShadow(
            color: Cons.shadowColor,
            alpha: 0.09, x: 0, y: 4, blur: 8, spread: 0
        )
        // Adjust header height according to contents.
        headerView.frame.size.height = max(56, (tableHeight - contentHeight) / 2)
        tableView.tableHeaderView = headerView
    }
}

// MARK: - Show & Dismiss

extension DockView {

    func show(on hostView: UIView, animated: Bool, completion: (() -> Void)? = nil) {
        hostView.addSubview(self)
        self.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        if animated {
            self.alpha = 0
            let coefficient: CGFloat = (direction == .right ? 1 : -1) / 3
            tableView.transform = CGAffineTransform(
                translationX: UIScreen.main.bounds.width * coefficient,
                y: 0
            )
            UIView.animate(withDuration: animationDuration, animations: {
                self.alpha = 1
                self.tableView.transform = .identity
            }, completion: { _ in
                completion?()
            })
        } else {
            completion?()
        }
    }

    func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        if animated {
            let coefficient: CGFloat = (direction == .right ? 1 : -1) / 3
            UIView.animate(withDuration: animationDuration, animations: {
                self.alpha = 0
                self.tableView.transform = CGAffineTransform(
                    translationX: UIScreen.main.bounds.width * coefficient,
                    y: 0
                )
            }, completion: { _ in
                self.removeFromSuperview()
                self.delegate?.dockViewDidDismiss(self)
                completion?()
            })
        } else {
            removeFromSuperview()
            self.delegate?.dockViewDidDismiss(self)
            completion?()
        }
    }

    private func processDismiss(progress: CGFloat) {
        let coefficient: CGFloat = (dragDirection == .right ? 1 : -1) / 1
        let transform = CGAffineTransform(
            translationX: UIScreen.main.bounds.width * coefficient * progress,
            y: 0
        )
        tableView.transform = transform
        tableView.alpha = 1 - progress
    }

    private func cancelDismiss(from progress: CGFloat) {
        let remainingTime = animationDuration * TimeInterval(progress)
        UIView.animate(withDuration: remainingTime, animations: {
            self.processDismiss(progress: 0)
        })
        let loopTimes = Int(remainingTime / 0.02)
        animateBlurEffect(toRadius: Cons.blurRadius, opacity: Cons.blurOpacity, loopTimes: loopTimes)
    }

    private func finishDismiss(from progress: CGFloat) {
        let coefficient: CGFloat = (dragDirection == .right ? 1 : -1) / 1
        UIView.animate(withDuration: animationDuration * TimeInterval(1 - progress), animations: {
            self.alpha = 0
            self.tableView.transform = CGAffineTransform(
                translationX: UIScreen.main.bounds.width * coefficient,
                y: 0
            )
        }, completion: { _ in
            self.removeFromSuperview()
            self.delegate?.dockViewDidDismiss(self)
        })

        let remainingTime = animationDuration * TimeInterval(1 - progress)
        UIView.animate(withDuration: remainingTime, animations: {
            self.processDismiss(progress: 1.0)
            self.backgroundBlurView.alpha = 0
        }, completion: { _ in
            self.removeFromSuperview()
            self.delegate?.dockViewDidDismiss(self)
        })
    }

    func animateBlurEffect(toRadius finalRadius: CGFloat, opacity finalOpacity: CGFloat, loopTimes: Int) {
        guard loopTimes > 0 else {
            backgroundBlurView.blurRadius = finalRadius
            backgroundBlurView.fillOpacity = finalOpacity
            return
        }
        let curOpacity = backgroundBlurView.fillOpacity
        let curRadius = backgroundBlurView.blurRadius
        let opacityStep = (finalOpacity - curOpacity) / CGFloat(loopTimes)
        let radiusStep = (finalRadius - curRadius) / CGFloat(loopTimes)
        let nextOpacity = max(0, min(Cons.blurOpacity, curOpacity + opacityStep))
        let nextRadius = max(0, min(Cons.blurRadius, curRadius + radiusStep))
        backgroundBlurView.blurRadius = nextRadius
        backgroundBlurView.fillOpacity = nextOpacity
        if finalOpacity == nextOpacity && finalRadius == nextRadius {
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
            self.animateBlurEffect(toRadius: finalRadius, opacity: finalOpacity, loopTimes: loopTimes - 1)
        }
    }
}

// MARK: - Handle Gestures

extension DockView {

    private func handleEvents() {
        // Scroll to top
        topMask.addTarget(self, action: #selector(didTapTopMask), for: .touchUpInside)

        // Pan to close
        let panGesture = DirectionalPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
        panGesture.allowedDirections = [.left, .right]
        addGestureRecognizer(panGesture)

        // Tap background to close
        tableView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTapBackground)))

        // Clear items
        headerView.confirmClearButton.addTarget(self, action: #selector(didTapClearButton(_:)), for: .touchUpInside)
    }

    @objc
    private func didPan(_ gesture: DirectionalPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            if gesture.currentDirection == .right {
                dragDirection = .right
            } else {
                dragDirection = .left
            }
        case .changed:
            let direction: CGFloat = dragDirection == .right ? 1 : -1
            let translation = gesture.translation(in: self)
            let progress = (translation.x / bounds.width) * direction
            processDismiss(progress: progress)
            backgroundBlurView.blurRadius = (1 - progress) * Cons.blurRadius
            backgroundBlurView.fillOpacity = (1 - progress) * Cons.blurOpacity
        case .ended:
            let direction: CGFloat = dragDirection == .right ? 1 : -1
            let translation = gesture.translation(in: self)
            let progress = (translation.x / bounds.width) * direction
            let velocity = gesture.velocity(in: self).x * direction
            if progress >= 0.2 || velocity > 1_000 {
                finishDismiss(from: progress)
            } else {
                cancelDismiss(from: progress)
            }
        case .cancelled, .failed:
            let direction: CGFloat = dragDirection == .right ? 1 : -1
            let translation = gesture.translation(in: self)
            let progress = (translation.x / bounds.width) * direction
            cancelDismiss(from: progress)
        default:
            break
        }
    }

    @objc
    private func didTapBackground() {
        dismiss(animated: true)
        // Analytics
        Tracker.post(TeaEvent(Homeric.TASKLIST_BACK))
    }

    @objc
    private func didTapTopMask() {
        // Scroll to top.
        tableView.setContentOffset(.zero, animated: true)
    }
}

// MARK: - DockCell Delegate

extension DockView: DockCellDelegate {

    func didSelectDockCell(_ cell: DockCell) {
        guard let item = cell.suspendItem else { return }
        delegate?.dockView(self, didSelectItem: item)
        // Analytics
        Tracker.post(TeaEvent(Homeric.TASKLIST_VALID_CLICK, params: [
            "task_type": item.analytics
        ]))
        print("tasklist_type: \(item.analytics)")
    }

    func didDeleteDockCell(_ cell: DockCell) {
        guard let item = cell.suspendItem,
              let indexPath = tableView.indexPath(for: cell) else { return }
        deleteCell(at: indexPath)
        delegate?.dockView(self, didDeleteItem: item)
        // Analytics
        Tracker.post(TeaEvent(Homeric.TASKLIST_DELETE, params: [
            "task_type": item.analytics
        ]))
        print("tasklist_type: \(item.analytics)")
    }

    @objc
    private func didTapClearButton(_ sender: UIButton) {
        let sections = dataSource.count
        dataSource = []
        tableView.deleteSections(IndexSet(0..<sections), with: .top)
        delegate?.dockViewDidClearItems(self)
    }

    private func deleteCell(at indexPath: IndexPath) {
        dataSource[indexPath.section].items.remove(at: indexPath.row)
        if dataSource[indexPath.section].items.isEmpty {
            dataSource.remove(at: indexPath.section)
            tableView.deleteSections([indexPath.section], with: .fade)
        } else {
            tableView.deleteRows(at: [indexPath], with: .fade)
        }
    }
}

// MARK: - TableView DataSource

extension DockView: UITableViewDataSource, UITableViewDelegate {

    private func cellHeightForGroup(_ group: SuspendGroup) -> CGFloat {
        return group.cellType.cellHeight
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = dataSource[indexPath.section].items[indexPath.row]
        return cellHeightForGroup(item.group)
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 20.auto()
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = DockSectionHeaderView()
        view.label.text = dataSource[section].group.name
        return view
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = dataSource[indexPath.section].items[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: String(describing: item.group.cellType)) as? DockCell
            ?? item.group.cellType.init()
        cell.configure(item: item)
        cell.delegate = self
        return cell
    }
}

fileprivate extension Sequence {
    func grouped<GroupingType: Hashable>(by key: (Iterator.Element) -> GroupingType) -> [[Iterator.Element]] {
        var groups: [GroupingType: [Iterator.Element]] = [:]
        var groupsOrder: [GroupingType] = []
        forEach { element in
            let key = key(element)
            if case nil = groups[key]?.append(element) {
                groups[key] = [element]
                groupsOrder.append(key)
            }
        }
        return groupsOrder.map { groups[$0]! }
    }
}

extension DockView {

    enum Cons {
        static var blurRadius: CGFloat { 60 }
        static var blurOpacity: CGFloat { 0.2 }
        static var blurColor: UIColor {
            UIColor.ud.primaryOnPrimaryFill
        }
        static var shadowColor: UIColor {
            UIColor.ud.N900 & UIColor.ud.staticBlack
        }
    }
}
