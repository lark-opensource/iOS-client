//
//  BTCardLayoutDisplayFieldView.swift
//  SKBitable
//
//  Created by zhysan on 2023/1/10.
//

import UIKit
import SKResource
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignFont
import SKFoundation

private struct Const {
    static let displayCellH: CGFloat = 48.0
}

protocol BTCardLayoutDisplayFieldViewDelegate: AnyObject {
    func onDeleteField(_ view: BTCardLayoutDisplayFieldView, field: BTFieldOperatorModel)
    func onSortField(_ view: BTCardLayoutDisplayFieldView, fields: [BTFieldOperatorModel])
}

final class BTCardLayoutDisplayFieldView: BTTableSectionCardView {
    // MARK: - public
    
    weak var delegate: BTCardLayoutDisplayFieldViewDelegate?
    
    func update(_ data: BTCardLayoutSettings.DisplaySection) {
        items = Array(data.fields.prefix(BTCardLayoutSettings.DisplaySection.maxDisplayCount))
        
        if data.fields.count >= BTCardLayoutSettings.DisplaySection.maxDisplayCount {
            let num = BTCardLayoutSettings.DisplaySection.maxDisplayCount
            footerText =  BundleI18n.SKResource.Bitable_Mobile_CardMode_ShowUpToNumFields_Description(num)
        } else {
            footerText = nil
        }
        
        // 隐藏或者无权限的字段不显示
        items = items.filter({ !$0.isHidden && !$0.isDeniedField })
        
        tableView.reloadData()
        tableView.isHidden = items.isEmpty
        emptyLabel.isHidden = !items.isEmpty
        
        setNeedsUpdateConstraints()
    }
    
    // MARK: - life cycle
    
    init(frame: CGRect = .zero, delegate: BTCardLayoutDisplayFieldViewDelegate? = nil) {
        self.delegate = delegate
        super.init(frame: frame)
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        tableView.snp.updateConstraints { make in
            let row = min(BTCardLayoutSettings.DisplaySection.maxDisplayCount, items.count)
            make.height.equalTo(CGFloat(row) * Const.displayCellH)
        }
        emptyLabel.snp.updateConstraints { make in
            make.height.equalTo(items.count > 0 ? 0 : 48)
        }
        
        super.updateConstraints()
    }
    
    // MARK: - private
    
    private var items: [BTFieldOperatorModel] = []
    
    private let emptyLabel = UILabel().construct { it in
        it.text = BundleI18n.SKResource.Bitable_Mobile_CardMode_NoFieldsToDisplay_Description
        it.textColor = UDColor.textCaption
        it.font = UDFont.body0
    }
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    private func subviewsInit() {
        headerText = BundleI18n.SKResource.Bitable_Mobile_CardMode_FieldsToDisplay_Title
        contentView.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
        contentView.addSubview(emptyLabel)
        emptyLabel.snp.makeConstraints { make in
            make.top.equalTo(tableView.snp.bottom)
            make.bottom.equalToSuperview()
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(0)
        }
        
        tableView.dragInteractionEnabled = true
        tableView.dragDelegate = self
        tableView.allowsSelection = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(DisplayCell.self, forCellReuseIdentifier: DisplayCell.kDefaultReuseID)
    }
}

private final class DisplayCell: UITableViewCell {
    // MARK: - public
    
    static let kDefaultReuseID = "DisplayCell"
    
    var deleteAction: (() -> Void)?
    
    let iconView = BTLightingIconView()
    
    let titleLabel = UILabel().construct { it in
        it.textColor = UDColor.textTitle
        it.font = UDFont.body0
    }
    
    let topSpLine = UIView().construct { it in
        it.backgroundColor = UDColor.lineDividerDefault
    }
    
    // MARK: - life cycle
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - private
    
    // Expand tap area
    private let deleteBtn = UIButton(type: .custom)
    private let deleteIcon = UIImageView().construct { it in
        it.image = UDIcon.deleteColorful
    }
    
    private let menuView = UIImageView().construct { it in
        it.image = UDIcon.menuOutlined.ud.withTintColor(UDColor.iconN3)
    }
    
    @objc
    private func onDeleteTapped(_ sender: UIButton) {
        deleteAction?()
    }
    
    private func subviewsInit() {
        contentView.addSubview(topSpLine)
        contentView.addSubview(deleteBtn)
        contentView.addSubview(deleteIcon)
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(menuView)
        
        deleteIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        deleteBtn.snp.makeConstraints { make in
            make.center.equalTo(deleteIcon)
            make.width.height.equalTo(44)
        }
        iconView.snp.makeConstraints { make in
            make.left.equalTo(deleteIcon.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(8)
            make.top.bottom.equalToSuperview()
        }
        menuView.snp.makeConstraints { make in
            make.width.height.equalTo(20)
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.left.equalTo(titleLabel.snp.right).offset(16)
        }
        topSpLine.snp.makeConstraints { make in
            make.top.right.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
            make.left.equalTo(iconView)
        }
        contentView.backgroundColor = UDColor.bgFloat
        
        deleteBtn.addTarget(self, action: #selector(onDeleteTapped(_:)), for: .touchUpInside)
    }
}

extension BTCardLayoutDisplayFieldView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        Const.displayCellH
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: DisplayCell.kDefaultReuseID, for: indexPath)
        if let cell = cell as? DisplayCell {
            let item = items[indexPath.row]
            cell.titleLabel.text = item.name
            cell.iconView.update(item.compositeType.icon(), showLighting: item.isSync, tintColor: UDColor.iconN2)
            cell.topSpLine.isHidden = indexPath.row == 0
            cell.deleteAction = { [weak self] in
                guard let self = self else {
                    return
                }
                self.delegate?.onDeleteField(self, field: item)
            }
        }
        return cell
    }
}

extension BTCardLayoutDisplayFieldView: UITableViewDragDelegate {
    func tableView(_ tableView: UITableView, itemsForBeginning session: UIDragSession, at indexPath: IndexPath) -> [UIDragItem] {
        let dragItem = UIDragItem(itemProvider: NSItemProvider())
        dragItem.localObject = items[indexPath.row]
        return [dragItem]
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        let mover = items.remove(at: sourceIndexPath.row)
        items.insert(mover, at: destinationIndexPath.row)
        delegate?.onSortField(self, fields: items)
    }
}
