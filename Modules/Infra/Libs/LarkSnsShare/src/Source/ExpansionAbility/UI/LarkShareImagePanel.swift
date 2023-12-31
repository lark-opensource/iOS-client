//
//  LarkShareImagePanel.swift
//  LarkSnsPanel
//
//  Created by Siegfried on 2021/12/8.
//

import Foundation
import UIKit
import SnapKit
import UniverseDesignLoading
import ByteWebImage
import RxSwift
import RxCocoa
import UniverseDesignButton
import LarkEmotion

final class LarkShareImagePanel: UIViewController, PanelHeaderCloseDelegate {
    weak var delegate: LarkShareItemClickDelegate?
    private var productLevel: String
    private var scene: String

    func showImageAndHideLoading(with image: UIImage?) {
        self.imagePreView.setImage(image: image)
        self.imagePanelLoadingView.isHidden = true
        self.imagePanelContainer.isHidden = false
    }

    private var imagePanelLoadingView = UDLoading.loadingImageView(lottieResource: nil)
    /// 控件容器
    private lazy var imagePanelContainer: UIStackView = {
        let container = UIStackView()
        container.spacing = ShareCons.defaultSpacing
        container.alignment = .center
        container.axis = .vertical
        container.translatesAutoresizingMaskIntoConstraints = false
        container.isHidden = true
        return container
    }()
    private lazy var imageHeaderView = ImageHeaderView(productLevel, scene)
    private lazy var imagePreViewContainer: UIStackView = {
        let container = UIStackView()
        container.spacing = ShareCons.defaultSpacing
        container.alignment = .center
        container.axis = .vertical
        container.translatesAutoresizingMaskIntoConstraints = false
        return container
    }()
    private lazy var divideLine = UIView()
    private lazy var imagePreView = ImagePreView()
    private lazy var shareOptionArea = ShareOptionSingleLineView(shareTypes: self.imageShareTypes)
    private lazy var containerFooterView = UIView()

    private var imageShareTypes: [LarkShareItemType]
    init(_ imageShareTypes: [LarkShareItemType],
         delegate: LarkShareItemClickDelegate? = nil,
         _ productLevel: String,
         _ scene: String) {
        self.imageShareTypes = imageShareTypes
        self.delegate = delegate
        self.productLevel = productLevel
        self.scene = scene

        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
    }
    private func setup() {
        setupSubViews()
        setupConstraints()
        setupAppearance()
    }

    private func setupSubViews() {
        self.view.addSubview(imagePanelLoadingView)
        self.view.addSubview(imagePanelContainer)
        self.imagePreViewContainer.addArrangedSubview(imagePreView)
        self.imagePreViewContainer.addArrangedSubview(divideLine)
        self.imagePanelContainer.addArrangedSubview(imageHeaderView)
        self.imagePanelContainer.addArrangedSubview(imagePreViewContainer)
        self.imagePanelContainer.addArrangedSubview(shareOptionArea)
        imagePanelContainer.addArrangedSubview(containerFooterView)
    }

    private func setupConstraints() {
        imagePanelLoadingView.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        imagePanelContainer.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        imagePreViewContainer.snp.makeConstraints { make in
            make.width.equalToSuperview()
        }
        divideLine.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(ShareCons.panelDivideLineHeight)
        }
        imageHeaderView.snp.makeConstraints { make in
            make.width.top.equalToSuperview()
            make.height.equalTo(ShareCons.imagePanelHeaderHeight)
        }
        imagePreView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(ShareCons.defaultSpacing)
            make.right.equalToSuperview().inset(ShareCons.defaultSpacing)
        }
        shareOptionArea.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(ShareCons.shareCellItemSize.height)
        }
        containerFooterView.snp.makeConstraints { make in
            make.width.equalToSuperview()
            make.height.equalTo(ShareCons.defaultSpacing / 2)
            self.imagePanelContainer.setCustomSpacing(0, after: shareOptionArea)
        }
    }

    private func setupAppearance() {
        self.modalPresentationCapturesStatusBarAppearance = true
        self.view.backgroundColor = ShareColor.panelBackgroundColor
        self.divideLine.backgroundColor = ShareColor.panelDivideLineColor
        imageHeaderView.delegate = self
        shareOptionArea.onShareItemViewClicked = { [weak self] clickedType in
            guard let self = self else { return }
            self.delegate?.shareItemDidClick(itemType: clickedType)
        }
    }

    func dismissCurrentVC(animated: Bool = true) {
        dismiss(animated: animated) { [weak self] in
            self?.delegate?.sharePanelDidClosed()
        }
    }
}

extension LarkShareImagePanel: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
            return true
        }
}
