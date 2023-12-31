//
//  SCDebugSectionView.swift
//  SecurityComplianceDebug
//
//  Created by ByteDance on 2023/11/28.
//

import Foundation

final class SCDebugSectionView: UIView {
    private let tableView = SCDebugTableView(frame: .zero)
    private let debugModels: [SCDebugModel]
    init(model: [SCDebugModel]) {
        self.debugModels = model
        super.init(frame: .zero)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SCDebugViewCell.self, forCellReuseIdentifier: "SCDebugViewCell")
        addSubview(tableView)

        tableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension SCDebugSectionView: UITableViewDataSource, UITableViewDelegate {    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SCDebugViewCell") as? SCDebugViewCell else {
            return UITableViewCell()
        }
        let model = debugModels[indexPath.row]
        cell.configModel(model: model)
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        debugModels.count
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = debugModels[indexPath.row]
        model.handleClick()
    }
}
