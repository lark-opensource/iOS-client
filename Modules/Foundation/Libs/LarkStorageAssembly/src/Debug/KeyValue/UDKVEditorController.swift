//
//  UDKVEditorController.swift
//  LarkStorageAssembly
//
//  Created by 李昊哲 on 2022/11/21.
//

#if !LARK_NO_DEBUG
import UIKit
import Foundation
import RxSwift

final class UDKVEditorController: UIViewController {
    let userDefaults: UserDefaults
    let item: UDKVDomainItem
    let disposeBag = DisposeBag()

    var isDeleted = false

    lazy var nameLabel = UILabel()
    lazy var nameDivider = UIView()
    lazy var typeLabel = UILabel()
    lazy var typeDivider = UIView()
    lazy var textView = AutoResizeTextView()
    lazy var scrollView = UIScrollView()
    lazy var contentView = UIView()
    lazy var deleteButton = UIButton(type: .system)

    init(userDefaults: UserDefaults, item: UDKVDomainItem) {
        self.userDefaults = userDefaults
        self.item = item

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()
        setupConstraints()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        guard !isDeleted, let text = textView.text else {
            return
        }

        if item.number() != nil {
            if let number = NumberFormatter().number(from: text) {
                userDefaults.set(number, forKey: item.actualKey)
            }
        } else if item.string() != nil {
            userDefaults.set(text, forKey: item.actualKey)
        } else if item.data() != nil {
            userDefaults.set(Data(text.utf8), forKey: item.actualKey)
        } else {
            // TODO: handle unexpected case
        }
    }

    private func setupView() {
        title = "Edit Value"

        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemGroupedBackground
        } else {
            view.backgroundColor = UIColor(red: 0.95, green: 0.95, blue: 0.97, alpha: 1.00)
        }

        scrollView.alwaysBounceVertical = true
        scrollView.keyboardDismissMode = .onDrag
        nameLabel.text = item.key
        nameLabel.font = .systemFont(ofSize: 18)
        typeLabel.text = "type: \(type(of: item.value))"
        deleteButton.setTitle("删除KEY", for: .normal)
        deleteButton.setTitleColor(.red, for: .normal)
        if #available(iOS 13.0, *) {
            nameDivider.backgroundColor = .systemGray4
            typeDivider.backgroundColor = .systemGray4
        } else {
            nameDivider.backgroundColor = UIColor(red: 0.82, green: 0.82, blue: 0.84, alpha: 1.00)
            typeDivider.backgroundColor = UIColor(red: 0.82, green: 0.82, blue: 0.84, alpha: 1.00)
        }
        textView.text = item.description
        textView.font = .systemFont(ofSize: 18)
        textView.layer.cornerRadius = 10
        textView.textContainerInset = UIEdgeInsets(top: 8, left: 5, bottom: 0, right: 0)
        textView.becomeFirstResponder()
        if item.number() != nil {
            textView.keyboardType = .decimalPad
        }

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(nameDivider)
        contentView.addSubview(typeLabel)
        contentView.addSubview(typeDivider)
        contentView.addSubview(textView)
        contentView.addSubview(deleteButton)

        deleteButton.rx.tap
            .bind { [weak self] in
                guard let self = self else { return }
                self.userDefaults.removeObject(forKey: self.item.actualKey)
                self.isDeleted = true
                self.navigationController?.popViewController(animated: true)
            }
            .disposed(by: disposeBag)
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentView.snp.makeConstraints { make in
            make.top.bottom.equalToSuperview()
            make.left.right.equalTo(view.safeAreaLayoutGuide)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(20)
            make.left.right.equalToSuperview().inset(10)
        }

        nameDivider.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(20)
            make.left.right.equalTo(nameLabel)
            make.height.equalTo(1)
        }

        typeLabel.snp.makeConstraints { make in
            make.top.equalTo(nameDivider.snp.bottom).offset(20)
            make.left.right.equalToSuperview().inset(10)
        }

        typeDivider.snp.makeConstraints { make in
            make.top.equalTo(typeLabel.snp.bottom).offset(20)
            make.left.right.equalTo(typeLabel)
            make.height.equalTo(1)
        }

        textView.snp.makeConstraints { make in
            make.top.equalTo(typeDivider.snp.bottom).offset(20)
            make.left.right.equalTo(typeLabel)
            make.height.greaterThanOrEqualTo(200)
        }

        deleteButton.snp.makeConstraints { make in
            make.top.equalTo(textView.snp.bottom).offset(30)
            make.left.right.equalTo(typeLabel)
            make.bottom.equalToSuperview()
        }
    }
}
#endif
