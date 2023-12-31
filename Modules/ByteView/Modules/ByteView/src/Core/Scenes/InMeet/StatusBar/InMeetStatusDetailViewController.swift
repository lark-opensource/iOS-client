//
//  InMeetStatusDetailViewController.swift
//  ByteView
//
//  Created by chenyizhuo on 2023/3/20.
//

import UIKit
import ByteViewUI

protocol InMeetStatusDetailViewModelDelegate: AnyObject {
    func statusItemsDidChange(_ items: [InMeetStatusItem])
}

class InMeetStatusDetailViewModel: InMeetStatusManagerListener {
    private let statusManager: InMeetStatusManager
    weak var delegate: InMeetStatusDetailViewModelDelegate? {
        didSet {
            delegate?.statusItemsDidChange(items.compactMap { $0 })
        }
    }

    private static let order: [InMeetStatusType] = [.lock, .record, .transcribe, .interpreter, .live, .interviewRecord, .countDown]
    lazy var items: [InMeetStatusItem?] = Self.order.map { _ in nil }

    init(resolver: InMeetViewModelResolver) {
        self.statusManager = resolver.resolve()!
        self.statusManager.addListener(self)

        for (key, value) in self.statusManager.statuses {
            if let index = Self.order.firstIndex(where: { $0 == key }) {
                items[index] = value
            }
        }
    }

    func statusDidChange(type: InMeetStatusType) {
        guard let index = Self.order.firstIndex(where: { $0 == type }) else { return }
        items[index] = statusManager.statuses[type]
        delegate?.statusItemsDidChange(items.compactMap { $0 })
    }
}

class InMeetStatusDetailViewController: VMViewController<InMeetStatusDetailViewModel>, UITableViewDelegate, UITableViewDataSource {

    private static let cellID = "InMeetStatusDetailViewControllerCellID"
    private lazy var tableView: BaseTableView = {
        let view = BaseTableView(frame: .zero)
        view.delegate = self
        view.dataSource = self
        view.bounces = false
        view.separatorStyle = .none
        view.contentInset = UIEdgeInsets(top: 4, left: 0, bottom: 0, right: 0)
        view.backgroundColor = .clear
        view.register(InMeetStatusDetailCell.self, forCellReuseIdentifier: Self.cellID)
        return view
    }()

    private var items: [InMeetStatusItem] = []
    private var contentSize: CGSize = .zero
    private var isPopover = false

    override func setupViews() {
        super.setupViews()

        view.backgroundColor = Display.pad ? UIColor.ud.bgFloat : UIColor.ud.bgBody
        view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    override func bindViewModel() {
        super.bindViewModel()
        viewModel.delegate = self
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    private var containerWidth: CGFloat {
        if self.currentLayoutContext.layoutType.isPhoneLandscape || VCScene.rootTraitCollection?.horizontalSizeClass == .regular {
            return 420
        }
        return VCScene.bounds.width
    }

    func itemHeight(_ item: InMeetStatusItem, within containerWidth: CGFloat) -> CGFloat {
        let buttonsWidth = item.actions
            .map { $0.title.vc.boundingWidth(height: .greatestFiniteMagnitude, font: InMeetStatusDetailCell.buttonFont) }
            .map {
                let buttonWidth = $0 + 16
                if buttonWidth < InMeetStatusDetailCell.buttonMinWidth {
                    return InMeetStatusDetailCell.buttonMinWidth
                } else if buttonWidth > InMeetStatusDetailCell.buttonMaxWidth {
                    return InMeetStatusDetailCell.buttonMaxWidth
                } else {
                    return buttonWidth
                }
            }.reduce(CGFloat(0), +)
        let textMaxWidth = containerWidth - 44 - 16 - max(CGFloat(item.actions.count) * 12 + buttonsWidth, item.clickAction != nil ? 24 : 0)
        let titleHeight = item.title.vc.boundingHeight(width: textMaxWidth, config: .body)
        var totalHeight = 12 + titleHeight + 12
        if let desc = item.desc {
            let descHeight = desc.vc.boundingHeight(width: textMaxWidth, config: .bodyAssist)
            totalHeight += 2 + descHeight
        }
        return totalHeight
    }

    func resetContentSize() {
        let containerWidth = self.containerWidth
        let calculatedHeight = items.map { self.itemHeight($0, within: containerWidth) }.reduce(0, +) + (isPopover ? 8 : 24)
        let newSize = CGSize(width: containerWidth, height: calculatedHeight)
        if newSize != contentSize {
            updateDynamicModalSize(newSize)
            contentSize = newSize
            panViewController?.updateBelowLayout()
        }
    }

    // MARK: - UITableViewDataSource & UITableViewDelegate

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellID, for: indexPath) as? InMeetStatusDetailCell else { return UITableViewCell() }
        cell.config(with: items[indexPath.row])
        cell.bottomLine.isHidden = indexPath.row == items.count - 1
        cell.onClick = { [weak self] in
            self?.dismiss(animated: true)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if let action = items[indexPath.row].clickAction {
            dismiss(animated: true, completion: action)
        }
    }
}

extension InMeetStatusDetailViewController: InMeetStatusDetailViewModelDelegate {
    func statusItemsDidChange(_ items: [InMeetStatusItem]) {
        Util.runInMainThread {
            if items.isEmpty {
                self.dismiss(animated: true)
                return
            }
            self.items = items
            self.tableView.reloadData()
            self.resetContentSize()
        }
    }
}

extension InMeetStatusDetailViewController: DynamicModalDelegate {
    func regularCompactStyleDidChange(isRegular: Bool) {
        isPopover = isRegular
        resetContentSize()
    }
}

extension InMeetStatusDetailViewController: PanChildViewControllerProtocol {
    func height(_ axis: RoadAxis, layout: RoadLayout) -> PanHeight {
        return .contentHeight(contentSize.height, minTopInset: 8)
    }

    func width(_ axis: RoadAxis, layout: RoadLayout) -> PanWidth {
        guard Display.phone else { return .fullWidth }
        switch axis {
        case .landscape:
            return .maxWidth(width: 420)
        default: return .fullWidth
        }
    }

    var panScrollable: UIScrollView? {
        tableView
    }

    var defaultLayout: RoadLayout {
        return .shrink
    }

    var backgroudColor: UIColor {
        view.backgroundColor ?? UIColor.ud.bgBody
    }
}
