//
//  MinutesRecordLanguageChooseController.swift
//  Minutes
//
//  Created by yangyao on 2021/3/16.
//

import UIKit
import MinutesFoundation
import MinutesNetwork
import UniverseDesignShadow

class MinutesRecordLanguageChooseController: UIViewController {
    struct Layout {
        static let arrowHeight: CGFloat = 10
        static let tableViewWidth: CGFloat = 102
        static let tableViewItemHeight: CGFloat = 50
        static let cornerRadius: CGFloat = 8
    }

    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.register(MinutesRecordChooseTranslationLanguageCell.self, forCellReuseIdentifier: MinutesRecordChooseTranslationLanguageCell.description())
        tableView.separatorStyle = .none
        tableView.dataSource = self
        tableView.delegate = self
        tableView.bounces = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.showsVerticalScrollIndicator = false
        tableView.layer.cornerRadius = Layout.cornerRadius
        tableView.backgroundColor = UIColor.ud.bgFloat
#if swift(>=5.5)
        if #available(iOS 15.0, *) {
            tableView.sectionHeaderTopPadding = 0
        }
#endif
        tableView.layer.borderWidth = 1.0
        tableView.layer.ud.setBorderColor(UIColor.ud.lineBorderCard)
        return tableView
    }()

    init(items: [MinutesTranslationLanguageModel]) {
        self.dataSource = items
        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .custom
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var selectBlock: ((Language) -> Void)?
    var dismissBlock: (() -> Void)?
    var dataSource: [MinutesTranslationLanguageModel] = []
    var controlPositionInWindow: CGPoint = .zero

    override func viewDidLoad() {
        super.viewDidLoad()

        let bgView = UIView()

        view.addSubview(bgView)
        view.addSubview(arrowView)
        view.addSubview(tableView)
        view.layer.ud.setShadow(type: .s3Down)
        bgView.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }

        let pointInSelf = view.convert(controlPositionInWindow, from: nil)

        var maxLabelWidth: CGFloat = 74
        for lang in dataSource {
            let text = lang.language
            let textWidth = ceil(text.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: 20), options: .usesLineFragmentOrigin, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14)], context: nil).size.width)
            maxLabelWidth = textWidth > maxLabelWidth ? textWidth : maxLabelWidth
        }

        let margin: CGFloat = 28
        let tableViewWidth = maxLabelWidth + margin > Layout.tableViewWidth ? maxLabelWidth + margin : Layout.tableViewWidth
        let count = dataSource.count > 10 ? 10 : dataSource.count
        let tableViewHeight = Int(Layout.tableViewItemHeight) * count + 16
        tableView.snp.makeConstraints { (maker) in
            maker.bottom.equalToSuperview().inset(view.bounds.height - pointInSelf.y + Layout.arrowHeight + 8)
            maker.height.equalTo(tableViewHeight)
            maker.width.equalTo(tableViewWidth)
            maker.left.equalToSuperview().offset(pointInSelf.x)
        }

        arrowView.snp.makeConstraints { (maker) in
            maker.edges.equalTo(tableView)
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissSelf))
        bgView.addGestureRecognizer(tapGesture)
    }

    var maskLayer: CAShapeLayer?
    private lazy var arrowView: UIView = {
        let view = UIView()
        return view
    }()

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if maskLayer == nil {
            let maskPath = UIBezierPath(roundedRect: arrowView.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: Layout.cornerRadius, height: Layout.cornerRadius))

            maskLayer = CAShapeLayer()
            if let layer = maskLayer {
                arrowView.layer.insertSublayer(layer, at: 0)
                layer.path = maskPath.cgPath
            }
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        if #available(iOS 13.0, *) {
            if let ptc = previousTraitCollection, ptc.hasDifferentColorAppearance(comparedTo: traitCollection) {
                if traitCollection.userInterfaceStyle == .dark {
                    maskLayer?.removeFromSuperlayer()

                    let maskPath = UIBezierPath(roundedRect: arrowView.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: Layout.cornerRadius, height: Layout.cornerRadius))

                    maskLayer = CAShapeLayer()
                    if let layer = maskLayer {
                        arrowView.layer.insertSublayer(layer, at: 0)
                        layer.path = maskPath.cgPath
                    }
                } else {
                    maskLayer?.removeFromSuperlayer()

                    let maskPath = UIBezierPath(roundedRect: arrowView.bounds, byRoundingCorners: .allCorners, cornerRadii: CGSize(width: Layout.cornerRadius, height: Layout.cornerRadius))

                    maskLayer = CAShapeLayer()
                    if let layer = maskLayer {
                        arrowView.layer.insertSublayer(layer, at: 0)
                        layer.shadowOffset = CGSize(width: 0, height: 4)
                        layer.ud.setShadowColor(UIColor.ud.N900.withAlphaComponent(0.15))
                        layer.shadowOpacity = 1
                        layer.path = maskPath.cgPath
                    }
                }
            }
        }
    }

    @objc func dismissSelf() {
        dismissBlock?()
        dismiss(animated: false, completion: nil)
    }
}

extension MinutesRecordLanguageChooseController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let lang = dataSource[indexPath.row]
        selectBlock?(Language(name: lang.language, code: lang.code))

        dismiss(animated: false, completion: nil)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 8
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 8
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: MinutesRecordChooseTranslationLanguageCell.description(), for: indexPath) as? MinutesRecordChooseTranslationLanguageCell else {
            return UITableViewCell()
        }
        cell.titleLabel.text = dataSource[indexPath.row].language
        cell.titleLabel.textColor =
            dataSource[indexPath.row].isHighlighted ?
            UIColor.ud.primaryContentDefault:
            UIColor.ud.textTitle

        return cell
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}
