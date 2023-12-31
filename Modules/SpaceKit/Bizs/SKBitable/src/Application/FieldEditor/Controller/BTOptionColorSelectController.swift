//
//  BTOptionColorSelectController.swift
//  SKBitable
//
//  Created by zoujie on 2021/12/1.
//  

import Foundation
import SKUIKit
import SnapKit
import SKBrowser
import SKFoundation
import SKResource
import EENavigator
import UniverseDesignIcon
import UniverseDesignColor
import UniverseDesignInput

protocol BTOptionColorSelectDelegate: AnyObject {
    func didClickColor(color: BTColorModel, optionID: String)
}

final class BTOptionColorSelectController: SKPanelController {
    weak var delegate: BTOptionColorSelectDelegate?
    var callback: ((BTColorModel, String) -> ())?
    private var colors: [BTColorModel]
    private var selectedColor: BTColorModel?
    private var optionID: String
    private weak var hostVC: UIViewController?
    //用来判断是该显示返回按钮还是关闭按钮
    private var shouldShowBackButton: Bool

    private lazy var backButton = UIButton().construct { it in
        it.setImage(UDIcon.leftSmallCcmOutlined.ud.withTintColor(UDColor.iconN1), for: [.normal, .highlighted])
        it.backgroundColor = .clear
        it.addTarget(self, action: #selector(didClickBack), for: .touchUpInside)
    }

    private lazy var closeButton = UIButton().construct { it in
        it.setImage(UDIcon.closeSmallOutlined.ud.withTintColor(UDColor.iconN1), for: [.normal, .highlighted])
        it.backgroundColor = .clear
        it.addTarget(self, action: #selector(didClickBack), for: .touchUpInside)
    }

    private lazy var titleView = UILabel().construct { it in
        it.font = .systemFont(ofSize: 17, weight: .medium)
        it.textColor = UDColor.textTitle
        it.textAlignment = .center
    }

    private var colorPickView: ColorPickerCorePanel

    private lazy var headerView = BTOptionMenuHeaderView().construct { it in
        it.backgroundColor = .clear
        it.setTitleView(titleView)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return [.allButUpsideDown]
    }
    
    var onCloseColorPanel: (() -> ())?

    init(colors: [BTColorModel],
         selectedColor: BTColorModel?,
         text: String,
         optionID: String,
         shouldShowBackButton: Bool = true,
         hostVC: UIViewController?) {
        self.colors = colors
        self.hostVC = hostVC
        self.optionID = optionID
        self.shouldShowBackButton = shouldShowBackButton
        self.selectedColor = selectedColor
        colorPickView = ColorPickerCorePanel(frame: .zero,
                                             infos: [],
                                             layoutConfig: ColorPickerLayoutConfig(colorWellTopMargin: 10,
                                                                                   detailColorHeight: 40,
                                                                                   defaultColorCount: 5,
                                                                                   layout: .fixedSpacing(itemSpacing: 10)))
        colorPickView.ignoreColorWellAdditionalMargin = true
        super.init(nibName: nil, bundle: nil)

        titleView.text = text
        initColorView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        onCloseColorPanel?()
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.dismiss(animated: false)
    }

    private func initColorView() {
        let (colorItems, selectedIndexPath) = BTUtil.getColorGroupItems(colors: colors, selectColorId: selectedColor?.id)
        colorPickView.lastHitIndexPath = selectedIndexPath
        colorPickView.updateInfos(infos: colorItems)
        colorPickView.updateColorWellView(bounds: hostVC?.view.bounds ?? .zero)
        colorPickView.delegate = self
    }

    override func setupUI() {
        super.setupUI()
        colorPickView.backgroundColor = view.backgroundColor
        containerView.addSubview(colorPickView)

        if self.modalPresentationStyle != .popover {
            containerView.addSubview(headerView)
            headerView.snp.makeConstraints { make in
                make.height.equalTo(48)
                make.top.left.right.equalTo(containerView.safeAreaLayoutGuide)
                make.bottom.equalTo(colorPickView.snp.top)
            }

            headerView.setLeftView(shouldShowBackButton ? backButton : closeButton)
        }

        colorPickView.snp.makeConstraints { make in
            if self.modalPresentationStyle != .popover {
                make.top.equalTo(headerView.snp.bottom)
                make.bottom.equalTo(containerView.safeAreaLayoutGuide)
            } else {
                make.top.equalTo(containerView.safeAreaLayoutGuide)
                make.bottom.equalTo(containerView.safeAreaLayoutGuide).offset(-16)
            }
            make.left.right.equalTo(containerView.safeAreaLayoutGuide)
            make.height.equalTo(countColorPickerViewHeight())
        }
    }

    @objc
    private func didClickBack() {
        self.dismiss(animated: true)
    }

    private func countColorPickerViewHeight() -> CGFloat {
        return colorPickView.layoutConfig.colorWellHeight + 82
    }
}

extension BTOptionColorSelectController: ColorPickerCorePanelDelegate {
    public func didChooseColor(panel: ColorPickerCorePanel, color: String, isTapDetailColor: Bool) {
        guard let selectedColor = colors.first(where: { $0.color == color }) else { return }
        delegate?.didClickColor(color: selectedColor, optionID: optionID)
        callback?(selectedColor, optionID)
    }
}
