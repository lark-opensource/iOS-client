//
//  OperationDialogController.swift
//  LarkWorkplace
//
//  Created by zhysan on 2021/8/17.
//

import UIKit
import UniverseDesignIcon
import LarkUIKit
import LarkAccountInterface
import LarkNavigator
import LKCommonsLogging

private enum Const {
    enum Style {
        enum CloseBtn {
            static let innerSize: CGFloat = 32.0
            static let outterSize: CGFloat = 44.0
            static let marginB: CGFloat = 16.0
        }

        enum Container {
            static let margin: CGFloat = 36.0
            static let minW: CGFloat = 174.0
            static let minH: CGFloat = 180.0
        }
    }
}

private func ratioSize(for config: CGSize, min: CGSize, max: CGSize) -> CGSize {
    if config.width <= 0 || config.height <= 0 {
        return min
    }
    if config.width < min.width {
        let scale = min.width / config.width
        var scaleSize = CGSize(width: config.width * scale, height: config.height * scale)
        if scaleSize.height > max.height {
            scaleSize.height = max.height
        }
        return ratioSize(for: scaleSize, min: min, max: max)
    }
    if config.height < min.height {
        let scale = min.height / config.height
        var scaleSize = CGSize(width: config.width * scale, height: config.height * scale)
        if scaleSize.width > max.width {
            scaleSize.width = max.width
        }
        return ratioSize(for: scaleSize, min: min, max: max)
    }
    if config.width > max.width {
        let scale = max.width / config.width
        var scaleSize = CGSize(width: config.width * scale, height: config.height * scale)
        if scaleSize.height < min.height {
            scaleSize.height = min.height
        }
        return ratioSize(for: scaleSize, min: min, max: max)
    }
    if config.height > max.height {
        let scale = max.height / config.height
        var scaleSize = CGSize(width: config.width * scale, height: config.height * scale)
        if scaleSize.width < min.width {
            scaleSize.width = min.width
        }
        return ratioSize(for: scaleSize, min: min, max: max)
    }
    return config
}

protocol OperationDialogControllerDelegate: NSObjectProtocol {
    func onImageDialogClick(_ vc: OperationDialogController, link: String?, context: WorkplaceContext)
}

final class OperationDialogController: BaseUIViewController {
    static let logger = Logger.log(OperationDialogController.self)

    // MARK: - public
    weak var delegate: OperationDialogControllerDelegate?

    // MARK: - private properties
    /// 弹窗内容容器 View
    private var container = UIView()

    /// 视频 View
    private lazy var medView: OperationDialogVideoView = {
        let session = userService.user.sessionKey ?? ""
        let imageFetcher = WPCacheTool.imageFetcher(withSession: true, session: session)
        let vi = OperationDialogVideoView(imageFetcher: imageFetcher, session: session)
        container.addSubview(vi)
        vi.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        return vi
    }()

    /// 图片 View
    private lazy var imgView: OperationDialogImageView = {
        let userSession = userService.user.sessionKey ?? ""
        let imageFetcher = WPCacheTool.imageFetcher(withSession: true, session: userSession)
        let vi = OperationDialogImageView(imageFetcher: imageFetcher)
        container.addSubview(vi)
        vi.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        vi.eventHandler = { [weak self] (_, action) in
            guard let self = self else { return }
            if action == .retry {
                self.loadDialogData()
            } else if action == .onTap {
                let link = self.dialogData.notification.content.parseElement.url
                self.delegate?.onImageDialogClick(self, link: link, context: self.context)
            }
        }
        return vi
    }()

    /// 关闭按钮
    private var closeBtn: UIButton = {
        let ins = UIButton(type: .custom)
        ins.addTarget(self, action: #selector(onClose(_:)), for: .touchUpInside)
        let vi = UIImageView()
        ins.addSubview(vi)
        vi.image = UDIcon.moreCloseOutlined.ud.withTintColor(UIColor.ud.primaryOnPrimaryFill.withAlphaComponent(0.9))
        vi.snp.makeConstraints { make in
            make.size.equalTo(Const.Style.CloseBtn.innerSize)
            make.center.equalToSuperview()
        }
        return ins
    }()

    /// 弹窗数据结构
    private let dialogData: OperationDialogData
    private let userService: PassportUserService

    let context: WorkplaceContext

    // MARK: life cycle

    init(
        context: WorkplaceContext,
        dialogData: OperationDialogData,
        delegate: OperationDialogControllerDelegate?,
        userService: PassportUserService
    ) {
        self.context = context
        self.dialogData = dialogData
        self.userService = userService
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        Self.logger.debug("[wp] deinit: \(type(of: self))")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupSubviews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        loadDialogData()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }

    // MARK: - public

    // MARK: - private

    private func loadDialogData() {
        let element = dialogData.notification.content.parseElement
        switch element.tag {
        case .img:
            loadImageElement(element)
        case .med:
            loadVideoElement(element)
        }
    }

    private func loadImageElement(_ element: OperationNotificationElement) {
        guard element.tag == .img else {
            assertionFailure("invalid element!")
            return
        }
        guard let urlStr = element.imageUrl, let url = URL(string: urlStr) else {
            imgView.loadImage(nil)
            return
        }
        imgView.loadImage(url)
    }

    private func loadVideoElement(_ element: OperationNotificationElement) {
        guard element.tag == .med else {
            assertionFailure("invalid element!")
            return
        }
        guard let urlStr = element.videoUrl, let url = URL(string: urlStr) else {
            medView.loadVideo(nil, coverURL: nil)
            return
        }
        var coverURL: URL?
        if let coverURLStr = element.imageUrl {
            coverURL = URL(string: coverURLStr)
        }
        medView.loadVideo(url, coverURL: coverURL)
    }

    private func setupSubviews() {
        isNavigationBarHidden = true
        view.backgroundColor = .clear

        view.addSubview(container)
        container.backgroundColor = UIColor.clear
        updateContainerSize()

        view.addSubview(closeBtn)
        let inset = (Const.Style.CloseBtn.outterSize - Const.Style.CloseBtn.innerSize) * 0.5
        closeBtn.snp.makeConstraints { make in
            make.width.height.equalTo(Const.Style.CloseBtn.outterSize)
            make.right.equalTo(container).offset(inset)
            make.bottom.equalTo(container.snp.top).offset(-Const.Style.CloseBtn.marginB + inset)
        }
    }

    private func updateContainerSize() {
        let vw = view.bounds.size.width
        let vh = view.bounds.size.height
        let l1 = Const.Style.Container.margin
        let l2 = Const.Style.CloseBtn.innerSize
        let l3 = Const.Style.CloseBtn.marginB

        let content = dialogData.notification.content
        let element = content.parseElement
        let configSize = CGSize(width: content.config.width, height: content.config.height)

        let containerSize: CGSize
        switch element.tag {
        case .img:
            let imgMinW = Const.Style.Container.minW
            let imgMinH = Const.Style.Container.minH
            let minSize = CGSize(width: imgMinW, height: imgMinH)

            let imgMaxW = vw - 2 * l1
            let imgMaxH = vh - 2 * (l1 + l2 + l3)
            let maxSize = CGSize(width: imgMaxW, height: imgMaxH)

            containerSize = ratioSize(for: configSize, min: minSize, max: maxSize)
            Self.logger.info("[dialog] size: \(containerSize), min: \(minSize), max: \(maxSize)")
        case .med:
            let medMinW = vw - 2 * l1
            let medMinH = Const.Style.Container.minH
            let minSize = CGSize(width: medMinW, height: medMinH)

            let medMaxW = vw - 2 * l1
            let medMaxH = vh - 2 * (l1 + l2 + l3)
            let maxSize = CGSize(width: medMaxW, height: medMaxH)

            containerSize = ratioSize(for: configSize, min: minSize, max: maxSize)
            Self.logger.info("[dialog] size: \(containerSize), min: \(minSize), max: \(maxSize)")
        }

        container.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(containerSize)
        }
    }

    @objc
    private func onClose(_ sender: Any) {
        Self.logger.info("[dialog] on close")
        dismiss(animated: true, completion: nil)
    }
}
