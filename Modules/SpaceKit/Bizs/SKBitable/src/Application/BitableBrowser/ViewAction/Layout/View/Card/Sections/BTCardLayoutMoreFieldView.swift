//
//  BTCardLayoutMoreFieldView.swift
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
    static let cellH: CGFloat = 48.0
}

protocol BTCardLayoutMoreFieldViewDelegate: AnyObject {
    func onAddField(_ view: BTCardLayoutMoreFieldView, field: BTFieldOperatorModel)
}

final class BTCardLayoutMoreFieldView: BTTableSectionCardView {
    
    // MARK: - public
    
    weak var delegate: BTCardLayoutMoreFieldViewDelegate?
    
    func update(_ data: BTCardLayoutSettings.MoreSection) {
        items = Array(data.fields.filter({ !$0.isHidden && !$0.isDeniedField }))
        addEnable = data.addEnable
        
        let hiddenCount = data.fields.filter({ $0.isHidden }).count
        if hiddenCount > 0 {
            footerText = BundleI18n.SKResource.Bitable_Mobile_CardMode_NumHiddenUnavailableFields_Description(hiddenCount)
        } else {
            footerText = nil
        }
        
        tableView.reloadData()
        tableView.isHidden = items.isEmpty
        emptyLabel.isHidden = !items.isEmpty
        
        setNeedsUpdateConstraints()
    }
    
    // MARK: - life cycle
    
    init(frame: CGRect = .zero, delegate: BTCardLayoutMoreFieldViewDelegate? = nil) {
        self.delegate = delegate
        super.init(frame: frame)
        subviewsInit()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func updateConstraints() {
        tableView.snp.updateConstraints { make in
            make.height.equalTo(CGFloat(items.count) * Const.cellH)
        }
        emptyLabel.snp.updateConstraints { make in
            make.height.equalTo(items.count > 0 ? 0 : 48)
        }
        
        super.updateConstraints()
    }
    
    // MARK: - private
    
    private var items: [BTFieldOperatorModel] = []
    
    private var addEnable: Bool = false
    
    private let emptyLabel = UILabel().construct { it in
        it.text = BundleI18n.SKResource.Bitable_Mobile_CardMode_NoAvailableFields_Description
        it.textColor = UDColor.textCaption
        it.font = UDFont.body0
    }
    
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    private func subviewsInit() {
        headerText = BundleI18n.SKResource.Bitable_Mobile_CardMode_MoreFields_Title
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
        
        tableView.allowsSelection = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(MoreCell.self, forCellReuseIdentifier: MoreCell.kDefaultReuseID)
    }
}

private final class MoreCell: UITableViewCell {
    // MARK: - public
    
    static let kDefaultReuseID = "MoreCell"
    
    var addAction: (() -> Void)?
    
    var addEnable: Bool = false {
        didSet {
            addIcon.isHighlighted = addEnable
            addBtn.isEnabled = addEnable
        }
    }
    
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
    private let addBtn = UIButton(type: .custom)
    private let addIcon = UIImageView().construct { it in
        it.image = SKResource.BundleResources.SKResource.Bitable.icon_add_colorful_gray
        it.highlightedImage = SKResource.BundleResources.SKResource.Bitable.icon_add_colorful_blue
    }
    
    @objc
    private func onAddTapped(_ sender: UIButton) {
        addAction?()
    }
    
    func subviewsInit() {
        contentView.addSubview(topSpLine)
        contentView.addSubview(addBtn)
        contentView.addSubview(addIcon)
        contentView.addSubview(iconView)
        contentView.addSubview(titleLabel)
        
        addIcon.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        addBtn.snp.makeConstraints { make in
            make.center.equalTo(addIcon)
            make.width.height.equalTo(44)
        }
        iconView.snp.makeConstraints { make in
            make.left.equalTo(addIcon.snp.right).offset(12)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        titleLabel.snp.makeConstraints { make in
            make.left.equalTo(iconView.snp.right).offset(8)
            make.right.equalToSuperview().inset(16)
            make.top.bottom.equalToSuperview()
        }
        topSpLine.snp.makeConstraints { make in
            make.top.right.equalToSuperview()
            make.height.equalTo(1 / UIScreen.main.scale)
            make.left.equalTo(iconView)
        }
        
        contentView.backgroundColor = UDColor.bgFloat
        
        addEnable = false
        addBtn.addTarget(self, action: #selector(onAddTapped(_:)), for: .touchUpInside)
    }
}

extension BTCardLayoutMoreFieldView: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        items.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        Const.cellH
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MoreCell.kDefaultReuseID, for: indexPath)
        if let cell = cell as? MoreCell {
            let item = items[indexPath.row]
            cell.titleLabel.text = item.name
            cell.iconView.update(item.compositeType.icon(), showLighting: item.isSync, tintColor: UDColor.iconN2)
            cell.topSpLine.isHidden = indexPath.row == 0
            cell.addAction = { [weak self] in
                guard let self = self else { return }
                self.delegate?.onAddField(self, field: item)
            }
            cell.addEnable = addEnable
        }
        return cell
    }
}

