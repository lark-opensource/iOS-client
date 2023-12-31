//
//  AudioSessionDebugViewController.swift
//  AudioSessionScenario
//
//  Created by ford on 2020/6/8.
//

import Foundation
import AVFoundation

class AudioSessionDebugViewController: UIViewController {

    enum AudioItems: String {
        case main
        case status
        case settings
        case audiounit
    }

    static var curSelCategory: () -> String = { AVAudioSession.sharedInstance().category.rawValue }
    static var curSelMode: () -> String = { AVAudioSession.sharedInstance().mode.rawValue }
    static var curSelCategoryOpts: () -> String = { AVAudioSession.sharedInstance().categoryOptions.description }

    lazy var audioEngine = AudioEngine()

    lazy var engineKeys: [String] = Self.getPropertyList(AVAudioEngine.self).filter { !["musicSequence"].contains($0) }
    lazy var playerKeys: [String] = Self.getPropertyList(AVAudioPlayerNode.self)
    lazy var mixerKeys: [String] = Self.getPropertyList(AVAudioMixerNode.self)

    var audioUnitDesc: String = ""

    var dataSource: [AudioDebugSectionModel] {
        guard let title = segmentControl.titleForSegment(at: segmentControl.selectedSegmentIndex) else { return [] }
        switch title {
        case AudioItems.main.rawValue:
            return [mainSection]
        case AudioItems.status.rawValue:
            return [statusSection]
        case AudioItems.settings.rawValue:
            return [settingsSection, actionSection]
        case AudioItems.audiounit.rawValue:
            return [auStatusSection, auActionSection]
        default:
            return []
        }
    }

    lazy var tableView: UITableView = {
        let tableView = UITableView(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height), style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = segmentControl
        tableView.estimatedRowHeight = 60
        tableView.rowHeight = UITableView.automaticDimension
        tableView.register(AudioDebugSubtitleCell.self, forCellReuseIdentifier: AudioDebugSubtitleCell.identifier)
        tableView.register(AudioDebugButtonCell.self, forCellReuseIdentifier: AudioDebugButtonCell.identifier)
        tableView.register(AudioDebugSingleSelCell.self, forCellReuseIdentifier: AudioDebugSingleSelCell.identifier)
        tableView.register(AudioDebugMultiSelCell.self, forCellReuseIdentifier: AudioDebugMultiSelCell.identifier)
        tableView.register(AudioDebugSwitchCell.self, forCellReuseIdentifier: AudioDebugSwitchCell.identifier)
        return tableView
    }()

    lazy var segmentControl: UISegmentedControl = {
        let segmentControl = UISegmentedControl(items: [AudioItems.main.rawValue, AudioItems.status.rawValue, AudioItems.settings.rawValue, AudioItems.audiounit.rawValue])
        segmentControl.frame = CGRect(x: 20, y: 0, width: view.bounds.width - 40, height: 30)
        segmentControl.selectedSegmentIndex = 0
        segmentControl.addTarget(self, action: #selector(clickSegment), for: .valueChanged)
        return segmentControl
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "音频调试"
        view.addSubview(tableView)
        view.addConstraints([
            NSLayoutConstraint(item: tableView,
                               attribute: .left,
                               relatedBy: .equal,
                               toItem: view,
                               attribute: .left,
                               multiplier: 1,
                               constant: 0),
            NSLayoutConstraint(item: tableView,
                               attribute: .top,
                               relatedBy: .equal,
                               toItem: view,
                               attribute: .top,
                               multiplier: 1,
                               constant: 0),
            NSLayoutConstraint(item: tableView,
                               attribute: .right,
                               relatedBy: .equal,
                               toItem: view,
                               attribute: .right,
                               multiplier: 1,
                               constant: 0),
            NSLayoutConstraint(item: tableView,
                               attribute: .bottom,
                               relatedBy: .equal,
                               toItem: view,
                               attribute: .bottom,
                               multiplier: 1,
                               constant: 0),
        ])
    }
}

extension AudioSessionDebugViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return dataSource.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource[section].cellModels.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return dataSource[section].sectionTitle
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = dataSource[indexPath.section].cellModels[indexPath.row]
        return dispatchCell(with: model, indexPath: indexPath)
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = dataSource[indexPath.section].cellModels[indexPath.row]
        if let m = model as? AudioDebugButtonCellModelGetter {
            m.execute { (v) in
                guard let cellModel = v as? AudioDebugButtonCellModel else {
                    return
                }
                cellModel.value()
            }
        }

        if let m = model as? AudioDebugSingleSelCellModelGetter {
            m.execute { [weak self] (v) in
                guard let cellModel = v as? AudioDebugSingleSelCellModel else {
                    return
                }
                let vc = AudioSessionSelViewController(mode: .single,
                                                       selectedItems: [cellModel.value.value],
                                                       optionalItems: cellModel.value.options,
                                                       onCompleted: { result in
                    if cellModel.title == "Category" {
                        AudioSessionDebugViewController.curSelCategory = { result.first ?? "AVAudioSessionCategoryPlayback" }
                    }
                    if cellModel.title == "Mode" {
                        AudioSessionDebugViewController.curSelMode = { result.first ?? "AVAudioSessionModeDefault" }
                    }
                    self?.tableView.reloadData()
                })
                self?.navigationController?.pushViewController(vc, animated: true)
            }
        }

        if let m = model as? AudioDebugMultiSelCellModelGetter {
            m.execute { [weak self] (v) in
                guard let cellModel = v as? AudioDebugMultiSelCellModel else {
                    return
                }
                let vc = AudioSessionSelViewController(mode: .multiple,
                                                       selectedItems: cellModel.value.value,
                                                       optionalItems: cellModel.value.options,
                                                       onCompleted: { result in
                    if cellModel.title == "Category Options" {
                        AudioSessionDebugViewController.curSelCategoryOpts = { result.joined(separator: "|") }
                    }
                    self?.tableView.reloadData()
                })
                self?.navigationController?.pushViewController(vc, animated: true)
            }
        }

        if let m = model as? AudioDebugSingleSelActionCellModelGetter {
            m.execute { [weak self] (v) in
                guard let cellModel = v as? AudioDebugSingleSelActionCellModel else {
                    return
                }
                let vc = KeyValueSelViewController(
                    cellItems: cellModel.value.options,
                    refObj: {
                        switch cellModel.title {
                        case "engine":
                            return self?.audioEngine.engine
                        case "player":
                            return self?.audioEngine.player
                        case "mixer":
                            return self?.audioEngine.recordMixer
                        default: return nil
                        }
                    }()) { _ in
                }
                self?.navigationController?.pushViewController(vc, animated: true)
            }
        }
    }

    func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        if (tableView.cellForRow(at: indexPath) as? AudioDebugButtonCell) != nil {
            return false
        }
        return true
    }

    func tableView(_ tableView: UITableView, canPerformAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return action == #selector(copy(_:))
    }

    func tableView(_ tableView: UITableView, performAction action: Selector, forRowAt indexPath: IndexPath, withSender sender: Any?) {
        if action == #selector(copy(_:)) {
            let cell = tableView.cellForRow(at: indexPath)
            if let cell = cell as? AudioDebugBaseCell {
                UIPasteboard.general.string = cell.subTitleLabel.text
            }
        }
    }
}

extension AudioSessionDebugViewController {
    func dispatchCell(with model: AudioDebugCellValue, indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell?
        if let m = model as? AudioDebugSubtitleCellModelGetter {
            let c = tableView.dequeueReusableCell(withIdentifier: AudioDebugSubtitleCell.identifier, for: indexPath) as? AudioDebugSubtitleCell
            c?.bindModel(model: m)
            cell = c
        } else if let m = model as? AudioDebugButtonCellModelGetter {
            let c = tableView.dequeueReusableCell(withIdentifier: AudioDebugButtonCell.identifier, for: indexPath) as? AudioDebugButtonCell
            c?.bindModel(model: m)
            cell = c
        } else if let m = model as? AudioDebugSingleSelCellModelGetter {
            let c = tableView.dequeueReusableCell(withIdentifier: AudioDebugSingleSelCell.identifier, for: indexPath) as? AudioDebugSingleSelCell
            c?.bindModel(model: m)
            cell = c
        } else if let m = model as? AudioDebugMultiSelCellModelGetter {
            let c = tableView.dequeueReusableCell(withIdentifier: AudioDebugMultiSelCell.identifier, for: indexPath) as? AudioDebugMultiSelCell
            c?.bindModel(model: m)
            cell = c
        } else if let m = model as? AudioDebugSwitchCellModelGetter {
            let c = tableView.dequeueReusableCell(withIdentifier: AudioDebugSwitchCell.identifier, for: indexPath) as? AudioDebugSwitchCell
            c?.bindModel(model: m)
            cell = c
        } else if let m = model as? AudioDebugSingleSelActionCellModelGetter {
            let c = tableView.dequeueReusableCell(withIdentifier: AudioDebugSingleSelCell.identifier, for: indexPath) as? AudioDebugSingleSelCell
            c?.bindModel(model: m)
            cell = c
        }
        return cell ?? UITableViewCell()
    }

    @objc
    func clickSegment() {
        self.tableView.reloadData()
    }
}
