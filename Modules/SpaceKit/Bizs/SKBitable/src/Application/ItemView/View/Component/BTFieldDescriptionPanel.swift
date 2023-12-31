//
// Created by duanxiaochen.7 on 2021/12/6.
// Affiliated with SKBitable.
//
// Description:

import Foundation
import UIKit
import SKUIKit
import SnapKit
import SKFoundation
import SKResource
import UniverseDesignColor

protocol BTFieldDescriptionPanelDelegate: AnyObject {
    func setDescriptionIndicator(ofFieldID: String, selected: Bool)
    func didTapView(withAttributes: [NSAttributedString.Key: Any], inFieldModel: BTFieldModel?)
}

extension BTController: BTFieldDescriptionPanelDelegate {
    func setDescriptionIndicator(ofFieldID fieldID: String, selected: Bool) {
        viewModel.tableModel.update(descriptionIndicatorIsSelected: selected, forFieldID: fieldID, recordID: viewModel.currentRecordID)
        // 用 notifyModelUpdate 会造成附件字段闪烁
        currentCard?.fieldsView.visibleCells
            .compactMap {
                $0 as? BTFieldCellProtocol
            }
            .filter {
                $0.fieldID == fieldID
            }
            .forEach {
                $0.updateDescriptionButton(toSelected: selected)
            }
    }
}

final class BTFieldDescriptionPanel: SKPanelController, BTReadOnlyTextViewDelegate {

    let fieldID: String

    private let fieldName: String

    private weak var delegate: BTFieldDescriptionPanelDelegate?

    private lazy var headerView = SKPanelHeaderView().construct { it in
        it.layer.ud.setShadow(type: .s4Up)
        it.setTitle(BundleI18n.SKResource.Bitable_Form_FullFieldDesc(fieldName))
        it.setCloseButtonAction(#selector(didClickMask), target: self)
        it.backgroundColor = UDColor.bgFloat
    }

    private var contentMaxHeightConstraint: Constraint?
    private var contentMinHeightConstraint: Constraint?

    private lazy var descriptionView = BTReadOnlyTextView().construct { it in
        it.btDelegate = self
        it.backgroundColor = UDColor.bgFloat
        it.textContainerInset = UIEdgeInsets(top: 16, left: 16, bottom: 20, right: 16)
        it.setContentHuggingPriority(.required, for: .vertical)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if SKDisplay.pad {
            return [.all]
        }
        return [.allButUpsideDown]
    }

    init(fieldID: String, fieldName: String, delegate: BTFieldDescriptionPanelDelegate) {
        self.fieldID = fieldID
        self.fieldName = fieldName
        self.delegate = delegate
        super.init(nibName: nil, bundle: nil)
        dismissalStrategy = SKDisplay.pad ? [.viewSizeChanged] : [] // iPad 在 popover 展示时，会概率性地被错误布局到页面左上方，所以直接关掉
        automaticallyAdjustsPreferredContentSize = false
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false) // 从外部网页退回到描述页面时要把导航栏隐藏
    }

    override func setupUI() {
        super.setupUI()
        containerView.addSubview(headerView)
        containerView.addSubview(descriptionView)
    }

    override func transitionToRegularSize() {
        super.transitionToRegularSize()
        containerView.backgroundColor = UDColor.bgFloat
        headerView.snp.removeConstraints()
        contentMaxHeightConstraint?.deactivate()
        contentMinHeightConstraint?.deactivate()
        descriptionView.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
            make.width.lessThanOrEqualTo(375)
        }
        view.layoutIfNeeded()
        preferredContentSize = CGSize(width: min(375, descriptionView.intrinsicContentSize.width), height: descriptionView.intrinsicContentSize.height)
        if descriptionView.intrinsicContentSize.height > descriptionView.bounds.height {
            descriptionView.isScrollEnabled = true
        }
    }

    override func transitionToOverFullScreen() {
        super.transitionToOverFullScreen()
        containerView.backgroundColor = UDColor.bgFloat
        headerView.titleLineBreakMode = .byTruncatingMiddle
        headerView.snp.remakeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(48)
        }
        descriptionView.snp.remakeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.equalToSuperview()
            make.leading.trailing.equalTo(containerView.safeAreaLayoutGuide)
            contentMinHeightConstraint = make.height.greaterThanOrEqualTo(view.snp.height).multipliedBy(0.4).offset(-48).constraint
            contentMaxHeightConstraint = make.height.lessThanOrEqualTo(view.snp.height).multipliedBy(0.8).offset(-48).constraint
        }
        view.layoutIfNeeded()
        if descriptionView.intrinsicContentSize.height > descriptionView.bounds.height {
            descriptionView.isScrollEnabled = true
        }
    }

    func updateDescription(attrText: NSAttributedString) {
        descriptionView.attributedText = attrText
    }

    func readOnlyTextView(_ textView: BTReadOnlyTextView, handleTapFromSender sender: UITapGestureRecognizer) {
        let attributes = BTUtil.getAttributes(in: textView, sender: sender)
        if !attributes.isEmpty {
            delegate?.didTapView(withAttributes: attributes, inFieldModel: nil)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc
    override func didClickMask() {
        delegate?.setDescriptionIndicator(ofFieldID: fieldID, selected: false)
        super.didClickMask()
    }

    deinit {
        delegate?.setDescriptionIndicator(ofFieldID: fieldID, selected: false)
    }
}
