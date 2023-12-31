//
//  SensitivityMockViewController.swift
//  SecurityComplianceDebug
//
//  Created by yifan on 2022/11/30.
//

import UIKit
import SnapKit
import LarkSnCService
import LarkContainer
import LarkSensitivityControl
import LarkSecurityCompliance
import UniverseDesignToast

final class SensitivityMockViewController: UIViewController {

    private var serviceImpl: SensitivityControlSnCService?
    
    init(resolver: UserResolver) {
        super.init(nibName: nil, bundle: nil)
        self.serviceImpl = try? resolver.resolve(assert: SensitivityControlSnCService.self)
    }
    
    required init?(coder: NSCoder) {
        return nil
    }

    private lazy var tokenDisabled: Bool = {
        (try? serviceImpl?.storage?.get(key: kTokenDisabledCacheKey)) ?? false
    }()

    private let disableTokenTip: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.text = "禁用所有Token:"
        label.font = UIFont.systemFont(ofSize: 15)
        return label
    }()

    private let disableTokenSwitch: UISwitch = {
        let btn = UISwitch(frame: CGRect.zero)
        btn.backgroundColor = .clear
        return btn
    }()
    
    private let permissionCheckerBtn: UIButton = {
        let btn = UIButton(frame: CGRect.zero)
        btn.setTitle("Permission Check", for: .normal)
        btn.backgroundColor = .orange
        return btn
    }()

    private let checkAtomicTip: UILabel = {
        let label = UILabel(frame: CGRect.zero)
        label.text = "校验Token的AtomicInfo是否匹配:"
        label.font = UIFont.systemFont(ofSize: 15)
        return label
    }()

    private let tokenIDField: UITextField = {
        let field = UITextField(frame: .zero)
        field.borderStyle = UITextField.BorderStyle.roundedRect
        field.keyboardType = UIKeyboardType.asciiCapable
        field.placeholder = "请输入tokenID"
        return field
    }()

    private let tokenAtomicInfoField: UITextField = {
        let field = UITextField(frame: .zero)
        field.borderStyle = UITextField.BorderStyle.roundedRect
        field.keyboardType = UIKeyboardType.asciiCapable
        field.placeholder = "请输入atomicInfoList，以,分开!"
        return field
    }()

    private let addTokenConfigButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setTitle("更新tokenConfig", for: .normal)
        button.backgroundColor = .brown
        return button
    }()

    private let atomicInfoCheckButton: UIButton = {
        let button = UIButton(frame: .zero)
        button.setTitle("checkToken", for: .normal)
        button.backgroundColor = .brown
        return button
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.ud.bgBody
        view.addSubview(disableTokenTip)
        view.addSubview(disableTokenSwitch)
        view.addSubview(permissionCheckerBtn)
        view.addSubview(atomicInfoCheckButton)
        view.addSubview(tokenIDField)
        view.addSubview(tokenAtomicInfoField)
        view.addSubview(addTokenConfigButton)
        view.addSubview(checkAtomicTip)

        setConstraints()
        setAction()

    }

    private func setConstraints() {
        disableTokenTip.snp.makeConstraints {
            $0.top.equalToSuperview().offset(85)
            $0.left.equalToSuperview().offset(16)
            $0.height.equalTo(40)
        }

        disableTokenSwitch.snp.makeConstraints {
            $0.top.equalToSuperview().offset(85)
            $0.left.equalTo(disableTokenTip.snp.right)
            $0.height.equalTo(40)
        }
        
        permissionCheckerBtn.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(150)
            make.left.equalToSuperview().offset(16)
            make.height.equalTo(60)
            make.width.equalTo(200)
        }

        checkAtomicTip.snp.makeConstraints {
            $0.top.equalTo(permissionCheckerBtn.snp.bottom).offset(20)
            $0.height.equalTo(40)
            $0.left.equalToSuperview().offset(16)
        }
        tokenIDField.snp.makeConstraints {
            $0.top.equalTo(checkAtomicTip.snp.bottom).offset(4)
            $0.height.equalTo(40)
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
        }

        tokenAtomicInfoField.snp.makeConstraints {
            $0.top.equalTo(tokenIDField.snp.bottom).offset(4)
            $0.height.equalTo(40)
            $0.left.equalToSuperview().offset(16)
            $0.right.equalToSuperview().offset(-16)
        }

        addTokenConfigButton.snp.makeConstraints {
            $0.top.equalTo(tokenAtomicInfoField.snp.bottom).offset(4)
            $0.height.equalTo(40)
            $0.width.equalTo(150)
            $0.left.equalToSuperview().offset(16)
        }

        atomicInfoCheckButton.snp.makeConstraints {
            $0.top.equalTo(tokenAtomicInfoField.snp.bottom).offset(4)
            $0.height.equalTo(40)
            $0.right.equalToSuperview().offset(-16)
            $0.width.equalTo(150)
        }
    }

    private func setAction() {
        disableTokenSwitch.setOn(tokenDisabled, animated: true)
        disableTokenSwitch.addTarget(nil, action: #selector(exchangeTokenStatus), for: .touchUpInside)
        permissionCheckerBtn.addTarget(self, action: #selector(permissionCheck), for: .touchUpInside)
        atomicInfoCheckButton.addTarget(self, action: #selector(checkToken), for: .touchUpInside)
        addTokenConfigButton.addTarget(self, action: #selector(addTokenConfig), for: .touchUpInside)
    }

    @objc
    private func addTokenConfig() {
        guard let tokenID = tokenIDField.text, let tokenAtomicInfo = tokenAtomicInfoField.text else {
            return
        }
        let token = Token(tokenID)
        let context = Context(tokenAtomicInfo.split(separator: ",").map { String($0) })
        DebugEntry.addTokenConfig(token: token, context: context)
        let config = UDToastConfig(toastType: .info, text: "token添加成功", operation: nil)
        UDToast.showToast(with: config, on: view)
    }

    @objc
    private func checkToken() {
        do {
            guard let tokenID = tokenIDField.text, let tokenAtomicInfo = tokenAtomicInfoField.text else {
                return
            }
            let token = Token(tokenID)
            let context = Context(tokenAtomicInfo.split(separator: ",").map { String($0) })
            try DebugEntry.checkToken(forToken: token, context: context)
            let config = UDToastConfig(toastType: .info, text: "token exist", operation: nil)
            UDToast.showToast(with: config, on: view)
        } catch {
            let config = UDToastConfig(toastType: .error, text: error.localizedDescription, operation: nil)
            UDToast.showToast(with: config, on: view)
        }
    }

    @objc
    private func exchangeTokenStatus() {
        tokenDisabled = !tokenDisabled
        try? serviceImpl?.storage?.set(tokenDisabled, forKey: kTokenDisabledCacheKey)
        DebugEntry.updateDisabledState(tokenDisabled)
    }
    
    /// 权限检测，防止Monitor引入不必要的权限。
    @objc
    private func permissionCheck() {
        assert(!isBadcase(of: "TSPKLocationOfCLLocationManagerPipeline"))
        assert(!isBadcase(of: "TSPKLocationOfCLLocationManagerReqAlwaysAuthPipeline"))
        
        assert(!isBadcase(of: "TSPKAlbumOfALAssetsLibraryPipeline"))
        assert(!isBadcase(of: "TSPKAlbumOfPHAssetPipeline"))
        assert(!isBadcase(of: "TSPKAlbumOfPHAssetChangeRequestPipeline"))
        assert(!isBadcase(of: "TSPKAlbumOfPHAssetCollectionPipeline"))
        assert(!isBadcase(of: "TSPKAlbumOfPHImageManagerPipeline"))
        assert(!isBadcase(of: "TSPKAlbumOfPHPhotoLibraryPipeline"))
        assert(!isBadcase(of: "TSPKAlbumOfPHPickerViewControllerPipeline"))
        assert(!isBadcase(of: "TSPKAlbumOfUIImagePickerControllerPipeline"))
        
        assert(!isBadcase(of: "TSPKAudioOfAudioToolboxPipeline"))
        assert(!isBadcase(of: "TSPKAudioOfAVAudioRecorPipeline"))
        assert(!isBadcase(of: "TSPKAudioOfAVAudioSessionPipeline"))
        assert(!isBadcase(of: "TSPKAudioOfAVCaptureDevicePipeline"))
        
        assert(!isBadcase(of: "TSPKAudioOfAVCaptureDevicePipeline"))
        
        assert(!isBadcase(of: "TSPKCalendarOfEKEventStorePipeline"))
        
        assert(!isBadcase(of: "TSPKContactOfCNContactStorePipeline"))
        
        assert(!isBadcase(of: "TSPKLockIDOfLAContextPipeline"))
        
        assert(!isBadcase(of: "TSPKMotionOfCLLocationManagerPipeline"))
        assert(!isBadcase(of: "TSPKMotionOfCMAltimeterPipeline"))
        assert(!isBadcase(of: "TSPKMotionOfCMMotionActivityManagerPipeline"))
        assert(!isBadcase(of: "TSPKMotionOfCMMotionManagerPipeline"))
        assert(!isBadcase(of: "TSPKMotionOfCMPedometerPipeline"))
        assert(!isBadcase(of: "TSPKMotionOfUIDevicePipeline"))
        
        assert(!isBadcase(of: "TSPKVideoOfAVCaptureStillImageOutputPipeline"))
        assert(!isBadcase(of: "TSPKVideoOfAVCaptureDevicePipeline"))
        assert(!isBadcase(of: "TSPKVideoOfAVCaptureSessionPipeline"))
         
        assert(!isBadcase(of: "TSPKIDFAOfASIdentifierManagerPipeline"))
        assert(!isBadcase(of: "TSPKIDFAOfATTrackingManagerPipeline"))
        
        assert(!isBadcase(of: "TSPKMediaOfMPMediaLibraryPipeline"))
        assert(!isBadcase(of: "TSPKMediaOfMPMediaQueryPipeline"))
    }
    
    private func isBadcase(of pipelineName: String) -> Bool {
        let permissions = pipeline2PermissionDict(of: pipelineName)
        guard let permissions = permissions else {
            return true
        }
        var result = (permissions.count == 0)
        for permission in permissions {
            if Bundle.main.infoDictionary?[permission] == nil {
                result = true
                break
            }
        }
        return result
    }
    
    private func pipeline2PermissionDict(of pipelineName: String) -> [String]? {
        var dict = [String: [String]]()
        // location
        dict["TSPKLocationOfCLLocationManagerPipeline"] = ["NSLocationAlwaysAndWhenInUseUsageDescription", "NSLocationWhenInUseUsageDescription", "NSLocationTemporaryUsageDescriptionDictionary"]
        dict["TSPKLocationOfCLLocationManagerPipeline"] = ["NSLocationAlwaysAndWhenInUseUsageDescription", "NSLocationWhenInUseUsageDescription"]
        // album
        dict["TSPKAlbumOfALAssetsLibraryPipeline"] = ["NSPhotoLibraryUsageDescription", "NSPhotoLibraryAddUsageDescription"]
        dict["TSPKAlbumOfPHAssetPipeline"] = ["NSPhotoLibraryUsageDescription", "NSPhotoLibraryAddUsageDescription"]
        dict["TSPKAlbumOfPHAssetChangeRequestPipeline"] = ["NSPhotoLibraryUsageDescription", "NSPhotoLibraryAddUsageDescription"]
        dict["TSPKAlbumOfPHAssetCollectionPipeline"] = ["NSPhotoLibraryUsageDescription", "NSPhotoLibraryAddUsageDescription"]
        dict["TSPKAlbumOfPHCollectionListPipeline"] = ["NSPhotoLibraryUsageDescription", "NSPhotoLibraryAddUsageDescription"]
        dict["TSPKAlbumOfPHImageManagerPipeline"] = ["NSPhotoLibraryUsageDescription", "NSPhotoLibraryAddUsageDescription"]
        dict["TSPKAlbumOfPHPhotoLibraryPipeline"] = ["NSPhotoLibraryUsageDescription", "NSPhotoLibraryAddUsageDescription"]
        dict["TSPKAlbumOfPHPickerViewControllerPipeline"] = ["NSPhotoLibraryUsageDescription", "NSPhotoLibraryAddUsageDescription"]
        dict["TSPKAlbumOfUIImagePickerControllerPipeline"] = ["NSPhotoLibraryUsageDescription", "NSPhotoLibraryAddUsageDescription"]
        // Audio
        dict["TSPKAudioOfAudioToolboxPipeline"] = ["NSMicrophoneUsageDescription"]
        dict["TSPKAudioOfAVAudioRecorPipeline"] = ["NSMicrophoneUsageDescription"]
        dict["TSPKAudioOfAVAudioSessionPipeline"] = ["NSMicrophoneUsageDescription"]
        dict["TSPKAudioOfAVCaptureDevicePipeline"] = ["NSMicrophoneUsageDescription"]
        
        // Calendar
        dict["TSPKCalendarOfEKEventStorePipeline"] = ["NSCalendarsUsageDescription"]
        
        // Contact
        dict["TSPKContactOfCNContactStorePipeline"] = ["NSContactsUsageDescription"]
        
        // LockID
        dict["TSPKLockIDOfLAContextPipeline"] = ["NSFaceIDUsageDescription"]
        
        // Motion
        dict["TSPKMotionOfCLLocationManagerPipeline"] = ["NSMotionUsageDescription"]
        dict["TSPKMotionOfCMAltimeterPipeline"] = ["NSMotionUsageDescription"]
        dict["TSPKMotionOfCMMotionActivityManagerPipeline"] = ["NSMotionUsageDescription"]
        dict["TSPKMotionOfCMMotionManagerPipeline"] = ["NSMotionUsageDescription"]
        dict["TSPKMotionOfCMPedometerPipeline"] = ["NSMotionUsageDescription"]
        dict["TSPKMotionOfUIDevicePipeline"] = ["NSMotionUsageDescription"]
        
        // Video
        dict["TSPKVideoOfAVCaptureStillImageOutputPipeline"] = ["NSCameraUsageDescription"]
        dict["TSPKVideoOfAVCaptureDevicePipeline"] = ["NSCameraUsageDescription"]
        dict["TSPKVideoOfAVCaptureSessionPipeline"] = ["NSCameraUsageDescription"]
        
        // IDFA
        dict["TSPKIDFAOfASIdentifierManagerPipeline"] = ["NSUserTrackingUsageDescription"]
        dict["TSPKIDFAOfATTrackingManagerPipeline"] = ["NSUserTrackingUsageDescription"]
        
        // Media
        dict["TSPKMediaOfMPMediaLibraryPipeline"] = ["NSAppleMusicUsageDescription"]
        dict["TSPKMediaOfMPMediaQueryPipeline"] = ["NSAppleMusicUsageDescription"]
        
        return dict[pipelineName]
    }
}
