//
//  DebugEnvPickerViewController.swift
//  LarkEnv
//
//  Created by au on 2022/1/10.
//

import Foundation
import LarkAlertController
import RxSwift
import SnapKit
import UIKit
import UniverseDesignTheme

public final class DebugEnvPickerViewController: UIViewController {

    private let completion: ((Env, String)) -> Void
    private let currentBrand: String
    private var currentEnv: Env { EnvManager.env }

    public init(brand: String, completion: @escaping ((Env, String)) -> Void) {
        self.currentBrand = brand
        self.completion = completion
        super.init(nibName: nil, bundle: nil)
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupDataSource()
    }

    private func setupView() {
        view.backgroundColor = UIColor.ud.bgBase

        view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
        }

        view.addSubview(brandControl)
        brandControl.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.height.equalTo(32)
            make.top.equalTo(titleLabel.snp.bottom).offset(64)
        }

        view.addSubview(envPickerView)
        envPickerView.snp.makeConstraints { (make) in
            make.left.equalToSuperview().offset(14)
            make.right.equalToSuperview().offset(-14)
            make.top.equalTo(brandControl.snp.bottom).offset(48)
            make.height.equalToSuperview().multipliedBy(0.4)
        }

        doneButton.addTarget(self, action: #selector(onDoneTapped), for: .touchUpInside)
        view.addSubview(doneButton)
        doneButton.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-96)
        }

        cancelButton.addTarget(self, action: #selector(onCancelTapped), for: .touchUpInside)
        view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().offset(-16)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-32)
        }
    }

    private func setupDataSource() {
        selectedTypeIndex = currentTypeIndex
        selectedUnitIndex = currentUnitIndex

        brandControl.selectedSegmentIndex = brandDataSource.firstIndex(of: currentBrand) ?? 0

        envPickerView.selectRow(selectedTypeIndex, inComponent: 0, animated: false)
        envPickerView.selectRow(selectedUnitIndex, inComponent: 1, animated: false)
    }

    @objc
    func onCancelTapped() {
        dismiss(animated: true, completion: nil)
    }

    @objc
    func onDoneTapped() {
        let type = typeDataSource[selectedTypeIndex]
        let unit = unitDataSource[selectedTypeIndex][selectedUnitIndex]
        let brand = brandDataSource[brandControl.selectedSegmentIndex]
        let geo = unitGeoMap[unit] ?? ""

        let env = Env(unit: unit, geo: geo, type: type)
        print(type, " - ", unit, " - ", brand)
        guard env != currentEnv || brand != currentBrand else {
            dismiss(animated: true, completion: nil)
            return
        }
        self.completion((env, brand))
        self.dismiss(animated: true)
    }

    init() {
        fatalError("use init(completion:) instead")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: Property

    private lazy var doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.ud.primaryContentDefault
        button.setTitle("确定", for: [])
        button.setTitleColor(.white, for: [])
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.layer.cornerRadius = 8
        if #available(iOS 13, *) {
            button.layer.cornerCurve = .continuous
        }
        return button
    }()

    private lazy var cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = UIColor.ud.bgBase
        button.setTitle("取消", for: [])
        button.setTitleColor(UIColor.ud.primaryContentDefault, for: [])
        button.titleLabel?.font = .systemFont(ofSize: 18, weight: .medium)
        button.layer.cornerRadius = 8
        if #available(iOS 13, *) {
            button.layer.cornerCurve = .continuous
        }
        return button
    }()

    private lazy var brandControl = UISegmentedControl(items: brandDataSource)

    private lazy var titleLabel: UILabel = {
        let titleLabel = UILabel()
        titleLabel.text = "当前品牌为 \(currentBrand)\n当前环境为 \(currentEnv.type.domainKey) \(currentEnv.unit)\n滚动下方选择器切换环境"
        titleLabel.textAlignment = .center
        titleLabel.textColor = UIColor.ud.textTitle
        titleLabel.numberOfLines = 0
        return titleLabel
    }()

    private lazy var envPickerView: UIPickerView = {
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        return picker
    }()

    private var currentTypeIndex: Int { typeDataSource.firstIndex(of: currentEnv.type) ?? 0 }
    private var currentUnitIndex: Int { unitDataSource[currentTypeIndex].firstIndex(of: currentEnv.unit) ?? 0 }

    fileprivate let typeDataSource: [Env.TypeEnum] = [.release, .preRelease, .staging]
    fileprivate let unitDataSource = [[Unit.NC, Unit.EA, Unit.SG], [Unit.NC, Unit.EA, Unit.SG], [Unit.BOECN, Unit.BOEVA]]
    fileprivate let brandDataSource = ["feishu", "lark"]

    private let unitGeoMap = [Unit.NC: "cn", Unit.EA: "us", Unit.SG: "sg", Unit.BOECN: "boe-cn", Unit.BOEVA: "boe-us"]

    fileprivate var selectedTypeIndex: Int = 0
    fileprivate var selectedUnitIndex: Int = 0

}

extension DebugEnvPickerViewController: UIPickerViewDataSource {
    public func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }

    public func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if component == 0 {
            return typeDataSource.count
        }
        if component == 1 {
            return unitDataSource[selectedTypeIndex].count
        }
        return 0
    }

    public func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        let item: String
        let textColor: UIColor
        if component == 0 {
            item = typeDataSource[row].domainKey
            textColor = row == currentTypeIndex ? UIColor.ud.primaryContentDefault : UIColor.ud.textTitle
        } else {
            item = unitDataSource[selectedTypeIndex][row]
            textColor = (selectedTypeIndex == currentTypeIndex) && (row == currentUnitIndex) ? UIColor.ud.primaryContentDefault : UIColor.ud.textTitle
        }
        return NSAttributedString(string: item, attributes: [NSAttributedString.Key.foregroundColor: textColor])
    }
}

extension DebugEnvPickerViewController: UIPickerViewDelegate {
    public func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if component == 0 {
            if row != selectedTypeIndex {
                selectedTypeIndex = row
                pickerView.reloadComponent(1)
                pickerView.selectRow(0, inComponent: 1, animated: true)
                selectedUnitIndex = 0
            }
            return
        }
        if component == 1 {
            selectedUnitIndex = row
        }
    }
}


final class DebugEnvCell: UITableViewCell {
    let titleLabel: UILabel = UILabel()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textAlignment = .center

        addSubview(titleLabel)
        titleLabel.snp.makeConstraints { (maker) in
            maker.edges.equalToSuperview()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
