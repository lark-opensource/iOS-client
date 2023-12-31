//
//  TemplateAPI.swift
//  SpaceInterface
//
//  Created by lijuyou on 2023/6/2.
//  


import Foundation
import RxSwift

public protocol TemplateAPI: AnyObject {
    
    
    /// 根据模板创建文档
    /// - Parameters:
    ///   - docType: 文档类型
    ///   - docToken: 模板文档Token
    ///   - templateId: 模板ID
    ///   - titleParam: 标题参数
    ///   - result: 结果回调
    func createDocsByTemplate(docType: Int,
                              docToken: String?,
                              templateId: String?,
                              templateSource: String?,
                              titleParam: CreateDocTitleParams?,
                              callback: ((DocsTemplateCreateResult?, Error?) -> Void)?)
    
    
    /// 获取分类模板列表
    /// - Parameters:
    ///   - categoryId: 分类ID
    ///   - pageIndex: 页码
    ///   - pageSize: 分页大小
    ///   - docsType: 指定文档类型，nil为所有。(DocComponent指定.docx类型)
    /// - Returns:Observable<分页模板列表>
    func fetchTemplateData(categoryId: String,
                           pageIndex: Int,
                           pageSize: Int,
                           docsType: DocsType?,
                           templateSource: String?) -> Observable<TemplateCategoryPageInfo>
    
    
    /// 删除文档
    /// - Parameters:
    ///   - docToken: 文档token
    ///   - docType: 文档类型
    /// - Returns: Completable
    func deleteDoc(docToken: String, docType: Int) -> Completable
    
    /// 创建水平模板列表View
    func createTemplateHorizontalListView(frame: CGRect,
                                          params: HorizontalTemplateParams,
                                          delegate: TemplateHorizontalListViewDelegate) -> TemplateHorizontalListViewProtocol
    
    /// 创建选择模板页
    func createTemplateSelectedPage(param: CreateTemplatePageParam,
                                    fromVC: UIViewController,
                                    delegate: TemplateSelectedDelegate?) -> UIViewController?
}
