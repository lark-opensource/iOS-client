//
//  MMKVEditorController.swift
//  LarkStorageAssembly
//
//  Created by 李昊哲 on 2022/11/22.
//

#if !LARK_NO_DEBUG
import UIKit
import Foundation
import MMKV
import RxSwift

final class MMKVEditorController: UIViewController {
    static let typeNames = ["int32", "int64", "uint32", "uint64", "float", "double"]

    lazy var scrollView = UIScrollView()
    lazy var scrollContentView = UIView()
    lazy var titleLabel = UILabel()
    lazy var boolLabel = UILabel()
    lazy var boolSwitch = UISwitch()
    lazy var typeViews = Self.typeNames.map(Self.makeTypeView)
    lazy var stackView = UIStackView(arrangedSubviews: typeViews.map(\.2))
    lazy var dateLabel = UILabel()
    lazy var datePicker = UIDatePicker()
    lazy var stringLabel = UILabel()
    lazy var stringTextView = UITextView()
    lazy var deleteButton = UIButton(type: .system)

    let mmkv: MMKV
    let item: MMKVDomainItem
    var key: String { item.actualKey }

    let disposeBag = DisposeBag()
    let dispatchQueue = DispatchQueue(label: "MMKVEditorController")

    init(mmkv: MMKV, item: MMKVDomainItem) {
        self.mmkv = mmkv
        self.item = item

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupConstraint()
        setupRx()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadData(typeName: "")
    }

    private func setupView() {
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemGroupedBackground
        } else {
            view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.00)
        }
        view.addSubview(scrollView)
        scrollView.addSubview(scrollContentView)
        scrollContentView.addSubview(titleLabel)
        scrollContentView.addSubview(boolLabel)
        scrollContentView.addSubview(boolSwitch)
        scrollContentView.addSubview(stackView)
        scrollContentView.addSubview(dateLabel)
        scrollContentView.addSubview(datePicker)
        scrollContentView.addSubview(stringLabel)
        scrollContentView.addSubview(stringTextView)
        scrollContentView.addSubview(deleteButton)

        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .onDrag
        titleLabel.text = key
        titleLabel.numberOfLines = 0
        titleLabel.font = .boldSystemFont(ofSize: 18)
        boolLabel.text = "bool"
        boolLabel.textAlignment = .right
        stackView.axis = .vertical
        stackView.spacing = 10
        dateLabel.text = "date"
        dateLabel.textAlignment = .right
        stringLabel.text = "string"
        stringLabel.textAlignment = .right
        stringTextView.layer.cornerRadius = 10
        stringTextView.textContainerInset = UIEdgeInsets(top: 8, left: 5, bottom: 0, right: 0)
        deleteButton.setTitleColor(.red, for: .normal)
        deleteButton.setTitle("删除KEY", for: .normal)
    }

    private func setupConstraint() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        scrollContentView.snp.makeConstraints { make in
            make.top.bottom.equalTo(scrollView)
            make.left.right.equalTo(view.safeAreaLayoutGuide)
        }

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(6)
            make.left.right.equalToSuperview().inset(10)
        }

        boolLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(4)
            make.top.bottom.equalTo(boolSwitch)
            make.width.equalTo(64)
        }

        boolSwitch.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.left.equalTo(boolLabel.snp.right).offset(10)
        }

        stackView.snp.makeConstraints { make in
            make.top.equalTo(boolSwitch.snp.bottom).offset(8)
            make.left.equalToSuperview().inset(4)
            make.right.equalToSuperview().inset(20)
        }

        dateLabel.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(4)
            make.top.bottom.equalTo(datePicker)
            make.width.equalTo(64)
        }

        datePicker.snp.makeConstraints { make in
            make.top.equalTo(stackView.snp.bottom).offset(8)
            make.left.equalTo(boolLabel.snp.right).offset(10)
        }

        stringLabel.snp.makeConstraints { make in
            make.top.equalTo(datePicker.snp.bottom).offset(8)
            make.left.equalToSuperview().inset(4)
            make.width.equalTo(64)
        }

        stringTextView.snp.makeConstraints { make in
            make.top.equalTo(stringLabel.snp.bottom).offset(4)
            make.left.right.equalToSuperview().inset(20)
            make.height.equalTo(100)
        }

        deleteButton.snp.makeConstraints { make in
            make.top.equalTo(stringTextView.snp.bottom).offset(8)
            make.left.right.bottom.equalToSuperview().inset(20)
        }
    }

    private func setupRx() {
        // TODO: 当用户点击一个textField时，会触发一次数据更新，导致明明没有改数据mmkv却被重新写入，希望研究一下怎么解决

        boolSwitch.rx.value.skip(1)
            .bind { [weak self] in
                guard let self = self else { return }

                self.mmkv.set($0, forKey: self.key)
                self.reloadData(typeName: "bool")
            }
            .disposed(by: disposeBag)

        stringTextView.rx.text.orEmpty.skip(1)
            .distinctUntilChanged()
            .debounce(.milliseconds(100), scheduler: MainScheduler.instance)
            .bind { [weak self] in
                guard let self = self else { return }

                self.mmkv.set($0, forKey: self.key)
                self.reloadData(typeName: "string")
            }
            .disposed(by: disposeBag)

        datePicker.rx.date.skip(1)
            .distinctUntilChanged()
            .bind { [weak self] in
                guard let self = self else { return }

                self.mmkv.set($0, forKey: self.key)
                self.reloadData(typeName: "date")
            }
            .disposed(by: disposeBag)

        deleteButton.rx.tap
            .bind { [weak self] in
                guard let self = self else { return }
                self.mmkv.removeValue(forKey: self.key)
                self.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)

        setupTypesRx()
    }

    private func setupTypesRx() {
        for (name, (_, textField, _)) in zip(Self.typeNames, typeViews) {
            textField.rx.text.orEmpty.skip(1)
                .distinctUntilChanged()
                .bind { [weak self] text in
                    guard let self = self else { return }

                    if let number = NumberFormatter().number(from: text) {
                        switch name {
                        case "int32":
                            self.mmkv.set(number.int32Value, forKey: self.key)
                            self.reloadData(typeName: name)
                        case "int64":
                            self.mmkv.set(number.int64Value, forKey: self.key)
                            self.reloadData(typeName: name)
                        case "uint32":
                            self.mmkv.set(number.uint32Value, forKey: self.key)
                            self.reloadData(typeName: name)
                        case "uint64":
                            self.mmkv.set(number.uint64Value, forKey: self.key)
                            self.reloadData(typeName: name)
                        case "float":
                            self.mmkv.set(number.floatValue, forKey: self.key)
                            self.reloadData(typeName: name)
                        case "double":
                            self.mmkv.set(number.doubleValue, forKey: self.key)
                            self.reloadData(typeName: name)
                        default: break
                        }
                    }
                }
                .disposed(by: disposeBag)
        }
    }

    private func reloadData(typeName: String) {
        dispatchQueue.async { [weak self] in
            guard let self = self else { return }

            if typeName != "bool" {
                let bool = self.mmkv.bool(forKey: self.key)
                self.boolSwitch.rx.value.onNext(bool)
            }

            if typeName != "string" {
                let string = self.mmkv.string(forKey: self.key)
                self.stringTextView.rx.text.onNext(string)
            }

            if typeName != "date", let date = self.mmkv.date(forKey: self.key) {
                self.datePicker.rx.date.onNext(date)
            }

            for (name, (_, textField, _)) in zip(Self.typeNames, self.typeViews) {
                guard name != typeName else { continue }

                let result: String?
                switch name {
                case "int32": result = String(describing: self.mmkv.int32(forKey: self.key))
                case "int64": result = String(describing: self.mmkv.int64(forKey: self.key))
                case "uint32": result = String(describing: self.mmkv.uint32(forKey: self.key))
                case "uint64": result = String(describing: self.mmkv.uint64(forKey: self.key))
                case "float": result = String(describing: self.mmkv.float(forKey: self.key))
                case "double": result = String(describing: self.mmkv.double(forKey: self.key))
                default: result = nil
                }
                textField.rx.text.onNext(result)
            }
        }
    }

    private static func makeTypeView(typeName: String) -> (UILabel, UITextField, UIStackView) {
        let label = UILabel()
        let textField = UITextField()

        label.text = typeName
        label.textAlignment = .right
        textField.borderStyle = .roundedRect
        switch typeName {
        case "int32", "int64", "uint32", "uint64":
            textField.keyboardType = .numberPad
        case "float", "double":
            textField.keyboardType = .decimalPad
        default: break
        }

        label.snp.makeConstraints { make in
            make.width.equalTo(64)
        }

        let stackView = UIStackView(arrangedSubviews: [label, textField])
        stackView.spacing = 8
        return (label, textField, stackView)
    }
}
#endif
