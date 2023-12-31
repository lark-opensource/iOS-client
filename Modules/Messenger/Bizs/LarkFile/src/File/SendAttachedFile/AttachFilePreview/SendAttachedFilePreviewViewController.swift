//
//  SendAttachedFilePreviewViewController.swift
//  Lark
//
//  Created by ChalrieSu on 19/12/2017.
//  Copyright © 2017 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import LarkUIKit
import Photos
import LarkExtensions
import LarkMessengerInterface
import LarkEMM
import LarkSensitivityControl

protocol SendAttachedFilePreviewViewControllerDelegate: AnyObject {
    func previewVC(_ vc: SendAttachedFilePreviewViewController, didTapSaveWith selectedAttachedFiles: [AttachedFile])
}

final class SendAttachedFilePreviewViewController: BaseUIViewController, UITableViewDataSource, UITableViewDelegate {

    weak var delegate: SendAttachedFilePreviewViewControllerDelegate?

    private let tableView = UITableView()
    private var aggregateFiles: [LocalAggregateFiles] = []
    private var expandIndexes = IndexSet()

    init(selectedAttachedFiles: [AttachedFile]) {
        aggregateFiles = selectedAttachedFiles.aggregateAttachedFiles.sorted { $0.type.rawValue < $1.type.rawValue }
        super.init(nibName: nil, bundle: nil)
        aggregateFiles.enumerated().forEach { (index, _) in
            expandIndexes.insert(index)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        titleString = BundleI18n.LarkFile.Lark_Legacy_SendFileTitle
        let saveItem = LKBarButtonItem(title: BundleI18n.LarkFile.Lark_Legacy_Save)
        saveItem.setProperty(alignment: .right)
        saveItem.setBtnColor(color: UIColor.ud.primaryContentDefault)
        saveItem.button.addTarget(self, action: #selector(saveBtnTapped), for: .touchUpInside)
        navigationItem.rightBarButtonItem = saveItem

        view.addSubview(tableView)

        tableView.delegate = self
        tableView.dataSource = self
        tableView.lu.register(cellSelf: SendAttachedFilePreviewCell.self)
        tableView.separatorStyle = .none
        tableView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }
    }

    @objc
    private func saveBtnTapped() {
        let allFiles = aggregateFiles.flatMap { $0.files }
        delegate?.previewVC(self, didTapSaveWith: allFiles)
    }
    // MARK: - UITableViewDataSource, UITableViewDelegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 64
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let aggregateFile = aggregateFiles[section]
        if aggregateFile.filesCount > 0 {
            return 52
        } else {
            return 0
        }
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let aggregateFile = aggregateFiles[section]
        if aggregateFile.filesCount > 0 {
            let headerView = SendAggregatedAttachedFileHeaderView()
            headerView.setContent(name: aggregateFile.displayName,
                                  count: aggregateFile.filesCount,
                                  expand: expandIndexes.contains(section)) { [weak self, weak tableView] (_) in
                                    guard let `self` = self else { return }
                                    if self.expandIndexes.contains(section) {
                                        self.expandIndexes.remove(section)
                                    } else {
                                        self.expandIndexes.insert(section)
                                    }
                                    UIView.performWithoutAnimation {
                                        tableView?.reloadSections([section], with: .none)
                                    }
            }
            return headerView
        } else {
            return nil
        }
    }

    // swiftlint:disable did_select_row_protection
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
    }
    // swiftlint:enable did_select_row_protection

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var aggregateFile = aggregateFiles[indexPath.section]
        let attachFile = aggregateFile.fileAtIndex(indexPath.row)

        let cellID = String(describing: SendAttachedFilePreviewCell.self)
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellID) as? SendAttachedFilePreviewCell else {
            return UITableViewCell()
        }
        cell.setContent(fileId: attachFile.id,
                        name: attachFile.name,
                        size: attachFile.size,
                        duration: attachFile.videoDuration,
                        isVideo: attachFile.type == .albumVideo || attachFile.type == .localVideo,
                        isLastRow: indexPath.row == (aggregateFile.filesCount - 1),
                        closeButtonClickedBlock: { [weak tableView, weak self] (_) in
                            aggregateFile.removeFile(attachFile)
                            self?.aggregateFiles[indexPath.section] = aggregateFile
                            tableView?.reloadSections([indexPath.section], with: .none)
        })
        if let albumFile = attachFile as? AlbumFile {
            try? AlbumEntry.requestImage(forToken: FileToken.requestImage.token,
                                         manager: PHCachingImageManager.default(),
                                         forAsset: albumFile.asset,
                                         targetSize: CGSize(width: 40, height: 40) * UIScreen.main.scale,
                                         contentMode: .aspectFill,
                                         options: nil,
                                         resultHandler: { (image, _) in
                                            if cell.fileId ?? "" == albumFile.asset.localIdentifier {
                                                cell.setImage(image)
                                            }
                            })
        } else if let file = attachFile as? LocalFile {
            cell.setImage(file.previewImage())
        }
        return cell
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        return aggregateFiles.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let aggregateFile = aggregateFiles[section]
        if expandIndexes.contains(section) {
            return aggregateFile.filesCount
        } else {
            return 0
        }
    }
}
