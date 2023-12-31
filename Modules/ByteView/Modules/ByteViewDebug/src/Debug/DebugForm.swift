//
//  Form.swift
//  ByteViewDebug
//
//  Created by liujianlong on 2021/5/8.
//

import Foundation
import RxSwift
import RxRelay
import ByteView

extension UITableViewCell {
    func configure(entry: DebugConfigs.CustomVCEntry) {
        self.textLabel?.text = entry.label
    }
}

class FormCellBuilder {
    func registerCells(tableView: UITableView) {
        tableView.register(SwitchFieldCell.self, forCellReuseIdentifier: SwitchFieldCell.identifier)
        tableView.register(InputFieldCell.self, forCellReuseIdentifier: InputFieldCell.identifier)
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "NestedCell")
    }

    // swiftlint:disable force_cast
    func createCell(tableView: UITableView, indexPath: IndexPath, for entry: DebugFormEntry) -> UITableViewCell {
        switch entry {
        case let entry as DebugConfigs.InputFieldEntry:
            let cell = tableView.dequeueReusableCell(withIdentifier: InputFieldCell.identifier, for: indexPath) as! InputFieldCell
            cell.configure(entry: entry)
            return cell
        case let entry as DebugConfigs.SwitchFieldEntry:
            let cell = tableView.dequeueReusableCell(withIdentifier: SwitchFieldCell.identifier, for: indexPath) as! SwitchFieldCell
            cell.configure(entry: entry)
            return cell
        case let entry as DebugConfigs.CustomVCEntry:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NestedCell", for: indexPath)
            cell.configure(entry: entry)
            return cell
        default:
            fatalError()
        }
    }
    // swiftlint:enable force_cast
}

class SwitchFieldCell: UITableViewCell {
    static let identifier = "SwitchFieldCell"
    var disposeBag = DisposeBag()
    let label: UILabel
    let field: UISwitch
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.label = UILabel()
        self.field = UISwitch()
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(entry: DebugConfigs.SwitchFieldEntry) {
        self.label.text = entry.label
        self.field.isOn = entry.variable.value
        self.field.rx.value
            .bind(to: entry.variable)
            .disposed(by: disposeBag)
    }

    private func setupLayout() {
        self.contentView.addSubview(label)
        self.contentView.addSubview(field)

        label.snp.makeConstraints { make in
            make.left.bottom.top.equalToSuperview().inset(10.0)
        }
        field.snp.makeConstraints { make in
            make.right.top.bottom.equalToSuperview().inset(10.0)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.disposeBag = DisposeBag()
    }
}

class InputFieldCell: UITableViewCell {
    static let identifier = "InputCell"
    var disposeBag = DisposeBag()
    let label: UILabel
    let field: UITextField
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        self.label = UILabel()
        self.field = UITextField()
        self.field.layer.borderWidth = 1.0
        self.field.layer.borderColor = UIColor.gray.cgColor
        self.field.textAlignment = .right

        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(entry: DebugConfigs.InputFieldEntry) {
        self.label.text = entry.label
        self.field.text = entry.variable.value
        self.field.rx.value.flatMap({ val -> Observable<String> in
            if val == nil {
                return .empty()
            } else {
                return .just(val!)
            }

        })
        .bind(to: entry.variable)
        .disposed(by: disposeBag)
    }

    private func setupLayout() {
        self.contentView.addSubview(label)
        self.contentView.addSubview(field)

        label.snp.makeConstraints { make in
            make.left.bottom.top.equalToSuperview().inset(10.0)
        }
        field.snp.makeConstraints { make in
            make.right.top.bottom.equalToSuperview().inset(10.0)
            make.left.equalTo(label.snp.right).offset(10.0)
            make.width.equalTo(200.0)
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        self.disposeBag = DisposeBag()
    }
}
