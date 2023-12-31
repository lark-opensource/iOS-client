//
//  TimeContainerManagerViewController.swift
//  Calendar
//
//  Created by ByteDance on 2023/11/16.
//

import Foundation
import LarkUIKit
import SnapKit

extension TimeContainerModel: CalendarManagerViewProtocol {
    var calSummary: String {
        self.displayName
    }
    
    var calSummaryRemark: String? {
        nil
    }
    
    var permission: CalendarAccess {
        .privacy
    }
    
    var color: UIColor {
        SkinColorHelper.pickerColor(of: self.colorIndex.rawValue)
    }
    
    var desc: String {
        ""
    }
    
    var calMemberCellModels: [CalendarMemberCellModel] {
        []
    }
    
    var canAddNewMember: Bool {
        false
    }
}

protocol TimeContainerManagerViewControllerDelegate: AnyObject {
    /// 点击取消
    func onCancel(_ vc: TimeContainerManagerViewController)
    /// 点击保存
    func onSave(_ vc: TimeContainerManagerViewController)
}

class TimeContainerManagerViewController: BaseUIViewController {
    
    private let childView: CalendarManagerView
    
    private(set) var originalContainer: TimeContainerModel
    
    private(set) var currentContainer: TimeContainerModel {
        didSet {
            self.childView.update(with: currentContainer)
        }
    }
    
    weak var delegate: TimeContainerManagerViewControllerDelegate?
    
    init(container: TimeContainerModel) {
        var condition = CalendarEditPermission(calendarfrom: .fromCreate)
        condition.authInfo.isSummaryEditable = false
        self.childView = CalendarManagerView(
            condition: condition,
            uiCondition: [.summary, .color]
        )
        self.originalContainer = container
        self.currentContainer = container
        super.init(nibName: nil, bundle: nil)
        childView.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNavibar()
        setupView()
    }
    
    private func setupView() {
        view.addSubview(childView)
        childView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        childView.update(with: currentContainer)
    }
    
    private func setupNavibar() {
        self.title = BundleI18n.Calendar.Calendar_Setting_CalendarSetting
        let backButton = UIBarButtonItem(title: I18n.Calendar_Common_Cancel, style: .plain, target: self, action: #selector(cancelHandler))
        self.navigationItem.leftBarButtonItem = backButton

        let saveButton = UIBarButtonItem(title: I18n.Calendar_Common_Save, style: .plain, target: self, action: #selector(saveHandler))
        saveButton.tintColor = UIColor.ud.primaryContentDefault
        self.navigationItem.rightBarButtonItem = saveButton
    }
    
    @objc
    private func cancelHandler() {
        self.delegate?.onCancel(self)
    }
    
    @objc
    private func saveHandler() {
        self.delegate?.onSave(self)
    }
    
    func updateCurrentContainer(_ container: TimeContainerModel) {
        self.currentContainer = container
    }
}

extension TimeContainerManagerViewController: CalendarManagerViewDelegate {
    /// 进入 ColorPicker
    func calColorPressed() {
        let colorEditVC = ColorEditViewController(selectedIndex: currentContainer.colorIndex.rawValue)
        colorEditVC.colorSelectedHandler = { [weak self] index in
            if let colorIndex = ColorIndex(rawValue: index),
               var container = self?.currentContainer {
                container.colorIndex = colorIndex
                self?.updateCurrentContainer(container)
            }
        }
        self.navigationController?.pushViewController(colorEditVC, animated: true)
    }
    
    func calSummaryChanged(newSummary: String) {}
    func calNoteChanged(newNote: String) {}
    func calAccessPressed() {}
    func calDescPressed() {}
    func addCalMemberPressed() {}
    func calMemberPressed(index: Int) {}
    func unsubscribeCalPressed() {}
    func deleteCalPressed() {}
}
