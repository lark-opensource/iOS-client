//
//  CountDownPickerViewController.swift
//  ByteView
//
//  Created by wulv on 2022/4/19.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import Foundation
import UIKit
import UniverseDesignDatePicker
import UniverseDesignIcon
import SnapKit
import ByteViewCommon
import ByteViewTracker
import ByteViewUI

extension CountDownPickerViewController {
    enum Layout {
        static var titleHeight: CGFloat = 48.0
        static let vGap: CGFloat = 16.0
        static let titleGap: CGFloat = 13.0
        static let left: CGFloat = 16.0
        static let right: CGFloat = 16.0
        static let audioLabelH: CGFloat = 20.0
        static let audioOffsetRemind: CGFloat = 4.0
        static let endRemindOffsetSwitch: CGFloat = 16.0
        static let endRemindFontConfig: VCFontConfig = .body
        static let lineH: CGFloat = 0.5
        static let nearRemindHeight: CGFloat = 22.0
        static let remindIconW: CGFloat = 12.0
        static let remindImageToTitle: CGFloat = 4.0
        static let bottomTipH: CGFloat = 18.0
    }
}

/// 创建倒计时 Or 延长倒计时 页面
final class CountDownPickerViewController: VMViewController<CountDownPickerViewModel> {

    enum Style {
        /// 倒计未开启，可开启
        case start
        /// 倒计时已开启，可延长
        case prolong

        var title: String {
            switch self {
            case .start:
                return I18n.View_G_CreateCountdown
            case .prolong:
                return I18n.View_G_ExtendCountdown_Title
            }
        }

        var buttonTitle: String {
            switch self {
            case .start:
                return I18n.View_G_Start
            case .prolong:
                return I18n.View_G_ConfirmButton
            }
        }

        var showAudioItem: Bool {
            switch self {
            case .start:
                return true
            case .prolong:
                return false
            }
        }
    }

    var style: Style {
        viewModel.style
    }

    var pickerHeight: CGFloat {
        if currentLayoutContext.layoutType.isPhoneLandscape {
            return 158.0
        }
        return 256.0
    }

    private lazy var rightBarButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setTitle(style.buttonTitle, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        button.setTitleColor(UIColor.ud.textLinkNormal, for: .normal)
        button.setTitleColor(UIColor.ud.textDisabled, for: .disabled)
        button.addTarget(self, action: #selector(rightBarButtonAction(_:)), for: .touchUpInside)
        button.backgroundColor = .clear
        button.addInteraction(type: .highlight)
        return button
    }()

    private lazy var line: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault.withAlphaComponent(0.15)
        return line
    }()

    private lazy var containerScrollView: UIScrollView = {
        let s = UIScrollView()
        s.showsVerticalScrollIndicator = false
        s.bounces = false
        s.backgroundColor = UIColor.clear
        return s
    }()

    private var wheelPicker: UDWheelPickerView?

    private lazy var enableAudioContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.ud.bgFloat
        view.layer.cornerRadius = 10
        view.layer.masksToBounds = true

        view.addSubview(endRemindLabel)
        endRemindLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(Layout.titleGap)
            $0.left.equalToSuperview().offset(Layout.left)
            $0.height.greaterThanOrEqualTo(22)
        }

        view.addSubview(endRemindSwitch)
        endRemindSwitch.snp.makeConstraints {
            $0.centerY.equalTo(endRemindLabel)
            $0.right.equalToSuperview().inset(Layout.right)
            $0.left.equalTo(endRemindLabel.snp.right).offset(Layout.endRemindOffsetSwitch)
        }

        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault
        view.addSubview(line)
        line.snp.makeConstraints { make in
            make.top.equalTo(endRemindLabel.snp.bottom).offset(Layout.titleGap - Layout.lineH)
            make.left.equalToSuperview().inset(Layout.left)
            make.right.equalToSuperview()
            make.height.equalTo(Layout.lineH)
        }

        view.addSubview(nearRemindLabel)
        nearRemindLabel.snp.makeConstraints {
            $0.top.equalTo(line.snp.bottom).offset(Layout.titleGap)
            $0.left.equalToSuperview().inset(Layout.left)
            $0.height.equalTo(Layout.nearRemindHeight)
            $0.bottom.equalToSuperview().inset(Layout.titleGap)
        }

        view.addSubview(nearRemindTimeButton)
        nearRemindTimeButton.snp.makeConstraints { make in
            make.centerY.equalTo(nearRemindLabel)
            make.right.equalToSuperview().inset(Layout.right)
            make.left.equalTo(nearRemindLabel.snp.right).offset(4)
        }

        return view
    }()

    /// “声音提醒”
    private lazy var audioLabel: UILabel = {
       let label = UILabel()
        label.textColor = UIColor.ud.textPlaceholder
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = I18n.View_G_PlayChime
        label.backgroundColor = .clear
        return label
    }()

    /// "结束提醒"
    private lazy var endRemindLabel: UILabel = {
       let label = UILabel()
        label.numberOfLines = 0
        let text = I18n.View_G_PlayChimeCountEnd
        label.attributedText = NSAttributedString(string: text, config: Layout.endRemindFontConfig, textColor: UIColor.ud.textTitle)
        label.backgroundColor = .clear
        return label
    }()

    /// "结束提醒开关"
    private lazy var endRemindSwitch: VCSwitch = {
        let s = VCSwitch()
        s.onTintColor = UIColor.ud.primaryContentDefault
        s.tintColor = UIColor.ud.lineBorderComponent
        s.thumbTintColor = UIColor.ud.primaryOnPrimaryFill
        s.addTarget(self, action: #selector(endRemindSwitchAction(_:)), for: .valueChanged)
        s.setContentCompressionResistancePriority(.required, for: .horizontal)
        return s
    }()

    /// "剩余提醒"
    private lazy var nearRemindLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        label.textColor = UIColor.ud.textTitle
        label.font = UIFont.systemFont(ofSize: 16)
        label.text = I18n.View_G_CountdownTimeReminder
        label.backgroundColor = .clear

        let tap = UITapGestureRecognizer(target: self, action: #selector(tapNearRemindLabel(_:)))
        label.addGestureRecognizer(tap)
        return label
    }()

    /// "剩余提醒时间"
    private lazy var nearRemindTimeButton: UIButton = {
        let b = UIButton(type: .custom)
        b.addTarget(self, action: #selector(nearRemindTimeButtonAction(_:)), for: .touchUpInside)
        b.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        b.setTitleColor(UIColor.ud.textPlaceholder, for: .normal)
        b.setContentCompressionResistancePriority(.required, for: .horizontal)
        b.addInteraction(type: .highlight)
        let imageWidth: CGFloat = Layout.remindIconW
        let icon = UDIcon.getIconByKey(.rightBoldOutlined, iconColor: .ud.iconN3, size: CGSize(width: imageWidth, height: imageWidth))
        b.setImage(icon, for: .normal)
        return b
    }()

    /// “所有参会人可见”
    private lazy var bottomTipLabel: UILabel = {
        let l = UILabel(frame: .zero)
        l.numberOfLines = 1
        l.textAlignment = .center
        l.font = UIFont.systemFont(ofSize: 12)
        l.text = I18n.View_G_AllSeeCountdown
        l.textColor = UIColor.ud.textPlaceholder
        return l
    }()

    private lazy var endRemindH: CGFloat = {
        let w = view.frame.size.width - Layout.left * 2 - Layout.endRemindOffsetSwitch - VCSwitch.defaultSize.width - Layout.right * 2
        let labelH = endRemindLabel.attributedText?.string.vc.boundingHeight(width: w, config: Layout.endRemindFontConfig) ?? 0
        return Layout.titleGap * 2 + labelH
    }()

    private lazy var nearRemindH: CGFloat = Layout.nearRemindHeight + Layout.titleGap * 2

    override func setupViews() {
        VCTracker.post(name: .vc_countdown_setup_view, params: [.from_source: viewModel.pageSource])

        view.backgroundColor = UIColor.ud.bgBase
        title = style.title
        setNavigationBarBgColor(UIColor.ud.bgBase)

        navigationItem.setRightBarButton(UIBarButtonItem(customView: rightBarButton), animated: true)

        view.addSubview(containerScrollView)
        containerScrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        view.addSubview(line)
        line.snp.makeConstraints {
            $0.left.right.top.equalToSuperview()
            $0.height.equalTo(1 / view.vc.displayScale)
        }

        setupWheelPicker()

        if style.showAudioItem {
            // 展示声音提醒条目
            setUpAudioLabel()

            containerScrollView.addSubview(enableAudioContainer)
            enableAudioContainer.snp.makeConstraints {
                $0.left.right.equalTo(view.safeAreaLayoutGuide).inset(Layout.left)
                $0.top.equalTo(audioLabel.snp.bottom).offset(Layout.audioOffsetRemind)
            }

            containerScrollView.addSubview(bottomTipLabel)
            bottomTipLabel.snp.makeConstraints { make in
                make.left.right.equalTo(view.safeAreaLayoutGuide).inset(16)
                make.top.equalTo(enableAudioContainer.snp.bottom).offset(Layout.vGap)
                make.height.equalTo(Layout.bottomTipH)
            }
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    override func bindViewModel() {
        if style.showAudioItem {
            endRemindSwitch.isOn = viewModel.enableAudio
        }

        resetOrientationDatasource()
        resetCurrentSelect()
        reloadRemindTimeButtonTitle()
        updateRemindTimeWhenSetTimeChanged()
    }

    private func setupWheelPicker() {
        let wheelPicker = UDWheelPickerView(pickerHeight: pickerHeight, gradientColor: UIColor.ud.bgBody)
        wheelPicker.dataSource = self
        wheelPicker.delegate = self
        wheelPicker.backgroundColor = UIColor.ud.bgBody
        wheelPicker.layer.cornerRadius = 10
        wheelPicker.layer.masksToBounds = true

        containerScrollView.addSubview(wheelPicker)
        wheelPicker.snp.makeConstraints {
            $0.top.equalToSuperview().offset(Layout.vGap)
            $0.left.right.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(pickerHeight)
        }
        self.wheelPicker = wheelPicker
    }

    private func setUpAudioLabel() {
        containerScrollView.addSubview(audioLabel)
        audioLabel.snp.remakeConstraints { make in
            make.left.right.equalTo(view.safeAreaLayoutGuide).inset(32)
            make.top.equalToSuperview().offset(Layout.vGap + pickerHeight + Layout.vGap)
            make.height.equalTo(Layout.audioLabelH)
        }
    }

    private func reloadRemindTimeButtonTitle() {
        let title = viewModel.remindTime?.title ?? I18n.View_VM_None
        nearRemindTimeButton.setTitle(title, for: .normal)
        updateRemindTimeButtonInsets()
    }

    private func enableRemindTimeButton(_ enable: Bool) {
        nearRemindLabel.isUserInteractionEnabled = enable
        nearRemindTimeButton.isEnabled = enable
        if enable {
            let imageWidth = Layout.remindIconW
            let icon = UDIcon.getIconByKey(.rightBoldOutlined, iconColor: .ud.iconN3, size: CGSize(width: imageWidth, height: imageWidth))
            nearRemindTimeButton.setImage(icon, for: .normal)
        } else {
            nearRemindTimeButton.setImage(nil, for: .normal)
        }
        updateRemindTimeButtonInsets()
    }

    private func updateRemindTimeButtonInsets() {
        if nearRemindTimeButton.image(for: .normal) != nil, let title = nearRemindTimeButton.title(for: .normal) {
            let labelString = NSString(string: title)
            let titleSize = labelString.size(withAttributes: [NSAttributedString.Key.font: nearRemindTimeButton.titleLabel?.font ?? UIFont.systemFont(ofSize: 14)])
            let imageToTitle = Layout.remindImageToTitle
            let imageWidth = Layout.remindIconW
            nearRemindTimeButton.titleEdgeInsets = UIEdgeInsets(top: 0,
                                                                left: -imageWidth - imageToTitle / 2,
                                                                bottom: 0,
                                                                right: imageWidth + imageToTitle / 2)
            nearRemindTimeButton.imageEdgeInsets = UIEdgeInsets(top: 0,
                                                                left: titleSize.width + imageToTitle / 2,
                                                                bottom: 0,
                                                                right: -titleSize.width - imageToTitle / 2)
        } else {
            nearRemindTimeButton.titleEdgeInsets = .zero
            nearRemindTimeButton.imageEdgeInsets = .zero
        }
    }

    private func enableRightButton(_ enable: Bool) {
        rightBarButton.isEnabled = enable
    }

    private func updateRemindTimeWhenSetTimeChanged() {
        let setMinute = viewModel.selectMinute()
        if setMinute <= CountDownRemindPickerViewModel.defaultMinute {
            // 剩余时间变“无”, 禁用剩余时长按钮
            viewModel.remindTime = nil
            reloadRemindTimeButtonTitle()
            enableRemindTimeButton(false)
        } else {
            enableRemindTimeButton(true)
            if let remindMinute = viewModel.remindTime?.value, setMinute <= remindMinute {
                // 剩余时长变“1min”
                viewModel.remindTime = .minute(CountDownRemindPickerViewModel.defaultMinute)
                reloadRemindTimeButtonTitle()
            }
        }
    }

    private func resetOrientationDatasource() {
        viewModel.orientation = currentLayoutContext.layoutType.isPhoneLandscape ? .landscape : .portrait
        wheelPicker?.reload()
    }

    private func resetCurrentSelect() {
        enableRightButton(false)
        for (column, time) in viewModel.selectTime.enumerated() {
            if let models = viewModel.pickerDataSource[safeAccess: column],
               let row = models.firstIndex(where: { $0.time == time }) {
                _ = wheelPicker?.select(in: column, at: row, animated: false)
                if viewModel.selectTime.count == column + 1 {
                    let enabled = viewModel.enabled(column: column, row: row)
                    enableRightButton(enabled)
                }
            }
        }
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        if Display.phone, newContext.layoutChangeReason.isOrientationChanged {
            self.navigationController?.panViewController?.updateBelowLayout()
            self.wheelPicker?.removeFromSuperview() //picker不支持动态高度，且使用autoLayout改高度后reload数据源无效
            self.setupWheelPicker()
            if self.style.showAudioItem { self.setUpAudioLabel() }
            self.resetOrientationDatasource()
            self.resetCurrentSelect()
        }
    }

    @objc private func rightBarButtonAction(_ b: Any) {
        switch style {
        case .start:
            viewModel.start()
        case .prolong:
            viewModel.prolong()
        }
        doBack()
    }

    @objc private func endRemindSwitchAction(_ s: Any) {
        viewModel.updateEnableAudio(endRemindSwitch.isOn)
    }

    @objc private func tapNearRemindLabel(_ t: Any) {
        nearRemindTimeButtonAction(nearRemindTimeButton)
    }

    @objc private func nearRemindTimeButtonAction(_ b: Any) {
        let selectTime = viewModel.selectMinute()
        guard selectTime > 1 else {
            // 1分钟以内，不支持提前提醒
            return
        }
        let vm = CountDownRemindPickerViewModel(range: selectTime > 99 ? 99 : selectTime - 1, defaultTime: viewModel.remindTime) { [weak self] time in
            guard let self = self else { return }
            self.viewModel.remindTime = time
            self.reloadRemindTimeButtonTitle()
        }
        vm.afterBack = { [weak self] in
            if self?.traitCollection.horizontalSizeClass == .compact {
                // 从剩余时间页切换SizeClass，返回后高度可能不对
                self?.navigationController?.panViewController?.updateBelowLayout()
            }
        }
        let vc = CountDownRemindPickerViewController(viewModel: vm)
        viewModel.meeting.router.push(vc, from: self)
    }
}

extension CountDownPickerViewController: UDWheelPickerViewDataSource {

    /// 滚轮的列数，有几列
    func numberOfCloumn(in wheelPicker: UDWheelPickerView) -> Int {
        return viewModel.pickerDataSource.count
    }

    /// 单个滚轮的展示行数
    func wheelPickerView(_ wheelPicker: UDWheelPickerView, numberOfRowsInColumn column: Int) -> Int {
        return viewModel.pickerDataSource[safeAccess: column]?.count ?? 0
    }

    /// 单个滚轮的宽度(比例关系)
    func wheelPickerView(_ wheelPicker: UDWheelPickerView, widthForColumn column: Int) -> CGFloat {
        return 1.0
    }

    /// 滚轮 cell 配置
    func wheelPickerView(_ wheelPicker: UDWheelPickerView, viewForRow row: Int,
                         atColumn column: Int) -> UDWheelPickerCell {
        guard let models = viewModel.pickerDataSource[safeAccess: column], let model = models[safeAccess: row] else {
            return UDDefaultWheelPickerCell()
        }
        let cell = UDDefaultWheelPickerCell()
        cell.labelAttributedString = model.title
        return cell
    }

    /// 配置滚轮滚动模式（无限/有限）
    func wheelPickerView(_ wheelPicker: UDWheelPickerView, modeOfColumn column: Int) -> UDWheelCircelMode {
        return .limited
    }
}

extension CountDownPickerViewController: UDWheelPickerViewDelegate {
    // Responding to Row Actions
    func wheelPickerView(_ wheelPicker: UDWheelPickerView, didSelectIndex index: Int, atColumn column: Int) {
        viewModel.updateSelectTime(column: column, row: index)
        let row = viewModel.realIndex(index)
        let enabled = viewModel.enabled(column: column, row: row)
        enableRightButton(enabled)

        updateRemindTimeWhenSetTimeChanged()
    }
}

extension CountDownPickerViewController: DynamicModalDelegate {
    func regularCompactStyleDidChange(isRegular: Bool) {
        line.isHidden = isRegular
    }
}

extension CountDownPickerViewController: PanChildViewControllerProtocol {

    var panScrollable: UIScrollView? {
        return nil
    }

    var showDragIndicator: Bool {
        return false
    }

    var showBarView: Bool {
        return false
    }

    func height(_ axis: RoadAxis, layout: RoadLayout) -> PanHeight {
        let contentHeight =
        Layout.vGap +
        pickerHeight +
        Layout.vGap +
        (style.showAudioItem ?
         Layout.audioLabelH +
         Layout.audioOffsetRemind +
         endRemindH +
         nearRemindH +
         Layout.vGap +
         Layout.bottomTipH +
         (VCScene.safeAreaInsets.bottom > 0 ? 0 : Layout.vGap) :
            0)
        let size = containerScrollView.contentSize
        containerScrollView.contentSize = CGSize(width: size.width, height: contentHeight)
        let allHeight = contentHeight + (navigationController?.navigationBar.frame.size.height ?? 0)
        let top: CGFloat = currentLayoutContext.layoutType.isPhoneLandscape ? 8 : 44
        return .contentHeight(allHeight, minTopInset: top)
    }

    func width(_ axis: RoadAxis, layout: RoadLayout) -> PanWidth {
        if Display.phone, axis == .landscape {
            return .maxWidth(width: 420)
        }
        return .fullWidth
    }
}
