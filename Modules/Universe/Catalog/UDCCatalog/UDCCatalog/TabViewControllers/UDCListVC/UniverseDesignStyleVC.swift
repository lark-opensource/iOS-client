//
//  UniverseDesignStyleVC.swift
//  UDCCatalog
//
//  Created by 强淑婷 on 2020/8/14.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignStyle

class UniverseDesignRadiusCell: UITableViewCell {
    lazy var view: UIView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let view = UIView(frame: CGRect(x: 180, y: 20, width: 200, height: 30))
        self.view = view
        view.backgroundColor = .red

        self.contentView.addSubview(view)
        self.isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UniverseDesignShadowCell: UITableViewCell {
    lazy var view: UIView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        let view = UIView(frame: CGRect(x: 180, y: 20, width: 200, height: 30))
        self.view = view
        view.backgroundColor = .yellow

        self.contentView.addSubview(view)
        self.isUserInteractionEnabled = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class UniverseDesignStyleVC: UIViewController {
    var tableView: UITableView = UITableView()
    var titleData: [String] = ["圆角", "阴影", "分割线"]
    var lineData: [String] = ["分割线"]
    var radiusData = ["Radius-XS", "Radius-S", "Radius-M", "Radius-L", "Radius-XL"]
    var radiusItem: [CGFloat] = [UDStyle.lessSmallRadius,
                                 UDStyle.smallRadius,
                                 UDStyle.middleRadius,
                                 UDStyle.largeRadius,
                                 UDStyle.moreLargeRadius]
    var shadowData = ["Shadow-S-up",
                      "Shadow-S-down",
                      "Shadow-S-left",
                      "Shadow-S-right",
                      "Shadow-M-up",
                      "Shadow-M-down",
                      "Shadow-M-left",
                      "Shadow-M-right",
                      "Shadow-M-blue",
                      "Shadow-L-up",
                      "Shadow-L-down",
                      "Shadow-L-left",
                      "Shadow-L-right"]

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "UniverseDesignStyle"

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
        self.tableView.register(UniverseDesignRadiusCell.self, forCellReuseIdentifier: "radiusCell")
        self.tableView.register(UniverseDesignShadowCell.self, forCellReuseIdentifier: "shadowCell")
        // Do any additional setup after loading the view.
    }

}

extension UniverseDesignStyleVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return radiusItem.count
        } else if section == 1 {
            return shadowData.count
        } else {
            return 1
        }
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return titleData.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "radiusCell") as? UniverseDesignRadiusCell {
                cell.textLabel?.text = radiusData[indexPath.row]
                cell.view.layer.cornerRadius = radiusItem[indexPath.row]
                return cell
            }
        } else if indexPath.section == 1 {
            if let cell = tableView.dequeueReusableCell(withIdentifier: "shadowCell") as? UniverseDesignShadowCell {
                cell.textLabel?.text = shadowData[indexPath.row]
                setShadow(indexPath.row, view: cell.view)
                return cell
            }
        } else {
            let cell = UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
            cell.textLabel?.text = lineData[indexPath.row]
            let split = UDLine.split
            split.frame = CGRect(x: 10, y: 10, width: 200, height: 2)
            cell.contentView.addSubview(split)
            return cell
        }
        return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return titleData[section]
    }
}

extension UniverseDesignStyleVC {
    func setShadow(_ row: Int, view: UIView) {
        if row == 0 {
            view.smallShadow(.up)
        } else if row == 1 {
            view.smallShadow(.down)
        } else if row == 2 {
            view.smallShadow(.left)
        } else if row == 3 {
            view.smallShadow(.right)
        } else if row == 4 {
            view.middleShadow(.up)
        } else if row == 5 {
            view.middleShadow(.down)
        } else if row == 6 {
            view.middleShadow(.left)
        } else if row == 7 {
            view.middleShadow(.right)
        } else if row == 8 {
            view.middleShadowBlue()
        } else if row == 9 {
            view.largeShadow(.up)
        } else if row == 10 {
            view.largeShadow(.down)
        } else if row == 11 {
            view.largeShadow(.left)
        } else if row == 12 {
            view.largeShadow(.right)
        }
    }
}
