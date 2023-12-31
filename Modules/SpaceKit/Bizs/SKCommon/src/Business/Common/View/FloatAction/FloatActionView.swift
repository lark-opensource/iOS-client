//
//  FloatActionView.swift
//  SKCommon
//
//  Created by zoujie on 2021/1/4.
//  


import Foundation
import SnapKit
import UniverseDesignColor

public struct FloatActionConfig {
    //item高度
    let cellHeight: CGFloat
    //菜单内边距
    let edgeInsets: UIEdgeInsets

    public init(cellHeight: CGFloat, edgeInsets: UIEdgeInsets) {
        self.cellHeight = cellHeight
        self.edgeInsets = edgeInsets
    }
}

public struct FloatActionItem {
    let icon: UIImage
    var title: String = ""
    let type: FloatActionType
    var enable: Bool = true

    public mutating func setItemEnable(enable: Bool) {
        self.enable = enable
    }

    public mutating func setTitle(title: String) {
        self.title = title
    }
}

public protocol FloatActionDelegate: AnyObject {
    func floatAction(_ actionView: FloatActionView, selectWith type: FloatActionType)
}

public final class FloatActionView: UIView {

    private var config: FloatActionConfig

    private let actionCells: [FloatActionCell]

    public weak var delegate: FloatActionDelegate?

    public var onItemClick: ((_ completion: (() -> Void)?) -> Void)?

    public init(items: [FloatActionItem], config: FloatActionConfig = FloatActionConfig(cellHeight: 50, edgeInsets: UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0))) {
        self.actionCells = items.map({ FloatActionCell(item: $0) })
        self.config = config
        super.init(frame: .zero)
        setupViews()
        setupLayouts()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViews() {
        actionCells.forEach({ $0.addTarget(self, action: #selector(didClickCell(_:)), for: .touchUpInside) })
    }

    private func setupLayouts() {
        layer.cornerRadius = 8.0
        layer.masksToBounds = true
        backgroundColor = UDColor.bgFloat
        var lastCell: FloatActionCell?
        actionCells.forEach({ cell in
            addSubview(cell)
            cell.snp.makeConstraints({ (make) in
                make.height.equalTo(config.cellHeight)
                make.leading.equalToSuperview().offset(config.edgeInsets.left)
                make.trailing.equalToSuperview().offset(-config.edgeInsets.right)
                if let lastCell = lastCell {
                    make.top.equalTo(lastCell.snp.bottom)
                } else {
                    make.top.equalToSuperview().offset(config.edgeInsets.top)
                }
            })
            lastCell = cell
        })
        self.snp.makeConstraints { (make) in
            make.height.equalTo(CGFloat(actionCells.count) * config.cellHeight + 2 * config.edgeInsets.top + config.edgeInsets.bottom)
        }
    }

    @objc
    private func didClickCell(_ sender: FloatActionCell) {
        guard sender.item.enable else { return }
        sender.backgroundColor = UDColor.bgFiller
        onItemClick? { [weak self] in
            guard let self = self else { return }
            self.delegate?.floatAction(self, selectWith: sender.item.type)
        }
    }
}
