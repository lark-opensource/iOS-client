//
//  ReadingDataViewController.swift
//  SpaceKit
//
//  Created by Webster on 2019/2/28.
//

import Foundation
import SkeletonView
import SwiftyJSON
import SKUIKit
import SKResource
import SKFoundation
import UniverseDesignColor

/// 文档阅读数据类型
///
/// - wordNumber: 单词数
/// - charNumber: 字符数
/// - readerNumber: 阅读人数
/// - readingTimer: 阅读次数
/// - thumbUpNumber: 点赞次数
public enum ReadingDataType {
    case wordNumber
    case charNumber
    case readerNumber
    case readingTimer
    case thumbUpNumber
    case fileType
    case fileSize

    /// UI展示的名字
    var name: String {
        switch self {
        case .wordNumber:
            return BundleI18n.SKResource.Doc_Doc_WordsCount
        case .charNumber:
            return BundleI18n.SKResource.Doc_Doc_CharacterCount
        case .readerNumber:
            return BundleI18n.SKResource.Doc_Doc_ReaderCount
        case .readingTimer:
            return BundleI18n.SKResource.Doc_Doc_ReadingCount
        case .thumbUpNumber:
            return BundleI18n.SKResource.Doc_Doc_ThumbUpCount
        case .fileType:
            return BundleI18n.SKResource.Drive_Drive_FileType
        case .fileSize:
            return BundleI18n.SKResource.Drive_Drive_FileSize
        }
    }
}

enum FileInfoType {
    case ownerInfo
    case createTime
    case titleInfo
}

//public protocol ReadingDataViewControllerDelegate: AnyObject {
//    func readingDataViewControllerDidDismiss(_ controller: ReadingDataViewController)
//}

/*
public class ReadingDataViewController: SKWidgetViewController, UICollectionViewDelegateFlowLayout,
                                        UICollectionViewDelegate, SkeletonCollectionViewDataSource,
                                        ReadingDetailControllerType {
    public weak var delegate: ReadingDataViewControllerDelegate?
    weak var fromVC: UIViewController?
    private let docsInfo: DocsInfo
    private var viewHeight: CGFloat = 476
    private let panelHeight: CGFloat = 75
    private let headerHeight: CGFloat = 48
    private let itemPadding: CGFloat = 24
    private var panelInfos: [ReadingPanelInfo]
    private var filePanelInfos: [FilePanelInfo]
    private var headerReuseIdentifier = "ReadingData.Header"
    private var fileCellResuseIdentifier = "FileInfo.Cell"
    private var cellResuseIdentifier = "ReadingData.Cell"
    private var dynamicResuseIdentifier = "ReadingData.Dynamic"
    private var multiTitleCellResuseIdentifier = "ReadingDataMultiTitle.Cell"
    private var hostSize: CGSize
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        layout.minimumLineSpacing = 24
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.contentInsetAdjustmentBehavior = .never
        view.register(ReadingDataPenelHeader.self,
                      forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                      withReuseIdentifier: headerReuseIdentifier)
        view.register(ReadingDataPanelCell.self, forCellWithReuseIdentifier: cellResuseIdentifier)
        view.register(FileInfoPanelCell.self, forCellWithReuseIdentifier: fileCellResuseIdentifier)
        view.register(DynamicTitleCell.self, forCellWithReuseIdentifier: dynamicResuseIdentifier)
        view.backgroundColor = UDColor.bgBody
        view.dataSource = self
        view.delegate = self
        return view
    }()

    public init(_ info: DocsInfo,
         readingPanelInfo: [ReadingPanelInfo],
         hostSize: CGSize,
         fromVC: UIViewController?) {
        self.hostSize = hostSize
        self.filePanelInfos = ReadingDataViewController.dynamicMakeFilePanelInfo(info, width: hostSize.width)
        self.docsInfo = info
        self.panelInfos = readingPanelInfo
        self.fromVC = fromVC
        viewHeight = headerHeight + CGFloat(panelInfos.count) * panelHeight + CGFloat(panelInfos.count + 1) * itemPadding + ReadingDataViewController.fileInfoSectionHeight(filePanelInfos)
        if viewHeight > (hostSize.height * 0.8) {
            viewHeight = hostSize.height * 0.8
        }
        super.init(contentHeight: viewHeight)
        contentView.addSubview(collectionView)
        collectionView.snp.makeConstraints { (make) in
            make.top.right.bottom.left.equalToSuperview()
        }
        if SKDisplay.pad {
            modalPresentationStyle = .formSheet
        }
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(willChangeStatusBarOrientation),
                                               name: UIApplication.willChangeStatusBarOrientationNotification,
                                               object: nil)
        DocsDetailInfoReport.detailView.report(docsInfo: info)
    }

    @objc
    func willChangeStatusBarOrientation() {
        dismiss(animated: false)
    }

    public func refresh(info: DocsReadingData?, data: [ReadingPanelInfo], avatarUrl: String?, success: Bool) {
        var newPanelInfo = [FilePanelInfo]()
        for item in filePanelInfos {
            var oldItem = item
            if oldItem.type == .ownerInfo {
                oldItem.imgURL = avatarUrl ?? ""
            }
            if oldItem.type == .ownerInfo, oldItem.text.count == 0, let name = getDisplayName(from: info) {
                oldItem.text = name
            }
            // 在iPad情况下不能使用hostSize做为当前的size
            if SKDisplay.pad, oldItem.type == .titleInfo {
                if self.hostSize.width != self.view.bounds.size.width {
                    let height = DynamicTitleCell.calcuDynamicHeight(for: self.view.bounds.size.width, text: oldItem.text)
                    oldItem.size = CGSize(width: self.view.bounds.size.width, height: height)
                }
            }
            newPanelInfo.append(oldItem)
        }
        filePanelInfos = newPanelInfo
        panelInfos = data
        collectionView.reloadData()
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if SKDisplay.pad {
            // 重置iPad的约束
            backgroundView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            contentView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
        }
    }

    open override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag, completion: completion)
        delegate?.readingDataViewControllerDidDismiss(self)
    }

    override public func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        super.willTransition(to: newCollection, with: coordinator)
        dismiss(animated: true)
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        coordinator.animate(alongsideTransition: nil) { _ in
            self.collectionView.collectionViewLayout.invalidateLayout()
        }
    }
    
    /// 构建文档信息、文档创建时间、文档title的信息（整理自天任的代码）
    class func dynamicMakeFilePanelInfo(_ info: DocsInfo, width: CGFloat) -> [FilePanelInfo] {

        var titleTitle = BundleI18n.SKResource.Doc_Doc_SheetTitle
        if info.inherentType == .bitable {
             titleTitle = BundleI18n.SKResource.Doc_Doc_BitableTitle
        }

        var ownerTitle = BundleI18n.SKResource.Doc_More_DocumentOwner
        if info.inherentType == .sheet {
            ownerTitle = BundleI18n.SKResource.Doc_Doc_SheetOwner
        } else if info.inherentType == .bitable {
             ownerTitle = BundleI18n.SKResource.Doc_Doc_BitableOwner
        }

        var timeTitle = BundleI18n.SKResource.Doc_More_CreationTime
        if info.inherentType == .sheet {
            timeTitle = BundleI18n.SKResource.Doc_Doc_SheetCreationTime
        } else if info.inherentType == .bitable {
             timeTitle = BundleI18n.SKResource.Doc_Doc_BitableCreationTime
        }
        
        var titleInfo = FilePanelInfo()
        titleInfo.title = titleTitle
        titleInfo.text = info.name ?? ""
        titleInfo.showImage = true
        titleInfo.type = .titleInfo
        let height = DynamicTitleCell.calcuDynamicHeight(for: width, text: titleInfo.text)
        titleInfo.size = CGSize(width: width, height: height)

        //用户信息
        var userPanelInfo = FilePanelInfo()
        userPanelInfo.title = ownerTitle
        userPanelInfo.text = info.displayName
        userPanelInfo.showImage = true
        userPanelInfo.type = .ownerInfo

        var timePanelInfo = FilePanelInfo()
        if let timeInterval = info.createTime {
            timePanelInfo.text = timeInterval.creationTime
        }
        timePanelInfo.image = BundleResources.SKResource.Doc.docs_fileinfo_date
        timePanelInfo.title = timeTitle
        timePanelInfo.showImage = true
        timePanelInfo.type = .createTime

        if info.type == .sheet || info.type == .bitable {
            return [titleInfo, userPanelInfo, timePanelInfo]
        } else {
            return [userPanelInfo, timePanelInfo]
        }
    }

    class func fileInfoSectionHeight(_ infos: [FilePanelInfo]) -> CGFloat {
        var height: CGFloat = 0
        for item in infos {
            height += item.size.height
        }
        let padding = CGFloat(infos.count) * 24
        return height + padding
    }
    
    private func getDisplayName(from model: DocsReadingData?) -> String? {
        guard case .details(let readingInfo) = model else { return nil }
        guard let user = readingInfo?.user else { return nil }
        return DocsSDK.currentLanguage == .en_US ? user.enName : user.cnName
    }
    // MARK: - UICollectionViewDelegateFlowLayout
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return section == 0 ? CGSize(width: collectionView.frame.width, height: headerHeight) : .zero
    }
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 24, left: 0, bottom: section == 0 ? 0 : 24, right: 0)
    }

    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            let size = CGSize(width: collectionView.frame.width, height: filePanelInfos[indexPath.row].size.height)
            return size
        } else {
            return CGSize(width: collectionView.frame.width, height: panelHeight)
        }
    }
    // MARK: - UICollectionViewDelegate
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.section == 0 else { return }
        let item = filePanelInfos[indexPath.row]
        switch item.type {
        case .ownerInfo:
            openUserProfile()
        default:
            ()
        }

    }

    private func openUserProfile() {
        guard let userID = docsInfo.ownerID, let fromVC = fromVC else {
            spaceAssertionFailure("must have userID and formVC cannot be nil")
            return
        }
        dismiss(animated: false) { [weak self] in
            HostAppBridge.shared.call(ShowUserProfileService(userId: userID, fileName: self?.docsInfo.title, fromVC: fromVC))
        }
    }
    // MARK: - SkeletonCollectionViewDataSource

    public func numSections(in collectionSkeletonView: UICollectionView) -> Int {
        return 1
    }

    public func collectionSkeletonView(_ skeletonView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.panelInfos.count
    }

    public func collectionSkeletonView(_ skeletonView: UICollectionView, cellIdentifierForItemAt indexPath: IndexPath) -> ReusableCellIdentifier {
        return indexPath.section == 0 ? fileCellResuseIdentifier : cellResuseIdentifier
    }

    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 2
    }

    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return section == 0 ? filePanelInfos.count : panelInfos.count
    }

    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        if indexPath.section == 0 {
            let data = filePanelInfos[indexPath.row]
            if data.type == .titleInfo {
                let cell1 = collectionView.dequeueReusableCell(withReuseIdentifier: dynamicResuseIdentifier, for: indexPath)
                guard let cell = cell1 as? DynamicTitleCell else {
                    return cell1
                }
                cell.configure(by: data)
                return cell
            } else {
                let cell1 = collectionView.dequeueReusableCell(withReuseIdentifier: fileCellResuseIdentifier, for: indexPath)
                guard let cell = cell1 as? FileInfoPanelCell else {
                    return cell1
                }
                let panelData = filePanelInfos[indexPath.row]
                cell.configure(by: panelData)
                return cell
            }
        } else {
            let cell1 = collectionView.dequeueReusableCell(withReuseIdentifier: cellResuseIdentifier, for: indexPath)
            guard let cell = cell1 as? ReadingDataPanelCell else {
                return cell1
            }
            let panelData = panelInfos[indexPath.row]
            cell.configure(panelData)
            return cell
        }
    }

    public func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {

        let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerReuseIdentifier, for: indexPath)
        guard let readingHeader = header as? ReadingDataPenelHeader else {
            return UICollectionReusableView()
        }
        var title = BundleI18n.SKResource.Doc_Doc_DocumentDetails
        switch docsInfo.type {
        case .doc:
            title = BundleI18n.SKResource.Doc_Doc_DocumentDetails
        case .sheet:
            title = BundleI18n.SKResource.Doc_Doc_SheetDetails
        case .file:
            title = BundleI18n.SKResource.Drive_Drive_FileDetails
        case .bitable:
            title = BundleI18n.SKResource.Doc_Doc_BitableDetails
        default:
            ()
        }
        readingHeader.needCloseButton = true
        readingHeader.onClose = { [weak self] in
            self?.dismiss(animated: true)
        }
        readingHeader.updateTitle(title: title)
        return readingHeader
    }

}
*/
