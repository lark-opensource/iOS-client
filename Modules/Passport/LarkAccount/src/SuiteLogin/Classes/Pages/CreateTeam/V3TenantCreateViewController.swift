//
//  V3CreateTeamViewController.swift
//  SuiteLogin
//
//  Created by Miaoqi Wang on 2019/9/22.
//

import UIKit
import LarkUIKit
import RxSwift
import Homeric
import LarkContainer
import SnapKit
import UniverseDesignTheme
import UniverseDesignActionPanel
import LarkActionSheet


class V3TenantCreateViewController: BaseViewController {

    private var vm: V3SetUpTeamViewModel

    init(vm: V3SetUpTeamViewModel) {
        self.vm = vm
        super.init(viewModel: vm)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var bannerView: UIImageView = {
        let bannerView = UIImageView()
        bannerView.contentMode = .scaleAspectFill
        bannerView.bt.setLarkImage(with: .default(key: vm.img),
                                   placeholder: BundleResources.LarkAccount.V4.tenant_info_background_default)
        bannerView.ud.setMaskView()
        return bannerView
    }()

    private lazy var cardView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Layout.cardViewCornerRadius
        view.clipsToBounds = true
        view.backgroundColor = UIColor.ud.bgLogin
        return view
    }()

    lazy var tenantNameTextField: V3FlatTextField = {
        let textfield = V3FlatTextField(type: .default)
        textfield.disableLabel = true
        textfield.textFieldFont = UIFont.systemFont(ofSize: 16)
        textfield.attributedPlaceholder = NSAttributedString(
            string: I18N.Lark_Login_V3_Input_TenantName_Placeholder,
            attributes: [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.ud.textPlaceholder
            ])
        if let inputContainerInfo = vm.inputContainerInfoFor(type: .tenantName) {
            textfield.textFiled.returnKeyType = getTextFieldReturnKeyType(for: inputContainerInfo)
            textfield.placeHolder = inputContainerInfo.placeholder
        }
        textfield.delegate = self
        return textfield
    }()

    lazy var userNameTextField: V3FlatTextField = {
        let textfield = V3FlatTextField(type: .default)
        textfield.disableLabel = true
        textfield.textFieldFont = UIFont.systemFont(ofSize: 16)
        textfield.delegate = self
        let placeholder = PassportConf.shared.nameTextFieldPlaceholderProvider?() ?? I18N.Lark_Login_V3_Input_RealName_Placeholder
        textfield.attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .font: UIFont.systemFont(ofSize: 16),
                .foregroundColor: UIColor.ud.textPlaceholder
            ])
        if let inputContainerInfo = vm.inputContainerInfoFor(type: .userName) {
            textfield.textFiled.returnKeyType = getTextFieldReturnKeyType(for: inputContainerInfo)
            textfield.placeHolder = inputContainerInfo.placeholder
        }
        textfield.delegate = self
        return textfield
    }()

    lazy var industryField: PickerTextField = {
        let field = PickerTextField()
        field.updateText(I18N.Lark_Passport_TeamInfoIndustryDropdown, isPlaceHolder: true)
        if let inputContainerInfo = vm.inputContainerInfoFor(type: .industryType) {
            field.updateText(inputContainerInfo.placeholder, isPlaceHolder: true)
        }
        field.rx
            .controlEvent(.touchUpInside)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.logger.info("n_action_tenant_prepare_select_industry")
                self.endEdit(gesture: UITapGestureRecognizer())
                self.becomeFirstResponder()
                self.showIndustryPicker(industry: self.vm.industryTypeList)
            }).disposed(by: self.disposeBag)
        return field
    }()

    lazy var staffSizeField: PickerTextField = {
        let field = PickerTextField()
        field.updateText(I18N.Lark_Passport_TeamInfoScaleDropdown, isPlaceHolder: true)
        if let inputContainerInfo = vm.inputContainerInfoFor(type: .staffSize) {
            field.updateText(inputContainerInfo.placeholder, isPlaceHolder: true)
        }
        field.rx
            .controlEvent(.touchUpInside)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.logger.info("n_action_tenant_prepare_select_scale")
                self.endEdit(gesture: UITapGestureRecognizer())
                self.becomeFirstResponder()
                self.showScalePicker(scale: self.vm.staffSizeList)
            })
            .disposed(by: self.disposeBag)
        return field
    }()
    
    private lazy var regionField: PickerTextField = {
        let field = PickerTextField()
        field.updateText(vm.inputContainerInfoFor(type: .region)?.placeholder ?? "", isPlaceHolder: true)
        field.rx
            .controlEvent(.touchUpInside)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] _ in
                guard let self = self else { return }
                self.logger.info("n_action_tenant_prepare_select_region")
                self.endEdit(gesture: UITapGestureRecognizer())
                self.becomeFirstResponder()
                self.showRegionPicker(supportedRegionList: self.vm.supportedRegionList ?? [], topRegionList: self.vm.topRegionList ?? [])
            })
            .disposed(by: self.disposeBag)
        return field
    }()
    
    private lazy var regionMessageLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .regular),
                                                         NSAttributedString.Key.foregroundColor: UIColor.ud.textCaption,
                                                         NSAttributedString.Key.paragraphStyle: paragraphStyle]
        label.attributedText = NSAttributedString(string: vm.beforeSelectRegionText ?? "", attributes: attributes)
        return label
    }()

    private lazy var trustedMailTipLabel: UILabel = {
        let label = UILabel(frame: .zero)
        label.numberOfLines = 0
        let attributedString = !isPad ? vm.getTrustedMailTips() : vm.getTurstedMailHover()
        label.attributedText = attributedString

        return label
    }()
    private lazy var learnMoreLink: LinkClickableLabel = {
        let clickLabel = LinkClickableLabel.default(with: self)
        clickLabel.contentInset = UIEdgeInsets.zero
        clickLabel.textContainer.lineFragmentPadding = 0
        let attributeString = vm.getLearnMoreTips()
        clickLabel.attributedText = attributeString
        return clickLabel
    }()

    private lazy var constraintItem: ConstraintItem = {
        return self.centerInputView.snp.top
    }()

    var createBtn: NextButton {
        return self.nextButton
    }

    private lazy var optInCheckbox: V3Checkbox = {
        let cb = V3Checkbox(iconSize: CL.checkBoxSize)
        cb.hitTestEdgeInsets = CL.checkBoxInsets
        return cb
    }()

    private lazy var optInTextLabel: LinkClickableLabel = {
        let lbl = LinkClickableLabel.default(with: self)
        return lbl
    }()

    private lazy var bannerViewHeight: CGFloat = {
        round(view.bounds.size.width * 264.0/375.0)
    }()
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if self.isPad {
            super.view.backgroundColor = UIColor.ud.bgBody
            self.navigationController?.navigationBar.barTintColor = UIColor.ud.bgBody
        } else {
            setupBackButton(light: false)
        }
    }

    private func setupCardView(){
        titleLabel.snp.remakeConstraints { (make) in
            make.top.equalToSuperview().offset(Layout.titleTopSpaceHeight)
            make.leading.equalToSuperview().offset(CL.itemSpace)
            make.trailing.lessThanOrEqualToSuperview().inset(CL.itemSpace)
            make.height.greaterThanOrEqualTo(BaseLayout.titleLabelHeight)
        }

        detailLabel.snp.remakeConstraints { (make) in
            make.leading.trailing.equalToSuperview().inset(CL.itemSpace)
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.detailLabelTop)
        }

        centerInputView.snp.remakeConstraints { (make) in
            make.top.equalTo(detailLabel.snp.bottom).offset(Layout.centerInputTop)
            make.left.right.equalTo(moveBoddyView)
            make.bottom.equalToSuperview()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        if isPad {
            inputAdjustView.snp.remakeConstraints { (make) in
                make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset( BaseLayout.visualNaviBarHeight)
                make.left.right.bottom.equalToSuperview()
            }
        } else {
            inputAdjustView.snp.remakeConstraints { (make) in
                make.edges.equalToSuperview()
            }
            inputAdjustView.addSubview(bannerView)
            bannerView.snp.remakeConstraints { (maker) in
                maker.top.equalToSuperview()
                maker.width.equalToSuperview()
                maker.left.right.equalToSuperview()
                maker.height.equalTo(bannerViewHeight)
            }

            titleLabel.removeFromSuperview()
            detailLabel.removeFromSuperview()
            centerInputView.removeFromSuperview()
            inputAdjustView.addSubview(cardView)
            cardView.snp.makeConstraints { make in
                make.top.equalTo(bannerView.snp.bottom).offset(-Layout.cardViewCornerRadius)
                make.width.equalToSuperview()
                make.left.right.bottom.equalToSuperview()
            }

            cardView.addSubview(titleLabel)
            cardView.addSubview(detailLabel)
            cardView.addSubview(centerInputView)
            setupCardView()
        }

        createBtn.setTitle(vm.nextButtonText, for: .normal)
        configInfo(vm.title, detail: vm.subtitle)

        var topSpace: CGFloat = 0
        self.constraintItem = centerInputView.snp.top
        vm.inputContainerInfoList.compactMap { inputContainerInfo -> (UIView, Bool)? in
            guard let textField = getTextField(for: inputContainerInfo.type) else {
                return nil
            }
            return (textField, vm.isLastInput(inputContainerInfo: inputContainerInfo))
        }.forEach { (textField, lastField) in
            centerInputView.addSubview(textField)
            textField.snp.makeConstraints { (make) in
                make.left.right.equalToSuperview().inset(Common.Layout.itemSpace)
                make.height.equalTo(CL.registerInfoFieldHeight)
                make.top.equalTo(constraintItem).offset(topSpace)
            }
            self.constraintItem = textField.snp.bottom
            topSpace = Layout.InputBoxSpace
            
            // 如果是最后一个 field 并且为 region picker，增加图标和提示文本
            if lastField && vm.hasRegionInput() {
                topSpace = Layout.BoxToLabelSpace
                centerInputView.addSubview(regionMessageLabel)
                regionMessageLabel.snp.makeConstraints { make in
                    make.left.equalToSuperview().inset(Common.Layout.itemSpace)
                    make.right.equalToSuperview().inset(Common.Layout.itemSpace)
                    make.top.equalTo(constraintItem).offset(topSpace)
                }
                constraintItem = regionMessageLabel.snp.bottom
            }
        }

        if vm.shouldShowTrustMailLabel() {
            topSpace = Layout.LabelMiddleSpace
            centerInputView.addSubview(trustedMailTipLabel)
            trustedMailTipLabel.snp.makeConstraints { make in
                make.left.equalToSuperview().inset(Common.Layout.itemSpace)
                make.right.equalToSuperview().inset(Common.Layout.itemSpace)
                make.top.equalTo(constraintItem).offset(topSpace)
            }
            constraintItem = trustedMailTipLabel.snp.bottom

            if !isPad {
                centerInputView.addSubview(learnMoreLink)
                learnMoreLink.snp.makeConstraints { make in
                    make.left.equalToSuperview().inset(Common.Layout.itemSpace)
                    make.top.equalTo(constraintItem)
                }
                let rightImage = UIImageView(image: BundleResources.UDIconResources.rightBoldOutlined.ud.withTintColor(UIColor.ud.textLinkHover))
                centerInputView.addSubview(rightImage)
                rightImage.snp.makeConstraints { make in
                    make.centerY.equalTo(learnMoreLink)
                    make.left.equalTo(learnMoreLink.snp.right)
                }
                constraintItem = learnMoreLink.snp.bottom
            }

        }

        createBtn.rx.tap.subscribe { [weak self] _ in
            guard let self = self else { return }
            self.logger.info("n_action_tenant_prepare_next")
            self.vm.trackNextClick()
            self.showLoading()
            self.updateFieldValueToVM()
            PassportMonitor.flush(PassportMonitorMetaStep.startTenantInfoCommit,
                                  eventName: ProbeConst.monitorEventName,
                                  categoryValueMap: [ProbeConst.flowType: self.vm.flowType],
                                  context: self.vm.context)
            let startTime = Date()
            self.vm.create().subscribe(onError: { (err) in
                self.stopLoading()
                self.handle(err)
                PassportMonitor.monitor(PassportMonitorMetaStep.tenantInfoCommitResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.flowType: self.vm.flowType],
                                              context: self.vm.context)
                .setResultTypeFail()
                .setPassportErrorParams(error: err)
                .flush()
                
            }, onCompleted: {
                self.stopLoading()
                PassportMonitor.monitor(PassportMonitorMetaStep.tenantInfoCommitResult,
                                              eventName: ProbeConst.monitorEventName,
                                              categoryValueMap: [ProbeConst.flowType: self.vm.flowType,
                                                                 ProbeConst.duration: Int(Date().timeIntervalSince(startTime) * 1000)],
                                              context: self.vm.context)
                .setResultTypeSuccess()
                .flush()
            }).disposed(by: self.disposeBag)
        }.disposed(by: disposeBag)

        if vm.showOptIn {
            moveBoddyView.addSubview(optInTextLabel)
            /// checkbox要后添加到视图上，需要扩大区域响应事件
            moveBoddyView.addSubview(optInCheckbox)
            optInCheckbox.isSelected = vm.optInDefaultValue

            optInTextLabel.attributedText = vm.optInText

            optInCheckbox.snp.makeConstraints { (make) in
                make.size.equalTo(CL.checkBoxSize)
                make.left.equalToSuperview().offset(CL.itemSpace)
                make.bottom.equalTo(optInTextLabel.snp.firstBaseline).offset(CL.checkBoxYOffset)
            }
            optInTextLabel.snp.makeConstraints { (make) in
                make.top.equalTo(inputAdjustView.snp.bottom).offset(Layout.optInTextTopSpace)
                make.top.equalTo(constraintItem).offset(Layout.optInTextTopSpace)
                make.left.equalTo(optInCheckbox.snp.right).offset(CL.checkBoxRightPadding)
                make.right.equalToSuperview().offset(-CL.itemSpace)
            }
        }

        centerInputView.addSubview(nextButton)
        nextButton.snp.remakeConstraints { (make) in
            if vm.showOptIn {
                make.top.equalTo(optInTextLabel.snp.bottom).offset(CL.itemSpace * 2)
            } else {
                let restHeight = self.view.frame.size.height - cardView.frame.bottom
                if restHeight >= Layout.restHeight {
                    make.top.equalTo(constraintItem).offset(Layout.nextButtonTop)
                } else {
                    make.top.equalTo(constraintItem).offset(CL.itemSpace)
                }
            }
            make.leading.trailing.equalToSuperview().inset(CL.itemSpace)
            make.height.equalTo(NextButton.Layout.nextButtonHeight48)
            make.bottom.equalToSuperview()
        }

        NotificationCenter.default
            .rx.notification(UITextField.textDidChangeNotification)
            .subscribe(onNext: { [weak self] (_) in
                self?.checkBtnDisable()
            }).disposed(by: disposeBag)

        if let name = vm.placeholderName {
            userNameTextField.text = name
            checkBtnDisable()
        }

        if let tenant = vm.defaultTenantName {
            tenantNameTextField.text = tenant
            checkBtnDisable()
        }

        PassportMonitor.flush(PassportMonitorMetaStep.tenantInfoEnter,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: [ProbeConst.flowType: vm.flowType],
                              context: vm.context)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        vm.trackViewAppear()
        logger.info("n_page_tenant_prepare_start")
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        if isPad {
            return .default
        }
        if #available(iOS 13.0, *), UDThemeManager.getRealUserInterfaceStyle() == .dark {
            return .darkContent
        }
        return .default
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard #available(iOS 13.0, *),
            traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) else {
            // 如果当前设置主题一致，则不需要切换资源
            return
        }

        setNeedsStatusBarAppearanceUpdate()
    }

    private func setupBackButton(light: Bool) {
        backButton.setImage(BundleResources.UDIconResources.leftOutlined.ud.withTintColor(light ? UIColor.ud.primaryOnPrimaryFill : UIColor.ud.staticBlack), for: .normal)
    }
    
    override func needBackImage() -> Bool {
        return false
    }

    func checkBtnDisable() {
        let otherCondition: Bool
        if vm.hasInputContainerForType(type: .industryType), !industryField.didSetValue {
            otherCondition = false
        } else if vm.hasInputContainerForType(type: .staffSize), !staffSizeField.didSetValue {
            otherCondition = false
        } else if vm.hasInputContainerForType(type: .region), !regionField.didSetValue {
            otherCondition = false
        } else {
            otherCondition = true
        }
        createBtn.isEnabled = isInputValid() && otherCondition
    }

    override func pageName() -> String? {
        vm.pageName
    }

    override func needSwitchButton() -> Bool {
        return false
    }

    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        let isControl = touch.view?.isKind(of: UIControl.self) ?? false
        return !isControl
    }

    override func needBottmBtnView() -> Bool {
        !iPadUseCompactLayout
    }

    override func handleKeyboardWhenShow(_ noti: Notification) {
        func adjust(orignalHeight: CGFloat) {
            UIView.animate(withDuration: 0.3) {
                self.bannerView.layer.opacity = 0.0
            }
            let contentOffset = self.bannerViewHeight - BaseLayout.visualNaviBarHeight - view.safeAreaInsets.top
            self.inputAdjustView.setContentOffset(CGPoint(x: 0, y: contentOffset), animated: true)
        }

        if !isPad {
            if let keyboardSize = (noti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue {
                adjust(orignalHeight: keyboardSize.height)
            }
            var isDarkModeTheme: Bool = false
            if #available(iOS 13.0, *) {
                isDarkModeTheme = UDThemeManager.getRealUserInterfaceStyle() == .dark
            }
            setupBackButton(light: isDarkModeTheme)
        }
    }

    override func handleKeyboardWhenHide(_ noti: Notification) {
        if !isPad {
            UIView.animate(withDuration: 0.3) {
                self.bannerView.layer.opacity = 1.0
            }
            self.inputAdjustView.setContentOffset(.zero, animated: true)
            setupBackButton(light: false)
        }
    }
    override func handleClickLink (_ URL: URL, textView: UITextView) {
        switch URL {
        case Link.trustedMailHoverURL:
            showActionPanel(attributeStr: vm.getTurstedMailHover())

        default:
            super.handleClickLink(URL, textView: textView)
        }
    }

    override func clickBackOrClose(isBack: Bool) {
        PassportMonitor.flush(PassportMonitorMetaStep.tenantInfoCancel,
                              eventName: ProbeConst.monitorEventName,
                              categoryValueMap: [ProbeConst.flowType: vm.flowType],
                              context: vm.context)
        super.clickBackOrClose(isBack: isBack)
    }
}

extension V3TenantCreateViewController {

    func makeIndustryDataSource(_ industryInfo: [V3Industry]) -> [(String, [SegPickerItem])] {

        func makeSubIndustryFromSelected(main: V3Industry, sub: V3Industry?) -> [SegPickerItem] {
            if let selectedSub = sub, let children = main.children {
                return children.compactMap({ (sub) -> SegPickerItem? in
                    SegPickerItem(content: sub.name, isSelected: sub.code == selectedSub.code)
                })
            } else {
                // no sub use main
                return [SegPickerItem(content: main.name, isSelected: true)]
            }
        }

        let mainIndustry: [SegPickerItem]
        var subIndustry: [SegPickerItem] = []   // 根据父级选择动态获取，初始空

        if let selectedIndustry = vm.industryInfo {
            mainIndustry = industryInfo.map({ (main) -> SegPickerItem in
                if main.code == selectedIndustry.main.code {
                    subIndustry = makeSubIndustryFromSelected(main: main, sub: selectedIndustry.sub)
                    return SegPickerItem(content: main.name, isSelected: true)
                } else {
                    return SegPickerItem(content: main.name, isSelected: false)
                }
            })
        } else {
            mainIndustry = industryInfo.map({ SegPickerItem(content: $0.name, isSelected: false) })
        }
        return [
            (I18N.Lark_Passport_TeamInfoMainIndustryDropdownTab, mainIndustry),
            (I18N.Lark_Passport_TeamInfoSubIndustryDropdownTab, subIndustry)
        ]
    }

    func showIndustryPicker(industry: [V3Industry]?) {
        guard let industryInfo = industry else {
            logger.error("no industry info")
            return
        }
        let dataSource = makeIndustryDataSource(industryInfo)

        let picker = SegmentPickerViewController(
            presentationStyle: isPad ? .full : .sheet,
            dataSource: dataSource,
            didSelect: { (indexes) in
                guard indexes.count == 2 else {
                    self.logger.error("indexes count \(indexes.count)")
                    return
                }
                self.logger.info("selected indexes \(indexes)")

                let mainIndex = indexes[0]
                let subIndex = indexes[1]
                if mainIndex < industryInfo.count {
                    let mainInfo = industryInfo[mainIndex]
                    if let childrens = mainInfo.children {
                        if subIndex < childrens.count {
                            let childInfo = childrens[subIndex]
                            self.vm.industryInfo = (mainInfo, childInfo)
                            self.industryField.updateText(childInfo.name, isPlaceHolder: false)
                        } else {
                            self.logger.error("children industry info index out of range")
                        }
                    } else {
                        self.logger.info("no children use main")
                        self.vm.industryInfo = (mainInfo, nil)
                        self.industryField.updateText(mainInfo.name, isPlaceHolder: false)
                    }
                } else {
                    self.logger.error("main industry info index out of range")
                }
                self.checkBtnDisable()
            }, newDataGetter: { (segIndex, index) -> [SegPickerItem]? in
                guard index < industryInfo.count, segIndex == 0 else { return nil }
                // 生成子级数据， 子级没有数据使用父级当前数据
                let mainInfo = industryInfo[index]
                let children = mainInfo.children?.map({ SegPickerItem(content: $0.name, isSelected: false) })
                return children ?? [SegPickerItem(content: mainInfo.name, isSelected: false)]
            }
        )
        if isPad {
            picker.modalPresentationStyle = .formSheet
        }
        self.present(picker, animated: true, completion: nil)
    }

    func showScalePicker(scale: [V3StaffScale]?) {
        guard let scaleInfo = scale else {
            logger.error("no staff scale info")
            return
        }

        let scaleData: [SegPickerItem]
        if let selectedScale = vm.scaleInfo {
            scaleData = scaleInfo.map({ SegPickerItem(content: $0.content, isSelected: $0.code == selectedScale.code) })
        } else {
            scaleData = scaleInfo.map({ SegPickerItem(content: $0.content, isSelected: false) })
        }

        let dataSource: [(String, [SegPickerItem])] = [(I18N.Lark_Passport_TeamInfoScaleDropdownTab, scaleData)]
        let picker = SegmentPickerViewController(
            segStyle: .plain,
            presentationStyle: isPad ? .full : .sheet,
            dataSource: dataSource,
            didSelect: { (indexes) in
                guard indexes.count == 1 else {
                    self.logger.error("indexes count \(indexes.count)")
                    return
                }
                self.logger.info("selected indexes \(indexes)")

                let index = indexes[0]
                if index < scaleInfo.count {
                    let info = scaleInfo[index]
                    self.vm.scaleInfo = info
                    self.staffSizeField.updateText(info.content, isPlaceHolder: false)
                } else {
                    self.logger.error("scale info index out of range")
                }
                self.checkBtnDisable()
            }
        )
        if isPad {
            picker.modalPresentationStyle = .formSheet
        }
        self.present(picker, animated: true, completion: nil)
    }
    
    func showRegionPicker(supportedRegionList: [Region], topRegionList: [Region]) {
        let decoder = JSONDecoder()
        
        let picker = RegionPickerViewController(regionList: supportedRegionList,
                                                topRegionList: topRegionList,
                                                didSelectBlock: { [weak self] region in
            guard let self = self else { return }
            self.vm.selectedRegion = region
            self.regionField.updateText(region.name, isPlaceHolder: false)
            self.updateRegionInfo()
            self.checkBtnDisable()
        })
        picker.modalPresentationStyle = .fullScreen
        present(picker, animated: true, completion: nil)
    }
    
    func updateRegionInfo() {
        guard vm.hasRegionInput() else { return }
        
        /// 当服务端返回的 current region 为空时，说明是内网 IP 或其它例外情形，此时不做地区校验
        /// 当 current region 可以拿到时，和用户选择的内容进行比对，如果不相同，界面上调整为黄色提醒文案
        guard let serverCurrentRegion = vm.currentRegion, !serverCurrentRegion.isEmpty else { return }
        guard let selectedRegion = vm.selectedRegion?.code else { return }
        
        let regionMatched = selectedRegion == serverCurrentRegion
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        let color = regionMatched ? UIColor.ud.N600 : UIColor.ud.colorfulOrange
        let attributes: [NSAttributedString.Key: Any] = [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14, weight: .regular),
                                                         NSAttributedString.Key.foregroundColor: color,
                                                         NSAttributedString.Key.paragraphStyle: paragraphStyle]
        self.regionField.layer.borderColor = color.cgColor
        let text = regionMatched ? vm.beforeSelectRegionText : vm.afterSelectRegionText
        regionMessageLabel.attributedText = NSAttributedString(string: text ?? "", attributes: attributes)
    }

    func showActionPanel(attributeStr: NSAttributedString) {
        let vc = UIViewController()
        let titleLabel = UILabel()
        titleLabel.numberOfLines = 0
        titleLabel.attributedText = attributeStr
        vc.view.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(Layout.itemSpace)
            make.left.equalToSuperview().offset(Layout.itemSpace)
            make.right.equalToSuperview().offset(-Layout.itemSpace)
        }


        //添加底部返回按钮
        let cancelButton = NextButton(title: I18N.Lark_Passport_ApprovedEmailJoinDirectly_DetailsDesc_GotItButton, style: .white)
        cancelButton.setTitleColor(UIColor.ud.textTitle, for: .normal)
        cancelButton.titleLabel?.font = UIFont.ud.title4
        cancelButton.rx.tap.subscribe { _ in
            vc.dismiss(animated: true)
        }
        vc.view.addSubview(cancelButton)
        cancelButton.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(Layout.itemSpace)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(Layout.buttonHeight)

        }

        //添加分隔线
        let devideLine = UIView()
        devideLine.backgroundColor = UIColor.ud.lineDividerDefault //lk.commonTableSeparatorColor
        vc.view.addSubview(devideLine)
        devideLine.snp.makeConstraints { make in
            make.bottom.equalTo(cancelButton.snp.top)
            make.left.right.equalToSuperview()
            make.height.equalTo(0.5)
        }

        var config = UDActionPanelUIConfig()
        //由于需要计算偏移尺寸，所以需要先进行Layout
        vc.view.setNeedsLayout()
        vc.view.layoutIfNeeded()
        config.originY = self.view.bounds.height - (nextButton.bounds.height + titleLabel.bounds.height + Layout.itemSpace * 2 + Layout.indicatorHeight)
        let panel = UDActionPanel(customViewController: vc, config: config)
        self.present(panel, animated: true)

    }
}

extension V3TenantCreateViewController {
    struct Layout {
        static let cardViewCornerRadius: CGFloat = Common.Layer.commonCardContainerViewRadius
        static let cardViewHeight: CGFloat = 322
        static let titleTopSpaceHeight: CGFloat = 10
        static let detailLabelTop: CGFloat = 10
        static let dismissBtnHeight: CGFloat = 30
        static let viewTop: CGFloat = 44
        static let centerInputTop: CGFloat = 20
        static let nextButtonTop: CGFloat = 24
        static let dismissTop: CGFloat = 8
        static let optInTextTopSpace: CGFloat = 20
        static let restHeight: CGFloat = 88
        static let InputBoxSpace: CGFloat = 14
        static let BoxToLabelSpace: CGFloat = 8
        static let LabelMiddleSpace: CGFloat = 24

        //actionpanel layout
        static let itemSpace: CGFloat = 16
        static let buttonHeight: CGFloat = 48
        static let indicatorHeight: CGFloat = 32
    }
}

extension V3TenantCreateViewController: V3FlatTextFieldDelegate {

    func textFieldShouldReturn(_ textField: V3FlatTextField) -> Bool {
        if let inputContainerInfo = getInputContainerInfo(for: textField),
            let index = vm.inputContainerInfoList.firstIndex(of: inputContainerInfo) {
            let nextIndex = index + 1
            if nextIndex < vm.inputContainerInfoList.count,
               let field = getTextField(for: vm.inputContainerInfoList[nextIndex].type) {
                return field.becomeFirstResponder()
            } else {
                return textField.resignFirstResponder()
            }
        } else {
            return textField.resignFirstResponder()
        }
    }
}

// MARK: textField

extension V3TenantCreateViewController {

    func updateFieldValueToVM() {
        if vm.hasInputContainerForType(type: .tenantName),
            let tenantNameText = tenantNameTextField.text {
            vm.tenantName = tenantNameText
        }
        if vm.hasInputContainerForType(type: .userName),
            let userName = userNameTextField.currentText {
            vm.userName = userName
        }

        if vm.showOptIn {
            vm.optIn = optInCheckbox.isSelected
        }
    }

    func getTextFieldReturnKeyType(for inputContainerInfo: V3InputContainerInfo) -> UIReturnKeyType {
        if vm.isLastInput(inputContainerInfo: inputContainerInfo) {
            return .done
        } else {
            return .next
        }
    }

    func getInputContainerInfo(for textField: V3FlatTextField) -> V3InputContainerInfo? {
        if textField === tenantNameTextField {
            return vm.inputContainerInfoFor(type: .tenantName)
        } else if textField === userNameTextField {
            return vm.inputContainerInfoFor(type: .userName)
        } else {
            return nil
        }
    }

    func getTextField(for type: V3InputContainerType) -> UIView? {
        if type == .tenantName {
            return tenantNameTextField
        } else if type == .userName {
            return userNameTextField
        } else if type == .industryType {
            return industryField
        } else if type == .staffSize {
            return staffSizeField
        } else if type == .region {
            return regionField
        } else {
            return nil
        }
    }

    func isInputValid() -> Bool {
        if vm.hasInputContainerForType(type: .tenantName) {
            guard let tenantName = tenantNameTextField.text,
            !tenantName.isEmpty else {
                return false
            }
        }
        if vm.hasInputContainerForType(type: .userName) {
            guard let userName = userNameTextField.currentText,
                !userName.isEmpty else {
                return false
            }
        }
        return true
    }
}


