//
//  CountDownRemindPickerViewController.swift
//  ByteView
//
//  Created by wulv on 2022/8/12.
//

import Foundation
import UniverseDesignDatePicker
import UniverseDesignIcon
import UIKit
import ByteViewUI

extension CountDownRemindPickerViewController {
    enum Layout {
        static var titleHeight: CGFloat = 48.0
        static let landscapeThresholdH: CGFloat = 344.0
        static let vGap: CGFloat = 16.0
    }
}

/// 设置倒计时剩余时间提醒 页面
final class CountDownRemindPickerViewController: VMViewController<CountDownRemindPickerViewModel> {

    private lazy var leftBarButton: UIButton = {
        let button = UIButton()
        let size = CGSize(width: 24, height: 24)
        let normalIcon = UDIcon.getIconByKey(UDIconType.leftOutlined, iconColor: UIColor.ud.iconN1, size: size)
        let hightlightIcon = UDIcon.getIconByKey(UDIconType.leftOutlined, iconColor: UIColor.ud.N500, size: size)
        button.setImage(normalIcon, for: .normal)
        button.setImage(hightlightIcon, for: .highlighted)
        button.addTarget(self, action: #selector(leftBarButtonAction(_:)), for: .touchUpInside)
        button.addInteraction(type: .highlight, shape: .roundedRect(CGSize(width: 44, height: 36), 8.0))
        return button
    }()

    private lazy var line: UIView = {
        let line = UIView()
        line.backgroundColor = UIColor.ud.lineDividerDefault.withAlphaComponent(0.15)
        return line
    }()

    private lazy var wheelPicker: UDWheelPickerView = {
        let picker = UDWheelPickerView(pickerHeight: pickerHeight,
                                       gradientColor: UIColor.ud.bgBody)
        picker.dataSource = self
        picker.delegate = self
        picker.backgroundColor = UIColor.ud.bgBody
        picker.layer.cornerRadius = 10
        picker.layer.masksToBounds = true
        return picker
    }()

    var pickerHeight: CGFloat {
        if currentLayoutContext.layoutType.isPhoneLandscape {
            return currentLayoutContext.viewSize.height > Layout.landscapeThresholdH ? 258.0 : 158.0
        }
        return 258.0
    }

    override func setupViews() {
        view.backgroundColor = UIColor.ud.bgBase
        title = I18n.View_G_CountdownTimeReminder
        navigationItem.setLeftBarButton(UIBarButtonItem(customView: leftBarButton), animated: true)
        setNavigationBarBgColor(UIColor.ud.bgBase)

        view.addSubview(line)
        line.snp.makeConstraints {
            $0.left.right.top.equalToSuperview()
            $0.height.equalTo(1 / self.view.vc.displayScale)
        }

        view.addSubview(wheelPicker)
        wheelPicker.snp.makeConstraints {
            $0.top.equalToSuperview().offset(Layout.vGap)
            $0.left.right.equalToSuperview().inset(16)
            $0.height.equalTo(pickerHeight)
        }
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .allButUpsideDown
    }

    override func bindViewModel() {

        if let scrollTime = viewModel.defaultTime,
           let scrollIndex = viewModel.pickerDataSource.firstIndex(where: { scrollTime == $0.time }) {
            _ = wheelPicker.select(in: 0, at: scrollIndex, animated: false)
        }
    }

    override func viewLayoutContextIsChanging(from oldContext: VCLayoutContext, to newContext: VCLayoutContext) {
        line.isHidden = VCScene.rootTraitCollection?.horizontalSizeClass == .regular
        if Display.phone, newContext.layoutChangeReason.isOrientationChanged {
            wheelPicker.snp.updateConstraints { make in
                make.height.equalTo(pickerHeight)
            }
            navigationController?.panViewController?.updateBelowLayout()
        }
    }

    @objc private func leftBarButtonAction(_ b: Any) {
        viewModel.callbackSelectTime()
        popOrDismiss(false)
        viewModel.afterBack?()
    }
}

extension CountDownRemindPickerViewController: UDWheelPickerViewDataSource {

    /// 滚轮的列数，有几列
    func numberOfCloumn(in wheelPicker: UDWheelPickerView) -> Int {
        return 1
    }

    /// 单个滚轮的展示行数
    func wheelPickerView(_ wheelPicker: UDWheelPickerView, numberOfRowsInColumn column: Int) -> Int {
        return viewModel.pickerDataSource.count
    }

    /// 单个滚轮的宽度(比例关系)
    func wheelPickerView(_ wheelPicker: UDWheelPickerView, widthForColumn column: Int) -> CGFloat {
        return 1.0
    }

    /// 滚轮 cell 配置
    func wheelPickerView(_ wheelPicker: UDWheelPickerView, viewForRow row: Int,
                         atColumn column: Int) -> UDWheelPickerCell {
        guard let model = viewModel.pickerDataSource[safeAccess: row] else {
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

extension CountDownRemindPickerViewController: UDWheelPickerViewDelegate {

    // Responding to Row Actions
    func wheelPickerView(_ wheelPicker: UDWheelPickerView, didSelectIndex index: Int, atColumn column: Int) {
        viewModel.updateSelectRow(index)
    }
}

extension CountDownRemindPickerViewController: PanChildViewControllerProtocol {

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
        let realHeight = (navigationController?.navigationBar.frame.size.height ?? 0) +
        Layout.vGap +
        pickerHeight +
        Layout.vGap
        return .contentHeight(realHeight, minTopInset: 44)
    }

    func width(_ axis: RoadAxis, layout: RoadLayout) -> PanWidth {
        if Display.phone, axis == .landscape {
            return .maxWidth(width: 420)
        }
        return .fullWidth
    }
}
