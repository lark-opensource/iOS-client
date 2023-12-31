//
//  LarkMenuFoldDetailView.swift
//  LarkSheetMenu
//
//  Created by liluobin on 2023/5/25.
//

import UIKit
import SnapKit
import FigmaKit
import UniverseDesignFont
import UniverseDesignIcon

class LarkMenuNavBar: UIView {
    private var backCallback: (() -> Void)?
    private let title: String

    init(title: String, backCallback: (() -> Void)?) {
        self.backCallback = backCallback
        self.title = title
        super.init(frame: .zero)
        setupView()
        self.backgroundColor = UIColor.ud.bgFloatBase
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        let label = UILabel()
        label.text = title
        label.textColor = UIColor.ud.textTitle
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        self.addSubview(label)

        let backBtn = UIButton()
        let icon = UDIcon.leftOutlined.ud.withTintColor(UIColor.ud.iconN3)
        backBtn.setImage(icon, for: .normal)
        self.addSubview(backBtn)
        backBtn.addTarget(self, action: #selector(tap), for: .touchUpInside)

        let line = UIView()
        self.addSubview(line)
        line.backgroundColor = UIColor.ud.lineDividerDefault

        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.left.lessThanOrEqualTo(backBtn.snp.right)
        }

        backBtn.snp.makeConstraints { make in
            make.left.equalTo(12)
            make.centerY.equalToSuperview()
            make.size.equalTo(CGSize(width: 28, height: 28))
        }

        line.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }
    }

    @objc
    func tap() {
        self.backCallback?()
    }
}

protocol FoldDetailViewProtocol: UIView {
    var contentHeight: CGFloat { get }
}

class LarkMenuFoldDetailView: UIView, UITableViewDelegate, UITableViewDataSource, FoldDetailViewProtocol {

    let foldItem: LarkSheetMenuActionItem
    var callBack: (() -> Void)?

    let barHeight: CGFloat = 52
    let itemHeight: CGFloat = 48

    var contentHeight: CGFloat {
        return barHeight + CGFloat(self.foldItem.subItems.count) * itemHeight
    }

    lazy var tableView: UITableView = {
        let view = InsetTableView()
        view.contentInsetAdjustmentBehavior = .never
        view.alwaysBounceHorizontal = false
        view.alwaysBounceVertical = false
        view.contentInset = .init(top: 0, left: 0, bottom: 14, right: 0)
        view.tableFooterView = UIView(frame: .zero)
        view.separatorColor = .ud.lineDividerDefault
        view.separatorInset = UIEdgeInsets(top: 0, left: 48, bottom: 0, right: 0)
        view.backgroundColor = .clear
        view.tableHeaderView = UIView(frame: CGRect(x: 0, y: 0, width: 0, height: 0.01))
        view.register(LarkSheetMenuCell.self, forCellReuseIdentifier: LarkSheetMenuCell.reuseIdentifier)
        return view
    }()

    init(foldItem: LarkSheetMenuActionItem, callBack: (() -> Void)?) {
        self.foldItem = foldItem
        self.callBack = callBack
        super.init(frame: .zero)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setupView() {
        let bar = LarkMenuNavBar(title: foldItem.text) { [weak self] in
            self?.callBack?()
        }
        self.addSubview(bar)
        bar.snp.makeConstraints { make in
            make.left.top.right.equalToSuperview()
            make.height.equalTo(barHeight)
        }
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = UIColor.clear
        self.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(bar.snp.bottom)
        }
        self.backgroundColor = UIColor.ud.bgFloatBase
    }

    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.foldItem.subItems.count
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return itemHeight
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: LarkSheetMenuCell.reuseIdentifier, for: indexPath)
                as? LarkSheetMenuCell else {
            return UITableViewCell()
        }
        guard self.foldItem.subItems.count > indexPath.row else {
            return UITableViewCell()
        }
        let item = self.foldItem.subItems[indexPath.row]
        cell.layer.cornerRadius = 10
        cell.setCell(item)
        return cell
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView(frame: .zero)
    }

    public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: .zero)
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 16
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
         return 0
    }
}

class LarkSheetMenuActionItemLayout {
    static let defaultHeight: CGFloat = 48
    static let textLeftMargin: CGFloat = 6
    static let textRightMargin: CGFloat = 2

    enum Style {
        case single(CGFloat)
        case double(CGFloat)

        var height: CGFloat {
            switch self {
            case .single(let height):
                return height
            case .double(let height):
                return height
            }
        }
    }

    static func layoutForItem(_ item: LarkSheetMenuActionItem, maxWidth: CGFloat) -> Style {
        guard !item.subItems.isEmpty, maxWidth > 0 else {
            return .single(defaultHeight)
        }
        /// 箭头右边距
        let arrowSpace: CGFloat = 16
        /// 箭头尺寸
        let arrowSize: CGSize = CGSize(width: 14, height: 14)
        /// 字体
        let textFont: UIFont = UIFont.systemFont(ofSize: 16)
        let subTextFont: UIFont = UIFont.systemFont(ofSize: 14)

        let textWidth = self.textWidth(item.text, font: textFont)
        let subTextWidth = self.textWidth(item.subText ?? "", font: subTextFont)

        if textWidth + subTextWidth + textRightMargin + textLeftMargin + arrowSize.width + arrowSpace > maxWidth {
            return .double(68)
        } else {
            return .single(48)
        }
    }

    static func textWidth(_ string: String, font: UIFont) -> CGFloat {
        if string.isEmpty { return 0 }
        let rect = (string as NSString).boundingRect(
            with: CGSize(width: CGFloat(MAXFLOAT), height: font.lineHeight + 2),
            options: .usesLineFragmentOrigin,
            attributes: [NSAttributedString.Key.font: font], context: nil)
        return rect.width
    }
}
