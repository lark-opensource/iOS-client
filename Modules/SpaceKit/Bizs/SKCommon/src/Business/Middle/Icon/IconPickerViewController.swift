//
//  IconPickerViewController.swift
//  SpaceKit
//
//  Created by 边俊林 on 2020/2/5.
//

import UIKit
import SnapKit
import SKFoundation
import SKUIKit
import SKResource
import UniverseDesignToast
import EENavigator
/*
public typealias IconData = (String, SpaceEntry.IconType) // IconKey, IconType

public class IconPickerViewController: BaseViewController {

    var pickerView: IconPickerView

    var modelConfig: BrowserModelConfig

    /// A value determine if back to previous page after a operation finished.
    var backAfterOperate: Bool = true

    private var token: String

    public init(token: String, iconData: IconData? = nil, model: BrowserModelConfig) {
        self.token = token
        let viewModel = IconPickerViewModel(token: token)
        self.pickerView = IconPickerView(viewModel: viewModel)
        pickerView.selectedIconData = iconData
        self.modelConfig = model

        super.init(nibName: nil, bundle: nil)

        modalPresentationStyle = .fullScreen
        pickerView.delegate = self
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        configure()
        doTrack(action: pickerView.selectedIconData == nil ? "icon_add" : "icon_change")
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureNavigation()
    }

    public static func canOpenIconPicker() -> Bool {
        // 3.19/3.20移动端不要打开，直接false
        if SpaceKit.version.hasPrefix("3.19") || SpaceKit.version.hasPrefix("3.20") {
            return false
        }
        return DocsNetStateMonitor.shared.isReachable
    }

    public static func showErrorIfExist() {
        // 3.19/3.20没灰度不用解释原因
        if SpaceKit.version.hasPrefix("3.19") || SpaceKit.version.hasPrefix("3.20") {
            return
        }

        if !DocsNetStateMonitor.shared.isReachable {
            showOfflineToast()
        }
    }

    static func showOfflineToast() {
        guard let mainWindow = Navigator.shared.mainSceneWindow else { return }
        UDToast.showTips(with: BundleI18n.SKResource.Doc_List_OfflineClickTips,
                            on: mainWindow)
    }
}

extension IconPickerViewController: IconPickerViewDelegate {

    func iconPickerView(_ pickerView: IconPickerView,
                        didSelect icon: IconSelectionInfo,
                        byRandom: Bool,
                        completion: @escaping ((Bool) -> Void)) {
        callbackIconChange(icon.asDictionary(), completion: completion)
        doTrack(action: byRandom ? "icon_random" : "icon_choose", iconId: icon.id)
    }

    func iconPickerViewShouldRemoveIcon(_ pickerView: IconPickerView,
                                        completion: @escaping ((Bool) -> Void)) {
        callbackIconChange(nil, completion: completion)
        doTrack(action: "icon_remove")
    }

    private func callbackIconChange(_ params: [String: Any]?, completion: @escaping ((Bool) -> Void)) {
        modelConfig.jsEngine.callFunction(.setIcon, params: params) {[weak self] _, err in
            if let err = err {
                DocsLogger.error("IconPicker set icon to js failed", extraInfo: ["params": params ?? [:]], error: err)
                completion(false)
                return
            }
            completion(true)
            DocsLogger.info("IconPicker did set icon", extraInfo: ["params": params ?? [:]])
            if  let aParams = params,
                let key = aParams["key"] as? String,
                let fsUnit = aParams["fs_unit"] as? String,
                let type = aParams["type"] as? Int,
                let iconType = SpaceEntry.IconType(rawValue: type) {
                let icon = SpaceEntry.CustomIcon(iconKey: key, iconType: iconType, iconFSUnit: fsUnit)
                self?.modelConfig.browserInfo.docsInfo?.updateIconInfo(icon)
            }
        }
    }

    func iconPickerViewDidUpdateIcon(_ pickerView: IconPickerView) {
        if backAfterOperate {
            back()
        }
    }

}

extension IconPickerViewController {

    @objc
    func randomSelect() {
        pickerView.randomSelect()
    }

}

extension IconPickerViewController {
    
    private func setupView() {
        view.backgroundColor = UIColor.ud.N00
        view.addSubview(pickerView)

        pickerView.snp.makeConstraints { (make) in
            make.leading.trailing.equalTo(view.safeAreaLayoutGuide)
            make.bottom.equalToSuperview()
            make.top.equalTo(navigationBar.snp.bottom)
        }
    }

    private func configure() {

    }
    
    private func configureNavigation() {
        navigationBar.title = BundleI18n.SKResource.Doc_Doc_ChooseIcon
        navigationBar.leadingBarButtonItem = closeButtonItem
        navigationBar.trailingBarButtonItem = SKBarButtonItem(title: BundleI18n.SKResource.Doc_Doc_IconRandom,
                                                              style: .plain,
                                                              target: self,
                                                              action: #selector(randomSelect))
            .construct { $0.id = .random }
    }
    
}

// MARK: - 埋点
extension IconPickerViewController {

    private func doTrack(action: String, iconId: Int? = nil) {
        guard let docsInfo = modelConfig.browserInfo.docsInfo else { return }

        var params: [String: Any] = [
            "file_id": docsInfo.encryptedObjToken,
            "file_type": docsInfo.type.name,
            "module": "doc",
            "action": action
            // "icon_style": 选了图标中的哪一套，具体取值PM待定
        ]
        if let iconId = iconId {
            params["icon_id"] = iconId
        }
        DocsTracker.log(enumEvent: DocsTracker.EventType.clientIconChange, parameters: params)
    }

}
*/
