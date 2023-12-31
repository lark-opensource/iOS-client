//
//  ASLDebugCell.swift
//  LarkSearchCore
//
//  Created by chenziyue on 2021/12/13.
//

import Foundation
import UIKit
import LarkDebugExtensionPoint

final class ASLDebugTableViewCell: UITableViewCell {
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .value1, reuseIdentifier: reuseIdentifier)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var item: ASLDebugCellItem?

    func setItem(_ item: ASLDebugCellItem) {
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
        case .uiTextField:
            fallthrough // use unknown default setting to fix warning
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
