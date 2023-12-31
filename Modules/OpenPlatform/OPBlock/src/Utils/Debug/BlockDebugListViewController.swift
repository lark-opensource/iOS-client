//
//  BlockDebugListViewController.swift
//  OPBlock
//
//  Created by xiangyuanyuan on 2022/8/2.
//

import Foundation
import UIKit
import UniverseDesignColor
import LarkEMM
import OPFoundation

public enum BlockDebugDetailInfo: String, CaseIterable {
    case appName = "应用名称"
    case appId = "应用ID"
    case blockId = "BlockID"
    case blockTypeId = "BlockTypeID"
    case isSupportDarkMode = "是否支持DarkMode"
    case blockVersion = "Block版本"
    case packageUrl = "包地址"
    case blockType = "Block类型"
    case host = "宿主"
}

struct BlockDetailDataItem {
    let title: String
    let detail: String?
}

public final class BlockDebugListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var blockDetailData: [BlockDetailDataItem] = []
    public init(_ info: [BlockDebugDetailInfo: String?]) {
        super.init(nibName: nil, bundle: nil)
        
        blockDetailData = BlockDebugDetailInfo.allCases.map { (key) -> BlockDetailDataItem in
            return BlockDetailDataItem(title: key.rawValue, detail: info[key] ?? "")
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Block Detail"
        view.addSubview(tableView)
        
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.backgroundColor = UIColor.ud.bgBase
        tableView.register(BlockDebugDetailCell.self, forCellReuseIdentifier: "blockDebugCell")
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier:"blockDebugCell") as? BlockDebugDetailCell {
            cell.setContent(info: blockDetailData[indexPath.row])
            return cell
        } else {
            return UITableViewCell()
        }
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        self.blockDetailData.count
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alertController = UIAlertController(title: self.blockDetailData[indexPath.row].title, message: nil, preferredStyle: .alert)
        alertController.addTextField{ textField in
            textField.text = self.blockDetailData[indexPath.row].detail
            textField.isEnabled = false
        }
        let confirmAction = UIAlertAction(title: "COPY", style: .default) { [weak alertController] _ in
            let config = PasteboardConfig(token: OPSensitivityEntryToken.debug.psdaToken)
            SCPasteboard.general(config).string = self.blockDetailData[indexPath.row].detail
        }
        alertController.addAction(confirmAction)
        let cancelAction = UIAlertAction(title: "OK", style: .cancel) { _ in }
        alertController.addAction(cancelAction)
        self.present(alertController, animated: true, completion: nil)
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50.0
    }
}

private class BlockDebugDetailCell: UITableViewCell {
    
    private let mainTitle: UILabel = UILabel()
    private let detailInfo: UILabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.selectionStyle = .none
        contentView.addSubview(mainTitle)
        contentView.addSubview(detailInfo)
        
        mainTitle.font = UIFont.systemFont(ofSize: 16)
        mainTitle.textColor = UDColor.textTitle
        
        detailInfo.font = UIFont.systemFont(ofSize: 16)
        detailInfo.textColor = UDColor.textCaption
        detailInfo.lineBreakMode = .byTruncatingTail
        
        mainTitle.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        
        detailInfo.snp.makeConstraints { (make) in
            make.left.greaterThanOrEqualTo(mainTitle.snp.right).offset(20)
            make.right.equalToSuperview().inset(10)
            make.centerY.equalToSuperview()
        }
    }
    
    func setContent(info: BlockDetailDataItem) {
        self.mainTitle.text = info.title
        self.detailInfo.text = info.detail
    }
    
    required init?(coder Decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
