//
//  DetailDenpendentListViewController.swift
//  Todo
//
//  Created by wangwanxin on 2023/7/14.
//

import CTFoundation
import LarkUIKit

final class DetailDenpendentListViewController:
    BaseUIViewController,
    UICollectionViewDelegate,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout
{
    var removeDependentHandler: (([String]) -> Void)?
    var didAddedDependentHandler: (() -> Void)?
    var clickTaskHandler: ((String) -> Void)?

    private lazy var headerView = ActionPanelHeaderView()
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 4
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = UIColor.ud.bgFloatBase
        cv.showsHorizontalScrollIndicator = false
        cv.showsVerticalScrollIndicator = false
        cv.alwaysBounceVertical = true
        cv.ctf.register(cellType: DetailDependentListCell.self)
        cv.dataSource = self
        cv.delegate = self
        return cv
    }()
    private let viewModel: DetailDependentListViewModel

    init(viewModel: DetailDependentListViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(headerView)
        headerView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(Config.HeaderHeight)
        }
        view.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.left.right.bottom.equalToSuperview()
        }
        headerView.title = ActionPanelHeaderView.Title(
            center: viewModel.title,
            right: viewModel.canEdit ? I18N.Todo_common_Add : nil
        )
        headerView.onCloseHander = { [weak self] in
            self?.dismiss(animated: true)
        }
        headerView.onSaveHandler = { [weak self] in
            guard let self = self else { return }
            self.dismiss(animated: true)
            self.didAddedDependentHandler?()
        }
        viewModel.onListUpdate = { [weak self] in
            self?.reloadList()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        reloadList()
    }


    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.cellDatas.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.ctf.dequeueReusableCell(DetailDependentListCell.self, for: indexPath),
              let row = viewModel.safeCheckRows(indexPath)
        else {
            return UICollectionViewCell()
        }
        cell.viewData = viewModel.cellDatas[row]
        cell.actionDelegate = self
        return cell
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath
    ) -> CGSize {
        guard let row = viewModel.safeCheckRows(indexPath) else {
            return .zero
        }
        let item = viewModel.cellDatas[row]
        let maxWidth = collectionView.frame.width - Config.hPadding * 2
        if let height = item.cellHeight {
            return CGSize(width: collectionView.frame.width, height: height)
        }
        let height = item.preferredHeight(maxWidth: maxWidth)
        viewModel.cellDatas[row].cellHeight = height
        return CGSize(width: collectionView.frame.width, height: height)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: Config.vSpace, left: 0, bottom: 0, right: 0)
    }

    private func reloadList() {
        collectionView.collectionViewLayout.invalidateLayout()
        collectionView.layoutIfNeeded()
        collectionView.reloadData()
    }

}

extension DetailDenpendentListViewController: DetailDependentListCellDelegate {

    func didClickRemove(from sender: DetailDependentListCell) {
        guard let indexPath = collectionView.indexPath(for: sender) else {
            return
        }
        if let guid = viewModel.removeItem(at: indexPath) {
            removeDependentHandler?([guid])
        }
    }

    func didClickContent(from sender: DetailDependentListCell) {
        guard let indexPath = collectionView.indexPath(for: sender),
              let guid = viewModel.itemGuid(at: indexPath) else {
            return
        }
        dismiss(animated: true)
        clickTaskHandler?(guid)
    }

}

extension DetailDenpendentListViewController {

    struct Config {
        static let hPadding = DetailDependentListCell.Config.hPadding
        static let HeaderHeight = 48.0
        static let vSpace = 4.0
        static let TopInset = 16.0
    }

}
