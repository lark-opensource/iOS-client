//
//  ChatThemeViewController.swift
//  LarkChatSetting
//
//  Created by JackZhao on 2022/12/20.
//

import UIKit
import Foundation
import RxSwift
import FigmaKit
import LarkUIKit
import EENavigator
import LKCommonsTracker
import LarkVideoDirector
import UniverseDesignToast
import LarkMessengerInterface
import LarkSplitViewController

// 聊天主题页
final class ChatThemeViewController: BaseSettingController,
                                     UITableViewDelegate,
                                     UITableViewDataSource,
                                     UICollectionViewDelegate,
                                     UICollectionViewDataSource,
                                     UICollectionViewDelegateFlowLayout {
    struct Config {
        static let heightForHeaderInSection: CGFloat = 12
        static let configCellHeight: CGFloat = ChatInfoShareCell.Config.cellHight
        static let collectionViewMinimumLineSpacing: CGFloat = 14
        static let collectionViewMinimumInteritemSpacing: CGFloat = 8
        static let collectionViewHorizontalPadding: CGFloat = 16
        static let collectionViewVerticalTopPadding: CGFloat = 16
    }

    private let disposeBag = DisposeBag()
    private let tableView = InsetTableView(frame: .zero)
    private var viewModel: ChatThemeViewModel
    private var cellSize: CGSize = .zero
    /// 容器：包装tableview和collectionView，使其能共同滑动
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsVerticalScrollIndicator = false
        scrollView.backgroundColor = .clear
        return scrollView
    }()

    private lazy var collectionView: UICollectionView = {
        let flowLayout = UICollectionViewFlowLayout()
        flowLayout.minimumLineSpacing = Config.collectionViewMinimumLineSpacing
        flowLayout.minimumInteritemSpacing = Config.collectionViewMinimumInteritemSpacing
        flowLayout.sectionInset = UIEdgeInsets(top: Config.collectionViewVerticalTopPadding, left: Config.collectionViewHorizontalPadding, bottom: 0, right: Config.collectionViewHorizontalPadding)
        flowLayout.scrollDirection = .vertical

        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: flowLayout)
        collectionView.layer.cornerRadius = 10
        collectionView.clipsToBounds = true
        collectionView.dataSource = self
        collectionView.isScrollEnabled = false
        collectionView.delegate = self
        collectionView.bounces = true
        collectionView.backgroundColor = UIColor.ud.bgBody
        collectionView.showsVerticalScrollIndicator = false
        collectionView.register(ChatThemeItemCell.self, forCellWithReuseIdentifier: NSStringFromClass(ChatThemeItemCell.self))
        return collectionView
    }()

    override var navigationBarStyle: NavigationBarStyle {
        return .custom(UIColor.ud.bgBase)
    }

    init(viewModel: ChatThemeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        configViewModel()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        pageInit()
    }

    private func pageInit() {
        view.backgroundColor = UIColor.ud.bgBase
        configScrollView()
        configInitNavi()
        configTableView()
        configCollection()
    }

    private func configInitNavi() {
        title = viewModel.title
    }

    func configScrollView() {
        self.view.addSubview(scrollView)
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    private func configTableView() {
        tableView.backgroundColor = UIColor.ud.bgBase
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionFooterHeight = UITableView.automaticDimension
        tableView.isScrollEnabled = false
        tableView.showsHorizontalScrollIndicator = false
        scrollView.addSubview(tableView)
        tableView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        tableView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.width.equalTo(self.view.snp.width)
            make.height.equalTo(Config.configCellHeight * 2 + Config.heightForHeaderInSection)
        }
        tableView.lu.register(cellSelf: ChatThemeShootPhotoCell.self)
        tableView.lu.register(cellSelf: ChatThemeFromAlbumCell.self)

        tableView.register(ChatThemeSectionEmptyView.self,
                           forHeaderFooterViewReuseIdentifier: String(describing: GroupSettingSectionEmptyView.self))
    }

    func configCollection() {
        scrollView.addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(tableView.snp.bottom).offset(12)
            make.left.equalTo(Config.collectionViewHorizontalPadding)
            make.right.equalTo(-Config.collectionViewHorizontalPadding)
            make.height.equalTo(500)
            make.bottom.equalToSuperview()
        }
        viewModel.fetchData()
    }

    private func configViewModel() {
        viewModel.reloadData
            .drive(onNext: { [weak self] (_) in
                self?.tableView.reloadData()
            })

        viewModel.collectionReloadData
            .drive(onNext: { [weak self] (_) in
                guard let `self` = self else { return }

                self.collectionView.reloadData()
                self.collectionView.snp.updateConstraints { make in
                    make.height.equalTo(self.caculateCollectionHeight(pageSize: self.view.frame.size))
                }

                // 有更多数据则添加上拉加载更多
                if self.viewModel.hasMoreData {
                    self.collectionView.addBottomLoadMoreView(infiniteScrollActionImmediatly: false) { [weak self] in
                        self?.viewModel.loadMoreData()
                    }
                } else {
                    self.collectionView.removeBottomLoadMore()
                }
            }).disposed(by: disposeBag)
        viewModel.targetVC = self
        viewModel.delegate = self
    }

    private func caculateCollectionHeight(pageSize: CGSize) -> CGFloat {
        let maxWidth = pageSize.width - Config.collectionViewHorizontalPadding * 2
        let themes = self.viewModel.themes
        let maxCount = Int(self.getLineDisplayCount(width: maxWidth)) ?? 0
        let line = themes.count % maxCount == 0 ? themes.count / maxCount : (themes.count / maxCount + 1)
        let height = Config.collectionViewVerticalTopPadding + (cellSize.height + Config.collectionViewMinimumLineSpacing) * CGFloat(line)
        return height
    }

    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        resetCollectionView(size: size)
    }

    private func resetCollectionView(size: CGSize) {
        let maxWidth = size.width - Config.collectionViewHorizontalPadding * 2
        cellSize = getSize(width: maxWidth)
        self.collectionView.collectionViewLayout.invalidateLayout()
        // 重新计算高度
        self.collectionView.snp.updateConstraints { make in
            make.height.equalTo(self.caculateCollectionHeight(pageSize: size))
        }
    }

    // MARK: 全屏按钮
    override func splitSplitModeChange(splitMode: SplitViewController.SplitMode) {
        resetCollectionView(size: self.view.frame.size)
    }

    // MARK: - UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }
        tableView.deselectRow(at: indexPath, animated: true)
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(
            withIdentifier: String(describing: ChatThemeSectionEmptyView.self))
    }

    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return tableView.dequeueReusableHeaderFooterView(
            withIdentifier: String(describing: ChatThemeSectionEmptyView.self))
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return Config.heightForHeaderInSection
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.01
    }

    // MARK: - UITableViewDataSource
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.items.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section < viewModel.items.count else { return 0 }
        return viewModel.items[section].items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let item = viewModel.items.item(at: indexPath),
           var cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier) as? CommonCellProtocol {
            cell.item = item
            if let cell = cell as? UITableViewCell {
                cell.backgroundView?.backgroundColor = UIColor.ud.bgBody
                return cell
            }
            return UITableViewCell()
        }
        return UITableViewCell()
    }

    // MARK: UICollectionViewDelegate, UICollectionViewDataSource
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        viewModel.themes.count ?? 0
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        cellSize = getSize(width: collectionView.frame.width)
        return cellSize
    }

    // 获取一行最多显示的cell数量
    private func getLineDisplayCount(width: CGFloat) -> CGFloat {
        let maxCount: CGFloat
        if Display.pad {
            if width > 720 {
                maxCount = 4
            } else if width > 320 {
                maxCount = 3
            } else {
                maxCount = 2
            }
        } else {
            maxCount = 3
        }
        return maxCount
    }

    private func getSize(width: CGFloat) -> CGSize {
        let maxWidth = width - Config.collectionViewHorizontalPadding * 2
        let maxCount = getLineDisplayCount(width: maxWidth)
        let preferWidth = (maxWidth - Config.collectionViewMinimumInteritemSpacing * (maxCount - 1)) / maxCount
        let labelHeight = ChatThemeItemCell.Config.descriptionTopMargin + ChatThemeItemCell.Config.descriptionLabelHeight
        let preferItemSize = Display.pad ? CGSize(width: preferWidth, height: preferWidth + labelHeight) : CGSize(width: preferWidth, height: preferWidth / 9 * 16 + labelHeight)
        return preferItemSize
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard  indexPath.row < viewModel.themes.count else {
            assertionFailure("datasource out of range")
            return UICollectionViewCell()
        }
        let cellVM = viewModel.themes[indexPath.row]
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellVM.reuseIdentify, for: indexPath) as? ChatThemeItemCell else { return UICollectionViewCell() }
        cell.model = cellVM
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard  indexPath.row < viewModel.themes.count else {
            assertionFailure("datasource out of range")
            return
        }
        let model = viewModel.themes[indexPath.row]
        viewModel.collectionItemTapped(model: model)
    }
}

typealias ChatThemeFromAlbumItem = ChatInfoShareModel
typealias ChatThemeShootPhotoItem = ChatInfoShareModel

typealias ChatThemeFromAlbumCell = ChatInfoShareCell
typealias ChatThemeShootPhotoCell = ChatInfoShareCell

extension ChatThemeViewController: ChatThemeDelegate {
    func actionTakePhoto(_ completion: ((UIImage, UIViewController) -> Void)?, cancel: (() -> Void)?) {
        LarkCameraKit.takePhoto(from: self, userResolver: viewModel.userResolver,
                                didCancel: { _ in cancel?() }, completion: completion)
    }
}

final class ChatThemeSectionEmptyView: UITableViewHeaderFooterView {
    override init(reuseIdentifier: String?) {
        super.init(reuseIdentifier: reuseIdentifier)
        contentView.backgroundColor = UIColor.ud.bgBase
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
