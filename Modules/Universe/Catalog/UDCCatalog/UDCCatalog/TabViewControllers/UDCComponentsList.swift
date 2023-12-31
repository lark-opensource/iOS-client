//
//  UDCComponentsList.swift
//  UDCCatalog
//
//  Created by 姚启灏 on 2020/8/11.
//  Copyright © 2020 姚启灏. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignIcon
import UniverseDesignDrawer
import UniverseDesignColor

public protocol EnumAllType {
    static var allValues: [Self] { get }
}

typealias ListItem = (String, UIImage, () -> UIViewController)

class UDCComponentsList: UIViewController {
    var dataSource: [ListItem] = [
        ListItem("ActionPanel", UDIcon.emojiFilled, { UniverseDesignActionPanelVC() }),
        ListItem("Avatar", UDIcon.earFilled, { UniverseDesignAvatarVC() }),
        ListItem("Badge", UDIcon.newBadgeColorful, { UniverseDesignBadgeVC() }),
        ListItem("Breadcrumb", UDIcon.boardsFilled, { UniverseDesignBreadcrumbVC() }),
        ListItem("Button", UDIcon.dayOutlined, { UniverseDesignButtonVC() }),
        ListItem("CardHeader", UDIcon.browserWinOutlined, { UniverseDesignCardHeaderVC() }),
        ListItem("CheckBox", UDIcon.callOutlined, { UniverseDesignCheckBoxVC() }),
        ListItem("Color", UDIcon.adminOutlined, { UniverseDesignColorVC() }),
        ListItem("ColorPicker", UDIcon.switchItemOutlined, { UniverseDesignColorPickerVC() }),
        ListItem("DatePicker", UDIcon.translateOutlined, { UniverseDesignDatePickerVC() }),
        ListItem("Dialog", UDIcon.groupFilled, { UniverseDesignDialogVC() }),
        ListItem("Drawer", UDIcon.dragOutlined, { UniverseDesignDrawerVC() }),
        ListItem("Empty", UDIcon.addSheetOutlined, { UniverseDesignEmptyVC() }),
        ListItem("Font", UDIcon.addCommentOutlined, { UniverseDesignFontVC() }),
        ListItem("Gradient", UDIcon.myaiColorful, { UniverseDesignGradientColorVC() }),
        ListItem("Icon", UDIcon.atOutlined, { UniverseDesignIconVC() }),
        ListItem("ImageList", UDIcon.addAppOutlined, { UniverseDesignImageListVC() }),
        ListItem("Input", UDIcon.flagFilled, { UniverseDesignInputVC() }),
        ListItem("Loading", UDIcon.chatLoadingOutlined, { UniverseDesignLoadingVC() }),
        ListItem("Menu", UDIcon.bringFrontOutlined, { UniverseDesignMenuVC() }),
        ListItem("Notice", UDIcon.alignCenterOutlined, { UniverseDesignNoticeVC() }),
        ListItem("ProgressView", UDIcon.squarendPointOutlined, { UniverseDesignProgressViewVC() }),
        ListItem("Rate", UDIcon.qrOutlined, { UniverseDesignRateVC() }),
        ListItem("Shadow", UDIcon.spaceDownOutlined, { UniverseDesignShadowVC() }),
        ListItem("Style", UDIcon.allOutlined, { UniverseDesignStyleVC() }),
        ListItem("Switch", UDIcon.switchOutlined, { UniverseDesignSwitchVC() }),
        ListItem("Tabs", UDIcon.jiraOutlined, { UniverseDesignTabsVC() }),
        ListItem("Tag", UDIcon.activityFilled, { UniverseDesignTagVC() }),
        ListItem("Toast", UDIcon.flagOutlined, { UniverseDesignToastVC() })
    ]

    private lazy var searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = "搜索组件关键字"
        bar.delegate = self
        return bar
    }()

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(
            width: self.view.bounds.width / 3,
            height: self.view.bounds.width / 3
        )
        layout.sectionInset = .zero
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.delegate = self
        collection.dataSource = self
        collection.backgroundColor = .clear
        collection.insetsLayoutMarginsFromSafeArea = true
        return collection
    }()

    let idenContentString = "idenContentString"
    private lazy var transitionManager = UDDrawerTransitionManager(host: self)

    override func viewDidLoad() {
        super.viewDidLoad()

        UDColor.registerToken()

        view.addSubview(searchBar)
        view.addSubview(collectionView)
        searchBar.snp.makeConstraints { make in
            if let naviBar = navigationController?.navigationBar {
                make.top.equalTo(naviBar.snp.bottom)
            } else {
                make.top.equalTo(view.safeAreaLayoutGuide)
            }
            make.leading.trailing.equalToSuperview()
        }
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(searchBar.snp.bottom)
            make.leading.trailing.bottom.equalToSuperview()
        }
        collectionView.register(UDCComponentsListCell.self,
                                forCellWithReuseIdentifier: idenContentString)
        transitionManager.addDrawerEdgeGesture(to: view)
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
        } else {
            view.backgroundColor = UIColor.ud.N00
        }
    }
}

extension UDCComponentsList: UDDrawerAddable {
    var fromVC: UIViewController? {
        self
    }

    var contentWidth: CGFloat {
        self.view.bounds.width * UDDrawerValues.contentDefaultPercent
    }

    var subVC: UIViewController? {
        UDDrawerGridViewController()
    }

    var direction: UDDrawerDirection {
        .left
    }
}

extension UDCComponentsList: UISearchBarDelegate {

    private func highlightMatchItem(forText searchText: String) {
        guard let firstMatch = dataSource.firstIndex(where: { $0.0.contains(searchText) }) else { return }
        let matchIndex = IndexPath(row: firstMatch, section: 0)
        collectionView.scrollToItem(at: matchIndex, at: .top, animated: true)
        if let cell = collectionView.cellForItem(at: matchIndex) as? UDCComponentsListCell {
            cell.shining()
        } else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                if let cell = self.collectionView.cellForItem(at: matchIndex) as? UDCComponentsListCell {
                    cell.shining()
                }
            }
        }
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else { return }
        searchBar.resignFirstResponder()
        highlightMatchItem(forText: searchText)
    }
}

extension UDCComponentsList: UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        searchBar.resignFirstResponder()
    }

    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let vc = dataSource[indexPath.row].2
        if type(of: vc()) == UniverseDesignActionPanelVC.self {
            let v1 = vc()
            self.present(v1, animated: true, completion: nil)
        } else {
            self.navigationController?.pushViewController(vc(), animated: true)
        }
    }

    //cellForItemAt indexPath
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: idenContentString,
            for: indexPath
        ) as? UDCComponentsListCell ?? UDCComponentsListCell()
        cell.titleLabel.text = dataSource[indexPath.row].0
        if #available(iOS 13.0, *) {
            cell.imageView.image = dataSource[indexPath.row].1.withTintColor(UIColor.ud.N700)
        } else {
            cell.imageView.image = dataSource[indexPath.row].1
        }
        return cell
    }
}

class UDCComponentsListCell: UICollectionViewCell {
    override init(frame: CGRect) {

        super.init(frame: frame)

        self.imageView.frame = CGRect(x: 10, y: 0, width: 50, height: 50)
        self.imageView.center = self.contentView.center
        self.titleLabel.frame = CGRect(x: 10, y: 60, width: frame.size.width - 20, height: 50)
        self.titleLabel.center.x = self.contentView.center.x
        self.titleLabel.center.y = self.contentView.center.y + 40
        self.titleLabel.numberOfLines = 0

        self.contentView.addSubview(self.titleLabel)
        self.contentView.addSubview(self.imageView)

        self.layer.ud.setBorderColor(UIColor.ud.N400)
        self.layer.borderWidth = 0.5
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    var titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.ud.caption1
        return label
    }()

    var imageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()

    func shining() {
        backgroundColor = UIColor.ud.N300
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UIView.animate(withDuration: 0.2) {
                self.backgroundColor = .clear
            }
        }
    }
}
