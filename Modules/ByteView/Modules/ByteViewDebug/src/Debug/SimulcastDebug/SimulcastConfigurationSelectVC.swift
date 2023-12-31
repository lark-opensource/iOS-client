//
// Created by liujianlong on 2022/10/18.
//

import UIKit
import ByteView
import UniverseDesignToast
import SnapKit
import ByteViewSetting

extension MultiResPhoneSubscribeConfig {
    var subscribeInfo: [String] {
        var lines: [String] = []
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let val = child.value as? ByteViewSetting.MultiResSubscribeResolution {
                lines.append("\(child.label): \(val)")
            }
        }
        return lines
    }
}

extension MultiResPadSubscribeConfig {
    var subscribeInfo: [String] {
        var lines: [String] = []
        let mirror = Mirror(reflecting: self)
        for child in mirror.children {
            if let val = child.value as? ByteViewSetting.MultiResSubscribeResolution {
                lines.append("\(child.label): \(val)")
            }
            if let val = child.value as? [MultiResPadGallerySubscribeRule] {
                for rule in val {
                    if rule.roomOrSip != 0 {
                        lines.append("room gallery: \(rule.max), \(rule.conf)")
                    } else {
                        lines.append("gallery: \(rule.max), \(rule.conf)")
                    }
                }
            }
        }
        return lines
    }
}

final class SimulcastConfigurationDetailVC: UIViewController {
    private let config: MultiResolutionConfig
    private var publish: MultiResPublishConfig {
        UIDevice.current.userInterfaceIdiom == .pad ? config.pad.publish : config.phone.publish
    }
    private var subscribeLines = [String]()
    private let sections: [String] = [
        "Publish",
        "Subscribe"
    ]
    private lazy var tableView = UITableView(frame: .zero, style: .grouped)

    init(config: MultiResolutionConfig) {
        self.config = config
        if UIDevice.current.userInterfaceIdiom == .pad {
            self.subscribeLines = config.pad.subscribe.subscribeInfo
        } else {
            self.subscribeLines = config.phone.subscribe.subscribeInfo
        }
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        return nil
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()

    }
    private func setupSubviews() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        tableView.dataSource = self
        tableView.delegate = self
    }
}

extension SimulcastConfigurationDetailVC: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.sections.count
    }

    public func tableView(_ tableView: UITableView, shouldHighlightRowAt indexPath: IndexPath) -> Bool {
        return false
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sections[section]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return self.publish.channel.count
        default:
            return self.subscribeLines.count
        }
    }

    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        let text: String
        switch indexPath.section {
        case 0:
            text = "\(self.publish.channel[indexPath.row])"
        default:
            text = subscribeLines[indexPath.row]
        }
        cell.textLabel?.text = text
        return cell
    }
}

final class SimulcastConfigurationSelectVC: UIViewController {
    typealias CfgItem = (name: String, cfg: MultiResolutionConfig)
    private func loadSimulcastConfigurations() {
        guard let bundleURL = Bundle.main.url(forResource: "ByteViewSimulcastConfigs", withExtension: "bundle"),
              let enumerator = try? FileManager.default.subpathsOfDirectory(atPath: bundleURL.path) else {
            return
        }
        var cfgs = [CfgItem]()
        for absPath in enumerator {
            let url = URL(fileURLWithPath: absPath, relativeTo: bundleURL)
            if url.pathExtension == "json",
               let data = try? Data(contentsOf: url) {
                let decoder = JSONDecoder()
                decoder.keyDecodingStrategy = .convertFromSnakeCase
                if let cfg = try? decoder.decode(MultiResolutionConfig.self, from: data) {
                    cfgs.append((url.lastPathComponent, cfg))
                }
            }
        }
        reloadData(items: cfgs)
    }

    private func reloadData(items: [CfgItem]) {
        self.cfgItems = items
        self.tableView.reloadData()
    }

    private lazy var tableView = UITableView(frame: .zero, style: .grouped)
    private var cfgItems = [CfgItem]()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
        loadSimulcastConfigurations()
    }

    private func setupSubviews() {
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.view.addSubview(self.tableView)
        self.tableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.reloadData()
    }
}

extension SimulcastConfigurationSelectVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
           return 1
        }
        return cfgItems.count
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "下发配置"
        }
        return "自定义配置"
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.accessoryType = .detailButton
        if indexPath.section == 0 {
            cell.textLabel?.text = "默认多分辨率配置"
        } else {
            cell.textLabel?.text = cfgItems[indexPath.row].name
        }
        return cell
    }

    func tableView(_ tableView: UITableView, accessoryButtonTappedForRowWith indexPath: IndexPath) {
        guard let setting = DebugConfig.shared.setting else { return }
        let vc: UIViewController
        if indexPath.section == 0 {
            vc = SimulcastConfigurationDetailVC(config: setting.multiResolutionConfig)
        } else {
            let cfg = self.cfgItems[indexPath.row].cfg
            DebugSettings.multiResolutionConfig = cfg
            vc = SimulcastConfigurationDetailVC(config: cfg)
        }
        vc.modalPresentationStyle = .pageSheet
        self.present(vc, animated: true)

    }

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let setting = DebugConfig.shared.setting else { return }
        if indexPath.section == 0 {
            DebugSettings.multiResolutionConfig = nil
            if let view = self.view.window {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    UDToast.showTips(with: "重置默认多分辨率配置", on: view)
                }
            }
        } else {
            let cfg = self.cfgItems[indexPath.row].cfg
            DebugSettings.multiResolutionConfig = cfg
            if let view = self.view.window {
                DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                    UDToast.showTips(with: "切换多分辨率配置 \(self.cfgItems[indexPath.row].name)", on: view)
                }
            }
        }
    }
}
