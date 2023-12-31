//
//  AlbumListViewController.swift
//  LarkImagePicker
//
//  Created by ChalrieSu on 2018/8/29.
//  Copyright © 2018 ChalrieSu. All rights reserved.
//

import Foundation
import UIKit
import Photos
import SnapKit
import LarkUIKit
import LarkSensitivityControl

final class AlbumListViewController: BaseUIViewController, UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate {
    var didSelectAlbum: ((Album) -> Void)?

    // DATA
    private let imageManager = PHCachingImageManager.default()
    private let albums: [Album]
    private let defaultSelectAlbum: Album

    // UI
    let tableViewWrapper = UIView()
    private let tableView = UITableView()

    init(albums: [Album], defaultSelectAlbum: Album) {
        self.albums = albums
        self.defaultSelectAlbum = defaultSelectAlbum
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.black.withAlphaComponent(0.3)
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundViewTapped(gesture:)))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)

        let trangleView = TrangleView()
        tableViewWrapper.addSubview(trangleView)
        trangleView.snp.makeConstraints { (make) in
            make.size.equalTo(CGSize(width: 18, height: 10))
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
        }

        tableViewWrapper.addSubview(tableView)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.rowHeight = 70
        tableView.clipsToBounds = true
        tableView.layer.cornerRadius = 8
        let defaultSelectIndex = albums.firstIndex(where: { $0 == defaultSelectAlbum }) ?? 0
        tableView.selectRow(at: IndexPath(item: defaultSelectIndex, section: 0), animated: false, scrollPosition: .none)
        tableView.register(AlbumListCell.self, forCellReuseIdentifier: String(describing: AlbumListCell.self))
        tableView.snp.makeConstraints { (make) in
            make.top.equalTo(trangleView.snp.bottom)
            make.left.bottom.right.equalToSuperview()
        }

        view.addSubview(tableViewWrapper)
        tableViewWrapper.snp.makeConstraints { (make) in
            make.top.equalTo(viewTopConstraint).offset(38)
            make.left.right.equalToSuperview()
            let height = CGFloat(tableView.numberOfRows(inSection: 0)) * tableView.rowHeight + 10
            make.height.equalTo(height).priority(.low)
            make.bottom.lessThanOrEqualTo(viewBottomConstraint).offset(-48).priority(.high)
        }
    }

    @objc
    private func backgroundViewTapped(gesture: UITapGestureRecognizer) {
        dismiss(animated: true, completion: nil)
    }

    // UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        // Ensure that the data source of this tableView won't be accessed by an indexPath out of range
        guard tableView.cellForRow(at: indexPath) != nil else { return }

        didSelectAlbum?(albums[indexPath.row])
    }

    // UITableViewDataSource
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let reuseID = String(describing: AlbumListCell.self)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: reuseID) as? AlbumListCell else {
            return UITableViewCell()
        }
        let album = albums[indexPath.row]
        if let asset = album.firstObject {
            cell.assetIdentifier = asset.localIdentifier
            _ = try? AlbumEntry.requestImage(forToken: AssetBrowserToken.requestImage.token,
                                             manager: imageManager,
                                             forAsset: asset,
                                             targetSize: cell.thumbnailSize,
                                             contentMode: .aspectFill,
                                             options: nil,
                                             resultHandler: { (image, _) in

                                    if cell.assetIdentifier ?? "" == asset.localIdentifier {
                                        cell.set(thumbnailImage: image)
                                    }
                })
        }
        cell.set(title: album.localizedTitle, subTitle: "\(album.assetsCount)")
        return cell
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albums.count
    }

    // UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        return !tableView.convert(tableView.bounds, to: view).contains(touch.location(in: view))
    }
}
