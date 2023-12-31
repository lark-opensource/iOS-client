//
//  NfcTagAdapter.swift
//  OPPlugin
//
//  Created by 张旭东 on 2022/9/28.
//

import CoreNFC
import Foundation

public enum NFCAdapterError: Error {
    /// 当前设备正在扫描NFC
    case isDiscovering
    /// 当前设备NFC已连接
    case techAlreadyConnected
    /// 当前设备NFC未连接
    case techNotConnected
    /// 系统未发现NFC标签
    case techNotDiscovered
    /// 当前NFC标签不支持该tech
    case techNotSupport
    /// 当前设备不支持该NFC能力
    case techFuncNotSupport
    /// 基础数据传输参数错误
    case dataIsNull
    /// array buffer数据传输参数错误
    case arrayBufferEmpty
    /// base64数据传输参数错误
    case base64ValueEmpty
    /// base64数据解码失败
    case base64DecodeError
    /// 数据传输协议报错，导致result为空 transceive： transmit + receive 复合词
    case transceiveError
    /// NFC标签为空
    case typeEmpty
    /// NFC服务已断开
    case serviceDead
    /// 当前设备不支持NFC
    case notAvailable
    /// 当前设备未开启NFC
    case notOpened
    
}
/// NFC 技术类型
public enum NfcTechnology: String {
    /// NFC forum NDEF 通用格式
    case ndef = "NDEF"
    /// RF层（硬件层）遵守 ISO 14443-A协议
    case nfcA = "NFC-A"
//    case nfcB = "NFC-B"
//    case nfcF = "NFC-F"
//    case nfcV = "NFC-V"
//    case isoDep = "ISO-DEP"
//    case mifareClassic = "MIFARE-Classic"
//    case mifareUltralight = "MIFARE-Ultralight"
}
/// 检测到的NFC tag
protocol DetectedTag {
    /// 该tag的支持的技术类型
    var techs: [NfcTechnology] { get }
    /// 改tag的 ID
    var identifier: Data? { get }
}

typealias NfcDetectTagsHandler = (DetectedTag) -> Void
///// NfcSessionAdapterDelegate
protocol NfcSessionAdapterDelegate: AnyObject {
    /// 扫描到NFC tag 的回调
    func nfcSessionAdapter(_ session: NfcSessionAdapter, didDetectTag: DetectedTag)
    /// session 开始活跃
    func nfcSeessionAdapterDidBecomeActive(_ session: NfcSessionAdapter)
    /// session失效，可能是用户点击 也可能是API调用了 stop
    func nfcSessionAdapter(_ session: NfcSessionAdapter, didInvalidateWithError error: Error)
}
/// NFC 扫描Session 的适配器
protocol NfcSessionAdapter {
    var delegate: NfcSessionAdapterDelegate? { get set }
    func startPolling() throws
    func stopPolling() throws
    func getTag(tech: NfcTechnology) throws -> any NfcTagAdapter
}
/// NFC Tag连接相关
protocol NfcTagConnect {
    associatedtype Session
    associatedtype Tag
    /// 扫描的Tag
    var tag: Tag { get }
    /// session
    var session: Session? { get }
    /// 发起连接
    func connect(handler: @escaping (Error?) -> Void)
    /// 关闭连接
    func close()
}
/// NFC 支持NDEF 适配器
protocol NfcNDDFTagAdapter {
    @available(iOS 13.0, *)
    var ndefTag: NFCNDEFTag? { get }
    /// 读操作
    func readNDEF(success successHandler: @escaping ([NFCNDEFPayload]) -> Void,
                  failure failureHandler: @escaping (Error) -> Void)
    /// 写操作
    @available(iOS 13.0, *)
    func writeNDEF(records: [NFCNDEFPayload],
                   success successHandler: @escaping () -> Void,
                   failure failureHandler: @escaping (Error) -> Void)
    /// 是否是可写的
    func isNDEFWritable(success successHandler: @escaping (Bool) -> Void,
                        failure failureHandler: @escaping (Error) -> Void)
    /// 将卡片变为只读
    func makeNDEFReadOnly(success successHandler: @escaping () -> Void,
                          failure failureHandler: @escaping (Error) -> Void)
}

protocol NfcTagTechAdapter {
    /// 只有在出现传输错误时才会走 failure。其余错误需要用户自行解析 success data
    /// transceive： transmit + receive 复合词
    func transceive(data: Data,
                    success successHandler: @escaping (Data?) -> Void,
                    failure failureHandler: @escaping (Error) -> Void)
}

typealias NfcTagAdapter = NfcTagConnect & NfcNDDFTagAdapter & NfcTagTechAdapter

extension NfcSessionAdapter {
    var isSupport: Bool { isSoftwareSupport && isHardwareSupport }
    var isSoftwareSupport: Bool {
        if #available(iOS 13.0, *) {
            return true
        }
        return false
    }

    var isHardwareSupport: Bool {
        NFCReaderSession.readingAvailable
    }
}
