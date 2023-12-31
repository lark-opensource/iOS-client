//
//  SwitchNormalCell.swift
//  LarkMine
//
//  Created by panbinghua on 2021/12/1.
//

import Foundation
import UIKit
import RxSwift

public typealias SwitchHandler = ((_ view: UITableViewCell, _ isOn: Bool) -> Void)

public final class SwitchNormalCellProp: BaseNormalCellProp {
    var isOn: Bool = false
    var onSwitch: SwitchHandler?
    var isEnabled: Bool = true

    public init(title: String,
         detail: String? = nil,
         isOn: Bool,
         isEnabled: Bool = true,
         cellIdentifier: String = "SwitchNormalCell",
         separatorLineStyle: CellSeparatorLineStyle = .normal,
         selectionStyle: CellSelectionStyle = .none,
         id: String? = nil,
         onSwitch: SwitchHandler? = nil) {
        self.isOn = isOn
        self.isEnabled = isEnabled
        self.onSwitch = onSwitch
        super.init(title: title,
                   detail: detail,
                   cellIdentifier: cellIdentifier,
                   separatorLineStyle: separatorLineStyle,
                   selectionStyle: selectionStyle,
                   id: id)
    }
}

public class SwitchNormalCell: BaseNormalCell {
    var onSwitch: SwitchHandler?

    lazy var switcher: UISwitch = {
        let switcher = UISwitch()
        switcher.onTintColor = UIColor.ud.primaryContentDefault
        return switcher
    }()

    public override func getTrailingView() -> UIView? {
        switcher.snp.makeConstraints { // 必须明确尺寸约束，否则会布局混乱
            $0.width.equalTo(48)
            $0.height.equalTo(28)
        }
        return switcher
    }

    public override func update(_ info: CellProp) {
        super.update(info)
        guard let info = info as? SwitchNormalCellProp else { return }
        switcher.isEnabled = info.isEnabled
        switcher.isOn = info.isOn
        onSwitch = info.onSwitch
        switcher.rx
            .isOn
            .changed
            .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isOn in
                guard let self = self else { return }
                info.onSwitch?(self, isOn)
            }).disposed(by: disposeBag)
    }
}
