//
//  WhiteboardMoreViewController.swift
//  Whiteboard
//
//  Created by helijian on 2022/12/5.
//

import Foundation
import UIKit
import ByteViewUI
import UniverseDesignIcon
import UniverseDesignColor
import SnapKit
import ByteViewCommon

protocol WhiteboardMoreItemBaseProtocol {
    var cellIdentifier: String { get }
    var title: String { get }
}

struct WhiteboardMoreSectionModel {
    var items: [WhiteboardMoreItemBaseProtocol] = []
    var headerText: String = ""
    var footerText: String = ""
    init(items: [WhiteboardMoreItemBaseProtocol] = [], headerText: String = "", footerText: String = "") {
        self.items = items
        self.headerText = headerText
        self.footerText = footerText
    }
}

class WhiteboardMoreBaseCell: UITableViewCell {
    var item: WhiteboardMoreItemBaseProtocol? {
        didSet {
            configCell()
        }
    }

    func configCell() {
        assert(false, "no override inherit empty function")
    }
}

// MARK: 多白板Cell
struct WhiteboardMorePresentModel: WhiteboardMoreItemBaseProtocol {
    var cellIdentifier: String
    var title: String
    var action: ((UIViewController?) -> Void)?
}

class WhiteboardMorePageCell: WhiteboardMoreBaseCell {
    private lazy var cellIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.getIconByKey(.multiBoardOutlined, iconColor: UDColor.iconN3, size: CGSize(width: 20, height: 20))
        return imageView
    }()

    private lazy var rightArrow: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UDIcon.getIconByKey(.hideToolbarOutlined, iconColor: UDColor.iconN3, size: CGSize(width: 12, height: 12))
        return imageView
    }()

    private let titleLabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.ud.bgFloat
        contentView.addSubview(cellIcon)
        cellIcon.snp.makeConstraints { (maker) in
            maker.left.equalToSuperview().inset(16)
            maker.centerY.equalToSuperview()
            maker.size.equalTo(CGSize(width: 20, height: 20))
        }
        contentView.addSubview(rightArrow)
        rightArrow.snp.makeConstraints { maker in
            maker.right.equalToSuperview().inset(16)
            maker.size.equalTo(CGSize(width: 12, height: 12))
            maker.centerY.equalToSuperview()
        }
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.left.equalTo(cellIcon.snp.right).offset(12)
            maker.centerY.equalToSuperview()
            maker.right.lessThanOrEqualTo(rightArrow.snp.left).offset(-16)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configCell() {
        guard let item = self.item as? WhiteboardMorePresentModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.attributedText = NSAttributedString(string: item.title, config: .body)
    }
}

// MARK: 清除内容Cell
struct WhiteboardMoreDetailModel: WhiteboardMoreItemBaseProtocol {
    var cellIdentifier: String
    var title: String
    var isLastModel: Bool
    var clickHandler: (() -> Void)
}

class WhiteboardMoreDetailCell: WhiteboardMoreBaseCell {
    private let titleLabel = UILabel()
    private let splitLine = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.ud.bgFloat
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview().inset(16)
            maker.centerY.equalToSuperview()
        }
        contentView.addSubview(splitLine)
        splitLine.backgroundColor = UIColor.ud.lineDividerDefault
        splitLine.snp.makeConstraints { maker in
            maker.bottom.equalToSuperview()
            maker.left.right.equalToSuperview().inset(8)
            maker.height.equalTo(0.5)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func configCell() {
        guard let item = self.item as? WhiteboardMoreDetailModel else {
            assert(false, "\(self):item.Type error")
            return
        }
        titleLabel.attributedText = NSAttributedString(string: item.title, config: .body)
        splitLine.isHidden = item.isLastModel
    }
}

// MARK: 白板 More VC
final class WhiteboardMoreViewController: UIViewController {
    private var items: [WhiteboardMoreSectionModel] = []

    private lazy var tableView: UITableView = {
        let tableView = BaseGroupedTableView()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 48
        tableView.showsVerticalScrollIndicator = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = UITableView.automaticDimension
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.contentInsetAdjustmentBehavior = .never
        registerCells(tableView)
        return tableView
    }()

    private lazy var line: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault.withAlphaComponent(0.15)
        return line
    }()

    private lazy var closeButton: UIBarButtonItem = {
        let imgKey: UniverseDesignIcon.UDIconType = .closeSmallOutlined
        let color = UIColor.ud.iconN1
        let actionButton = UIButton()
        actionButton.setImage(UDIcon.getIconByKey(imgKey, iconColor: color, size: CGSize(width: 24, height: 24)), for: .normal)
        actionButton.addTarget(self, action: #selector(dismissAction), for: .touchUpInside)
        return UIBarButtonItem(customView: actionButton)
    }()

    init(items: [WhiteboardMoreSectionModel]) {
        self.items = items
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = BundleI18n.Whiteboard.View_G_More
        view.backgroundColor = UIColor.ud.bgBase

        navigationController?.navigationBar.backgroundColor = UIColor.ud.bgFloatBase
        navigationItem.setLeftBarButton(closeButton, animated: false)

        view.addSubview(tableView)
        tableView.snp.makeConstraints { maker in
            maker.left.right.equalToSuperview()
            maker.top.equalToSuperview()
            maker.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
        }
        view.addSubview(line)
        line.snp.makeConstraints {
            $0.left.right.top.equalToSuperview()
            $0.height.equalTo(1 / view.vc.displayScale)
        }
        if Display.phone {
            NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange),
                name: UIApplication.didChangeStatusBarOrientationNotification, object: nil)
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setNavigationBarBgColor(UIColor.ud.bgBase)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    private func setNavigationBarBgColor(_ bgColor: UIColor) {
        let specializedNavigationBarStyle = ByteViewNavigationBarStyle.generateCustomStyle(.light, bgColor: bgColor)
        guard let nav = navigationController, nav == self.parent else { return }
        nav.vc.updateBarStyle(specializedNavigationBarStyle)
    }

    private func registerCells(_ tableView: UITableView) {
        tableView.register(WhiteboardMorePageCell.self, forCellReuseIdentifier: WhiteboardMorePageCell.description())
        tableView.register(WhiteboardMoreDetailCell.self, forCellReuseIdentifier: WhiteboardMoreDetailCell.description())
    }

    func setItems(items: [WhiteboardMoreSectionModel]) {
        self.items = items
    }

    @objc func dismissAction() {
        self.presentingViewController?.dismiss(animated: true)
    }

    @objc private func orientationDidChange() {
        guard let panVC = navigationController?.panViewController else {
            return
        }
        panVC.updateBelowLayout()
    }
}

extension WhiteboardMoreViewController: DynamicModalDelegate {
    func regularCompactStyleDidChange(isRegular: Bool) {
    }
}

extension WhiteboardMoreViewController: PanChildViewControllerProtocol {

    public var panScrollable: UIScrollView? {
        return nil
    }

    public var showDragIndicator: Bool {
        return false
    }

    public var showBarView: Bool {
        return false
    }

    func height(_ axis: RoadAxis, layout: RoadLayout) -> PanHeight {
        var contentHeight: CGFloat = CGFloat((items.count - 1) * 44) + 16.0
        for item in items {
            contentHeight += CGFloat(48 * item.items.count)
        }
        let allHeight = contentHeight + (navigationController?.navigationBar.frame.size.height ?? 0)
        let top: CGFloat = self.view.isPhoneLandscape ? 8 : 44
        return .contentHeight(allHeight, minTopInset: top)
    }

    func width(_ axis: RoadAxis, layout: RoadLayout) -> PanWidth {
        if Display.phone, axis == .landscape {
            return .maxWidth(width: 420)
        }
        return .fullWidth
    }
}

extension WhiteboardMoreViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.items.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section >= self.items.count { return 0 }
        return self.items[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section >= self.items.count || indexPath.row >= self.items[indexPath.section].items.count {
            return UITableViewCell()
        }
        let item: WhiteboardMoreItemBaseProtocol = self.items[indexPath.section].items[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier, for: indexPath) as? WhiteboardMoreBaseCell {
            cell.item = item
            return cell
        }
        return UITableViewCell()
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section < self.items.count else { return .leastNonzeroMagnitude }
        if section == 0 {
            return 16.0
        } else if self.items[section].headerText.isEmpty {
            return 20.0
        } else {
            return 44.0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section < self.items.count else { return nil }
        let model = self.items[section]
        return createHeadView(title: model.headerText)
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return nil
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard indexPath.section < self.items.count,
            indexPath.row < self.items[indexPath.section].items.count else {
            return
        }
        if let item = items[indexPath.section].items[indexPath.row] as? WhiteboardMoreDetailModel {
            item.clickHandler()
            self.dismissAction()
        }
        if let item = items[indexPath.section].items[indexPath.row] as? WhiteboardMorePresentModel {
            item.action?(self)
        }
    }

    private func createHeadView(title: String) -> UIView? {
        let headerView: UIView = UIView()
        headerView.backgroundColor = UIColor.clear
        if !title.isEmpty {
            let headerLabel = UILabel()
            headerLabel.textAlignment = .left
            headerLabel.font = UIFont.systemFont(ofSize: 14.0, weight: .regular)
            headerLabel.textColor = UIColor.ud.textPlaceholder
            headerLabel.numberOfLines = 0
            headerLabel.text = title
            headerView.addSubview(headerLabel)
            headerLabel.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview().inset(16)
                make.bottom.equalTo(-4)
            }
        }
        return headerView
    }
}
