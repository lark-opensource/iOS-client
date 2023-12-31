//
//  NfcATagISO7816Adapter.swift
//  OPPlugin
//
//  Created by 张旭东 on 2022/9/29.
//
import CoreNFC
import LKCommonsLogging
/// 支持 ISO7816 相关操作
@available(iOS 13.0, *)
final class NfcATagISO7816Adapter: NfcTagAdapter {
    private static let logger = Logger.oplog(NfcATagISO7816Adapter.self, category: "NfcTagAdapter")
    weak var session: NFCTagReaderSession?
    let tag: NFCTag
    let communicationTag: NFCISO7816Tag
    var ndefTag: NFCNDEFTag? { return communicationTag }
   
    init?(session: NFCTagReaderSession, tag: NFCTag) {
        guard case .iso7816(let communicationTag) = tag else {
            Self.logger.error("NfcATagISO7816Adapter init failed. tag is not iso7816. tag:\(tag)")
            return nil
        }
        self.session = session
        self.tag = tag
        self.communicationTag = communicationTag
    }
    
    func transceive(data: Data,
                    success successHandler: @escaping (Data?) -> Void,
                    failure failureHandler: @escaping (Error) -> Void)
    {
        guard !data.isEmpty else {
            Self.logger.error("transceive failed. data is empty")
            failureHandler(NFCAdapterError.arrayBufferEmpty)
            return
        }
        guard let apdu = NFCISO7816APDU(data: data) else {
            Self.logger.error("transceive failed. ISO7816 init failed")
            failureHandler(NFCAdapterError.transceiveError)
            return
        }
        Self.logger.info("send iso7816 command")
        communicationTag.sendISO7816Command(data: data) { resultData in
            Self.logger.info("sendISO7816Command success")
            successHandler(resultData)
        } failure: { error in
            Self.logger.error("sendISO7816Command failed. error: \(error)")
            failureHandler(error)
        }
    }
    
}

@available(iOS 13.0, *)
extension NFCISO7816Tag {
    func sendISO7816Command(data: Data,
                            success successHandler: @escaping (Data?) -> Void,
                            failure failureHandler: @escaping (Error) -> Void)
    {
        guard let apdu = NFCISO7816APDU(data: data) else {
            return
        }
        if #available(iOS 14.0, *) {
            sendCommand(apdu: apdu) { result in
                let finalResult: Result<Data?, Error>
                switch result {
                case .failure(let error):
                    failureHandler(error)
                case .success(let resultApdu):
                    let resultData = Data(apduRespose: resultApdu)
                    successHandler(resultData)
                }
            }
        } else {
            sendCommand(apdu: apdu) { data, statusWord1, statusWord2, error in
                if let error = error {
                    failureHandler(error)
                    return
                }
                let resultData = Data(apduResonse: data, statusWord1: statusWord1, statusWord2: statusWord2)
                successHandler(resultData)
            }
        }
    }

}
/// ISO7816-4 APUD response to Data
extension Data {
    @available(iOS 14.0, *)
    init(apduRespose: NFCISO7816ResponseAPDU) {
        self.init(apduResonse: apduRespose.payload,
                  statusWord1: apduRespose.statusWord1,
                  statusWord2: apduRespose.statusWord2)
    }
    ///https://docs.yubico.com/yesdk/users-manual/yubikey-reference/apdu.html
    init(apduResonse payload: Data?, statusWord1: UInt8, statusWord2: UInt8) {
        let bytes = Array(payload ?? Data()) + [statusWord1, statusWord2]
        self.init(bytes)
    }
}


