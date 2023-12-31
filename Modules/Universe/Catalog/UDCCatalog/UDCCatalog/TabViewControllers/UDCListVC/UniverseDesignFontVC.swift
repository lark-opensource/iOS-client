//
//  UniverseDesignFontVC.swift
//  UDCCatalog
//
//  Created by 姚启灏 on 2020/8/13.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UniverseDesignFont
import UIKit

class UniverseDesignFontCell: UITableViewCell {

    lazy var title: UILabel = UILabel()

    lazy var des: UILabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let title = UILabel(frame: CGRect(x: 20, y: 20, width: 100, height: 30))
        self.title = title

        let des = UILabel(frame: CGRect(x: 120, y: 20, width: UIScreen.main.bounds.width - 130, height: 30))
        self.des = des

        self.contentView.addSubview(title)
        self.contentView.addSubview(des)
        self.isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UniverseDesignFontVC: UIViewController {

    private func getDataSource() -> [(String, UIFont, String)] {
        UDFont.FontType.allCases.map {
            (name: $0.rawValue,
             font: $0.uiFont(forZoom: UDZoom.currentZoom),
             desc: getFontDesc($0.uiFont(forZoom: UDZoom.currentZoom))
            )
        }
    }

    lazy var fontDataSource = getDataSource()

    var tableView: UITableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "UniverseDesignFont"

        self.tableView = UITableView(frame: self.view.bounds, style: .plain)
        self.view.addSubview(tableView)
        self.tableView.frame.origin.y = 88
        self.tableView.frame = CGRect(x: 0,
                                      y: 88,
                                      width: self.view.bounds.width,
                                      height: self.view.bounds.height - 88)
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.rowHeight = 68
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.contentInsetAdjustmentBehavior = .never
        self.tableView.register(UniverseDesignFontCell.self, forCellReuseIdentifier: "cell")
    }
}

extension UniverseDesignFontVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fontDataSource.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? UniverseDesignFontCell {
            cell.title.text = fontDataSource[indexPath.row].0
            cell.title.font = fontDataSource[indexPath.row].1
            cell.des.text = fontDataSource[indexPath.row].2
            cell.des.font = UDFont.getBody2(for: .normal)
            return cell
        } else {
            return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
        }
    }
}

extension UniverseDesignFontVC {

    private func getFontDesc(_ font: UIFont) -> String {
        guard var weight = font.fontDescriptor.fontAttributes[UIFontDescriptor.AttributeName(rawValue: "NSCTFontUIUsageAttribute")] as? String else { return "" }
        weight.removeFirst(6)
        weight.removeLast(5)
        if weight == "Demi" {
            weight = "Semibold"
        }
        return "字号：\(Int(font.pointSize))，字重：\(weight)，行高：\(Int(font.figmaHeight))"
    }
}
