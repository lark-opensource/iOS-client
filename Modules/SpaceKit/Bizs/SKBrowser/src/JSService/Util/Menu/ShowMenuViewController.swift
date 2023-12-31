//
//  ShowMenuViewController.swift
//  SKBrowser
//
//  Created by lizechuang on 2021/2/4.
//

import Foundation
import RxSwift
import LarkTraitCollection
import SKResource
import SKUIKit
import UniverseDesignColor

class ShowMenuViewController: UIViewController {
    fileprivate struct Const {
        static let contentItemHeight: CGFloat = 50
        static let contentWidth: CGFloat = 148
    }

    private let selectActionPublishSubject: PublishSubject<String> = PublishSubject<String>()
    var selectAction: Observable<String> {
        return selectActionPublishSubject.asObserver()
    }

    private let bag = DisposeBag()
    var disappearCallBack: (() -> Void)?

    private let menuItems: [BrowserMenuItem]

    public init(menuItems: [BrowserMenuItem]) {
        self.menuItems = menuItems
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private var contentSize: CGSize {
        let contentHeight: CGFloat = Const.contentItemHeight * CGFloat(menuItems.count)
        var contentWidth: CGFloat = Const.contentWidth
        menuItems.forEach { (item) in
            let curCaculateWidth: CGFloat = item.text.estimatedSingleLineUILabelWidth(in: UIFont.systemFont(ofSize: 14)) + 16 * 2 + 20 + 12
            contentWidth = max(contentWidth, curCaculateWidth)
        }
        return CGSize(width: contentWidth, height: contentHeight)
    }
    
    lazy var tableView: UITableView = {
        return setupTableView()
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.addSubview(tableView)
        self.view.backgroundColor = UDColor.bgFloat
        tableView.snp.makeConstraints { (make) in
            make.left.right.equalToSuperview()
            make.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(8)
            make.bottom.equalToSuperview().offset(8)
        }
        self.preferredContentSize = contentSize
        NotificationCenter.default.addObserver(self, selector: #selector(willChangeStatusBarOrientation(_:)), name: UIApplication.willChangeStatusBarOrientationNotification, object: nil)
        // 监听sizeClass
        RootTraitCollection.observer
            .observeRootTraitCollectionWillChange(for: self.view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] change in
                if change.old != change.new || self?.modalPresentationStyle == .popover {
                    self?._dismissIfNeed()
                }
            }).disposed(by: bag)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.disappearCallBack?()
    }

    private func setupTableView() -> UITableView {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.estimatedRowHeight = 50
        tableView.rowHeight = UITableView.automaticDimension
        tableView.backgroundColor = UDColor.bgFloat
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.tableFooterView = UIView()
        tableView.isScrollEnabled = false
        tableView.register(MenuItemViewCell.self, forCellReuseIdentifier: NSStringFromClass(MenuItemViewCell.self))
        return tableView
    }

    // 由于这种情况下展示具体的Icon，数据项是由前端返回，需要这里判断需要什么Icon
    private func obtainDisplayIconWithID(_ id: String) -> UIImage {
        switch id {
        case "ChooseCover":
            return BundleResources.SKResource.Common.Cover.icon_image_outlined.ud.withTintColor(UDColor.iconN1)
        case "EditCoverPosition":
            return BundleResources.SKResource.Common.Cover.icon_move_selected_outlined.ud.withTintColor(UDColor.iconN1)
        case "RemoveCover":
            return BundleResources.SKResource.Common.Icon.icon_delete_trash_outlined_20.ud.withTintColor(UDColor.iconN1)
        case "AdjustCoverPosition":
            return BundleResources.SKResource.Common.Cover.icon_move_selected_outlined.ud.withTintColor(UDColor.iconN1)
        default:
            return UIImage()
        }
    }

    @objc
    private func _dismissIfNeed() {
        dismiss(animated: true, completion: nil)
    }

    @objc
    func willChangeStatusBarOrientation(_ notice: Notification) {
        _dismissIfNeed()
    }
}

extension ShowMenuViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return menuItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: NSStringFromClass(MenuItemViewCell.self)) as? MenuItemViewCell else {
            return UITableViewCell()
        }

        // cell统一设置separatorInset
        cell.separatorInset.left = self.view.bounds.width
        let item = menuItems[indexPath.row]
        cell.set(title: item.text, image: obtainDisplayIconWithID(item.id))
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = menuItems[indexPath.row]
        selectActionPublishSubject.onNext(item.id)
        dismiss(animated: true, completion: nil)
    }
}

class MenuItemViewCell: UITableViewCell {
    lazy private var label: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .left
        label.textColor = UDColor.textTitle
        return label
    }()
    lazy private var iconView: UIImageView = {
        let imgView = UIImageView()
        imgView.contentMode = .center
        return imgView
    }()
        
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.backgroundColor = UDColor.bgFloat
        self.contentView.addSubview(self.iconView)
        self.contentView.addSubview(self.label)
        self.iconView.snp.makeConstraints { (make) in
            make.left.equalTo(16)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(20)
        }
        self.label.snp.makeConstraints { (make) in
            make.left.equalTo(self.iconView.snp.right).offset(12)
            make.centerY.equalToSuperview()
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func set(title: String, image: UIImage) {
        self.label.text = title
        self.iconView.image = image
    }
}
