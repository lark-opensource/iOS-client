//
//  NfcATagMiFareAdapter.swift
//  OPPlugin
//
//  Created by 张旭东 on 2022/9/29.
//
import CoreNFC
import LKCommonsLogging
/// 支持 Mifare 卡 相关操作
@available(iOS 13.0, *)
final class NfcATagMiFareAdapter: NfcTagAdapter {

    private static let logger = Logger.oplog(NfcATagMiFareAdapter.self, category: "NfcTagAdapter")
    weak var session: NFCTagReaderSession?
    private let communicationTag: NFCMiFareTag
    let tag: NFCTag
    var ndefTag: NFCNDEFTag? { return communicationTag }
    
    init?(session: NFCTagReaderSession, tag: NFCTag) {
        guard case .miFare(let communicationTag) = tag else {
            Self.logger.error("NfcATagMiFareAdapter init failed. tag is not miFare")
            return nil
        }
        self.session = session
        self.tag = tag
        self.communicationTag = communicationTag
    }

    func transceive(data: Data, success successHandler: @escaping (Data?) -> Void, failure failureHandler: @escaping (Error) -> Void) {
        guard !data.isEmpty else {
            Self.logger.error("transceive data is empty")
            failureHandler(NFCAdapterError.arrayBufferEmpty)
            return
        }
        Self.logger.info("sendCommand use MiFareCommand, mifareFamily: \(communicationTag.mifareFamily)")
        communicationTag.sendMiFareCommand(data: data) { resultData in
            Self.logger.info("communicationTag.sendMiFareCommand success")
            successHandler(resultData)
        } failure: { error in
            Self.logger.error("communicationTag.sendMiFareCommand failed!, error: \(error)")
            failureHandler(error)
        }
    }

}

@available(iOS 13.0, *)
extension NFCMiFareTag {
    func sendISO7816Command(data: Data,
                            success successHandler: @escaping (Data?) -> Void,
                            failure failureHandler: @escaping (Error) -> Void)
    {
        guard let apdu = NFCISO7816APDU(data: data) else {
            failureHandler(NFCAdapterError.transceiveError)
            return
        }
        if #available(iOS 14.0, *) {
            sendMiFareISO7816Command(apdu) { result in
                switch result {
                case .failure(let error):
                    failureHandler(error)
                case .success(let resultApdu):
                    let resultData = Data(apduRespose: resultApdu)
                    successHandler(resultData)
                }
            }
           
        } else {
            sendMiFareISO7816Command(apdu) { data, statusWord1, statusWord2, error in
                if let error = error {
                    failureHandler(error)
                    return
                }
                let resultData = Data(apduResonse: data, statusWord1: statusWord1, statusWord2: statusWord2)
                successHandler(resultData)
            }
        }
    }
    
    func sendMiFareCommand(data: Data,
                           success successHandler: @escaping (Data?) -> Void,
                           failure failureHandler: @escaping (Error) -> Void)
    {
        if #available(iOS 14.0, *) {
            sendMiFareCommand(commandPacket: data) { result in
                switch result {
                case .failure(let error):
                    failureHandler(error)
                case .success(let resultData):
                    successHandler(resultData)
                }
            }
            
        } else {
            sendMiFareCommand(commandPacket: data) { resultData, error in
                if let error = error {
                    failureHandler(error)
                    return
                }
                successHandler(resultData)
            }
        }
    }
}
