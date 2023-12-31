//
//  BTOptionEditorPanel.swift
//  SKBitable
//
//  Created by zoujie on 2021/10/19.
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
import UIKit

public protocol BTOptionEditorPanelDelegate: AnyObject {
    //点击选择已有选项
    func didClickSelect(model: BTCapsuleModel)
    //点击取消
    func didClickCancel()
    //点击完成
    func didClickDone(model: BTCapsuleModel, editMode: BTOptionEditMode)
    //埋点事件上报
    func trackOptionEditEvent(event: String, params: [String: Any])
}

public enum BTOptionEditMode: String {
    case add //新增选项
    case update //编辑选项
}

public final class BTOptionEditorPanel: SKPanelController {
    private weak var delegate: BTOptionEditorPanelDelegate?
    private weak var gestureManager: BTPanGestureManager?
    private weak var hostVC: UIViewController?
    public var currentViewMinY: CGFloat = 0
    private var viewMaxTop: CGFloat = 0
    private var keyboard: Keyboard?
    private var isIgnoreKeyboardEvent = false
    private var keyboardHeight: CGFloat = 0
    private var defaultColorWellHeight: CGFloat = 124
    private var inputConfig = UDTextFieldUIConfig()
    private var colors: [BTColorModel]
    private var superViewBottomOffset: CGFloat
    private var isSingle: Bool

    private lazy var cancelButton = UIButton().construct { it in
        it.setTitle(BundleI18n.SKResource.Bitable_Common_ButtonCancel, for: .normal)
        it.setTitleColor(UDColor.primaryContentDefault, for: .normal)
        it.hitTestEdgeInsets = UIEdgeInsets(edges: -10)
        it.addTarget(self, action: #selector(didClickCancel), for: .touchUpInside)
    }

    private lazy var doneButton = UIButton().construct { it in
        it.setTitle(BundleI18n.SKResource.Bitable_Common_ButtonDone, for: .normal)
        it.setTitleColor(editMode == .update ? UDColor.primaryContentDefault : UDColor.textDisabled, for: .normal)
        it.hitTestEdgeInsets = UIEdgeInsets(edges: -10)
        it.isEnabled = (editMode == .update)
        it.addTarget(self, action: #selector(didClickDone), for: .touchUpInside)
    }

    private lazy var titleView = UILabel().construct { it in
        it.font = .systemFont(ofSize: 17, weight: .medium)
        it.textColor = UDColor.textTitle
        it.textAlignment = .center
        it.text = BundleI18n.SKResource.Bitable_Option_Modify
    }

    private var colorPickView: ColorPickerCorePanel

    private lazy var similarOptionView = CustomBTOptionButton().construct { it in
        let topSeparator = UIView()
        topSeparator.backgroundColor = UDColor.lineDividerDefault

        it.addSubview(topSeparator)
        topSeparator.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.top.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }
        it.setTitle(text: BundleI18n.SKResource.Bitable_Option_OptionExists)
        it.delegate = self
    }

    private lazy var inputTextView = BTUDConditionalTextField()

    private lazy var editorView = UIView().construct { it in
        inputConfig.textColor = UIColor.docs.rgb(model.color.textColor)
        inputConfig.font = .systemFont(ofSize: 14, weight: .medium)
        inputConfig.backgroundColor = UIColor.docs.rgb(model.color.color)
        inputConfig.placeholderColor = UIColor.docs.rgb(model.color.textColor).withAlphaComponent(0.5)
        inputConfig.contentMargins = UIEdgeInsets(top: 2, left: 12, bottom: 2, right: 12)

        inputTextView = BTUDConditionalTextField()
        inputTextView.text = model.text
        inputTextView.config = inputConfig
        inputTextView.placeholder = model.text.isEmpty ? BundleI18n.SKResource.Bitable_Option_PleaseEnter : model.text
        inputTextView.input.addTarget(self, action: #selector(textDidChange(_:)), for: .editingChanged)

        let bottomSeparator = UIView()
        bottomSeparator.backgroundColor = UDColor.lineDividerDefault

        it.addSubview(inputTextView)
        it.addSubview(bottomSeparator)

        bottomSeparator.snp.makeConstraints { make in
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview()
            make.leading.trailing.equalToSuperview()
        }

        inputTextView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.lessThanOrEqualTo(view.bounds.width - 32)
            make.height.equalTo(26)
        }

        inputTextView.backgroundColor = UIColor.docs.rgb(model.color.color)
        inputTextView.layer.cornerRadius = 12
    }

    private lazy var headerView = BTOptionMenuHeaderView().construct { it in
        it.backgroundColor = .clear
        it.setLeftView(cancelButton)
        it.setRightView(doneButton)
        it.setTitleView(titleView)
    }

    private lazy var bottomMaskView = UIView().construct { it in
        it.backgroundColor = UDColor.bgBody
    }

    private var model: BTCapsuleModel
    private var models: [BTCapsuleModel]
    private var editMode: BTOptionEditMode

    init(model: BTCapsuleModel,
         models: [BTCapsuleModel],
         colors: [BTColorModel],
         editMode: BTOptionEditMode,
         hostVC: UIViewController?,
         superViewBottomOffset: CGFloat,
         isSingle: Bool,
         gestureManager: BTPanGestureManager?,
         delegate: BTOptionEditorPanelDelegate?) {
        self.model = model
        self.models = models
        self.editMode = editMode
        self.delegate = delegate
        self.hostVC = hostVC
        self.colors = colors
        self.isSingle = isSingle
        self.gestureManager = gestureManager
        self.superViewBottomOffset = superViewBottomOffset
        colorPickView = ColorPickerCorePanel(frame: .zero,
                                             infos: [],
                                             layoutConfig: ColorPickerLayoutConfig(colorWellTopMargin: 10,
                                                                                   detailColorHeight: 40,
                                                                                   defaultColorCount: 5,
                                                                                   layout: .fixedSpacing(itemSpacing: 10)))
        colorPickView.ignoreColorWellAdditionalMargin = true
        super.init(nibName: nil, bundle: nil)

        if editMode == .add {
            titleView.text = BundleI18n.SKResource.Bitable_Option_CreateTitle
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        inputTextView.becomeFirstResponder()
        //设置单一文档保护
        let encryptId = inputTextView.getEncryptId()
        inputTextView.input.pointId = encryptId
        
        delegate?.trackOptionEditEvent(event: DocsTracker.EventType.bitableOptionFieldEditPanelOpen.rawValue,
                                       params: [:])
    }

    override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        self.dismiss(animated: false)
//        coordinator.animate(alongsideTransition: nil) { [self] (_) in
            //iPad分屏会导致输入框失焦
//            inputTextView.becomeFirstResponder()
//            colorPickView.refreshViewLayout()
//            colorPickView.snp.updateConstraints { make in
//                make.height.equalTo(countColorPickerViewHeight())
//            }
//        }
    }

    @objc
    public override func didClickMask() {
        super.didClickMask()
        delegate?.didClickCancel()
    }

    deinit {
        keyboard?.stop()
    }

    private func initColorView() {
        let (colorItems, selectedIndexPath) = BTUtil.getColorGroupItems(colors: colors, selectColorId: model.color.id)
        colorPickView.lastHitIndexPath = selectedIndexPath
        colorPickView.updateInfos(infos: colorItems)
        colorPickView.updateColorWellView(bounds: view.bounds)
        colorPickView.delegate = self
    }

    public override func setupUI() {
        super.setupUI()

        similarOptionView.isHidden = true
        view.addSubview(bottomMaskView)
        containerView.addSubview(headerView)
        containerView.addSubview(colorPickView)
        containerView.addSubview(editorView)

        initColorView()
        
        editorView.snp.makeConstraints { make in
            make.left.right.equalToSuperview()
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.equalTo(colorPickView.snp.top)
            make.height.equalTo(58)
        }

        if editMode == .add {
            containerView.addSubview(similarOptionView)
            similarOptionView.snp.makeConstraints { make in
                make.left.right.equalToSuperview()
                make.bottom.equalToSuperview()
                make.top.equalTo(colorPickView.snp.bottom)
                make.height.equalTo(0)
            }
        }

        headerView.snp.makeConstraints { make in
            make.height.equalTo(48)
            make.top.left.right.equalToSuperview()
            make.bottom.equalTo(editorView.snp.top)
        }

        colorPickView.snp.makeConstraints { make in
            make.top.equalTo(editorView.snp.bottom)
            make.left.right.equalToSuperview()
            make.height.equalTo(countColorPickerViewHeight())
            if editMode == .update {
                make.bottom.equalToSuperview()
            } else {
                make.bottom.equalTo(similarOptionView.snp.top)
            }
        }

        bottomMaskView.snp.makeConstraints { make in
            make.height.equalTo(0)
            make.left.right.equalToSuperview()
            make.top.equalTo(containerView.snp.bottom)
        }

        startKeyBoardObserver()

        guard let host = hostVC else { return }
        currentViewMinY = host.view.bounds.height - 287
        viewMaxTop = self.gestureManager?.maxTop ?? 44
    }

    private func startKeyBoardObserver() {
        keyboard = Keyboard(listenTo: [inputTextView.input], trigger: "edit_bitable_option")
        keyboard?.on(events: [.willShow, .didShow]) { [weak self] option in
            guard let self = self, !self.isIgnoreKeyboardEvent else { return }
            self.keyboardHeight = option.endFrame.height
            let animationCurve = UIView.AnimationOptions(rawValue: UInt(option.animationCurve.rawValue))
            UIView.animate(withDuration: option.animationDuration, delay: 0, options: animationCurve, animations: {
                self.containerView.snp.updateConstraints { make in
                    make.bottom.equalToSuperview().offset(-self.keyboardHeight)
                }
                self.bottomMaskView.snp.updateConstraints { make in
                    make.height.equalTo(self.keyboardHeight)
                }
                self.view.layoutIfNeeded()
            }, completion: nil)
        }

        keyboard?.on(events: [.didHide]) { [weak self] _ in
            guard let self = self else { return }
            self.keyboardHeight = 0
            self.isIgnoreKeyboardEvent = false
            self.containerView.snp.updateConstraints { make in
                make.bottom.equalToSuperview()
            }
            self.bottomMaskView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
        }
        keyboard?.start()
    }

    @objc
    private func didClickCancel() {
        inputTextView.resignFirstResponder()
        delegate?.didClickCancel()
        delegate?.trackOptionEditEvent(event: DocsTracker.EventType.bitableOptionFieldEditPanelClick.rawValue,
                             params: ["click": "cancel"])
    }

    @objc
    private func didClickDone() {
        //修改当前选项，通知前端更新数据源
        inputTextView.resignFirstResponder()
        delegate?.didClickDone(model: model, editMode: editMode)
        delegate?.trackOptionEditEvent(event: DocsTracker.EventType.bitableOptionFieldEditPanelClick.rawValue,
                                       params: ["click": "complete",
                                                "target": "ccm_bitable_option_field_panel_view",
                                                "field_type": isSingle ? "single_option" : "multi_option"])
    }

    @objc
    private func textDidChange(_ textField: UITextField) {
        guard let string = textField.text,
              !string.isEmpty else {
            inputTextView.placeholder = BundleI18n.SKResource.Bitable_Option_PleaseEnter
            
            if editMode == .add {
                similarOptionView.isHidden = true
                similarOptionView.snp.updateConstraints { make in
                    make.height.equalTo(0)
                }
            }
            doneButton.isEnabled = false
            doneButton.setTitleColor(UDColor.textDisabled, for: .normal)
            return
        }

        doneButton.isEnabled = true
        doneButton.setTitleColor(UDColor.primaryContentDefault, for: .normal)
        //string不是唯一标识，可存在string相同的多个选项
        model.text = string
        inputTextView.placeholder = string
        //需要全匹配
        let containModel = models.filter { $0.text == string }
        if !containModel.isEmpty, let first = containModel.first {
            similarOptionView.isHidden = false
            similarOptionView.updateModel(model: first)
            similarOptionView.snp.updateConstraints { make in
                make.height.equalTo(56)
            }
        } else {
            similarOptionView.isHidden = true
            similarOptionView.snp.updateConstraints { make in
                make.height.equalTo(0)
            }
        }
    }

    private func countColorPickerViewHeight() -> CGFloat {
        return colorPickView.layoutConfig.colorWellHeight + 82
    }
}

extension BTOptionEditorPanel: ColorPickerCorePanelDelegate {
    public func didChooseColor(panel: ColorPickerCorePanel, color: String, isTapDetailColor: Bool) {
        //更改输入框的属性，会触发键盘事件，在已有键盘的情况下忽略后续的show事件
        guard let selectedColor = colors.first(where: { $0.color == color }) else { return }
        isIgnoreKeyboardEvent = keyboardHeight > 0
        inputConfig.textColor = UIColor.docs.rgb(selectedColor.textColor)
        inputConfig.backgroundColor = UIColor.docs.rgb(selectedColor.color)
        inputConfig.placeholderColor = UIColor.docs.rgb(selectedColor.textColor).withAlphaComponent(0.5)
        inputTextView.backgroundColor = UIColor.docs.rgb(selectedColor.color)
        inputTextView.config = inputConfig
        model.color = selectedColor
        delegate?.trackOptionEditEvent(event: DocsTracker.EventType.bitableOptionFieldEditPanelClick.rawValue,
                             params: ["click": isTapDetailColor ? "change_saturation" : "change_color"])
    }
}

extension BTOptionEditorPanel: CustomBTOptionButtonDelegate {
    public func didClick(model: BTCapsuleModel) {
        delegate?.didClickSelect(model: model)
        delegate?.trackOptionEditEvent(event: DocsTracker.EventType.bitableOptionFieldEditPanelClick.rawValue,
                             params: ["click": "similar_option",
                                      "target": "ccm_bitable_option_field_panel_view"])
    }
}
