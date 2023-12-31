//
//  FormConditionController.swift
//  SKBitable
//
//  Created by X-MAN on 2023/5/18.
//

import Foundation
import SKFoundation
import SKCommon
import UniverseDesignColor

final class FormConditionController: UIViewController {
    
    enum SectionType: Int, CaseIterable {
        case conjunction
        case condition
        case add
    }
    
    var dismissBlock: (() -> Void)?
    
    private(set) var cellHeightCache: [String: CGFloat] = [:]
    private var model: FormConditionModel = FormConditionModel()
    private var context: BTDDUIContext?
    
    private lazy var titleView: FormConditionTitleView = {
        let view = FormConditionTitleView()
        return view
    }()
    
    private lazy var tableView: UITableView = {
        let tableV = UITableView(frame: .zero, style: .plain)
        tableV.backgroundColor = .clear
        tableV.delegate = self
        tableV.dataSource = self
        tableV.separatorStyle = .none
        tableV.contentInset = UIEdgeInsets(top: 16, left: 0, bottom: 16, right: 0)
        tableV.register(BTConditionSelectCell.self, forCellReuseIdentifier: BTConditionSelectCell.reuseIdentifier)
        tableV.register(BTConditionConjunctionCell.self, forCellReuseIdentifier: BTConditionConjunctionCell.reuseIdentifier)
        tableV.register(FormConditionAddCell.self, forCellReuseIdentifier: FormConditionAddCell.reuseIdentifier)
        return tableV
    }()
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UDColor.bgFloatBase
        setupUI()
    }
    
    private func setupUI() {
        view.addSubview(titleView)
        view.addSubview(tableView)
        titleView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(48)
        }
        tableView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
            make.top.equalTo(titleView.snp.bottom)
        }
    }
    
    func setData(model: FormConditionModel, with context: BTDDUIContext? = nil) {
        self.model = model
        if let context = context {
            self.context = context
        }
        if let titleModel = model.titleBar {
            titleView.setData(titleModel, with: context)
        }
        tableView.reloadData()
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        dismissBlock?()
        super.dismiss(animated: flag, completion: completion)
    }
    
}

extension FormConditionController: UIAdaptivePresentationControllerDelegate {
    func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
        self.dismissBlock?()
    }
}

extension FormConditionController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let sectionType = SectionType(rawValue: section)
        switch sectionType {
        case .conjunction?:
            return (model.conjunction != nil) ? 1 : 0
        case .condition?:
            return model.conditions?.count ?? 0
        case .add?:
            return 1
        case .none:
            return 0
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return SectionType.allCases.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let sectionType = SectionType(rawValue: indexPath.section)
        switch sectionType {
        case .conjunction?:
            let cell = tableView.dequeueReusableCell(withIdentifier: BTConditionConjunctionCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? BTConditionConjunctionCell, let conjuncion = model.conjunction {
                cell.setData(conjuncion)
                cell.didTapConjuctionButton = { [weak self] _ in
                    if let onClick = self?.model.conjunction?.center?.onClick {
                        self?.context?.emitEvent(onClick, args: [:])
                    }
                }
            }
            return cell
        case .condition?:
            let cell = tableView.dequeueReusableCell(withIdentifier: BTConditionSelectCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? BTConditionSelectCell {
                if let cellModel = model.conditions?[indexPath.row] {
                    cell.delegate = self
                    cell.setData(cellModel)
                    cell.isFirstCell = indexPath.row == 0
                    let height = cell.relayout()
                    cellHeightCache[cellModel.conditionId] = height
                }
                
            }
            return cell
        case .add?:
            let cell = tableView.dequeueReusableCell(withIdentifier: FormConditionAddCell.reuseIdentifier, for: indexPath)
            if let cell = cell as? FormConditionAddCell, let addCondition = model.addCondition {
                cell.setData(addCondition)
            }
            return cell
        case .none:
            return UITableViewCell()
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch SectionType(rawValue: indexPath.section) {
        case .conjunction?:
            return 52
        case .condition?:
            if let cellModel = self.model.conditions?[indexPath.row] {
                if let height = cellHeightCache[cellModel.conditionId] {
                    return height
                } else {
                    let height = BTConditionSelectCell.calculateCellHeight(with: cellModel.originModel,
                                                                           cellWith: tableView.frame.width,
                                                                           hasTopSpacing: indexPath.row != 0)
                    cellHeightCache[cellModel.conditionId] = height
                    return height
                }
            }
            return 0
        case .add:
            return 64
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        let sectionType = SectionType(rawValue: section)
        switch sectionType {
        case .conjunction?:
            let num = (model.conjunction != nil) ? 1 : 0
            return num != 0 ? 12 : 0.01
        case .condition?:
            let num =  model.conditions?.count ?? 0
            return num != 0 ? 12 : 0.01
        case .add?:
            return 0.01
        case .none:
            return 0.01
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        switch SectionType(rawValue: indexPath.section) {
        case .add?:
            if let callabckId = model.addCondition?.onClick {
                context?.emitEvent(callabckId, args: [:])
            }
        default:
            break
        }
    }
    
}

extension FormConditionController: BTConditionSelectCellDelegate {
    
    func didClickDelete(cell: UITableViewCell) {
        guard let index = tableView.indexPath(for: cell)?.row else {
            return
        }
        if let onClick = self.model.conditions?[index].rightIcon?.onClick {
            context?.emitEvent(onClick, args: [:])
        }
    }
    
    func didClickContainerButton(index: Int, cell: UITableViewCell, subCell: UICollectionViewCell?) {
        guard let cellIndex = tableView.indexPath(for: cell)?.row else {
            return
        }
        if let callbackId = self.model.conditions?[cellIndex].cells?[index].onClick {
            context?.emitEvent(callbackId, args: [:])
        }
    }
    
    func didClickRetry(index: Int, cell: UITableViewCell, subCell: UICollectionViewCell?) {
        
    }
    
}
