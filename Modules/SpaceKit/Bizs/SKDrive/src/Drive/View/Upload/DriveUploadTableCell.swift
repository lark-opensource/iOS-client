//
//  DriveUploadTableCell.swift
//  SpaceKit
//
//  Created by Duan Ao on 2019/1/21.
//

import UIKit
import SnapKit
import Kingfisher
import SKCommon
import SKResource
import SKFoundation
import UniverseDesignColor

enum DriveUploadStatus: Equatable {
    case waiting
    case uploading(progress: CGFloat)
    case broken
    case completed
    case failNoRetry
    case canceled
}

extension DriveUploadStatus {
    var nameFrontColor: UIColor {
        return UIColor.ud.N900
    }

    var statusFrontColor: UIColor {
        switch self {
        case .broken, .failNoRetry:
            return UIColor.ud.colorfulRed
        default:
            return UIColor.ud.N600
        }
    }
}

protocol DriveUploadTableCellPresenter {
    var wikiImage: UIImage? { get }
    var image: UIImage? { get }
    var name: String { get }
    var uploadStatus: DriveUploadStatus { get }
    var errorCode: String { get }
    var bytesTotal: String { get }
    var bytesTransferred: String { get }
}

extension DriveUploadTableCellPresenter {
    var statusDescription: String {
        switch uploadStatus {
        case .waiting: return BundleI18n.SKResource.Drive_Drive_WaitingForUpload
        case .uploading: return BundleI18n.SKResource.Drive_Drive_Uploading
        case .broken, .failNoRetry, .canceled: return getErrorDescription(errorCode: errorCode)
        case .completed: return BundleI18n.SKResource.Drive_Drive_UploadComplete
        }
    }

    func getErrorDescription(errorCode: String) -> String {
        guard let code = Int(errorCode), let uploadErrorCode = FileUploaderErrorCode(rawValue: code) else {
            return BundleI18n.SKResource.Drive_Drive_UploadInterrupt
        }
        switch uploadErrorCode {
        case .pathError:
            return BundleI18n.SKResource.Drive_Drive_LocalFileIsDeleted
        case .mountPointIsDeleted, .mountPointNotExist:
            return BundleI18n.SKResource.Drive_Drive_SpaceFolderIsDeleted
        case .fileSizeLimited:
            return BundleI18n.SKResource.CreationMobile_Drive_Upload_No_MaxSizeReached_var
        case .mountPointCountLimited, .uploadStorageLimited,
             .userStorageLimited, .mountNodeOutOfSiblingNum, .forbidden:
            return BundleI18n.SKResource.Drive_Drive_UploadInterrupt
        }
    }
}

protocol DriveUploadTableCellDelegate: AnyObject {
    func driveUploadTableCell(_ cell: DriveUploadTableCell, didClick retryButton: UIButton)
}

class DriveUploadTableCell: UITableViewCell {

    static let cellHeight: CGFloat = 68.0
    weak var delegate: DriveUploadTableCellDelegate?

    private(set) var iconView: UIImageView = .init(image: nil)
    private(set) var nameLabel: UILabel = .init()
    private(set) var sizeLabel: UILabel = .init()
    fileprivate var rightIndicator: DriveUploadCellIndicator!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = UDColor.bgBody
        doInitUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension DriveUploadTableCell {

    private func doInitUI() {
        iconView = UIImageView()
        iconView.contentMode = .scaleAspectFill
        contentView.addSubview(iconView)
        iconView.snp.makeConstraints { (make) in
            make.left.equalTo(20)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(48)
        }

        rightIndicator = DriveUploadCellIndicator(frame: .zero)
        rightIndicator.backgroundColor = .clear
        rightIndicator.delegate = self
        contentView.addSubview(rightIndicator)
        rightIndicator.snp.makeConstraints { (make) in
            make.right.equalToSuperview()
            make.height.equalToSuperview()
            make.width.equalTo(100)
            make.centerY.equalToSuperview()
        }

        nameLabel = UILabel(frame: .zero)
        nameLabel.textColor = UDColor.textTitle
        nameLabel.font = UIFont.systemFont(ofSize: 17)
        contentView.addSubview(nameLabel)
        nameLabel.snp.makeConstraints { (make) in
            make.left.equalTo(iconView.snp.right).offset(15)
            make.bottom.equalTo(contentView.snp.centerY).offset(-2)
            make.right.equalTo(rightIndicator.snp.left).offset(-12)
        }

        sizeLabel = UILabel(frame: .zero)
        sizeLabel.textColor = UDColor.textPlaceholder
        sizeLabel.font = UIFont.systemFont(ofSize: 14)
        contentView.addSubview(sizeLabel)
        sizeLabel.snp.makeConstraints { (make) in
            make.left.equalTo(nameLabel.snp.left)
            make.top.equalTo(contentView.snp.centerY).offset(2)
            make.right.lessThanOrEqualTo(rightIndicator.snp.left)
        }
    }

    func render(presenter: DriveUploadTableCellPresenter, isInWiki: Bool) {
        iconView.image = isInWiki ? presenter.wikiImage : presenter.image
        nameLabel.text = presenter.name
        nameLabel.textColor = presenter.uploadStatus.nameFrontColor
        if let byteTotal = presenter.bytesTotal.convertByteCount(),
           let transport = presenter.bytesTransferred.convertByteCount() {
            switch presenter.uploadStatus {
            case .broken, .failNoRetry, .canceled:
                sizeLabel.text = presenter.statusDescription + " / " + byteTotal
            case .waiting:
                sizeLabel.text = byteTotal
            case .uploading, .completed:
                sizeLabel.text = transport + " / " + byteTotal
            }
        } else {
            // 转换字节失败时由展示状态描述兜底
            sizeLabel.text = presenter.statusDescription
            sizeLabel.textColor = presenter.uploadStatus.statusFrontColor
        }
        rightIndicator.render(status: presenter.uploadStatus)
    }
}

extension DriveUploadTableCell: DriveUploadCellIndicatorDelegate {
    func driveUploadCellIndicator(_ indicator: DriveUploadCellIndicator, didClick retryButton: UIButton) {
        delegate?.driveUploadTableCell(self, didClick: retryButton)
    }
}

extension String {
    // 将字节数转换为适合展示的相应单位
    func convertByteCount() -> String? {
        guard let bytes = Int64(self) else {
            DocsLogger.error("convert byte count from rust error")
            return nil
        }
        if bytes < 1024 { return "\(bytes) B" }
        let exp = Int(log2(Double(bytes)) / log2(1024.0))
        let unit = ["KB", "MB", "GB", "TB", "PB", "EB"][exp - 1]
        let number = Double(bytes) / pow(1024, Double(exp))
        return String(format: "%.2f %@", number, unit)
    }
}
