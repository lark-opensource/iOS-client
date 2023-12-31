//
//  SafeModeDebugViewController.swift
//  LarkSafeMode
//
//  Created by luyz on 2022/3/17.
//

import UIKit
import Foundation
import LarkDebugExtensionPoint

// Debug 工具代码，无需进行统一存储规则检查
// lint:disable lark_storage_check

struct BadAccessDebugItem: DebugCellItem {
    var title: String = "模拟触发安全模式"
    var type: DebugCellType { return .switchButton }

    var isSwitchButtonOn: Bool {
        return false
    }

    var switchValueDidChange: ((Bool) -> Void)? = { (on) in
        WriteBadData.writeBadData(isWrite: on)
    }
}

struct ExceptionDebugItem: DebugCellItem {
    var title: String = "模拟拉取热补丁"
    var type: DebugCellType { return .switchButton }

    var isSwitchButtonOn: Bool {
        return UserDefaults.standard.bool(forKey: "safemode_hot_fix")
    }

    var switchValueDidChange: ((Bool) -> Void)? = { (on) in
        UserDefaults.standard.set(on, forKey: "safemode_hot_fix")
    }
}

struct AsanDebugItem: DebugCellItem {
    var title: String = "模拟GWPASan-c崩溃"
    var type: DebugCellType { return .switchButton }

    var isSwitchButtonOn: Bool {
        return false
    }

    var switchValueDidChange: ((Bool) -> Void)? = { (on) in
        if on {
            TestGWPAsan.testGWPAsanCrash()
        }
    }
}

struct AsanSwiftDoubleFreeItem: DebugCellItem {
    var title: String = "模拟swift double free"
    var type: DebugCellType { return .switchButton }

    var isSwitchButtonOn: Bool {
        return false
    }

    var switchValueDidChange: ((Bool) -> Void)? = { (on) in
        if on {
            TestSwiftAsan.testDoubleFree()
        }
    }
}

struct AsanSwiftUseAfterFreeItem: DebugCellItem {
    var title: String = "模拟swift use after free"
    var type: DebugCellType { return .switchButton }

    var isSwitchButtonOn: Bool {
        return false
    }

    var switchValueDidChange: ((Bool) -> Void)? = { (on) in
        if on {
            TestSwiftAsan.testUseAfterFree()
        }
    }
}

struct WatchdogItem: DebugCellItem {
    var title: String = "模拟watchdog"
    var type: DebugCellType { return .switchButton }

    var isSwitchButtonOn: Bool {
        return false
    }

    var switchValueDidChange: ((Bool) -> Void)? = { (on) in
        if on {
            //sleep(100000)
            while (true) {
                
            }
        }
    }
}

struct RustDataCorruptItem: DebugCellItem {
    var title: String = "模拟rust数据库损坏"
    var type: DebugCellType { return .switchButton }

    var isSwitchButtonOn: Bool {
        return false
    }

    var switchValueDidChange: ((Bool) -> Void)? = { (on) in
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let rustData = "rust data"
        let tempPath = documentPath[0] + "/sdk_storage/staging/f5d0d415f74411c544321197f28f2333"
        let urlPath = URL(fileURLWithPath: tempPath).appendingPathComponent("im.db-shm").path
        let msgUrlPath = URL(fileURLWithPath: tempPath).appendingPathComponent("messages.db-shm").path
        let walUrlPath = URL(fileURLWithPath: tempPath).appendingPathComponent("im.db-wal").path
        
        if on {
            if FileManager.default.fileExists(atPath: walUrlPath) {
                try? FileManager.default.removeItem(atPath: walUrlPath)
                FileManager.default.createFile(atPath: walUrlPath, contents: nil, attributes: nil)
            }
            let fileHandle = FileHandle(forWritingAtPath: walUrlPath)
            fileHandle?.seekToEndOfFile()
            fileHandle?.write(rustData.data(using: .utf8)!)
        } else {
            if FileManager.default.fileExists(atPath: urlPath) {
                try? FileManager.default.removeItem(atPath: urlPath)
            }
        }
    }
}

struct CrashImmediatelyItem: DebugCellItem {
    var title: String = "模拟立即crash"
    var type: DebugCellType { return .switchButton }

    var isSwitchButtonOn: Bool {
        return false
    }

    var switchValueDidChange: ((Bool) -> Void)? = { (on) in
        if on {
            var t = 0
            let array: [Int] = [10, 20, 30]
            for i in 0..<array.count + 1 {
                t = array[i]
            }
        }
    }
}


struct PureDebugCrashItem: DebugCellItem {
    var title: String = "模拟触发兜底安全模式"
    var type: DebugCellType { return .switchButton }

    var isSwitchButtonOn: Bool {
        return false
    }

    var switchValueDidChange: ((Bool) -> Void)? = { (on) in
        UserDefaults.standard.set(true, forKey: SAFEMODEPUREENABLE)
        UserDefaults(suiteName: LARKSAFEMODE)?.set(true, forKey: PURESAFEMODE)
        WriteBadData.writeBadData(isWrite: on)
    }
}

public final class BadAccessDebug {
    public static func test() {
        if ((UserDefaults(suiteName: LARKSAFEMODE)?.bool(forKey: POINTMANUALCLEAR) ?? false ||
            UserDefaults(suiteName: LARKSAFEMODE)?.bool(forKey: POINTDEEPCLEAR) ?? false) &&
            ((UserDefaults(suiteName: LARKSAFEMODE)?.bool(forKey: PURESAFEMODE)) != true)) {
            NSLog("[safeMode-BadAccessDebug-return]")
            return
        }
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let tempPath = documentPath[0] + "/safemode_test"
        let urlPath = URL(fileURLWithPath: tempPath).appendingPathComponent("bad_data").path
        if FileManager.default.fileExists(atPath: urlPath) {
            var t = 0
            let array: [Int] = [10, 20, 30]
            for i in 0..<array.count + 1 {
                t = array[i]
            }
        }
    }
}

public final class ExceptionDebug {
    public static func test() {
        if UserDefaults.standard.bool(forKey: "safemode_hot_fix") {
            var t = 0
            let array: [Int] = [10, 20, 30]
            for i in 0..<array.count + 1 {
                t = array[i]
            }
        }
    }
}

public final class WriteBadData {
    public static func writeBadData(isWrite : Bool) {
        let documentPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        let tempPath = documentPath[0] + "/safemode_test"
        let urlPath = URL(fileURLWithPath: tempPath).appendingPathComponent("bad_data").path
        if isWrite {
            if !FileManager.default.fileExists(atPath: tempPath) {
                try? FileManager.default.createDirectory(at: URL(fileURLWithPath: tempPath), withIntermediateDirectories: true, attributes: nil)
            }
            FileManager.default.createFile(atPath: urlPath, contents: nil, attributes: nil)
        } else {
            if FileManager.default.fileExists(atPath: urlPath) {
                try? FileManager.default.removeItem(atPath: urlPath)
            }
        }
    }
}

final class SafeModeDebugViewController: UITableViewController {

    let data: [DebugCellItem] = [
        BadAccessDebugItem(),
        ExceptionDebugItem(),
        AsanDebugItem(),
        AsanSwiftDoubleFreeItem(),
        AsanSwiftUseAfterFreeItem(),
        WatchdogItem(),
        RustDataCorruptItem(),
        CrashImmediatelyItem(),
        PureDebugCrashItem()
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(DebugTableViewCell.self, forCellReuseIdentifier: DebugTableViewCell.lu.reuseIdentifier)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(
            withIdentifier: DebugTableViewCell.lu.reuseIdentifier,
            for: indexPath
        ) as? DebugTableViewCell {
            cell.setItem(data[indexPath.row])
            return cell
        } else {
            return UITableViewCell()
        }
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        let item = data[indexPath.row]
        if item.type != .switchButton {
            item.didSelect(item, debugVC: self)
        }
    }
}

final class DebugTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var item: DebugCellItem?

    func setItem(_ item: DebugCellItem) {
        self.item = item
        textLabel?.text = item.title
        detailTextLabel?.text = item.detail

        switch item.type {
        case .none:
            accessoryType = .none
            selectionStyle = .none
            accessoryView = nil
        case .disclosureIndicator:
            accessoryType = .disclosureIndicator
            selectionStyle = .default
            accessoryView = nil
        case .switchButton:
            accessoryType = .none
            selectionStyle = .none

            let switchButton = UISwitch()
            switchButton.isOn = item.isSwitchButtonOn
            switchButton.addTarget(self, action: #selector(switchButtonDidClick), for: .valueChanged)
            accessoryView = switchButton
        @unknown default:
            #if DEBUG
            assert(false, "new value")
            #else
            break
            #endif
        }
    }

    @objc
    private func switchButtonDidClick() {
        let isOn = (accessoryView as? UISwitch)?.isOn ?? false
        item?.switchValueDidChange?(isOn)
    }
}
