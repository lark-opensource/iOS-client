import UIKit
import EENavigator
import LarkDebugExtensionPoint

class PassportDebugViewController: UIViewController {

    let tableView = UITableView(frame: .zero, style: .plain)

    let data: [(SectionType, [DebugCellItem])] = SectionType.allCases.compactMap { (SectionType) in
        if let items = PassportDebugCellItemRegistries[SectionType], !items.isEmpty {
            return (SectionType, items.map { $0() })
        } else {
            return nil
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Passport 调试"
        tableView.register(PassportDebugTableViewCell.self, forCellReuseIdentifier: "PassportDebugTableViewCell")
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        EnvInfoManager.shared.envInfoManagerDelegate = self
    }
}

// MARK: - UITableViewDataSource
extension PassportDebugViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return data.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return data[section].1.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "PassportDebugTableViewCell"
        ) as? PassportDebugTableViewCell else {
            return UITableViewCell()
        }

        cell.setItem(data[indexPath.section].1[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        let item = data[indexPath.section].1[indexPath.row]
        return item.canPerformAction != nil
    }

    func tableView(
        _ tableView: UITableView,
        canPerformAction action: Selector,
        forRowAt indexPath: IndexPath,
        withSender sender: Any?
    ) -> Bool {
        let item = data[indexPath.section].1[indexPath.row]
        return item.canPerformAction?(action) ?? false
    }

    func tableView(
        _ tableView: UITableView,
        performAction action: Selector,
        forRowAt indexPath: IndexPath,
        withSender sender: Any?
    ) {
        let item = data[indexPath.section].1[indexPath.row]
        item.perfomAction?(action)
    }
}

// MARK: - UITableViewDelegate
extension PassportDebugViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        tableView.deselectRow(at: indexPath, animated: true)
        let item = data[indexPath.section].1[indexPath.row]
        item.didSelect(item, debugVC: self)
    }
}

extension PassportDebugViewController: EnvInfoManagerDelegate {
    func updateButtonStatus() {
        tableView.reloadData()
    }
}
