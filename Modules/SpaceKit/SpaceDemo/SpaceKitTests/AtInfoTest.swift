//
//  AtInfoTest.swift
//  DocsTests
//
//  Created by chenjiahao.gill on 2019/6/13.
//  Copyright © 2019 Bytedance. All rights reserved.

import XCTest
@testable import SpaceKit
@testable import Docs
import Quick
import Nimble

class AtInfoTestSpec: QuickSpec {
    func testHTMLToAtInfoForSpace(rawHTML: String, expect: String) -> Bool {
        let prefix = NSTextAttachment()
        prefix.image = AtType.doc.prefixImage
        let expectResult = NSMutableAttributedString(attributedString: NSAttributedString(attachment: prefix))
        expectResult.append(NSAttributedString(string: expect))
        return self.testHTMLToAtInfo(rawHTML: rawHTML, expect: expectResult.string)

    }

    func testHTMLToAtInfo(rawHTML: String, expect: String) -> Bool {let attributedString = NSAttributedString(string: rawHTML)
        let result = AtInfo.translateAtFormat(from: attributedString).string
        print("[AtInfo 测试] 预期: \(expect)")
        print("[AtInfo 测试] 结果: \(result)")
        return result == expect
    }

    override func spec() {
        self.testNormalCase()
        self.testSpecialCase()
    }
}

extension AtInfoTestSpec {
    func testNormalCase() {
        describe("HTML 标签转为富文本") {
            it("User", closure: {
                let html = """
                            <at category="at-user-block" type="0" href="javascript:void(0)" token="6629468029279273224" name="陈嘉豪" en_name="Jiahao Chen">@陈嘉豪</at>
                            """
                let expectResult = "@陈嘉豪"
                expect(self.testHTMLToAtInfo(rawHTML: html, expect: expectResult)).to(beTrue())
            })
            it("Docs", closure: {
                let html = """
                            <at type="1" href="https://bytedance.feishu.cn/space/doc/doccnL7Fr6xx7CiEmwwZvw" token="doccnL7Fr6xx7CiEmwwZvw">WWDC</at>
                            """
                let expectResult = "WWDC"
                expect(self.testHTMLToAtInfoForSpace(rawHTML: html, expect: expectResult)).to(beTrue())
            })

            it("Sheet", closure: {
                let html = """
                            <at type="3" href="https%3A%2F%2Fbytedance.feishu.cn%2Fspace%2Fsheet%2Fh9ldO0iVKSNBuW2WVbOEPc" token="h9ldO0iVKSNBuW2WVbOEPc">菜单用例</at>
                            """
                let expectResult = "菜单用例"
                expect(self.testHTMLToAtInfoForSpace(rawHTML: html, expect: expectResult)).to(beTrue())
            })

            it("Bitable", closure: {
                let html = """
                            <at type="8" href="https%3A%2F%2Fbytedance.feishu.cn%2Fspace%2Fbitable%2FbasMexGJ2NJFPWFvliFY9t" token="basMexGJ2NJFPWFvliFY9t">Bitable 项目</at>
                            """
                let expectResult = "Bitable 项目"
                expect(self.testHTMLToAtInfoForSpace(rawHTML: html, expect: expectResult)).to(beTrue())
            })

            it("Mindnote", closure: {
                let html = """
                            <at type="11" href="https://bytedance.feishu.cn/space/mindnote/bmncnbCobMV86JpEFlxXLm" token="bmncnbCobMV86JpEFlxXLm">qqqq</at>
                            """
                let expectResult = "qqqq"
                expect(self.testHTMLToAtInfoForSpace(rawHTML: html, expect: expectResult)).to(beTrue())
            })

            it("Drive", closure: {
                let html = """
                            <at type="12" href="https://bytedance.feishu.cn/space/file/boxcnznpAr9h4eX6s1kPwE" token="boxcnznpAr9h4eX6s1kPwE">IMG_4874.HEIC</at>
                            """
                let expectResult = "IMG_4874.HEIC"
                expect(self.testHTMLToAtInfoForSpace(rawHTML: html, expect: expectResult)).to(beTrue())
            })

            it("Slide", closure: {
                let html = """
                            <at type="15" href="https://bytedance.feishu.cn/space/slide/sldcnC0whL5LQosLzmf9s0" token="sldcnC0whL5LQosLzmf9s0">slide test</at>
                            """
                let expectResult = "slide test"
                expect(self.testHTMLToAtInfoForSpace(rawHTML: html, expect: expectResult)).to(beTrue())
            })
        }
    }
    func testSpecialCase() {
        describe("特殊 case 测试") {
            it("很多空格", closure: {
                let html = """
                            <at type="15"    href="https://bytedance.feishu.cn/space/slide/sldcnC0whL5LQosLzmf9s0"    token="sldcnC0whL5LQosLzmf9s0">slide test</at>
                            """
                let expectResult = "slide test"
                expect(self.testHTMLToAtInfoForSpace(rawHTML: html, expect: expectResult)).to(beTrue())
            })

            it("字段不按顺序", closure: {
                let html = """
                            <at type="15" token="sldcnC0whL5LQosLzmf9s0"  href="https://bytedance.feishu.cn/space/slide/sldcnC0whL5LQosLzmf9s0">字段不按顺序</at>
                            """
                let expectResult = "字段不按顺序"
                expect(self.testHTMLToAtInfoForSpace(rawHTML: html, expect: expectResult)).to(beTrue())
            })
            it("未知类型", closure: {
                let html = """
                            <at type="1888"    href="https://bytedance.feishu.cn/space/slide/sldcnC0whL5LQosLzmf9s0"    token="sldcnC0whL5LQosLzmf9s0">未知类型</at>
                            """
                let expectResult = "未知类型"
                expect(self.testHTMLToAtInfo(rawHTML: html, expect: expectResult)).to(beTrue())
            })

            it("没有名字", closure: {
                let html = """
                            <at type="15"    href="https://bytedance.feishu.cn/space/slide/sldcnC0whL5LQosLzmf9s0"    token="sldcnC0whL5LQosLzmf9s0"></at>
                            """
                let expectResult = ""
                expect(self.testHTMLToAtInfoForSpace(rawHTML: html, expect: expectResult)).to(beTrue())
            })

            it("未知字段", closure: {
                let html = """
                            <at type="15" href="https://bytedance.feishu.cn/space/slide/sldcnC0whL5LQosLzmf9s0"    token="sldcnC0whL5LQosLzmf9s0" tag="unknown">未知字段</at>
                            """
                let expectResult = "未知字段"
                expect(self.testHTMLToAtInfoForSpace(rawHTML: html, expect: expectResult)).to(beTrue())
            })
        }
    }
}
