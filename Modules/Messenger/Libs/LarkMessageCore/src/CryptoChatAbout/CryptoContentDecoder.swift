//
//  CryptoContentDecoder.swift
//  LarkMessageCore
//
//  Created by zc09v on 2021/10/11.
//

import Foundation
import AsyncComponent
import LarkMessageBase
import LarkModel
import RustPB
import LarkCore
import LarkRustClient
import LKCommonsLogging
import LarkContainer
import TangramService
import ThreadSafeDataStructure
import EEAtomic

// 该类最终会定义在密聊模块中，不对外模块暴露
public final class CryptoContentDecoder {
    static private var logger = Logger.log(CryptoContentDecoder.self, category: "LarkMessage.CryptoContentDecoder")
    @SafeLazy private var rustClient: RustService = Injected().wrappedValue

    private var realTextContents: SafeDictionary<String, TextContent> = [:] + .readWriteLock

    public init() {}

    public func getRealContent(token: String) -> TextContent? {
        if let realTextContent = self.realTextContents[token] {
            CryptoContentDecoder.logger.info("crypto trace direct return \(token)")
            if realTextContent.richText.elements.isEmpty {
                CryptoContentDecoder.logger.error("crypto trace direct return empty \(token)")
            }
            return realTextContent
        }
        CryptoContentDecoder.logger.info("crypto trace request start \(token)")
        var request = RustPB.Im_V1_GetDecryptedContentRequest()
        request.decryptedTokens = [token]
        let res: RustPB.Im_V1_GetDecryptedContentResponse? = try? self.rustClient.sendSyncRequest(request)
        CryptoContentDecoder.logger.info("crypto trace request finish \(token)")
        if let content = res?.contents[token] {
            let textContent = TextContent(
                text: content.text,
                previewUrls: content.previewUrls,
                richText: content.richText,
                docEntity: nil,
                abbreviation: nil,
                typedElementRefs: nil
            )
            CryptoContentDecoder.logger.info("crypto trace req return \(token)")
            if textContent.richText.elements.isEmpty {
                CryptoContentDecoder.logger.error("crypto trace req return empty \(token)")
            }
            self.realTextContents[token] = textContent
            return textContent
        }
        Self.logger.error("crypto trace can not getRealTextContent \(token)")
        return nil
    }
}
