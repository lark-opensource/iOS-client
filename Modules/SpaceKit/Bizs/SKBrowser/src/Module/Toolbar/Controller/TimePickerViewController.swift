//
//  TimePickerViewController.swift
//  SKBrowser
//
//  Created by lijuyou on 2023/6/16.
//

import SKFoundation
import SKUIKit
import SKCommon
import UniverseDesignDatePicker
import UniverseDesignColor
import UniverseDesignIcon
import UniverseDesignButton
import UniverseDesignFont
import SnapKit
import SKResource
import LarkTraitCollection
import RxSwift

protocol TimePickerViewControllerDelegate: AnyObject {
    func onTimePickDone(timeBlockId: String, hour: Int, minute: Int)
    func onTimePickDeleteTime(timeBlockId: String)
    func onTimePickClose()
}

class TimePickerViewController: SKWidgetViewController {
    
    enum Layout {
        static var headerHeight: CGFloat = 48.0
        static var titleHeight: CGFloat = 48.0
        static var buttonHeight: CGFloat = 48.0
        static var pickerHeight: CGFloat {
            return 256.0
        }
        static var contentWidth: CGFloat = 540.0
        static var defaultContentHeight: CGFloat = 430.0
        static let hGap: CGFloat = 16.0
        static let vGap: CGFloat = 16.0
        static let bottomGap: CGFloat = 16.0
    }
    
    var viewDistanceToWindowBottom: CGFloat = 0
    
    private var contentNeededHeight: CGFloat {
        Layout.headerHeight + Layout.vGap
        + Layout.pickerHeight
        + Layout.vGap + Layout.buttonHeight + Layout.bottomGap
        + viewDistanceToWindowBottom // 为 Magic Share 适配
    }
    
    weak var delegate: TimePickerViewControllerDelegate?
    
    private lazy var containerScrollView: UIScrollView = {
           let s = UIScrollView()
           s.showsVerticalScrollIndicator = false
           s.bounces = false
           s.backgroundColor = UIColor.clear
           return s
       }()
    
    private let timeBlockId: String
    private var currentDate: Date
    private lazy var wheelPicker: UDWheelPickerView = {
        let wheelPicker = UDWheelPickerView(pickerHeight: Layout.pickerHeight, gradientColor: UIColor.ud.bgFloat)
        wheelPicker.backgroundColor = UIColor.ud.bgFloat
        wheelPicker.layer.cornerRadius = 10
        wheelPicker.layer.masksToBounds = true
        wheelPicker.dataSource = self
        wheelPicker.delegate = self
        return wheelPicker
    }()
    
    private lazy var closeButton: UIButton = {
        let button = UIButton()
        button.setImage(UDIcon.closeSmallOutlined.ud.withTintColor(UDColor.iconN1), for: .normal)
        button.addTarget(self, action: #selector(onTapClose), for: .touchUpInside)
        return button
    }()

    private lazy var headerView = UIView().construct { it in
        it.backgroundColor = UDColor.bgBase

        it.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        it.addSubview(doneButton)
        doneButton.snp.makeConstraints { make in
            make.right.equalToSuperview().inset(6)
            make.centerY.equalToSuperview()
        }
        
        let separator = UIView().construct { s in
            s.backgroundColor = UDColor.lineDividerDefault
        }
        it.addSubview(separator)
        separator.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(0.5)
            make.bottom.equalToSuperview()
        }
        
        it.addSubview(closeButton)
        closeButton.snp.makeConstraints { make in
            make.left.equalToSuperview().inset(Layout.hGap)
            make.centerY.equalToSuperview()
            make.width.height.equalTo(24)
        }
    }

    private lazy var titleLabel = UILabel().construct { it in
        it.font = UIFont.systemFont(ofSize: 17, weight: .medium)
        it.textColor = UIColor.ud.textTitle
    }
    
    private lazy var doneButton: UDButton = {
        let config = UDButtonUIConifg.textBlue
        let button = UDButton(config)
        button.titleLabel?.font = UDFont.body0
        button.setTitle(BundleI18n.SKResource.Doc_Facade_Confirm, for: .normal)
        button.addTarget(self, action: #selector(handleDoneButtonClick), for: .touchUpInside)
        return button
    }()
    
    private lazy var deleteButton: UIButton = {
        var button = UIButton()
        button.layer.ud.setBorderColor(UIColor.clear)
        button.backgroundColor = UIColor.ud.bgFloat
        button.setTitleColor(UIColor.ud.functionDanger500, for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        button.setTitle(BundleI18n.SKResource.LarkCCM_Docs_MeetingAgenda_DeleteTime_Button, for: .normal)
        button.layer.cornerRadius = 10.0
        button.addTarget(self, action: #selector(handleDeleteButtonClick), for: .touchUpInside)
        return button
    }()
    
    private let timePlaceHolderCount = 3
    private lazy var hourList: [TimePickerCellModel] = {
        // disable-lint: magic number
        var hours = (0...23).map { createTimeModel(type: .hour, time: $0) }
        for _ in 0..<timePlaceHolderCount {
            hours.insert(createTimeModel(type: .placeHolder, time: 0), at: 0)
            hours.append(createTimeModel(type: .placeHolder, time: 0))
        }
        // enable-lint: magic number
        return hours
    }()
    
    private lazy var minuteList: [TimePickerCellModel] = {
        // disable-lint: magic number
        var minutes = (0...59).map { createTimeModel(type: .minute, time: $0) }
        for _ in 0..<timePlaceHolderCount {
            minutes.insert(createTimeModel(type: .placeHolder, time: 0), at: 0)
            minutes.append(createTimeModel(type: .placeHolder, time: 0))
        }
        // enable-lint: magic number
        return minutes
    }()
    private let disposeBag = DisposeBag()
    
    init(timeBlockId: String, hour: Int, minute: Int) {
        self.timeBlockId = timeBlockId
        var date = Date()
        date.hour = hour
        date.minute = minute
        self.currentDate = date
        super.init(contentHeight: Layout.defaultContentHeight)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        if self.modalPresentationStyle == .formSheet {
            preferredContentSize = CGSize(width: Layout.contentWidth, height: contentNeededHeight)
        }
        setupContentView()
        
        _ = self.wheelPicker.select(in: 0, at: getTimePickerCellIndex(self.currentDate.hour), animated: false)
        _ = self.wheelPicker.select(in: 1, at: getTimePickerCellIndex(self.currentDate.minute), animated: false)
        
        RootTraitCollection.observer
            .observeRootTraitCollectionWillChange(for: self.view)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] change in
                guard SKDisplay.pad else { return }
                if change.old != change.new || self?.modalPresentationStyle == .formSheet {
                    self?.closePicker()
                }
            }).disposed(by: disposeBag)
    }

    // MARK: - UI
    private func setupContentView() {
        backgroundView.backgroundColor = UDColor.bgBase
        contentView.backgroundColor = UDColor.bgBase
        contentView.clipsToBounds = true
        contentView.layer.cornerRadius = 12
        contentView.layer.maskedCorners = .top
        
        contentView.addSubview(headerView)
        contentView.addSubview(containerScrollView)
        
        containerScrollView.snp.makeConstraints { make in
            make.left.right.bottom.equalToSuperview()
            make.top.equalTo(headerView.snp.bottom)
            make.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
        }
        
        headerView.snp.makeConstraints { (make) in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(Layout.headerHeight)
        }
        titleLabel.text = BundleI18n.SKResource.LarkCCM_Docs_MeetingAgenda_EditTime_Button
        
        containerScrollView.addSubview(wheelPicker)
        wheelPicker.snp.makeConstraints {
            $0.top.equalToSuperview().offset(Layout.vGap)
            $0.left.right.equalTo(view.safeAreaLayoutGuide).inset(Layout.hGap)
            $0.height.equalTo(Layout.pickerHeight)
        }
        
        containerScrollView.addSubview(self.deleteButton)
        deleteButton.snp.makeConstraints { make in
            make.left.right.equalToSuperview().inset(Layout.hGap)
            make.top.equalTo(wheelPicker.snp.bottom).offset(Layout.vGap)
            make.height.equalTo(Layout.buttonHeight)
            make.width.equalTo(wheelPicker.snp.width)
        }
        
        self.resetHeight(self.contentNeededHeight)
        view.layoutIfNeeded()
    }
    
    override func dismiss(animated flag: Bool, completion: (() -> Void)? = nil) {
        super.dismiss(animated: flag) { [weak self] in
            completion?()
            self?.delegate?.onTimePickClose()
        }
    }
    
    func closePicker() {
        self.dismiss(animated: true, completion: nil)
    }
    
    // MARK: - Actions
    @objc
    private func onTapClose() {
        closePicker()
    }
        
    @objc
    func handleDeleteButtonClick() {
        self.delegate?.onTimePickDeleteTime(timeBlockId: self.timeBlockId)
        closePicker()
    }
    
    @objc
    func handleDoneButtonClick() {
        DocsLogger.info("pick time: \(String(describing: self.currentDate))")
        let hour = self.currentDate.hour
        let min = self.currentDate.minute
        self.delegate?.onTimePickDone(timeBlockId: self.timeBlockId, hour: hour, minute: min)
        closePicker()
    }
}

extension TimePickerViewController: UDWheelPickerViewDataSource {
    /// 滚轮的列数，有几列
    func numberOfCloumn(in wheelPicker: UniverseDesignDatePicker.UDWheelPickerView) -> Int {
        return 2
    }

    /// 单个滚轮的展示行数
    func wheelPickerView(_ wheelPicker: UniverseDesignDatePicker.UDWheelPickerView, numberOfRowsInColumn column: Int) -> Int {
        if column == 0 {
            return hourList.count
        } else {
            return minuteList.count
        }
    }

    /// 单个滚轮的宽度
    func wheelPickerView(_ wheelPicker: UniverseDesignDatePicker.UDWheelPickerView, widthForColumn column: Int) -> CGFloat {
        return 1.0
    }

    /// 滚轮 cell 配置
    func wheelPickerView(_ wheelPicker: UniverseDesignDatePicker.UDWheelPickerView, viewForRow row: Int, atColumn column: Int) -> UniverseDesignDatePicker.UDWheelPickerCell {
        var model: TimePickerCellModel?
        if column == 0 {
            model = hourList.safe(index: row)
        } else if column == 1 {
            model = minuteList.safe(index: row)
        }
        let cell = UDDefaultWheelPickerCell()
        guard let model = model else {
            spaceAssertionFailure()
            return cell
        }
        cell.labelAttributedString = model.text
        return cell
    }

    /// 配置滚轮滚动模式（无限/有限）
    func wheelPickerView(_ wheelPicker: UniverseDesignDatePicker.UDWheelPickerView, modeOfColumn column: Int) -> UniverseDesignDatePicker.UDWheelCircelMode {
        return .limited
    }
}

extension TimePickerViewController: UDWheelPickerViewDelegate {
    
    func wheelPickerView(_ wheelPicker: UDWheelPickerView, didSelectIndex index: Int, atColumn column: Int) {
        var realIndex = getTimePickerCellIndex(index)
        if column == 0 {
            if let hour = hourList.safe(index: realIndex), hour.type != .placeHolder {
                self.currentDate.hour = hour.time
                debugPrint("[picker] select hour:\(hour.time)")
            }
        } else if column == 1 {
            if let minute = minuteList.safe(index: realIndex), minute.type != .placeHolder {
                self.currentDate.minute = minute.time
                debugPrint("[picker] select minute:\(minute.time)")
            }
        }
    }
}

//MARK: TimePickerCellModel
extension TimePickerViewController {
    
    struct TimePickerCellModel {
        enum TimeType {
            case hour
            case minute
            case placeHolder
        }
        let type: TimeType
        let time: Int
        let text: NSAttributedString
    }
    
    func createTimeModel(type: TimePickerCellModel.TimeType, time: Int) -> TimePickerCellModel {
        guard type != .placeHolder else {
            return TimePickerCellModel(type: type, time: time, text: NSAttributedString())
        }
        let text = type == .hour ? "\(time) \(BundleI18n.SKResource.LarkCCM_Docs_MeetingAgenda_TimeH_Placeholder)"
        : "\(time) \(BundleI18n.SKResource.LarkCCM_Docs_MeetingAgenda_TimeMin_Placeholder)"
        let attrString = NSAttributedString(string: text,
                                            attributes: [
                                                .font: UDFont.title4,
                                                .foregroundColor: UDColor.textTitle
                                            ])
        return TimePickerCellModel(type: type, time: time, text: attrString)
    }
    
    func getTimePickerCellIndex(_ row: Int) -> Int {
        return timePlaceHolderCount + row
    }
}
