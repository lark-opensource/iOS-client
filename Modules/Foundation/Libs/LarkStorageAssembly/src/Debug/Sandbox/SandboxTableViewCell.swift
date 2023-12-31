//
//  SandboxTableViewCell.swift
//  LarkStorageAssembly
//
//  Created by 李昊哲 on 2022/11/16.
//

#if !LARK_NO_DEBUG
import UIKit
import Foundation
import RxSwift
import RxCocoa
import LarkStorage

protocol SandboxCellDelegate: AnyObject {
    func onTapCellItem(section: SandboxSection, item: SandboxItem, root: RootPathType.Normal)
    func onTapDeleteButton(section: SandboxSection, item: SandboxItem)
}

private final class RootItemButton: UIStackView {
    let root: RootPathType.Normal
    let label = UILabel()
    let imageView = UIImageView()
    let disposeBag = DisposeBag()

    var enabled = false {
        willSet {
            if newValue {
                label.textColor = .black
                imageView.tintColor = .systemBlue
            } else {
                label.textColor = .gray
                imageView.tintColor = .gray
            }
        }
    }

    init(cell: SandboxTableViewCell, root: RootPathType.Normal, domain: String, systemName: String) {
        self.root = root
        super.init(frame: CGRect())
        addArrangedSubview(imageView)
        addArrangedSubview(label)

        label.text = domain
        label.font = .systemFont(ofSize: 14)
        if #available(iOS 13.0, *) {
            let config = UIImage.SymbolConfiguration(font: label.font)
            imageView.image = UIImage(systemName: systemName, withConfiguration: config)
        } else {
            // TODO: handle fallback
        }
        imageView.contentMode = .scaleAspectFit

        let tapGesture = UITapGestureRecognizer()

        axis = .vertical
        alignment = .center
        addGestureRecognizer(tapGesture)

        tapGesture.rx.event
            .bind { [weak self, weak cell = cell] _ in
                guard let self = self, let cell = cell,
                      let item = cell.item,
                      let section = cell.section,
                      let delegate = cell.delegate
                else { return }

                if self.enabled {
                    delegate.onTapCellItem(section: section, item: item, root: root)
                }
            }
            .disposed(by: disposeBag)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class SandboxTableViewCell: UITableViewCell, UIAlertViewDelegate {
    let disposeBag = DisposeBag()
    let subItems: [(RootPathType.Normal, String, String)] = [
        (.library, "Library", "building.columns"),
        (.document, "Documents", "doc"),
        (.temporary, "Tmp", "externaldrive.badge.timemachine"),
        (.cache, "Cache", "archivebox")
    ]
    weak var delegate: SandboxCellDelegate?

    lazy var titleLabel = UILabel()
    lazy var deleteButton = UIButton()
    private lazy var buttons: [RootItemButton] = subItems.map { root, domain, name in
        RootItemButton(cell: self, root: root, domain: domain, systemName: name)
    }
    lazy var stackView = UIStackView(arrangedSubviews: buttons)

    var section: SandboxSection?
    var item: SandboxItem? {
        didSet {
            if let item = item {
                titleLabel.text = item.domain

                for button in buttons {
                    button.enabled = item.roots.contains(button.root)
                }
            }
        }
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        let newView = loadView()
        contentView.addSubview(newView)

        newView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func loadView() -> UIView {
        titleLabel.numberOfLines = 0
        titleLabel.setContentHuggingPriority(.required, for: .vertical)
        stackView.distribution = .fillEqually
        deleteButton.setContentHuggingPriority(.required, for: .horizontal)
        deleteButton.contentEdgeInsets = UIEdgeInsets(edges: 2)
        if #available(iOS 13.0, *) {
            deleteButton.setImage(UIImage(systemName: "trash"), for: .normal)
            deleteButton.imageView?.contentMode = .scaleAspectFit
            deleteButton.tintColor = .red
        } else {
            // TODO: handle fallback
        }

        let newView = UIView()
        newView.addSubview(titleLabel)
        newView.addSubview(deleteButton)
        newView.addSubview(stackView)

        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().inset(8)
            make.left.equalToSuperview().inset(20)
            make.right.equalTo(deleteButton.snp.left)
        }
        deleteButton.snp.makeConstraints { make in
            make.top.equalTo(titleLabel)
            // 不知道怎么用button的baseline对齐titleLabel的baseline，所以写成了下面这种形式
            make.bottom.equalTo(titleLabel.snp.firstBaseline).offset(4)
            make.right.equalToSuperview().inset(20)
        }
        stackView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(16)
            make.left.equalToSuperview()
            make.right.bottom.equalToSuperview().inset(12)
        }

        deleteButton.rx.tap
            .bind { [weak self] _ in
                guard let self = self,
                      let item = self.item,
                      let section = self.section,
                      let delegate = self.delegate
                else { return }

                delegate.onTapDeleteButton(section: section, item: item)
            }
            .disposed(by: disposeBag)

        return newView
    }
}
#endif
