//
//  DocsDebugViewController+Action.swift
//  Docs
//
//  Created by nine on 2018/11/7.
//  Copyright © 2018 Bytedance. All rights reserved.
//
#if DEBUG || BETA
import Foundation
import CreationLogger
import SpaceKit
import SSZipArchive
import FLEX
import SKCommon
import SKUIKit
import Foundation
import EENavigator
import RoundedHUD


private var fpsMonitor: FPSMonitor?

extension DocsDebugViewController {

    func didSelectEnv(indexPath: IndexPath) {
        if indexPath.row == 0 {     // 研发环境

            let devPickerVC = SKDebugEnvPickVC(complete: { env in
                NotificationCenter.default.post(name: NSNotification.Name(rawValue: "SKDemoDebugSwitchEnv"), object: nil, userInfo: ["env": env])
            })
            devPickerVC.view.backgroundColor = UIColor.ud.N00
            Navigator.shared.present(devPickerVC)
        }
    }


    func didSelectLog(indexPath: IndexPath) {
        if indexPath.row == 0 {
            uploadLogger()
        } else if indexPath.row == 1 {
            checkLogger()
        } else if indexPath.row == 2 {
            configureLogFilter()
        }
    }

    func isFPSMonitorExist() -> Bool {
        return fpsMonitor != nil
    }

    func openFPSMonitor(_ isOn: Bool) {
        if isOn {
            DocsPerformanceMonitorService.run()
        } else {
            DocsPerformanceMonitorService.stop()
        }
    }

    func switchFLEXManager() {
        if FLEXManager.shared().isHidden {
            FLEXManager.shared().showExplorer()
        } else {
            FLEXManager.shared().hideExplorer()
        }
    }

    func uploadLogger() {
        CTLogger.default.getLogFilePath { (logDirPath) in
            let uploadURL = "https://amfr.snssdk.com/file_report/upload?device_id=\(AppUtil.shared.deviceID)&aid=\(AppUtil.shared.appID)&device_platform=iphone"
            var request = URLRequest(method: .post, url: uploadURL)
            request?.setValue("multipart/form-data;boundary=docsdocsdocsdocs", forHTTPHeaderField: "Content-Type")

            let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
            let logZipPath = "\(paths[0])/docs_log.zip"

            SSZipArchive.createZipFile(atPath: logZipPath, withContentsOfDirectory: logDirPath)

            var data: Data = "--docsdocsdocsdocs".data(using: .utf8)!
            data.append("\r\n".data(using: .utf8)!)
            data.append("Content-Disposition: form-data; name=\"file\"; filename=\"docs_log.zip\"".data(using: .utf8)!)
            data.append("\r\n".data(using: .utf8)!)
            data.append("\r\n".data(using: .utf8)!)
            do {
                let zipURL = URL(fileURLWithPath: logZipPath)
                let zipData = try Data(contentsOf: zipURL)
                data.append(zipData)
            } catch {
                CTLogger.default.error("获取 zip 错误")
            }
            data.append("\r\n".data(using: .utf8)!)
            data.append("--docsdocsdocsdocs--".data(using: .utf8)!)

            let session = URLSession(configuration: URLSessionConfiguration.default)
            let uploadTask = session.uploadTask(with: request!, from: data) { (_, _, error) in
                if error == nil {
                    CTLogger.default.info("日志上传成功")
                    DispatchQueue.main.async {
                        ProgressHUD.showSuccess("日志上传成功", duration: 2)
                    }
                }
            }
            uploadTask.resume()
        }
    }

    func checkLogger() {
        let fileDesitnation: CTLoggerFileDestination = (CTLogger.default.destination(withIdentifier: NSStringFromClass(CTLoggerFileDestination.self)) as? CTLoggerFileDestination)!
        guard let logFilePath = fileDesitnation.logFilePath else {
            ProgressHUD.showFail("获取日志路径失败", duration: 2)
            return
        }

        do {
            let log = try String(contentsOfFile: logFilePath)
            let logViewController = UIViewController()
            logViewController.view.backgroundColor = .white
            logViewController.view.addSubview({
                let logView = UITextView(frame: {
                    var frame = self.view.frame
                    let offset: CGFloat = UIApplication.shared.statusBarFrame.size.height + (self.navigationController?.navigationBar.bounds.size.height)!
                    frame.origin.y += offset
                    frame.size.height -= offset + 20
                    return frame
                }())
                logView.text = log
                logView.contentInsetAdjustmentBehavior = .never
                return logView
                }())
            self.navigationController?.pushViewController(logViewController, animated: false)
        } catch {
        }
    }

    func configureLogFilter() {
        let logFilterViewController = LogFilterViewController()
        self.navigationController?.pushViewController(logFilterViewController, animated: true)
    }
    func gotoDriveLocalPreview() {
        let vc = DriveLocalFilesTableViewController()
        self.navigationController?.pushViewController(vc, animated: true)
    }

    func autoTestOpenBitable(isOn: Bool) {
//        bitableAutoOpenManager.isOn = isOn
//        if isOn {
//            ProgressHUD.showSuccess("2秒后开始测试，过程中如需关闭，可以在pop到本页面时关闭开关...", duration: 2)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                self.bitableAutoOpenManager.start(navigationController: self.navigationController)
//            }
//        } else {
//            bitableAutoOpenManager.stop()
//        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//            if self.bitableAutoOpenManager.isOn == true {
//                self.bitableAutoOpenManager.repeatOpen()
//            }
//        }
    }
}

extension DocsDebugConstant {
    static var isFlexOn: Bool {
        return !FLEXManager.shared().isHidden
    }
}
#endif
