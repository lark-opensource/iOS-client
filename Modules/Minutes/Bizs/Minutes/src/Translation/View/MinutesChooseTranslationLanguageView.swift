//
//  MinutesChooseTranslationLanguageView.swift
//  Minutes
//
//  Created by yangyao on 2021/2/26.
//

import UIKit
import MinutesFoundation
import UniverseDesignIcon
import FigmaKit

class MinutesChooseTranslationLanguageView: UIView {
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        let image = UDIcon.getIconByKey(.closeSmallOutlined, iconColor: UIColor.ud.iconN1, size: CGSize(width: 24, height: 24))
        button.setImage(image, for: .normal)
        button.addTarget(self, action: #selector(onBtnCancel), for: .touchUpInside)
        return button
    }()

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = BundleI18n.Minutes.MMWeb_G_SelectLanguage
        label.font = .systemFont(ofSize: 17)
        label.textColor = UIColor.ud.textTitle
        return label
    }()

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 0)
        tableView.layer.cornerRadius = 12
        tableView.isScrollEnabled = dataSource.count > 4
        tableView.register(MinutesChooseTranslationLanguageCell.self, forCellReuseIdentifier: MinutesChooseTranslationLanguageCell.description())
        tableView.backgroundColor = UIColor.ud.bgFloat
        return tableView
    }()

    private lazy var blurView: BackgroundBlurView = {
        let blurView = BackgroundBlurView()
        blurView.blurRadius = 24
        blurView.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.1)
        return blurView
    }()

    var cancelBlock: (() -> Void)?
    var selectBlock: ((MinutesTranslationLanguageModel) -> Void)?

    @objc func onBtnCancel() {
        cancelBlock?()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var dataSource: [MinutesTranslationLanguageModel] = []

    init(items: [MinutesTranslationLanguageModel], frame: CGRect) {
        super.init(frame: frame)

        self.dataSource = items
        self.backgroundColor = UIColor.ud.bgBody.withAlphaComponent(0.6)

        addSubview(blurView)
        updateMaskLayer()
        addSubview(titleLabel)
        addSubview(closeButton)
        addSubview(tableView)

        blurView.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.bottom.equalToSuperview()
        }

        titleLabel.snp.makeConstraints { (maker) in
            maker.centerX.equalToSuperview()
            maker.top.equalToSuperview().offset(14)
            maker.height.equalTo(24)
        }

        closeButton.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(6)
            maker.width.height.equalTo(34)
            maker.centerY.equalTo(titleLabel)
        }

        let sep1 = UIView()
        sep1.backgroundColor = UIColor.ud.lineDividerDefault
        addSubview(sep1)
        sep1.snp.makeConstraints { (maker) in
            maker.left.right.equalToSuperview()
            maker.top.equalTo(titleLabel.snp.bottom).offset(10)
            maker.height.equalTo(0.5)
        }

        tableView.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().offset(16)
            maker.right.equalToSuperview().inset(16)
            maker.top.equalTo(sep1.snp.bottom).offset(15.5)
            maker.height.equalTo(52 * dataSource.count)
        }
    }

    private func updateMaskLayer() {
        let maskPath = UIBezierPath(roundedRect: self.bounds,
                                    byRoundingCorners: [UIRectCorner.topRight, UIRectCorner.topLeft],
                                    cornerRadii: CGSize(width: 8, height: 8))
        let maskLayer = CAShapeLayer()
        maskLayer.frame = self.bounds
        maskLayer.path = maskPath.cgPath
        self.layer.mask = maskLayer
    }
}

extension MinutesChooseTranslationLanguageView: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 52
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MinutesChooseTranslationLanguageCell.description(), for: indexPath) as? MinutesChooseTranslationLanguageCell else {
            return UITableViewCell()
        }
        cell.titleLabel.text = dataSource[indexPath.row].language
        cell.titleLabel.textColor =
            dataSource[indexPath.row].isHighlighted ?
            UIColor.ud.primaryContentDefault :
            UIColor.ud.textTitle

        if indexPath.row == dataSource.count - 1 {
            cell.separatorInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: cell.bounds.width + 50)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let lang = dataSource[indexPath.row]
        selectBlock?(lang)
    }
}
