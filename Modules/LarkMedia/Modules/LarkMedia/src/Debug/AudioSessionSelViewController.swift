//
//  AudioSessionSelViewController.swift
//  AudioSessionScenario
//
//  Created by ford on 2020/6/11.
//

import Foundation

class AudioSessionSelViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    enum SelectMode {
        case single
        case multiple
    }

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height), style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        return tableView
    }()

    var selectMode: SelectMode = .single

    var selectedItems: [String]

    var optionalItems: [String]
    
    let onCompleted: ([String]) -> ()

    // 当选择interruptSpokenAudioAndMixWithOthers时optional会自动带上mixWithOthers，此处需要保持独立性
    var transferredOptionalItems: [String] {
        return optionalItems.map {
            if $0 == "interruptSpokenAudioAndMixWithOthers|mixWithOthers" {
                return "interruptSpokenAudioAndMixWithOthers"
            } else {
                return $0
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
    }

    init(mode: SelectMode,
         selectedItems: [String],
         optionalItems: [String],
         onCompleted: @escaping ([String]) -> ()) {
        self.selectMode = mode
        self.selectedItems = selectedItems
        self.optionalItems = optionalItems
        self.onCompleted = onCompleted
        super.init(nibName: nil, bundle: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        self.onCompleted(selectedItems)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return optionalItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        cell.textLabel?.text = transferredOptionalItems[indexPath.row]
        if selectedItems.contains(transferredOptionalItems[indexPath.row]) {
            cell.accessoryType = .checkmark
            tableView.selectRow(at: indexPath, animated: true, scrollPosition: .none)
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        if selectMode == .single {
            selectedItems.removeAll()
            selectedItems.append(transferredOptionalItems[indexPath.row])
            cell.accessoryType = .checkmark
        } else if selectMode == .multiple {
            if cell.accessoryType == .none {
                selectedItems.append(transferredOptionalItems[indexPath.row])
                cell.accessoryType = .checkmark
            } else if cell.accessoryType == .checkmark {
                selectedItems.removeAll(where: { (item) -> Bool in
                    item == transferredOptionalItems[indexPath.row]
                })
                cell.accessoryType = .none
            }
        }
    }

    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        guard selectMode == .single else { return }
        guard let cell = tableView.cellForRow(at: indexPath) else { return }
        selectedItems.removeAll { (item) -> Bool in
            item == transferredOptionalItems[indexPath.row]
        }
        cell.accessoryType = .none
    }
}

class KeyValueSelViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    weak var refObj: NSObject?

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height), style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
        return tableView
    }()

    private var counter: UInt = 0

    var cellItems: [(String, String?)] = []
    let onCompleted: ((String, String)?) -> ()

    var result: (String, String)?

    init(cellItems: [String],
         refObj: NSObject?,
         onCompleted: @escaping ((String, String)?) -> ()) {
        self.refObj = refObj
        self.onCompleted = onCompleted
        super.init(nibName: nil, bundle: nil)
        NSExceptionCatcher.async {
            for key in cellItems {
                if let value = self.refObj?.value(forKey: key) {
                    self.cellItems.append((key, String(describing: value)))
                } else {
                    self.cellItems.append((key, nil))
                }
            }
            DispatchQueue.main.async {
                self.tableView.reloadData()
            }
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(tableView)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.onCompleted(self.result)
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cellItems.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: UITableViewCell = UITableViewCell(style: .subtitle, reuseIdentifier: "UITableViewCell")
        let item = cellItems[indexPath.row]
        cell.textLabel?.text = item.0
        cell.detailTextLabel?.text = item.1
        cell.detailTextLabel?.numberOfLines = 0
        return cell
    }

    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        true
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .insert
    }

    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let action: UITableViewRowAction = .init(style: .normal, title: "编辑") { [weak self] _, indexPath in
            if let key = self?.cellItems[indexPath.row].0 {
                let alert = UIAlertController(title: key, message: "", preferredStyle: .alert)
                alert.addTextField()
                alert.addAction(UIAlertAction(title: "设置", style: .default, handler: { [weak alert] _ in
                    guard let text = alert?.textFields?.first?.text else {
                        return
                    }
                    NSExceptionCatcher.async {
                        self?.refObj?.setValue(text, forKey: key)
                    }
                }))
                alert.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
                self?.present(alert, animated: true)
            }
        }
        action.backgroundColor = .lightGray

        let action2: UITableViewRowAction = .init(style: .normal, title: "跳转") { [weak self] _, indexPath in
            if let key = self?.cellItems[indexPath.row].0 {
                NSExceptionCatcher.async {
                    if let value = self?.refObj?.value(forKey: key) as? NSObject {
                        let list = AudioSessionDebugViewController.getPropertyList(value.classForCoder)
                        let vc = KeyValueSelViewController(cellItems: list, refObj: self?.refObj) { [weak self] result in
                            self?.result = result
                        }
                        DispatchQueue.main.async {
                            self?.navigationController?.pushViewController(vc, animated: true)
                        }
                    }
                }
            }
        }
        action2.backgroundColor = .lightGray
        return [action, action2]
    }
}
