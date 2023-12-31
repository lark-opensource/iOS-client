//
//  UniverseDesignColorVC.swift
//  UDCCatalog
//
//  Created by 姚启灏 on 2020/8/13.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignColor

import UniverseDesignTheme

extension UDComponentsExtension where BaseType == UIColor {

    /// T400 at light mode, T600 at dark mode.
    static var messageTextPin: UIColor {
        return UIColor.ud.T400 & UIColor.ud.T600
    }

    /// T600 at light mode, N400 at dark mode.
    static var feedBgTop: UIColor {
        return UIColor.ud.N600 & UIColor.ud.N400
    }
}

extension UIColor {

    static func hexStringFromColor(color: UIColor) -> String {
        let components = color.cgColor.components
        let rvalue: CGFloat = components?[0] ?? 0.0
        let gvalue: CGFloat = components?[1] ?? 0.0
        let bvalue: CGFloat = components?[2] ?? 0.0
        let hexString = String(
            format: "#%02lX%02lX%02lX",
            lroundf(Float(rvalue * 255)),
            lroundf(Float(gvalue * 255)),
            lroundf(Float(bvalue * 255))
        )
        return hexString
    }

    var rgba: (red: Int, green: Int, blue: Int, alpha: Double) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (Int(red * 255), Int(green * 255), Int(blue * 255), Double(round(100 * alpha)/100))
    }
}

class PaletteView: UIView {

    private lazy var label: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 8)
        return label
    }()

    init(left: Bool) {
        super.init(frame: .zero)
        self.label.textAlignment = left ? .left : .right
        self.addSubview(label)
        self.label.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            if left {
                make.leading.equalToSuperview().offset(10)
            } else {
                make.trailing.equalToSuperview().offset(-10)
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setColor(_ color: UIColor) {
        backgroundColor = color
        var hue: CGFloat        = 0.0
        var saturation: CGFloat = 0.0
        var brightness: CGFloat = 0.0
        var red: CGFloat        = 0.0
        var green: CGFloat      = 0.0
        var blue: CGFloat       = 0.0
        var alpha: CGFloat      = 0.0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        color.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)
        let r = Int(red * 255)
        let g = Int(green * 255)
        let b = Int(blue * 255)
        let a = Double(round(100 * alpha)/100)
        let hex = color.hex6!
        label.textColor = UIColor(white: brightness > 0.5 ? 0 : 1, alpha: 1)
        label.text = "R:\(r)\nG:\(g)\nB:\(b)\nA:\(a)\n\(hex)"
    }
}

struct SampleColor {
    var name: String
    var color: UIColor
    var keyword: String

    init(_ name: String, _ color: UIColor) {
        self.name = name
        self.color = color
        if #available(iOS 13, *) {
            let hex = "\(color.alwaysLight.hex6!)&\(color.alwaysDark.hex6!)"
            self.keyword = "\(name),\(hex)".lowercased()
        } else {
            let hex = "\(color.hex6!)"
            self.keyword = "\(name),\(hex)".lowercased()
        }
    }
}

class UniverseDesignColorCell: UITableViewCell {

    private var color: SampleColor?

    private lazy var title: UILabel = UILabel()

    private lazy var lightBackground = UIView()
    private lazy var darkBackground = UIView()
    private lazy var lightView = PaletteView(left: true)
    private lazy var darkView = PaletteView(left: false)

    private lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16, weight: .bold)
        label.textColor = .systemGray
        return label
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(title)
        contentView.addSubview(lightBackground)
        contentView.addSubview(darkBackground)
        contentView.addSubview(lightView)
        contentView.addSubview(darkView)
        contentView.addSubview(nameLabel)
        nameLabel.textAlignment = .center
        self.selectionStyle = .none
        lightBackground.backgroundColor = .white
        darkBackground.backgroundColor = .black
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        lightView.frame = CGRect(x: 0, y: 0, width: bounds.width / 2, height: bounds.height)
        darkView.frame = CGRect(x: bounds.width / 2, y: 0, width: bounds.width / 2, height: bounds.height)
        nameLabel.frame = bounds
        lightBackground.frame = lightView.frame
        darkBackground.frame = darkView.frame
    }

    func setColor(_ color: SampleColor) {
        self.color = color
        nameLabel.text = color.name
        if #available(iOS 12.0, *) {
            lightView.setColor(color.color.resolvedCompatibleColor(with: UITraitCollection(userInterfaceStyle: .light)))
            darkView.setColor(color.color.resolvedCompatibleColor(with: UITraitCollection(userInterfaceStyle: .dark)))
        } else {
            lightView.setColor(color.color)
            darkView.setColor(color.color)
        }
    }

    func shining() {
        layer.borderColor = UIColor.systemRed.cgColor
        layer.borderWidth = 2
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIView.animate(withDuration: 0.2) {
                self.layer.borderWidth = 0
            }
        }
    }
}

class UniverseDesignColorVC: UIViewController {

    private var searchKeyword: String?
    private var searchResult: [IndexPath] = []
    private var highlightedIndex: Int = 0

    private lazy var searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = "搜索关键字"
        bar.delegate = self
        return bar
    }()

    var tableView: UITableView = UITableView()

    override func viewDidLoad() {
        super.viewDidLoad()

        self.title = "UniverseDesignColor"

        self.tableView = UITableView(frame: self.view.bounds, style: .plain)
        setupSubviews()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.rowHeight = 68
        self.tableView.separatorStyle = .none
        self.tableView.keyboardDismissMode = .onDrag
        self.tableView.contentInsetAdjustmentBehavior = .automatic
        self.tableView.register(UniverseDesignColorCell.self, forCellReuseIdentifier: "cell")
    }

    @objc
    private func hideKeyboard() {
        searchBar.resignFirstResponder()
    }

    private func setupSubviews() {
        view.addSubview(searchBar)
        view.addSubview(tableView)
        searchBar.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
        }
        tableView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
}

extension UniverseDesignColorVC: UITableViewDataSource, UITableViewDelegate {

    private func getColor(for indexPath: IndexPath) -> SampleColor {
        return colorDataSource[indexPath.section].1[indexPath.row]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return colorDataSource[section].1.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return colorDataSource.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return colorDataSource[section].0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "cell") as? UniverseDesignColorCell {
            cell.setColor(getColor(for: indexPath))
            return cell
        } else {
            return UITableViewCell(style: .default, reuseIdentifier: "emptyCell")
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        hideKeyboard()
        let color = getColor(for: indexPath)
        let string = "UIColor.ud.\(color.name)"
        UIPasteboard.general.string = string
        print(string)
    }
}

extension UniverseDesignColorVC: UISearchBarDelegate {

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else { return }
        findSearchResultsIfNeeded(searchText: searchText)
    }

    private func findSearchResultsIfNeeded(searchText keyword: String) {
        guard keyword != searchKeyword else {
            // Highlight next item
            if !searchResult.isEmpty {
                highlightedIndex = (highlightedIndex + 1) % searchResult.count
                highlightMatchItem(forIndexPath: searchResult[highlightedIndex])
            }
            return
        }
        searchResult.removeAll()
        for (section, data) in colorDataSource.enumerated() {
            for (row, color) in data.1.enumerated() {
                if color.keyword.contains(keyword.lowercased()) {
                    searchResult.append(IndexPath(row: row, section: section))
                }
            }
        }
        searchKeyword = keyword
        highlightedIndex = 0
        if !searchResult.isEmpty {
            // Highlight first item
            highlightMatchItem(forIndexPath: searchResult[highlightedIndex])
        }
    }

    private func highlightMatchItem(forIndexPath indexPath: IndexPath) {
        tableView.scrollToRow(at: indexPath, at: .top, animated: true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard let cell = self.tableView.cellForRow(at: indexPath) as? UniverseDesignColorCell else { return }
            cell.shining()
        }
    }
}

var colorDataSource: [(String, [SampleColor])] = [
    ("Neutral", [
        SampleColor("N00", UIColor.ud.N00),
        SampleColor("N50", UIColor.ud.N50),
        SampleColor("N100", UIColor.ud.N100),
        SampleColor("N200", UIColor.ud.N200),
        SampleColor("N300", UIColor.ud.N300),
        SampleColor("N400", UIColor.ud.N400),
        SampleColor("N500", UIColor.ud.N500),
        SampleColor("N600", UIColor.ud.N600),
        SampleColor("N650", UIColor.ud.N650),
        SampleColor("N700", UIColor.ud.N700),
        SampleColor("N800", UIColor.ud.N800),
        SampleColor("N900", UIColor.ud.N900),
        SampleColor("N950", UIColor.ud.N950),
        SampleColor("N1000", UIColor.ud.N1000)
    ]), ("Red", [
        SampleColor("R50", UIColor.ud.R50),
        SampleColor("R100", UIColor.ud.R100),
        SampleColor("R200", UIColor.ud.R200),
        SampleColor("R300", UIColor.ud.R300),
        SampleColor("R400", UIColor.ud.R400),
        SampleColor("colorfulRed", UIColor.ud.colorfulRed),
        SampleColor("R600", UIColor.ud.R600),
        SampleColor("R700", UIColor.ud.R700),
        SampleColor("R800", UIColor.ud.R800),
        SampleColor("R900", UIColor.ud.R900)
    ]), ("Orange", [
        SampleColor("O50", UIColor.ud.O50),
        SampleColor("O100", UIColor.ud.O100),
        SampleColor("O200", UIColor.ud.O200),
        SampleColor("O300", UIColor.ud.O300),
        SampleColor("O400", UIColor.ud.O400),
        SampleColor("colorfulOrange", UIColor.ud.colorfulOrange),
        SampleColor("O600", UIColor.ud.O600),
        SampleColor("O700", UIColor.ud.O700),
        SampleColor("O800", UIColor.ud.O800),
        SampleColor("O900", UIColor.ud.O900)
    ]), ("Yellow", [
        SampleColor("Y50", UIColor.ud.Y50),
        SampleColor("Y100", UIColor.ud.Y100),
        SampleColor("Y200", UIColor.ud.Y200),
        SampleColor("Y300", UIColor.ud.Y300),
        SampleColor("Y400", UIColor.ud.Y400),
        SampleColor("colorfulYellow", UIColor.ud.colorfulYellow),
        SampleColor("Y600", UIColor.ud.Y600),
        SampleColor("Y700", UIColor.ud.Y700),
        SampleColor("Y800", UIColor.ud.Y800),
        SampleColor("Y900", UIColor.ud.Y900)
    ]), ("Sunflower", [
        SampleColor("S50", UIColor.ud.S50),
        SampleColor("S100", UIColor.ud.S100),
        SampleColor("S200", UIColor.ud.S200),
        SampleColor("S300", UIColor.ud.S300),
        SampleColor("S400", UIColor.ud.S400),
        SampleColor("colorfulSunflower", UIColor.ud.colorfulSunflower),
        SampleColor("S600", UIColor.ud.S600),
        SampleColor("S700", UIColor.ud.S700),
        SampleColor("S800", UIColor.ud.S800),
        SampleColor("S900", UIColor.ud.S900)
    ]), ("Lime", [
        SampleColor("L50", UIColor.ud.L50),
        SampleColor("L100", UIColor.ud.L100),
        SampleColor("L200", UIColor.ud.L200),
        SampleColor("L300", UIColor.ud.L300),
        SampleColor("L400", UIColor.ud.L400),
        SampleColor("colorfulLime", UIColor.ud.colorfulLime),
        SampleColor("L600", UIColor.ud.L600),
        SampleColor("L700", UIColor.ud.L700),
        SampleColor("L800", UIColor.ud.L800),
        SampleColor("L900", UIColor.ud.L900)
    ]), ("Green", [
        SampleColor("G50", UIColor.ud.G50),
        SampleColor("G100", UIColor.ud.G100),
        SampleColor("G200", UIColor.ud.G200),
        SampleColor("G300", UIColor.ud.G300),
        SampleColor("G400", UIColor.ud.G400),
        SampleColor("colorfulGreen", UIColor.ud.colorfulGreen),
        SampleColor("G600", UIColor.ud.G600),
        SampleColor("G700", UIColor.ud.G700),
        SampleColor("G800", UIColor.ud.G800),
        SampleColor("G900", UIColor.ud.G900)
    ]), ("Turquoise", [
        SampleColor("T50", UIColor.ud.T50),
        SampleColor("T100", UIColor.ud.T100),
        SampleColor("T200", UIColor.ud.T200),
        SampleColor("T300", UIColor.ud.T300),
        SampleColor("T400", UIColor.ud.T400),
        SampleColor("colorfulTurquoise", UIColor.ud.colorfulTurquoise),
        SampleColor("T600", UIColor.ud.T600),
        SampleColor("T700", UIColor.ud.T700),
        SampleColor("T800", UIColor.ud.T800),
        SampleColor("T900", UIColor.ud.T900)
    ]), ("Wathet", [
        SampleColor("W50", UIColor.ud.W50),
        SampleColor("W100", UIColor.ud.W100),
        SampleColor("W200", UIColor.ud.W200),
        SampleColor("W300", UIColor.ud.W300),
        SampleColor("W400", UIColor.ud.W400),
        SampleColor("colorfulWathet", UIColor.ud.colorfulWathet),
        SampleColor("W600", UIColor.ud.W600),
        SampleColor("W700", UIColor.ud.W700),
        SampleColor("W800", UIColor.ud.W800),
        SampleColor("W900", UIColor.ud.W900)
    ]), ("Blue", [
        SampleColor("B50", UIColor.ud.B50),
        SampleColor("B100", UIColor.ud.B100),
        SampleColor("B200", UIColor.ud.B200),
        SampleColor("B300", UIColor.ud.B300),
        SampleColor("B400", UIColor.ud.B400),
        SampleColor("colorfulBlue", UIColor.ud.colorfulBlue),
        SampleColor("B600", UIColor.ud.B600),
        SampleColor("B700", UIColor.ud.B700),
        SampleColor("B800", UIColor.ud.B800),
        SampleColor("B900", UIColor.ud.B900)
    ]), ("Indigo", [
        SampleColor("I50", UIColor.ud.I50),
        SampleColor("I100", UIColor.ud.I100),
        SampleColor("I200", UIColor.ud.I200),
        SampleColor("I300", UIColor.ud.I300),
        SampleColor("I400", UIColor.ud.I400),
        SampleColor("colorfulIndigo", UIColor.ud.colorfulIndigo),
        SampleColor("I600", UIColor.ud.I600),
        SampleColor("I700", UIColor.ud.I700),
        SampleColor("I800", UIColor.ud.I800),
        SampleColor("I900", UIColor.ud.I900)
    ]), ("Purple", [
        SampleColor("P50", UIColor.ud.P50),
        SampleColor("P100", UIColor.ud.P100),
        SampleColor("P200", UIColor.ud.P200),
        SampleColor("P300", UIColor.ud.P300),
        SampleColor("P400", UIColor.ud.P400),
        SampleColor("colorfulPurple", UIColor.ud.colorfulPurple),
        SampleColor("P600", UIColor.ud.P600),
        SampleColor("P700", UIColor.ud.P700),
        SampleColor("P800", UIColor.ud.P800),
        SampleColor("P900", UIColor.ud.P900)
    ]), ("Violet", [
        SampleColor("V50", UIColor.ud.V50),
        SampleColor("V100", UIColor.ud.V100),
        SampleColor("V200", UIColor.ud.V200),
        SampleColor("V300", UIColor.ud.V300),
        SampleColor("V400", UIColor.ud.V400),
        SampleColor("colorfulViolet", UIColor.ud.colorfulViolet),
        SampleColor("V600", UIColor.ud.V600),
        SampleColor("V700", UIColor.ud.V700),
        SampleColor("V800", UIColor.ud.V800),
        SampleColor("V900", UIColor.ud.V900)
    ]), ("Carmine", [
        SampleColor("C50", UIColor.ud.C50),
        SampleColor("C100", UIColor.ud.C100),
        SampleColor("C200", UIColor.ud.C200),
        SampleColor("C300", UIColor.ud.C300),
        SampleColor("C400", UIColor.ud.C400),
        SampleColor("colorfulCarmine", UIColor.ud.colorfulCarmine),
        SampleColor("C600", UIColor.ud.C600),
        SampleColor("C700", UIColor.ud.C700),
        SampleColor("C800", UIColor.ud.C800),
        SampleColor("C900", UIColor.ud.C900)
    ])
]

extension UIColor {
    func reversed() -> UIColor {
        var red: CGFloat   = 0.0
        var green: CGFloat = 0.0
        var blue: CGFloat  = 0.0
        var alpha: CGFloat = 0.0
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return UIColor(
            red: 1 - red,
            green: 1 - green,
            blue: 1 - blue,
            alpha: alpha
        )
    }
}
