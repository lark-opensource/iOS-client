//
//  SecretPermissionDetailViewController.swift
//  SKCommon
//
//  Created by tanyunpeng on 2023/4/20.
//  


import Foundation
import SKFoundation
import SKInfra
import UniverseDesignColor
import UniverseDesignToast
import SKResource
import SKUIKit
import UniverseDesignEmpty
import UniverseDesignIcon

struct DataEntity {
    let text: String
    let isImage: Bool
    let isRight: Bool
}

public final class SecretPermissionDetailViewController: BaseViewController, UICollectionViewDelegate, UIGestureRecognizerDelegate {
    
    public private(set) var viewModel: SecretPermissionInfoViewModel
    
    var didClickRetryAction: (() -> Void)?
    var secretGridView: UICollectionView?
    
    private var failView: UIView = {
        let view = UIView()
        view.backgroundColor = UDColor.bgBody
        return view
    }()
    
    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        view.image = UDEmptyType.loadingFailure.defaultImage()
        return view
    }()
    
    private lazy var descLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UDEmptyColorTheme.emptyDescriptionColor
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    
    private(set) public lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        return view
    }()
    
    public init(viewModel: SecretPermissionInfoViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }
    
    func setupUI() {
        view.addSubview(containerView)
        containerView.snp.makeConstraints { make in
            make.top.equalTo(navigationBar.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        setupDefaultValue()
        request()
    }
    
    func setupDefaultValue() {
        view.backgroundColor = UDColor.N100
        navigationBar.title = BundleI18n.SKResource.LarkCCM_Workspace_SecLevil_PermDetails_Title
    }

    func request() {
        guard DocsNetStateMonitor.shared.isReachable else {
            showToast(text: BundleI18n.SKResource.Doc_Facade_NetworkInterrutedRetry, type: .failure)
            return
        }
        showLoading()
        viewModel.request { [weak self] success in
            guard let self = self else { return }
            self.hideLoading()
            if success {
                self.reloadViewByItems()
                if self.secretGridView == nil {
                    self.setupThumbnailGridView()
                }
                self.secretGridView?.collectionViewLayout.invalidateLayout()
                self.secretGridView?.reloadData()
            } else {
                self.showFailView()
            }
        }
    }
    
    func reloadViewByItems() {
        failView.removeFromSuperview()
        reloadItems()
    }
    
    func createSecretGridView() -> UICollectionView {
        let layout = UICollectionGridViewLayout()
        layout.rowsValue = viewModel.rowsValue
        layout.cols = viewModel.cols
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = UIColor.ud.bgBase
        view.register(UICollectionGridViewCell.self, forCellWithReuseIdentifier: "cell")
        view.dataSource = self
        view.delegate = self
        return view
    }
    
    func setupThumbnailGridView() {
        let secretGridView = createSecretGridView()
        containerView.addSubview(secretGridView)
        secretGridView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
        self.secretGridView = secretGridView
    }

    
    private func reloadItems() {
        viewModel.reloadDataSoure()
    }

    private func showFailView() {
        containerView.addSubview(iconView)
        containerView.addSubview(descLabel)
        
        iconView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(120)
        }
        
        descLabel.snp.makeConstraints { make in
            make.top.equalTo(iconView.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.leading.equalToSuperview().offset(8)
            make.trailing.equalToSuperview().offset(-8)
        }
        addGestureRecognizer()
        
        let retryDesc = BundleI18n.SKResource.CreationMobile_PDFPreview_Failed_Placeholder1 +
            BundleI18n.SKResource.CreationMobile_PDFPreview_Failed_Placeholder2
        let descriptionString = NSMutableAttributedString(string: retryDesc)
        descriptionString.addAttribute(.foregroundColor,
                                       value: UDEmptyColorTheme.emptyDescriptionColor,
                                       range: .init(location: 0, length: descriptionString.length))
        let range = descriptionString.mutableString.range(of: BundleI18n.SKResource.CreationMobile_PDFPreview_Failed_Placeholder2, options: .caseInsensitive)
        descriptionString.addAttribute(.foregroundColor,
                                       value: UDEmptyColorTheme.emptyNegtiveOperableColor,
                                       range: range)
        descLabel.attributedText = descriptionString
    }
    
}

extension SecretPermissionDetailViewController {
    func showToast(text: String, type: DocsExtension<UDToast>.MsgType) {
        guard let view = self.view.window ?? self.view else {
            return
        }
        UDToast.docs.showMessage(text, on: view, msgType: type)
    }
}

extension SecretPermissionDetailViewController: UICollectionViewDataSource {
    //返回表格总行数
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        if viewModel.cols.isEmpty {
                return 0
            }
            //总行数是：记录数＋1个表头
        return viewModel.rowsValue.count + 1
    }
    
    //返回表格的列数
    public func collectionView(_ collectionView: UICollectionView,
                                 numberOfItemsInSection section: Int) -> Int {
        return viewModel.cols.count
    }
    
    //单元格内容创建
    public func collectionView(_ collectionView: UICollectionView,
                            cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell",
                                                      for: indexPath)
        guard let cell = cell as? UICollectionGridViewCell else {
            DocsLogger.warning("drive.secret.permission.cell --- get unexcepted reuseable cell type")
            return cell
        }
        
        //设置列头单元格，内容单元格的数据
        if indexPath.section == 0 {
            let text = NSAttributedString(string: viewModel.cols[indexPath.row], attributes: [
                NSAttributedString.Key.font:UIFont.boldSystemFont(ofSize: 14)
                ])
            cell.label.attributedText = text
            cell.label.numberOfLines = 3
            cell.label.textColor = UIColor.ud.textTitle
            cell.label.lineBreakMode = .byTruncatingTail
            cell.contentView.backgroundColor = UDColor.udtokenTableBgHead
            cell.avatarView.image = nil
            cell.updateLine()
            if indexPath.row == 0 {
                cell.updateLine2()
            } else {
                cell.hideLine2()
            }
        } else {
            cell.label.numberOfLines = 0
            cell.label.lineBreakMode = .byWordWrapping
            cell.contentView.backgroundColor = UDColor.bgBody
            if viewModel.rowsValue[indexPath.section-1][indexPath.row].text == "" {
                if viewModel.rowsValue[indexPath.section-1][indexPath.row].isRight {
                    cell.avatarView.image = UDIcon.getIconByKey(.listCheckColorful, iconColor: UIColor.ud.functionSuccessContentDefault)
                } else {
                    cell.avatarView.image = UDIcon.getIconByKey(.closeSmallOutlined, iconColor: UIColor.ud.functionDangerContentDefault)
                }
                cell.label.text = ""
            } else {
                cell.avatarView.image = nil
                cell.label.font = UIFont.systemFont(ofSize: 14)
                cell.label.text = "\(viewModel.rowsValue[indexPath.section-1][indexPath.row].text)"
            }
            if indexPath.row == 0 {
                cell.updateLine2()
                cell.label.textColor = UDColor.textTitle
            } else {
                cell.hideLine2()
            }
            if indexPath.section % 2 == 0 || indexPath.section == 5 {
                cell.updateLine()
            } else {
                cell.hideLine()
            }
            if indexPath.section != 0 && indexPath.row != 0 {
                cell.label.textColor = UIColor.ud.textCaption
            }
        }
        
        return cell
    }
    
    func addGestureRecognizer() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(onTapDimiss))
        tapGesture.delegate = self
        descLabel.isUserInteractionEnabled = true
        descLabel.addGestureRecognizer(tapGesture)
    }
    
    @objc
    private func onTapDimiss(sender: UIGestureRecognizer) {
        request()
    }
}
