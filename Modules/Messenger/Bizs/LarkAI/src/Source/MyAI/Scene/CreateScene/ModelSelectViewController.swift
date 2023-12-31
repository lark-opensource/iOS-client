//
//  ModelSelectViewController.swift
//  LarkAI
//
//  Created by Zigeng on 2023/10/16.
//

import Foundation
import ServerPB
import UniverseDesignCheckBox

struct AgentModel {
    let name: String
    let id: String
}

struct AgentModelSection {
    let name: String?
    let models: [AgentModel]
}

/// 场景编辑页面的模型选择列表
class ModelSelectViewController: UIViewController {
    private var selectedModel: AgentModel? {
        didSet {
            customNavigationBar.confirmIsEnable = (selectedModel != nil)
        }
    }
    private let dataSource: [AgentModelSection]
    private lazy var tableView = UITableView(frame: .zero, style: .grouped)
    private var confirmAction: (AgentModel) -> Void
    private lazy var customNavigationBar = SceneDetailNavBar(title: BundleI18n.LarkAI.MyAI_Scenario_SelectModel_Mobile_Title,
                                                             confirmText: BundleI18n.LarkAI.MyAI_Scenario_SelectModel_Done_Mobile_Button,
                                                             confirmAction: { [weak self] in
                                                                guard let self = self, let model = self.selectedModel else { return }
                                                                self.confirmAction(model)
                                                                self.dismiss(animated: true)
                                                            },
                                                             cancelAction: { [weak self] in
                                                                self?.dismiss(animated: true)
                                                            })

    init(_ dataSource: [AgentModelSection], selectedModel: AgentModel?, confirmAction: @escaping (AgentModel) -> Void) {
        self.dataSource = dataSource
        self.selectedModel = selectedModel
        self.confirmAction = confirmAction
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .pageSheet
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        customNavigationBar.confirmIsEnable = (selectedModel != nil)
        view.addSubview(customNavigationBar)
        customNavigationBar.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.height.equalTo(60)
            make.left.right.equalToSuperview()
        }
        customNavigationBar.backgroundColor = .ud.bgBody
        view.addSubview(tableView)
        tableView.backgroundColor = .ud.bgBody
        tableView.register(ModelSelectViewCell.self, forCellReuseIdentifier: ModelSelectViewCell.identifier)
        tableView.separatorStyle = .none
        tableView.rowHeight = 48
        tableView.delegate = self
        tableView.dataSource = self
        tableView.snp.makeConstraints { make in
            make.top.equalTo(customNavigationBar.snp.bottom)
            make.bottom.equalToSuperview()
            make.width.equalToSuperview()
        }
        tableView.reloadData()
        view.backgroundColor = .ud.bgBody
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension ModelSelectViewController: UITableViewDataSource {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section <= dataSource.count else { return 0 }
        return dataSource[section].models.count
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard indexPath.section < dataSource.count, indexPath.row < dataSource[indexPath.section].models.count else { return UITableViewCell() }
        let model = dataSource[indexPath.section].models[indexPath.row]
        if let cell = tableView.dequeueReusableCell(withIdentifier: ModelSelectViewCell.identifier) as? ModelSelectViewCell {
            cell.setCell(name: model.name, selected: model.id == selectedModel?.id)
            return cell
        } else {
            return UITableViewCell()
        }
    }

    public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        guard section <= dataSource.count else { return .leastNonzeroMagnitude }
        guard dataSource[section].name != nil else { return .leastNonzeroMagnitude }
        return 44.0
    }

    public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard section <= dataSource.count else { return UIView() }
        guard let name = dataSource[section].name else { return UIView() }
        // 设置zero即可，tableView会把contentView的宽设置为tableView的宽，高设置为heightForHeaderInSection返回的高
        let contentView = UIView(frame: .zero)
        let label = UILabel(); label.textColor = .ud.textCaption; label.font = .systemFont(ofSize: 14); label.text = name
        contentView.addSubview(label)
        label.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(20)
            make.left.equalTo(16)
            make.bottom.equalTo(-4)
            make.right.equalTo(-16)
        }
        return contentView
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return .leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
}

extension ModelSelectViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        guard indexPath.section < dataSource.count, indexPath.row < dataSource[indexPath.section].models.count else { return }
        let model = dataSource[indexPath.section].models[indexPath.row]
        self.selectedModel = model
        tableView.reloadData()
    }
}

class ModelSelectViewCell: UITableViewCell {
    static let identifier = "ModelSelectViewCell"
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let containerView = UIView()
        self.contentView.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.width.equalToSuperview()
        }
        containerView.addSubview(checkbox)
        checkbox.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
        }
        containerView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { make in
            make.centerY.equalToSuperview()
            make.left.equalTo(checkbox.snp.right).offset(12)
            make.right.equalToSuperview().offset(-16)
        }
        containerView.addSubview(line)
        line.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(1)
            make.right.equalToSuperview()
            make.bottom.equalToSuperview()
        }
        self.backgroundColor = .clear
        selectionStyle = .none // 去掉点击高亮效果
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    lazy var nameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    lazy var checkbox: UDCheckBox = {
        let checkBox = UDCheckBox()
        // 响应整个Cell的点击
        checkBox.isUserInteractionEnabled = false
        return checkBox
    }()

    lazy var line: UIView = {
        let view = UIView()
        view.backgroundColor = .ud.lineBorderCard
        view.alpha = 0.6
        return view
    }()

    override func prepareForReuse() {
        super.prepareForReuse()
        nameLabel.text = nil
        self.checkbox.isSelected = false
    }

    func setCell(name: String, selected: Bool) {
        self.nameLabel.text = name
        self.checkbox.isSelected = selected
    }
}
