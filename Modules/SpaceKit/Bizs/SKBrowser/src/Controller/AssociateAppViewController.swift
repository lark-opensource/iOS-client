//
//  AssociateAppViewController.swift
//  SKBrowser
//
//  Created by huangzhikai on 2023/10/19.
//

import SKFoundation
import SKCommon
import SnapKit
import RxSwift
import ByteWebImage
import UniverseDesignIcon
import SKUIKit
import SKResource
import EENavigator
import LarkUIKit
import LarkNavigator
import LarkNavigation
import TangramService
import LarkContainer

class AssociateAppCell: UITableViewCell {
    static let reuseIdentifier = "AssociateAppCell"
    private var disposeBag = DisposeBag()
    private let inlinePreviewService = InlinePreviewService()
    
    lazy var iconImage: UIImageView = {
        let view = UIImageView()
        return view
    }()
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 16.0)
        label.textColor = UIColor.ud.N900
        return label
    }()
    
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        setupView()
        setupConstraints()
    }
    
    private func setupView() {
        self.addSubview(self.iconImage)
        self.addSubview(self.titleLabel)
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        disposeBag = DisposeBag()
    }
    
    private func setupConstraints() {
        self.iconImage.snp.makeConstraints { make in
            make.width.height.equalTo(24)
            make.left.equalTo(self).offset(24)
            make.centerY.equalToSuperview()
        }
        self.titleLabel.snp.makeConstraints { make in
            make.height.equalTo(24)
            make.left.equalTo(self.iconImage.snp.right).offset(12)
            make.right.equalToSuperview().offset(-24)
            make.centerY.equalToSuperview()
        }
    }
    
    func updateCellInfo(referencesModel: AssociateAppModel.ReferencesModel, viewModel: AssociateAppViewModel) {
        //url中台解析失败，则用兜底图标和url显示
        self.titleLabel.text = referencesModel.url ?? ""
        self.iconImage.image = UDIcon.globalLinkOutlined
        
        viewModel.getAssociateInfo(referencesModel: referencesModel)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] result in
                guard let self = self else {
                    return
                }
                guard let info = result.first else {
                    return
                }
                if let title = info.value.title, !title.isEmpty {
                    self.titleLabel.text = title
                }
                
                //图标为空就不处理了，使用一开始兜底的图标
                guard info.value.iconKey != nil else {
                    return
                }
                
                _ = self.inlinePreviewService.iconView(entity: info.value, iconColor: UIColor.ud.textLinkNormal) { imageView, image, _ in
                    if let imageView = imageView {
                        self.iconImage.image = imageView.image
                    } else if let image = image {
                        //后面等url中台优化后，看下是否有返回tintColor，有则跟url中台保持一致
                        self.iconImage.setImage(image, tintColor: UIColor.ud.textLinkNormal)
                    }
                }
            }).disposed(by: self.disposeBag)
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


public final class AssociateAppViewController: BaseViewController, UITableViewDataSource, UITableViewDelegate  {
    
    private var viewModel: AssociateAppViewModel
    
    
    init(viewModel: AssociateAppViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private lazy var tableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = .clear
        tableView.register(AssociateAppCell.self, forCellReuseIdentifier: AssociateAppCell.reuseIdentifier)
        return tableView
    }()
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.title = BundleI18n.SKResource.LarkCCM_Docs_AppLinkDoc_LinkProject_Title
        setupView()
    }
    private func setupView() {
        self.view.addSubview(tableView)
        tableView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom)
        }
        self.tableView.reloadData()
    }
    
    public override func refreshLeftBarButtons() { //重新刷新左边按钮
        super.refreshLeftBarButtons()
        let itemComponents: [SKBarButtonItem] = navigationBar.leadingBarButtonItems
        if !itemComponents.contains(closeButtonItem) { // iphone正常拿不到按钮
            self.navigationBar.leadingBarButtonItems.removeAll()
            closeButtonItem.image = UDIcon.closeSmallOutlined //修改x按钮图标变小，再加入
            self.navigationBar.leadingBarButtonItems.insert(closeButtonItem, at: 0)
        }
    }
    
    @objc
    public override func closeButtonItemAction() {
        self.dismiss(animated: true)
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.viewModel.references.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: AssociateAppCell.reuseIdentifier, for: indexPath)
        
        guard let cell = cell as? AssociateAppCell else {
            return cell
        }
        
        guard self.viewModel.references.count > indexPath.row else {
            return cell
        }
        let reference = self.viewModel.references[indexPath.row]
        
        cell.updateCellInfo(referencesModel: reference, viewModel: self.viewModel)
       
        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let presenVC: UIViewController? = self.presentingViewController
        guard self.viewModel.references.count > indexPath.row else {
            return
        }
        let reference = self.viewModel.references[indexPath.row]
        guard let url = reference.url, let pushUrl = URL(string: url) else {
            return
        }
        
        guard let fromVC = presenVC else {
            return
        }
        self.dismiss(animated: true) {
            Navigator.shared.showDetailOrPush(pushUrl, wrap: LkNavigationController.self, from: fromVC, animated: true)
        }
        AssociateAppTracker.reportDocContentClickTrackerEvent(webUrl: pushUrl, urlId: reference.urlMetaId)
    }
}
