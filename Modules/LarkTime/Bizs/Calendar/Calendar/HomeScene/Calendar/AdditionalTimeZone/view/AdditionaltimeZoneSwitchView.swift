//
//  AdditionaltimeZoneSwitchView.swift
//  Calendar
//
//  Created by chaishenghua on 2023/10/24.
//

import Foundation
import UniverseDesignFont
import UniverseDesignColor
import UniverseDesignIcon
import RxSwift

class AdditionaltimeZoneSwitchView: UIView {
    private let disposebag = DisposeBag()

    private lazy var title = {
        let label = UILabel()
        label.textColor = UDColor.textTitle
        label.text = BundleI18n.Calendar.Calendar_Timezone_ShowAdditionalTimeZone
        label.font = UDFont.body0(.fixed)
        return label
    }()

    private var switchChangedAction: ((Bool) -> Void)?

    private lazy var switchView = UISwitch()

    init() {
        super.init(frame: .zero)
        setupView()
    }

    private func setupView() {
        self.backgroundColor = UDColor.bgBody
        self.addSubview(title)
        self.addSubview(switchView)

        title.snp.makeConstraints { make in
            make.leading.equalToSuperview().inset(16)
            make.trailing.equalTo(switchView.snp.trailing).offset(-12)
            make.height.equalTo(22)
            make.centerY.equalToSuperview()
        }
        switchView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.height.equalTo(28)
            make.width.equalTo(46)
            make.centerY.equalToSuperview()
        }
    }

    func setModel(isOn: Bool, switchChangedAction: @escaping ((Bool) -> Void)) {
        switchView.isOn = isOn
        self.switchChangedAction = switchChangedAction
        switchView.rx.isOn
            .skip(1)
            .subscribe(onNext: { [weak self] isOn in
                self?.switchChangedAction?(isOn)
            }).disposed(by: disposebag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}
