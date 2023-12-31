//
//  VEPolicyImpl.swift
//  LarkSensitivityControl
//
//  Created by ByteDance on 2023/10/31.
//

#if canImport(TTVideoEditor)
import TTVideoEditor
import LarkSensitivityControl
import LarkSecurityComplianceInfra

final class VEPolicyImpl: NSObject, VEPolicyDelegate {
    
    func audioStart(_ component: AudioComponentInstance, withPrivacyCert privacyCert: Any?, error: NSErrorPointer) -> OSStatus {
        guard let token = privacyCert as? Token else {
            Logger.info("LarkSensitivity access ve audioStart, privacyCert is not Token")
            return AudioToolbox.AudioOutputUnitStart(component)
        }
        do {
            Logger.info("LarkSensitivity access ve audioStart, privacyCert is Token")
            return try AudioRecordEntry.audioOutputUnitStart(forToken: token, ci: component)
        } catch let err {
            error?.pointee = err as NSError
            Logger.info("LarkSensitivity access ve audioStart, error \(err.localizedDescription)")
        }
        return -1
    }

    func audioStop(_ component: AudioComponentInstance, withPrivacyCert privacyCert: Any?, error: NSErrorPointer) -> OSStatus {
        Logger.info("LarkSensitivity access ve audioStop")
        return AudioToolbox.AudioOutputUnitStop(component)
    }

    func auGraphStart(_ inGraph: AUGraph, withPrivacyCert privacyCert: Any?, error: NSErrorPointer) -> OSStatus {
        guard let token = privacyCert as? Token else {
            Logger.info("LarkSensitivity access ve auGraphStart, privacyCert is not Token")
            return AudioToolbox.AUGraphStart(inGraph)
        }
        do {
            Logger.info("LarkSensitivity access ve auGraphStart, privacyCert is Token")
            return try AudioRecordEntry.AUGraphStart(forToken: token, inGraph: inGraph)
        } catch let err {
            error?.pointee = err as NSError
            Logger.info("LarkSensitivity access ve auGraphStart, error \(err.localizedDescription)")
        }
        return -1
    }

    func auGraphStop(_ inGraph: AUGraph, withPrivacyCert privacyCert: Any?, error: NSErrorPointer) -> OSStatus {
        Logger.info("LarkSensitivity access ve auGraphStop")
        return AudioToolbox.AUGraphStop(inGraph)
    }

    func cameraStartRuning(_ session: AVCaptureSession, withPrivacyCert privacyCert: Any?, error: NSErrorPointer) {
        guard let token = privacyCert as? Token else {
            Logger.info("LarkSensitivity access ve cameraStartRuning, privacyCert is not Token")
            session.startRunning()
            return
        }
        do {
            Logger.info("LarkSensitivity access ve cameraStartRuning, privacyCert is Token")
            try CameraEntry.startRunning(forToken: token, session: session)
        } catch let err {
            error?.pointee = err as NSError
            Logger.info("LarkSensitivity access ve cameraStartRuning, error \(err.localizedDescription)")
        }
    }

    func cameraStopRuning(_ session: AVCaptureSession, withPrivacyCert privacyCert: Any?, error: NSErrorPointer) {
        Logger.info("LarkSensitivity access ve cameraStopRuning")
        session.stopRunning()
    }
}
#endif
