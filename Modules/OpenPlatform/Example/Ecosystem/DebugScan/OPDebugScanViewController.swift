//
//  OPDebugScanViewController.swift
//  Ecosystem
//
//  Created by baojianjun on 2022/5/13.
//  Copyright © 2022 Bytedance.Inc. All rights reserved.
//

import UIKit
import AVFoundation

public protocol OPDebugScanDelegate: AnyObject {
    func didCapture(outputValue: String?)
}

@objcMembers
public class OPDebugScanViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate, AVCaptureDepthDataOutputDelegate {
    weak var delegate: OPDebugScanDelegate?
    
    private lazy var captureSession: AVCaptureSession = AVCaptureSession()
    private var captureLayer: AVCaptureVideoPreviewLayer?
    private var sanFrameView: UIView?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        edgesForExtendedLayout = UIRectEdge();
        title = "Scan"
        self.prepareForScan()
    }
    
    private func prepareForScan() {
#if targetEnvironment(simulator)
        return
#endif
        captureSession.sessionPreset = AVCaptureSession.Preset.high
        let device = AVCaptureDevice.default(for: AVMediaType.video)
        guard let device = device else {
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: device)
            let output = AVCaptureMetadataOutput()
            output.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            captureSession.addInput(input)
            captureSession.addOutput(output)
            output.metadataObjectTypes = output.availableMetadataObjectTypes
            captureLayer = AVCaptureVideoPreviewLayer()
            captureLayer?.session = captureSession
            if let captureLayer = captureLayer {
                captureLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill
                captureLayer.frame = view.layer.bounds
            }
        } catch {
        }
    }
    
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: false)
        if let captureLayer = captureLayer {
            view.layer.addSublayer(captureLayer)
            captureSession.startRunning()
        }
    }
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        captureLayer?.removeFromSuperlayer()
        captureSession.stopRunning()
    }
    
    private func process(urlString: String) -> String {
        return urlString
    }
    
    private func getComponents(urlString: String?) -> URLComponents? {
        guard let urlString = urlString else {
            return nil
        }
        let realURL = URL(string: urlString)
        guard let realURL = realURL else {
            return nil
        }
        return URLComponents(url: realURL, resolvingAgainstBaseURL: false)
    }
    
    // AVCaptureMetadataOutputObjectsDelegate
    public func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureLayer?.removeFromSuperlayer()
        captureSession.stopRunning()
        guard metadataObjects.count > 0 else {
            return
        }
        let metadataObject = metadataObjects[0]
        if metadataObject is AVMetadataMachineReadableCodeObject {
            let outputVal = (metadataObject as! AVMetadataMachineReadableCodeObject).stringValue
            self.navigationController?.popViewController(animated: true)
            self.delegate?.didCapture(outputValue: outputVal)
        }
    }
}
