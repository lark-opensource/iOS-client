//
//  DemoVC+Container.swift
//  SCDemo
//
//  Created by qingchun on 2022/9/16.
//

import UIKit
import LarkUIKit
import LarkContainer
import EENavigator
import LarkDebug
import LarkSecurityCompliance
import SecurityComplianceDebug
import LarkSecurityComplianceInfra

private let cellID = "UITableViewCell"

extension DemoVC {
    final class Container: UIView, UITableViewDelegate, UITableViewDataSource {
        private lazy var tableView: UITableView = {
            let tblV: UITableView
            if #available(iOS 13.0, *) {
                tblV = UITableView(frame: CGRect(x: 0, y: 0, width: 200, height: 100), style: .insetGrouped)
            } else {
                tblV = UITableView(frame: CGRect(x: 0, y: 0, width: 200, height: 100), style: .grouped)
            }
            tblV.delegate = self
            tblV.dataSource = self
            tblV.register(SCDebugViewCell.self, forCellReuseIdentifier: cellID)
            let insets = LayoutConfig.currentWindow?.safeAreaInsets ?? .zero
            tblV.contentInset = UIEdgeInsets(top: insets.top, left: 0, bottom: insets.bottom, right: 0)
            return tblV
        }()
        
        let userResolver: UserResolver
        let debugEntrance: SCDebugEntrance
        let sections = SCDebugSectionType.allCases

        init(userResolver: UserResolver, frame: CGRect) throws {
            self.userResolver = userResolver
            self.debugEntrance = try userResolver.resolve(assert: SCDebugEntrance.self)
            super.init(frame: frame)
            setupDebugEntrance()
            addSubview(tableView)
            tableView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        
        required init?(coder: NSCoder) {
            return nil
        }

        func setupDebugEntrance() {
            debugEntrance.config()
            debugEntrance.registRedirectorForSection(section: .debugEntrance, redirectBlock: { _, _ in
                guard let vc = self.userResolver.navigator.mainSceneWindow else { return }
                self.userResolver.navigator.present( // Global
                    body: DebugBody(),
                    wrap: LkNavigationController.self,
                    from: vc,
                    prepare: { $0.modalPresentationStyle = .fullScreen }
                )
            })
        }

        // 返回单元格行数
        func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
            sections.count
        }
        
        // 配置并返回单元格
        func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
            let model = sections[indexPath.row]
            cell.textLabel?.text = model.name
            return cell
        }
        
        // MARK: UITableViewDelegate Method
        // 选中单元格时触发对应的调试页面跳转事件
        func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
            tableView.deselectRow(at: indexPath, animated: true)
            let section = sections[indexPath.row]
            let sectionViewModels = debugEntrance.generateSectionViewModels(section: section)
            let redirector = debugEntrance.generateRedirectorForSection(section: section)
            redirector(sectionViewModels, section.name)
        }
    }
}
