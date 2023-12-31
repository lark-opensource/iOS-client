//
//  ParticipantActionViewController.swift
//  ByteView
//
//  Created by Tobb Huang on 2023/6/20.
//
// 手机宫格：不带箭头气泡
// 手机参会人：半屏
// pad宫格（C+R）：带箭头气泡
// pad-C参会人：半屏
// pad-R参会人：带箭头气泡

import Foundation
import ByteViewCommon
import ByteViewUI

class ParticipantActionViewModel {
    let title: String
    let sections: [ParticipantActionSection]
    let source: ParticipantActionSource

    var didTap: ((ParticipantAction) -> Void)?

    init(title: String, sections: [ParticipantActionSection], source: ParticipantActionSource) {
        self.title = title
        self.sections = sections
        self.source = source
    }
}

class ParticipantActionViewController: VMViewController<ParticipantActionViewModel>, UITableViewDelegate, UITableViewDataSource {

    enum CellModel {
        case action(ParticipantAction)
        case lineDivider
    }

    struct Layout {
        static let popoverMinWidth: CGFloat = 132
        static let popoverLayoutMargins: CGFloat = 8

        static let titleConfig: VCFontConfig = .bodyAssist

        static let titleHorizontalInset: CGFloat = 16
        static let titleTopInset: CGFloat = 12
        static let titleBottomInset: CGFloat = 8
        static let popoverLineHeight: CGFloat = 1
        static let panLineHeight: CGFloat = 8

        static func contentInset(isPopover: Bool) -> CGFloat {
            return isPopover ? 4 : 0
        }
    }

    private var lastLayoutSubviewsSize: CGSize = .zero

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.numberOfLines = 1
        label.attributedText = NSAttributedString(string: viewModel.title,
                                                  config: Layout.titleConfig,
                                                  lineBreakMode: .byTruncatingTail)
        return label
    }()

    private lazy var titleHeaderView: UIView = {
        let view = UIView()
        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(Layout.titleTopInset)
            make.left.right.equalToSuperview().inset(Layout.titleHorizontalInset)
        }
        return view
    }()

    private lazy var tableView: UITableView = {
        let tableView = BaseTableView()
        tableView.bounces = false
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableView.automaticDimension
        tableView.contentInsetAdjustmentBehavior = .never
        tableView.register(cellType: ParticipantActionCell.self)
        tableView.register(cellType: ParticipantActionLineCell.self)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    var isPopover: Bool {
        return viewModel.source.fromGrid || VCScene.isRegular
    }

    var cellModels: [CellModel] {
        var models: [CellModel] = []
        viewModel.sections.forEach { section in
            models.append(.lineDivider)
            models.append(contentsOf: section.rows.map { CellModel.action($0) })
        }
        if isPopover && !models.isEmpty {
            models.removeFirst()
        }
        return models
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    override var shouldAutorotate: Bool {
        return true
    }

    override func setupViews() {
        super.setupViews()
        view.addSubview(tableView)
        updateBackgroundColor()
        updateLayout()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if let headerView = tableView.tableHeaderView {
            headerView.frame = .init(x: 0, y: 0, width: self.tableView.bounds.width, height: self.titleHeight)
        }
    }

    private func updateLayout() {
        if isPopover {
            tableView.tableHeaderView = nil
        } else {
            tableView.tableHeaderView = titleHeaderView
        }
        let contentInset = Layout.contentInset(isPopover: isPopover)
        tableView.snp.remakeConstraints { make in
            make.top.bottom.equalTo(self.view.safeAreaLayoutGuide).inset(contentInset)
            make.left.right.equalTo(self.view.safeAreaLayoutGuide)
        }
        updateDynamicModalSize(totalPopoverSize)
        panViewController?.updateBelowLayout()
        tableView.reloadData()
    }

    private func updateBackgroundColor() {
        view.backgroundColor = VCScene.isRegular ? .ud.bgFloat : .ud.bgBody
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellModels.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cellModels = self.cellModels
        switch cellModels[indexPath.row] {
        case .action(let action):
            let actionCell = tableView.dequeueReusableCell(withType: ParticipantActionCell.self, for: indexPath)
            actionCell.config(appearance: cellAppearance, action: action)
            return actionCell
        case .lineDivider:
            let lineCell = tableView.dequeueReusableCell(withType: ParticipantActionLineCell.self, for: indexPath)
            lineCell.cellHeight = self.isPopover ? Layout.popoverLineHeight : Layout.panLineHeight
            return lineCell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if case .action(let action) = cellModels[indexPath.row] {
            dismiss(animated: true)
            viewModel.didTap?(action)
        }
    }
}

extension ParticipantActionViewController: PanChildViewControllerProtocol {
    var cellAppearance: ParticipantActionCellAppearance {
        isPopover ? .popover : .pan
    }

    var contentWidth: CGFloat {
        let appearance: ParticipantActionCellAppearance = cellAppearance
        var maxWidth: CGFloat = 0
        cellModels.compactMap {
            if case .action(let action) = $0 {
                return action
            }
            return nil
        }.forEach {
            let titleWidth = $0.title.vc.boundingWidth(height: appearance.titleFontConfig.lineHeight, config: appearance.titleFontConfig) + 1
            var width = appearance.horizontalOffset * 2 + titleWidth
            if $0.icon != nil {
                width += (appearance.horizontalOffset + ParticipantActionCell.Layout.iconSize)
            }
            maxWidth = max(maxWidth, width)
        }
        return maxWidth
    }

    var titleHeight: CGFloat {
        tableView.tableHeaderView == nil ? 0 : Layout.titleTopInset + Layout.titleBottomInset + Layout.titleConfig.lineHeight
    }

    var contentHeight: CGFloat {
        let cellModels = self.cellModels
        var cellCount = 0
        var lineCount = 0
        cellModels.forEach {
            switch $0 {
            case .action:
                cellCount += 1
            case .lineDivider:
                lineCount += 1
            }
        }

        let cellHeight = 2 * cellAppearance.verticalOffset + cellAppearance.titleFontConfig.lineHeight
        let lineHeight = isPopover ? Layout.popoverLineHeight : Layout.panLineHeight
        return cellHeight * CGFloat(cellCount) + lineHeight * CGFloat(lineCount)
    }

    var totalPopoverSize: CGSize {
        let contentInset = Layout.contentInset(isPopover: isPopover)
        return CGSize(width: max(Layout.popoverMinWidth, contentWidth + 2 * contentInset), height: contentHeight + 2 * contentInset)
    }

    var totalPanHeight: CGFloat {
        // 12是bar的高度
        titleHeight + contentHeight + 12
    }

    func height(_ axis: RoadAxis, layout: RoadLayout) -> PanHeight {
        return .contentHeight(totalPanHeight, minTopInset: 44)
    }

    func width(_ axis: RoadAxis, layout: RoadLayout) -> PanWidth {
        if Display.phone, axis == .landscape {
            return .maxWidth(width: 375)
        }
        return .fullWidth
    }
}

extension ParticipantActionViewController: DynamicModalDelegate {
    func regularCompactStyleDidChange(isRegular: Bool) {
        self.updateBackgroundColor()
        self.updateLayout()
    }
}
