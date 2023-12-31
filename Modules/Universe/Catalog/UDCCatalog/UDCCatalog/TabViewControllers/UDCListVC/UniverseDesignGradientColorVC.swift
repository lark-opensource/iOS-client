//
//  UniverseDesignGradientColorVC.swift
//  UDCCatalog
//
//  Created by 白镜吾 on 2023/5/24.
//  Copyright © 2023 姚启灏. All rights reserved.
//

import UIKit
import UniverseDesignColor

class UniverseDesignGradientColorVC: UIViewController, UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: UDGradientColorCell.id) as? UDGradientColorCell {
            cell.setColor(title: dataSource[indexPath.row].0, color: dataSource[indexPath.row].1)
            return cell
        } else {
            return UITableViewCell(style: .default, reuseIdentifier: UDGradientColorCell.id)
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.showView.backgroundColor = dataSource[indexPath.row].1(self.showView.frame.size)
        UIView.animate(withDuration: 0.25, animations: {
            self.showView.alpha = 1
            self.maskView.alpha = 1
            self.maskView.isUserInteractionEnabled = true
        })
    }

    lazy var maskView: UIView = UIView()
    lazy var showView: UIView = UIView()

    lazy var dataSource: [(String, (CGSize) -> UIColor?)] = [
        ("AI-primary-fill-default", UDColor.AIPrimaryFillDefault),
        ("AI-primary-fill-hover", UDColor.AIPrimaryFillHover),
        ("AI-primary-fill-pressed", UDColor.AIPrimaryFillPressed),
        ("AI-primary-fill-loading", UDColor.AIPrimaryFillLoading),
        ("AI-primary-content-default", UDColor.AIPrimaryContentDefault),
        ("AI-primary-content-hover", UDColor.AIPrimaryContentHover),
        ("AI-primary-content-pressed", UDColor.AIPrimaryContentPressed),
        ("AI-primary-content-loading", UDColor.AIPrimaryContentLoading),
        ("AI-primary-fill-solid-01", UDColor.AIPrimaryFillSolid01),
        ("AI-primary-fill-solid-02", UDColor.AIPrimaryFillSolid02),
        ("AI-primary-fill-solid-03", UDColor.AIPrimaryFillSolid03),
        ("AI-primary-fill-transparent-01", UDColor.AIPrimaryFillTransparent01),
        ("AI-primary-fill-transparent-02", UDColor.AIPrimaryFillTransparent02),
        ("AI-primary-fill-transparent-03", UDColor.AIPrimaryFillTransparent03),
        ("AI-loading", UDColor.AILoading),
        ("AI-sendicon", UDColor.AISendicon),
        ("AI-dynamic-line", UDColor.AIDynamicLine)
    ]

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: self.view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 90
        tableView.separatorStyle = .none
        tableView.keyboardDismissMode = .onDrag
        tableView.contentInsetAdjustmentBehavior = .automatic
        tableView.register(UDGradientColorCell.self, forCellReuseIdentifier: UDGradientColorCell.id)
        return tableView
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "UniverseDesignGradientColorVC"
        self.view.addSubview(tableView)
        self.view.addSubview(maskView)
        self.view.addSubview(showView)
        tableView.snp.makeConstraints { make in
            make.width.equalTo(self.view.safeAreaLayoutGuide)
            make.top.equalToSuperview()
            make.bottom.equalToSuperview()
        }

        maskView.alpha = 0
        showView.alpha = 0
        maskView.backgroundColor = UIColor.ud.bgBase
        maskView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        showView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(150)
            make.center.equalToSuperview()
        }

        maskView.isUserInteractionEnabled = false
        showView.isUserInteractionEnabled = false
        let gest = UITapGestureRecognizer(target: self, action: #selector(closeMaskView(_:)))
        maskView.addGestureRecognizer(gest)
    }

    @objc
    func closeMaskView(_ sender: UIPanGestureRecognizer) {
        self.maskView.alpha = 0
        self.showView.alpha = 0
    }
}

class UDGradientColorCell: UITableViewCell {

    static var id = "UDGradientColorCell"

    var color: UIColor?
    var title: String?

    private lazy var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    private lazy var holderView: UIView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(label)
        contentView.addSubview(holderView)
        label.textAlignment = .left
        self.selectionStyle = .none

        label.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.right.equalTo(holderView.snp.left).offset(-16)
        }

        holderView.snp.makeConstraints { make in
            make.width.equalTo(160)
            make.height.equalTo(70)
            make.centerY.equalToSuperview()
            make.right.equalToSuperview().offset(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setColor(title: String, color: (CGSize) -> UIColor?) {
        self.label.text = title
        self.title = title
        holderView.layoutIfNeeded()
        self.holderView.backgroundColor = color(holderView.frame.size)
        self.color = holderView.backgroundColor
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.title = nil
        self.label.text = nil
        self.holderView.backgroundColor = nil
        self.color = nil
    }
}
