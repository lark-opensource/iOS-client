//
//  LocalCoverPhotosSelectView.swift
//  SKDoc
//
//  Created by lizechuang on 2021/2/1.
//

//import Foundation
//import UniverseDesignColor

//protocol LocalCoverPhotosSelectViewDelegate: AnyObject {
//    func didSelectLocalCoverPhotoActionWith(_ action: LocalCoverPhotoAction)
//}
//
//class LocalCoverPhotosSelectView: UIView {
//
//    weak var delegate: LocalCoverPhotosSelectViewDelegate?
//
//    let actionList: [LocalCoverPhotoAction] = [.album, .takePhoto]
//
//    lazy var tableView: UITableView = {
//        return setupTableView()
//    }()
//
//    lazy var tipLabel: UILabel = {
//        let label = UILabel()
//        label.font = UIFont.systemFont(ofSize: 12)
//        label.textColor = UDColor.textCaption
//        // TODO: Kubrick
//        label.text = "封面最大大小"
//        label.textAlignment = .center
//        return label
//    }()
//
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        setupSubViews()
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    private func setupSubViews() {
//        self.backgroundColor = UDColor.bgBase
//        self.addSubview(tableView)
//        self.addSubview(tipLabel)
//        self.tableView.snp.makeConstraints { (make) in
//            make.top.equalToSuperview().offset(12)
//            make.left.right.equalToSuperview()
//            make.height.equalTo(48 * actionList.count)
//        }
//        self.tipLabel.snp.makeConstraints { (make) in
//            make.top.equalTo(self.tableView.snp.bottom).offset(12)
//            make.centerX.equalToSuperview()
//            make.left.right.equalToSuperview()
//        }
//    }
//
//    private func setupTableView() -> UITableView {
//        let tableView = UITableView(frame: .zero, style: .plain)
//        tableView.delegate = self
//        tableView.dataSource = self
//        tableView.rowHeight = 48
//        tableView.backgroundColor = UDColor.bgBody
//        tableView.showsVerticalScrollIndicator = false
//        tableView.showsHorizontalScrollIndicator = false
//        tableView.tableFooterView = UIView()
//        tableView.isScrollEnabled = false
//        tableView.register(LocalCoverPhotosSelectViewCell.self, forCellReuseIdentifier: NSStringFromClass(LocalCoverPhotosSelectViewCell.self))
//        return tableView
//    }
//}
//
//extension LocalCoverPhotosSelectView: UITableViewDelegate, UITableViewDataSource {
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return actionList.count
//    }
//    
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        guard let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(LocalCoverPhotosSelectViewCell.self)) as? LocalCoverPhotosSelectViewCell else {
//            return UITableViewCell()
//        }
//
//        // cell统一设置separatorInset
//        cell.separatorInset.left = (indexPath.row + 1 == actionList.count) ? 0.0 : 16.0
//        // TODO: Kubrick
//        if actionList[indexPath.row] == .album {
//            cell.set(title: "从本地相册选择")
//        } else {
//            cell.set(title: "相机拍照")
//        }
//        return cell
//    }
//
//
//    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        tableView.deselectRow(at: indexPath, animated: true)
//        delegate?.didSelectLocalCoverPhotoActionWith(actionList[indexPath.row])
//    }
//}
//
//class LocalCoverPhotosSelectViewCell: UITableViewCell {
//    private lazy var titleLabel: UILabel = UILabel()
//
//    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
//        super.init(style: style, reuseIdentifier: reuseIdentifier)
//        self.backgroundColor = UDColor.bgBody
//
//        self.titleLabel.font = UIFont.systemFont(ofSize: 16)
//        self.titleLabel.textAlignment = .left
//        self.titleLabel.textColor = UDColor.textTitle
//        self.contentView.addSubview(self.titleLabel)
//        self.titleLabel.snp.makeConstraints { (make) in
//            make.left.equalTo(16)
//            make.centerY.equalToSuperview()
//        }
//    }
//
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//
//    func set(title: String) {
//        self.titleLabel.text = title
//    }
//}
