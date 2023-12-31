//
//  MentionedEntityLocalizationManagerTests.swift
//  SKCommon_Tests-Unit-_Tests
//
//  Created by chensi(陈思) on 2022/5/20.
//  


import XCTest
@testable import SKCommon

class MentionedEntityLocalizationManagerTests: XCTestCase {
    
    private var manager: MentionedEntityLocalizationManager!
    
    override func setUp() {
        super.setUp()
        manager = MentionedEntityLocalizationManager.createInstance()
    }
    
    func testGetUser() {
        
        let model1 = MentionedEntity.UserModel.init()
        model1.id = "mockId_1"
        model1.cn_name = "成龙"
        model1.en_name = "Jackie Chen"
        
        let model2 = MentionedEntity.UserModel.init()
        model2.id = "mockId_2"
        model2.cn_name = "麻花藤"
        model2.en_name = "Pony Ma"
        
        manager.updateUsers([model1.id: model1,
                             model2.id: model2])
        
        let result1 = manager.getUserById(model1.id)
        XCTAssert(result1?.en_name == model1.en_name)
        
        let result2 = manager.getUserById(model2.id)
        XCTAssert(result2?.cn_name == model2.cn_name)
    }
    
    func testGetDoc() {
        
        let model1 = MentionedEntity.DocModel.init()
        model1.token = "mockToken_1"
        model1.title = "未命名文档"
        model1.doc_type = .doc
        
        let model2 = MentionedEntity.DocModel.init()
        model2.token = "mockToken_2"
        model2.title = "未命名表格"
        model2.doc_type = .sheet
        
        manager.updateDocMetas([model1.token: model1,
                                model2.token: model2])
        
        let result1 = manager.getDocMetaByToken(model1.token)
        XCTAssert(result1?.title == model1.title)
        
        let result2 = manager.getDocMetaByToken(model2.token)
        XCTAssert(result2?.doc_type == model2.doc_type)
    }
}
