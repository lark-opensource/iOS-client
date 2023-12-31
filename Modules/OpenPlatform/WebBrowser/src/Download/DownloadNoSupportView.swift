//
//  DownloadNoSupportView.swift
//  WebBrowser
//
//  Created by Ding Xu on 2022/7/20.
//

import Foundation
import UIKit
import UniverseDesignEmpty

class DownloadNoSupportView: UIView {
    weak var delegate: DownloadPercentHandleProtocol?
    
    var downloadedBytes: Int64 = 0 {
        didSet {
            updatePercent()
        }
    }
    var totalBytes: Int64? {
        didSet {
            updatePercent()
        }
    }
    
    private var percent: CGFloat = 0.0 {
        didSet {
            setTitleAttributedString(self.descriptionText)
            self.bar.updatePercent(self.percent)
        }
    }
    
    private var descriptionText: String {
        let downloadedSize = ByteCountFormatter.string(fromByteCount: downloadedBytes, countStyle: .file)
        let expectedSize = totalBytes != nil ? ByteCountFormatter.string(fromByteCount: totalBytes!, countStyle: .file) : nil
        guard let expectedSize = expectedSize else {
            return self.percent == 1.0 ? BundleI18n.WebBrowser.OpenPlatform_PreviewDrive_DownloadCompleted : BundleI18n.WebBrowser.OpenPlatform_PreviewDrive_Downloading
        }
        guard downloadedSize == expectedSize else {
            return "\(downloadedSize)/\(expectedSize)\n\(BundleI18n.WebBrowser.OpenPlatform_PreviewDrive_Downloading)"
        }
        return "\(downloadedSize)/\(expectedSize)\n\(BundleI18n.WebBrowser.OpenPlatform_PreviewDrive_DownloadCompleted)"
    }
    
    private var isComplete: Bool = false
    
    private let contentView: UIView = {
        let view = UIView()
        return view
    }()
    
    private let fileView: UIImageView = {
        let view = UIImageView(image: UDEmptyType.noPreview.defaultImage())
        view.contentMode = .scaleAspectFit
        return view
    }()
    
    private let titleLbl: UILabel = {
        let label = UILabel()
        label.font = DownloadCons.titleFont
        label.textColor = DownloadColor.titleColor
        label.numberOfLines = 0
        label.textAlignment = DownloadCons.titleAlignment
        return label
    }()
    
    private let noPreviewLbl: UILabel = {
        let label = UILabel()
        label.font = DownloadCons.tipsFont
        label.textColor = DownloadColor.tipsColor
        let text = BundleI18n.WebBrowser.OpenPlatform_PreviewDrive_UnsupportedFileFormatTip
        label.text = text
        label.attributedText = NSAttributedString(string: text, attributes: [.paragraphStyle: DownloadCons.tipsParagraphStyle, .baselineOffset: DownloadCons.tipsBaselineOffset, .font: DownloadCons.tipsFont, .foregroundColor: DownloadColor.tipsColor])
        label.numberOfLines = 0
        label.textAlignment = DownloadCons.tipsAlignment
        return label
    }()
    
    private lazy var bar: DownloadProgressBar = {
        let bar = DownloadProgressBar()
        return bar
    }()
    
    private lazy var iconBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.setImage(DownloadIcon.iconDefaultIcon, for: .normal)
        btn.addTarget(self, action: #selector(didClickIconBtn), for: .touchUpInside)
        return btn
    }()
    
    private let descLbl: UILabel = {
        let label = UILabel()
        label.font = DownloadCons.descFont
        label.textColor = DownloadColor.descColor
        label.numberOfLines = 0
        label.textAlignment = DownloadCons.descAlignment
        return label
    }()
    
    private lazy var downloadBtn: UIButton = {
        let btn = UIButton(type: .custom)
        btn.backgroundColor = DownloadColor.downloadBGColor
        btn.titleLabel?.font = DownloadCons.downloadBtnFont
        btn.setTitle(BundleI18n.WebBrowser.OpenPlatform_PreviewDrive_DownloadAndOpen, for: .normal)
        btn.setTitleColor(DownloadColor.downloadTitleColor, for: .normal)
        btn.addTarget(self, action: #selector(didClickDownloadBtn), for: .touchUpInside)
        btn.layer.cornerRadius = DownloadCons.downloadBtnRadius
        return btn
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        updateConstraint()
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setTitleAttributedString(_ text: String) {
        titleLbl.text = text
        titleLbl.attributedText = NSAttributedString(string: text, attributes: [.paragraphStyle: DownloadCons.titleParagraphStyle, .baselineOffset: DownloadCons.titleBaselineOffset, .font: DownloadCons.titleFont, .foregroundColor: DownloadColor.titleColor])
    }
    
    private func setDescAttributedString(_ text :String) {
        descLbl.text = text
        descLbl.attributedText = NSAttributedString(string: text, attributes: [.paragraphStyle: DownloadCons.descParagraphStyle, .baselineOffset: DownloadCons.descBaselineOffset, .font: DownloadCons.descFont, .foregroundColor: DownloadColor.descColor])
    }
    
    private func setTipsAttributedString(_ text :String) {
        noPreviewLbl.text = text
        noPreviewLbl.attributedText = NSAttributedString(string: text, attributes: [.paragraphStyle: DownloadCons.tipsParagraphStyle, .baselineOffset: DownloadCons.tipsBaselineOffset, .font: DownloadCons.tipsFont, .foregroundColor: DownloadColor.tipsColor])
    }
    
    private func setupViews() {
        backgroundColor = UIColor.ud.bgBody
        addSubview(contentView)
        contentView.addSubview(fileView)
        contentView.addSubview(titleLbl)
        contentView.addSubview(noPreviewLbl)
        contentView.addSubview(bar)
        contentView.addSubview(iconBtn)
        contentView.addSubview(descLbl)
        contentView.addSubview(downloadBtn)
        bar.isHidden = true
        iconBtn.isHidden = true
        descLbl.isHidden = true
        downloadBtn.isHidden = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateConstraint()
    }
    
    private func updateConstraint() {
        let offsetY: CGFloat = (UIScreen.main.bounds.height - self.bounds.height) / 2.0
        contentView.snp.remakeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview().offset(-offsetY)
            make.left.equalToSuperview().offset(DownloadCons.contentOffset)
            make.right.equalToSuperview().offset(-DownloadCons.contentOffset)
        }
        
        fileView.snp.remakeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.width.height.equalTo(100)
        }
        
        titleLbl.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(fileView.snp.bottom).offset(DownloadCons.formatTitleSpacing)
        }
        
        noPreviewLbl.snp.remakeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(titleLbl.snp.bottom).offset(4)
        }
        
        let barLeft: CGFloat = (self.bounds.width - DownloadCons.contentOffset * 2 - DownloadCons.progressBarWidth - DownloadCons.statusIconBarSpacing - DownloadCons.statusIconWidth) / 2
        bar.snp.remakeConstraints { make in
            make.left.equalToSuperview().offset(barLeft)
            make.top.equalTo(noPreviewLbl.isHidden ? titleLbl.snp.bottom : noPreviewLbl.snp.bottom).offset(DownloadCons.progressBarTextSpacing)
            make.size.equalTo(CGSize(width: DownloadCons.progressBarWidth, height: DownloadCons.progressBarHeight))
        }
        
        iconBtn.snp.remakeConstraints { make in
            make.left.equalTo(bar.snp.right).offset(DownloadCons.statusIconBarSpacing)
            make.centerY.equalTo(bar)
            make.width.height.equalTo(DownloadCons.statusIconWidth)
            if downloadBtn.isHidden {
                make.bottom.equalToSuperview()
            }
        }
        
        descLbl.snp.remakeConstraints { make in
            make.left.equalTo(bar.snp.left)
            make.right.equalTo(iconBtn.snp.right)
            make.top.equalTo(bar.snp.bottom).offset(DownloadCons.progressBarDescSpacing)
        }
        
        var btnWidth: CGFloat = 0
        if let btnText = downloadBtn.titleLabel?.text {
            btnWidth = (btnText as NSString).boundingRect(with: CGSize(width: Int.max, height: Int(DownloadCons.downloadBtnFont.pointSize)), options: .usesLineFragmentOrigin, attributes: [.font: DownloadCons.downloadBtnFont], context: nil).width
        }
        btnWidth += DownloadCons.downloadBtnFont.pointSize * 2
        if btnWidth > self.bounds.width - DownloadCons.contentOffset * 2 {
            btnWidth = self.bounds.width - DownloadCons.contentOffset * 2
        }
        downloadBtn.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            if isComplete {
                make.top.equalTo(bar.snp.bottom).offset(22)
            } else if descLbl.isHidden {
                make.top.equalTo(noPreviewLbl.snp.bottom).offset(16)
            } else {
                make.top.equalTo(descLbl.snp.bottom).offset(16)
            }
            make.size.equalTo(CGSize(width: btnWidth, height: DownloadCons.downloadBtnHeight))
            if !downloadBtn.isHidden {
                make.bottom.equalToSuperview()
            }
        }
    }
    
    func didCompleteWithError(_ error: Error?) {
        iconBtn.isUserInteractionEnabled = false
        guard let error = error else {
            isComplete = true
            self.percent = 1.0
            setTipsAttributedString(BundleI18n.WebBrowser.OpenPlatform_PreviewDrive_UnsupportedFileFormatTip2)
            bar.updateHighlightColor(DownloadColor.barSuccessColor)
            iconBtn.setImage(DownloadIcon.iconSuccessIcon, for: .normal)
            downloadBtn.setTitle(BundleI18n.WebBrowser.CreationDriveSDK_common_openelsewhere, for: .normal)
            downloadBtn.isHidden = false
            updateConstraint()
            return
        }
        let errorCode = (error as NSError).code
        if errorCode == -999 {
            // 取消下载
            var text = BundleI18n.WebBrowser.OpenPlatform_PreviewDrive_DownloadCanceled
            var btnText = BundleI18n.WebBrowser.OpenPlatform_PreviewDrive_DownloadAndOpen
            if let totalBytes = self.totalBytes {
                let expectedSize = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
                text = "\(expectedSize)\n" + text
                btnText = btnText + " (\(expectedSize))"
            }
            setTitleAttributedString(text)
            downloadBtn.setTitle(btnText, for: .normal)
            
            noPreviewLbl.isHidden = false
            bar.isHidden = true
            iconBtn.isHidden = true
            descLbl.isHidden = true
        } else {
            // 网络异常或其他错误
            var text = BundleI18n.WebBrowser.OpenPlatform_PreviewDrive_DownloadFailed
            if let totalBytes = self.totalBytes {
                let expectedSize = ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
                text = "\(expectedSize)/\(expectedSize)\n" + text
            }
            setTitleAttributedString(text)
            bar.updateHighlightColor(DownloadColor.barFailColor)
            setDescAttributedString(BundleI18n.WebBrowser.OpenPlatform_PreviewDrive_FileDownloadFailed)
            if errorCode == 28 {
                // 若设备存储空间不足
                setDescAttributedString(BundleI18n.WebBrowser.OpenPlatform_PreviewDrive_InsufficientStorageTip)
            }
            downloadBtn.setTitle(BundleI18n.WebBrowser.OpenPlatform_PreviewDrive_DownloadAgainAndOpen, for: .normal)
            
            noPreviewLbl.isHidden = true
            bar.isHidden = false
            iconBtn.isHidden = false
            descLbl.isHidden = false
        }
        downloadBtn.isHidden = false
        updateConstraint()
    }
    
    private func updatePercent() {
        DispatchQueue.main.async {
            guard let totalBytes = self.totalBytes else {
                self.percent = 0.0
                return
            }
            
            self.percent = CGFloat(self.downloadedBytes) / CGFloat(totalBytes)
        }
    }
    
    @objc private func didClickIconBtn() {
        delegate?.didClickCancel()
    }
    
    @objc private func didClickDownloadBtn() {
        iconBtn.isUserInteractionEnabled = true
        guard isComplete else {
            noPreviewLbl.isHidden = false
            bar.updateHighlightColor(UIColor.ud.primaryContentDefault)
            bar.isHidden = false
            iconBtn.isHidden = false
            descLbl.isHidden = true
            downloadBtn.isHidden = true
            updateConstraint()
            delegate?.didClickDownload()
            return
        }
        delegate?.didClickOpenInOthersApps(view: downloadBtn)
    }
}
