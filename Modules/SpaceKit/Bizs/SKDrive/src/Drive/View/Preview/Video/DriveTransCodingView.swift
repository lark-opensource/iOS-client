//longweiwei

import Foundation
import SKResource
import SKCommon
import SKFoundation
import UniverseDesignColor
import UniverseDesignEmpty
import UniverseDesignButton
import LarkDocsIcon

class DriveTransCodingView: UIView {

    weak var delegate: DriveUnSupportFileViewDelegate?
    var downloadForPreviewHandler: (() -> Void)?

    private var displayMode: DrivePreviewMode = .normal

    var fileType = DriveFileType(fileExtension: "unknown") {
        didSet {
            updateUI()
        }
    }

    // LoadingView
    private lazy var loadingView = DocsUDLoadingImageView()

    private lazy var openWith3rdAppButton: UDButton = {
        var openWith3rdAppButton = UDButton()
        openWith3rdAppButton.setTitle(BundleI18n.SKResource.Drive_Drive_OpenWithOtherApps, for: .normal)
        openWith3rdAppButton.config = UDButtonUIConifg(normalColor: UDEmpty.primaryColor, type: .middle)
        openWith3rdAppButton.addTarget(self, action: #selector(openWith3rdApp(_:)), for: .touchUpInside)
        openWith3rdAppButton.layer.masksToBounds = true
        openWith3rdAppButton.titleLabel?.font = UIFont.systemFont(ofSize: fontSize).medium
        openWith3rdAppButton.layer.cornerRadius = cornerRadius
        openWith3rdAppButton.contentEdgeInsets = UIEdgeInsets(horizontal: 20, vertical: 0)
        return openWith3rdAppButton
    }()

    private lazy var downloadForLocalPlaybackButton: UDButton = {
        var downloadForLocalPlaybackButton = UDButton()
        downloadForLocalPlaybackButton.setTitle(BundleI18n.SKResource.LarkCCM_Docs_FileBlock_DownloadVideosToWatchOffline_Button_Mob, for: .normal)
        downloadForLocalPlaybackButton.config = UDButtonUIConifg(normalColor: UDEmpty.secordaryColor, type: .middle)
        downloadForLocalPlaybackButton.addTarget(self, action: #selector(downloadForLocalPlayback(_:)), for: .touchUpInside)
        downloadForLocalPlaybackButton.layer.masksToBounds = true
        downloadForLocalPlaybackButton.titleLabel?.font = UIFont.systemFont(ofSize: fontSize).medium
        downloadForLocalPlaybackButton.layer.cornerRadius = cornerRadius
        downloadForLocalPlaybackButton.contentEdgeInsets = UIEdgeInsets(horizontal: 20, vertical: 0)
        return downloadForLocalPlaybackButton
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    init(mode: DrivePreviewMode) {
        super.init(frame: .zero)
        self.displayMode = mode
        setupUI()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        DocsLogger.driveInfo("DriveTransCodingView-----deinit")
    }

    private func setupUI() {
        backgroundColor = UDColor.bgBase
        addSubview(loadingView)
        loadingView.snp.makeConstraints { (make) in
            make.edges.equalToSuperview()
        }

        loadingView.textFontSize = textFontSize
        loadingView.textTopMargin = textTopMargin
        loadingView.loadingSize = iconSize
        loadingView.label.textColor = UDColor.textTitle
        loadingView.isHidden = false

        loadingView.addSubview(openWith3rdAppButton)
        openWith3rdAppButton.isHidden = (displayMode == .card)
        openWith3rdAppButton.snp.makeConstraints { (make) in
            make.top.equalTo(loadingView.label.snp.bottom).offset(26)
            make.centerX.equalToSuperview()
            make.height.equalTo(buttonHeight)
        }

        loadingView.addSubview(downloadForLocalPlaybackButton)
        downloadForLocalPlaybackButton.isHidden = true
        downloadForLocalPlaybackButton.snp.makeConstraints { (make) in
            make.top.equalTo(openWith3rdAppButton.snp.bottom).offset(12)
            make.centerX.equalToSuperview()
            make.height.equalTo(buttonHeight)
        }
    }

    private func updateUI() {
        loadingView.label.text =
            fileType.isVideo
            ? BundleI18n.SKResource.LarkCCM_IM_VideoTranscoding_Empty
            : BundleI18n.SKResource.Drive_Sdk_WaitingForTranscode

        let buttonEnabled = UserScopeNoChangeFG.CWJ.enableUserDownloadVideoDuringTranscoding
        let hideButton = (displayMode == .card)
        downloadForLocalPlaybackButton.isHidden = (!(buttonEnabled && fileType.isVideo && fileType.isSupport) || hideButton)
    }

    private var buttonHeight: CGFloat {
        return (displayMode == .card) ? 28 : 36
    }

    private var fontSize: CGFloat {
        return (displayMode == .card) ? 14 : 17
    }

    private var cornerRadius: CGFloat {
        return (displayMode == .card) ? 6 : 8
    }

    private var textFontSize: CGFloat {
        return (displayMode == .card) ? 14 : 17
    }

    private var textTopMargin: CGFloat {
        return (displayMode == .card) ? 8 : 11
    }

    private var loadingCenter: Bool {
        return (displayMode == .card)
    }

    private var iconSize: CGSize? {
        return (displayMode == .card) ? CGSize(width: 75, height: 75) : nil
    }

    @objc
    func openWith3rdApp(_ button: UIButton) {
        DocsLogger.driveInfo("click open with other app")
        delegate?.didClickOpenWith3rdApp(button: button)
    }

    @objc
    func downloadForLocalPlayback(_ button: UIButton) {
        DocsLogger.driveInfo("click download for local playback")
        downloadForPreviewHandler?()
    }
}

extension DriveTransCodingView: DKViewModeChangable {
    func changeMode(_ mode: DrivePreviewMode, animate: Bool) {
        guard displayMode != mode else { return }
        displayMode = mode

        loadingView.textFontSize = textFontSize
        loadingView.textTopMargin = textTopMargin
        loadingView.loadingSize = iconSize

        let buttonEnabled = UserScopeNoChangeFG.CWJ.enableUserDownloadVideoDuringTranscoding
        let hideButton = (displayMode == .card)
        updateButton(button: openWith3rdAppButton, hidden: hideButton)
        updateButton(button: downloadForLocalPlaybackButton,
                     hidden: (!(buttonEnabled && fileType.isVideo && fileType.isSupport) || hideButton))

        if animate {
            UIView.animate(withDuration: 0.25) {
                self.setNeedsLayout()
                self.layoutIfNeeded()
            }
        }
    }

    private func updateButton(button: UIButton, hidden: Bool) {
        button.isHidden = hidden
        button.snp.updateConstraints { make in
            make.height.equalTo(buttonHeight)
        }
        button.titleLabel?.font = UIFont.systemFont(ofSize: fontSize).medium
        button.layer.cornerRadius = cornerRadius
    }
}
