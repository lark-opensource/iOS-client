//
//  FBGetSwiftAllRetainedObjects.swift
//  FBRetainCycleDetector
//
//  Created by  郎明朗 on 2021/5/7.
//

import Foundation


enum MetaDataKind:UInt {
    case SWIFT_CLASS_1  = 0x0
    case SWIFT_STRUCT   = 0x200
    case SWIFT_ENUM     = 0x201
    case SWIFT_OPTIONAL = 0x202
    case SWIFT_FOREIGN_CLASS = 0x203
    case SWIFT_OPAQUE   = 0x300
    case SWIFT_TUPlE    = 0x301
    case SWIFT_FUNCTION = 0x302
    case SWIFT_EXISTENTIAL = 0x303
    case SWIFT_METATYPE = 0x304
    case PURE_OC_CLASS  = 0x305
    case SWIFT_CLASS_2  = 0x7FF
}



enum OptionalAssociateType {
    case baseType
    case classType
    case otherType
}



/*
 Used to cache class strong properties to improve efficiency
 不能存储是否是Class的信息，因为相同属性不同情况类型可能不同，比如属性遵守某协议
 */
var strongPropertyCache = [String:[Int]]()



class PropertyAndName : NSObject, PropertyAndNameProtocol {
    var name:NSString = ""
    var value:Any
    
    init(with val:Any) {
        self.value = val
    }
    
    init(with val:Any, name:NSString){
        self.value = val
        self.name = name
    }
    
    public func propertyName() -> String {
        return name as String
    }
    
    public func propertyValue() -> Any{
        return value
    }
}



@objc(FBGetSwiftAllRetainedObjects)
class FBGetSwiftAllRetainedObjects : NSObject,FBSiwftGetStrongReferenceProtocol {
    
    class func isSwiftInstance(with instance:Any) -> Bool {
        let instanceType = type(of:instance)
        let instanceMetaData:UnsafeMutablePointer<TargetMetadata> = unsafeBitCast(instanceType as Any.Type, to: UnsafeMutablePointer<TargetMetadata>.self)
        let kind:UInt = instanceMetaData.pointee.Kind
        if ( kind == MetaDataKind.PURE_OC_CLASS.rawValue ) {
            return false
        }
        return true
    }
    
    
    class func judgeIfClassType(with instance:Any) -> Bool {
        let instanceType = type(of:instance)
        let instanceMetaData:UnsafeMutablePointer<TargetMetadata> = unsafeBitCast(instanceType as Any.Type, to: UnsafeMutablePointer<TargetMetadata>.self)
        let kind:UInt = instanceMetaData.pointee.Kind
        if kind > MetaDataKind.SWIFT_CLASS_2.rawValue || kind == MetaDataKind.SWIFT_CLASS_1.rawValue || kind == MetaDataKind.PURE_OC_CLASS.rawValue {
            return true
        }
        return false
    }
    
    
    class func isNull(_ obj: AnyObject) -> Bool {
        let address = unsafeBitCast(obj, to: Int.self)
        return address == 0x0
    }
    
    class func isHeapPointer(_ obj: AnyObject) -> Bool {
        var classPtr = unsafeBitCast(obj, to:UnsafeRawPointer.self)
        if((fb_safe_malloc_zone_from_ptr_swift(classPtr)) == nil){
            return false
        }
        return true
    }
    
    class func getOCClassTypeInstanceAllStrongReferance(of instance:AnyObject, currentClass:AnyClass, strongClassTypeReferences:inout Array<PropertyAndName>, otherRetainedReferences:inout Array<PropertyAndName>, configuration:FBObjectGraphConfiguration) {
        
        if !(currentClass is NSObject.Type) {
            return
        }
        
        let res:NSDictionary = FBGetStrongReferencesForSwiftClass(currentClass, instance,configuration) as NSDictionary
        for key in res.allKeys {
            let temp:PropertyAndName = PropertyAndName.init(with: res.object(forKey: key)!)
            temp.name = key as! NSString
            
            if self.judgeIfClassType(with:res.object(forKey: key)!) {
                strongClassTypeReferences.append(temp)
            } else {
                otherRetainedReferences.append(temp)
            }
        }
    }
    
    
    class func getSwiftClassTypeInstanceAllStrongReferance(of currentMirror:Mirror, currentMeta:UnsafeMutablePointer<ClassMetadata>, currentClass:AnyClass, strongClassTypeReferences:inout Array<PropertyAndName>, otherRetainedReferences:inout Array<PropertyAndName>) {
        
        let className:String = NSStringFromClass(currentClass);
        var strongPropertyCacheAry:[Int]? = strongPropertyCache[className];
        
        
        if strongPropertyCacheAry == nil { //没有缓存
            strongPropertyCacheAry = [Int]()
        } else { // 命中缓存
            reportAlog("hit cache" + className + strongPropertyCacheAry!.description)
            
            let children = currentMirror.children
            for index in strongPropertyCacheAry! {
                if index >= children.count {
                    reportAlog(className + "cache error")
                    assert(index < children.count, "swift class property cache error! ")
                    break;
                }
                reportAlog("access class ：" + String(index) + "property")
                
                let property = children[children.index(children.startIndex, offsetBy: index)]
                
                let proValue:AnyObject = property.value as AnyObject;
                if isNull(proValue) {
                   continue
                }
                
                if self.judgeIfClassType(with: property.value) {
                    strongClassTypeReferences.append(PropertyAndName(with: property.value, name: property.label != nil ? property.label! as NSString : ""))
                } else{
                    otherRetainedReferences.append(PropertyAndName(with: property.value, name: property.label != nil ? property.label! as NSString : ""))
                }
            }
            return
        }
        
        // get weak/unowned propety info
        var weakOrUnowenProDic = [String: String]()
        var weakOrUnowenProIndexAry = [Int]()
        let propertyCount = Int(currentMeta.pointee.Description.pointee.NumFields)
        (0..<propertyCount).forEach {
            let propertyPtr = currentMeta.pointee.Description.pointee.Fields.get().pointee.getField(index: $0)
            let propertyTypeFlag:String = String(cString: makeSymbolicMangledNameStringRef(propertyPtr.pointee.MangledTypeName.get()));
            let propertyName:String = String(cString: propertyPtr.pointee.FieldName.get());
            
            reportAlog("property name and type that was detected by FB: name: " + propertyName  + " typeFlag: " + propertyTypeFlag);
            
            if propertyTypeFlag.hasSuffix("Xw") || propertyTypeFlag.hasSuffix("Xo") {
                weakOrUnowenProDic.updateValue(propertyTypeFlag,forKey:propertyName);
                weakOrUnowenProIndexAry.append($0)
            }
        }
        
        //reportAlog("weakOrUnowenProDic that was detected by FB:" + weakOrUnowenProDic.description);
        reportAlog("weakOrUnowenProIndexAry that was detected by FB:" + weakOrUnowenProIndexAry.description);
        
        
        let children = currentMirror.children
        for index_raw in children.indices {
            let index: Int = children.distance(from: children.startIndex, to: index_raw)
            
            if weakOrUnowenProIndexAry.contains(index) { // judge weak
                continue
            }
            
            reportAlog("not weak property index that was detected by FB:" + String(index));
            
            let property = children[index_raw]
            
            let proValue:AnyObject = property.value as AnyObject;
            if isNull(proValue) {
               continue
            }
            
            reportAlog("not weak property name that was detected by FB:" + (property.label ?? "nil"));
            
            
            if property.label != nil && weakOrUnowenProDic.keys.contains(property.label!) {// judge weak again
                continue
            }

            
            let childMirror = Mirror(reflecting: property.value)
            let subTypeString = String(describing:childMirror.subjectType)
            
            if subTypeString.contains("Optional") {
                let optionalType = self.getSwiftOptioanalTypeInstanceAllStrongReferance(of: property.value, instanceName: property.label != nil ? property.label! : "", strongClassTypeReferences: &strongClassTypeReferences, otherRetainedReferences: &otherRetainedReferences)
                
                if optionalType == OptionalAssociateType.classType || optionalType == OptionalAssociateType.otherType {
                    strongPropertyCacheAry?.append(index)
                }
            } else { // 非 optional 一定不为nil
                if childMirror.displayStyle != nil {//非基础类型+闭包 || subTypeString.contains("->") 暂时不处理
                    let temp:PropertyAndName = PropertyAndName.init(with: property.value)
                    if property.label != nil {
                        temp.name = property.label! as NSString
                    }
                    if self.judgeIfClassType(with:property.value) {
                        strongClassTypeReferences.append(temp)
                    } else {//非 class 类型，需要再继续拆分
                        otherRetainedReferences.append(temp)
                    }
                    strongPropertyCacheAry?.append(index)
                }
            }
        }
        
        
        if className.contains("SwiftDeferredNSArray") || className.contains("SwiftDeferredNSSet") || className.contains("SwiftDeferredNSDictionary") {
        } else {
            strongPropertyCache.updateValue(strongPropertyCacheAry!,forKey:className)
        }
    }
    
    
    /*
     处理 struct 和容器类型：
        struct 需考虑 strong/weak，
        容器类型中一定是 strong；字典类型容器 == 没有key的struct，成员是tuple,dic 中的一对key/value变成两个tuple；array类型容器 == 没有key的struct，成员是array类型容器的成员
     */
    //todo 增加缓存提高效率 数组/字典均不能增加缓存
    class func getSwiftStructTypeInstanceAllStrongReferance(of instance:Any, instanceName:String, strongClassTypeReferences:inout Array<PropertyAndName>, otherRetainedReferences:inout Array<PropertyAndName>) {
        
        //get weak/unowned property
        let instanceType = type(of:instance)
        var weakOrUnowenProDic =  [String: String]()
        var weakOrUnowenProIndexAry = [Int]()
        let structMeta:UnsafeMutablePointer<StructMetadata> = unsafeBitCast(instanceType as Any.Type, to: UnsafeMutablePointer<StructMetadata>.self)
        let propertyCount = Int(structMeta.pointee.Description.pointee.NumFields)
        (0..<propertyCount).forEach {
            let propertyPtr = structMeta.pointee.Description.pointee.Fields.get().pointee.getField(index: $0)
            let propertyTypeFlag:String = String(cString: makeSymbolicMangledNameStringRef(propertyPtr.pointee.MangledTypeName.get()));
            let propertyName:String = String(cString: propertyPtr.pointee.FieldName.get());
            
            if propertyTypeFlag.hasSuffix("Xw") || propertyTypeFlag.hasSuffix("Xo") {
                weakOrUnowenProDic.updateValue(propertyTypeFlag,forKey: propertyName)
                weakOrUnowenProIndexAry.append($0)
            }
        }
        
        reportAlog("strut init mirror: " + instanceName)
        if(!isHeapPointer(instance as AnyObject)){
            return
        }
        let structMirror = Mirror(reflecting:instance)
        let children = structMirror.children
        for index_raw in children.indices {
            let index: Int = children.distance(from: children.startIndex, to: index_raw)
            if weakOrUnowenProIndexAry.contains(index) { //weak
                continue
            }
            let property = children[index_raw]
            
            let proValue:AnyObject = property.value as AnyObject;
            if isNull(proValue) {
               continue
            }
            
            if property.label != nil && weakOrUnowenProDic.keys.contains(property.label!)  {//weak
                continue
            }
    
            
            let childMirror = Mirror(reflecting: property.value)
            let subTypeString = String(describing:childMirror.subjectType)
            
            if index >= 4 && (structMirror.description.contains("Dictionary") || structMirror.description.contains("Array"))  {
                break;
            }
            
            if subTypeString.contains("Optional") {
                if case Optional<Any>.none = property.value {//nil
                    continue
                }
            }

            if childMirror.displayStyle != nil {//暂时不判断|| subTypeString .contains("->")
                let temp:PropertyAndName = PropertyAndName.init(with: property.value)
                if property.label != nil {
                    temp.name = (instanceName + "->" +  property.label!) as NSString
                } else {
                    temp.name = instanceName as NSString
                }
                
                if self.judgeIfClassType(with:property.value) {
                    strongClassTypeReferences.append(temp)
                }else {
                    otherRetainedReferences.append(temp)
                }
            }
            
        }
    }
    
    
    /*
     处理 optional 类型
     由于可选类型作为属性已经被筛选过一次，到这里的可选类型肯定不是weak或unowned，
     */
    class func getSwiftOptioanalTypeInstanceAllStrongReferance(of instance:Any, instanceName:String, strongClassTypeReferences:inout Array<PropertyAndName>, otherRetainedReferences:inout Array<PropertyAndName>) -> OptionalAssociateType {
        
        let optionalMirror = Mirror(reflecting: instance)
        if optionalMirror.children.count > 0 {
            let property = optionalMirror.children.first!
            let childMirror = Mirror(reflecting: property.value)
            
            if childMirror.displayStyle != nil {//闭包暂时不处理|| subTypeString .contains("->")
                let temp:PropertyAndName = PropertyAndName.init(with: property.value)
                temp.name = instanceName as NSString
                if self.judgeIfClassType(with:property.value) {
                    strongClassTypeReferences.append(temp)
                    return OptionalAssociateType.classType
                }else {
                    otherRetainedReferences.append(temp)
                    return OptionalAssociateType.otherType
                }
            }
            return OptionalAssociateType.baseType
        }
        return OptionalAssociateType.otherType
    }
    
    
    /*
     处理Tuple类型
     key永远不需要考虑，肯定不是strong，——value不需要考虑，一定是strong
     todo @langminglang 需要缓存提高效率
     */
    class func getSwiftTupleTypeInstanceAllStrongReferance(of instance:Any, instanceName:String,  strongClassTypeReferences:inout Array<PropertyAndName>, otherRetainedReferences:inout Array<PropertyAndName>) {
        let tupleMirror = Mirror(reflecting: instance)
        for property in tupleMirror.children {
            let proValue:AnyObject = property.value as AnyObject;
            if isNull(proValue) {
               continue
            }
            let childMirror = Mirror(reflecting: property.value)
            let subTypeString = String(describing:childMirror.subjectType)
            if subTypeString.contains("Optional") { // 加一层更安全
                if case Optional<Any>.none = property.value {
                    continue
                }
            }
            
            if childMirror.displayStyle != nil {//暂时不处理闭包
                let temp:PropertyAndName = PropertyAndName.init(with: property.value)
                if property.label != nil {
                    temp.name = (instanceName + "->" + property.label!) as NSString
                } else {
                    temp.name = instanceName as NSString
                }
                
                if self.judgeIfClassType(with:property.value) {
                    strongClassTypeReferences.append(temp)
                }else {
                    otherRetainedReferences.append(temp)
                }
            }
        }
    }
    
    
    //enumMirror 的child永远只有一个,且是tuple类型，不需要在提高效率了
    class func getSwiftEnumTypeInstanceAllStrongReferance(of instance:Any, instanceName:String, strongClassTypeReferences:inout Array<PropertyAndName>, otherRetainedReferences:inout Array<PropertyAndName>) {
        let enumMirror = Mirror(reflecting: instance)
        for property in enumMirror.children {
            let childMirror = Mirror(reflecting: property.value)
            let subTypeString = String(describing:childMirror.subjectType)
            if subTypeString.contains("Optional") {
                if case Optional<Any>.none = property.value {
                    continue
                }
            }
            if childMirror.displayStyle != nil { //闭包暂时不处理|| subTypeString.contains("->")
                let temp:PropertyAndName = PropertyAndName.init(with: property.value)
                if property.label != nil {
                    temp.name = (instanceName + "->" + property.label!) as NSString
                } else {
                    temp.name = instanceName as NSString
                }
                
                if self.judgeIfClassType(with:property.value) {
                    strongClassTypeReferences.append(temp)
                }else {
                    otherRetainedReferences.append(temp)
                }
            }
        }
    }
    
    
    /*
     功能：获取一个swift class 的所有strong References，且如果是 struct等非class类型需要进一步获取其 strong referance
     说明：1.该方法入参一定是非 OC class type
          2.需要获取父类的 strong referance
          3.对于 class type 和非 class type 区分处理，class type strong referance 直接return，非 class type referance 需要继续拆分
          4.返回的 NSArray 里面的值一定是class 类型
          5. 实际上入参数和返回参数均是Class类型，但是由于与OC 的 id 类型对接，导致需要用 any 修饰
     */
    
    class func getAllStrongRetainedReferences(of swiftInstance:Any, with configuration:FBObjectGraphConfiguration)-> [Any] {
        var strongClassTypeReferences = [PropertyAndName]()
        var otherRetainedReferences = [PropertyAndName]()
    
        let temp = PropertyAndName.init(with: swiftInstance)
        otherRetainedReferences.append(temp)
        
        while(otherRetainedReferences.count > 0){
            let instance:Any = otherRetainedReferences[0].value
            let instanceName:String = otherRetainedReferences[0].name as String
            let instanceType = type(of:instance)
            
            let instanceMetaData:UnsafeMutablePointer<TargetMetadata> = unsafeBitCast(instanceType as Any.Type, to: UnsafeMutablePointer<TargetMetadata>.self)
            let kind:UInt = instanceMetaData.pointee.Kind
            
            if (kind > MetaDataKind.SWIFT_CLASS_2.rawValue || kind == MetaDataKind.SWIFT_CLASS_1.rawValue || kind == MetaDataKind.PURE_OC_CLASS.rawValue) { // instance is class
                assert(kind != MetaDataKind.PURE_OC_CLASS.rawValue, " pure OC objects should not appear here")
                
                var classList = [Any.Type]() //ypealias AnyClass = AnyObject.Type
                classList.append(instanceType)
                
                var mirrorsList = [Mirror]()
                
                //增加保护和log**********************************************************************
                let logTemp = NSStringFromClass(instanceType as! AnyClass)
                reportAlog("swift class name that will init mirror:" + logTemp);
                let currentMetaTemp:UnsafeMutablePointer<ClassMetadata> = unsafeBitCast(instanceType, to: UnsafeMutablePointer<ClassMetadata>.self)
                let address = Int(bitPattern: currentMetaTemp.pointee.Description)
                if address == 0x0 {
                    reportAlog("swift class Description is nil!!!!!:" + logTemp);
                    otherRetainedReferences.remove(at: 0)
                    continue
                }
                //增加保护和log**********************************************************************
    
                mirrorsList.append(Mirror(reflecting: instance))
                
                while(mirrorsList.count > 0 && classList.count > 0){
                    let currentMirror = mirrorsList[0]
                    let currentClass = classList[0]
                    
                    let currentMeta:UnsafeMutablePointer<ClassMetadata> = unsafeBitCast(currentClass, to: UnsafeMutablePointer<ClassMetadata>.self)
                    let currentKind:UInt = currentMeta.pointee.Kind;
                    
                    
                    if currentKind == MetaDataKind.PURE_OC_CLASS.rawValue { //oc
                        self.getOCClassTypeInstanceAllStrongReferance(of: instance as AnyObject, currentClass: currentClass as! AnyClass, strongClassTypeReferences: &strongClassTypeReferences, otherRetainedReferences: &otherRetainedReferences, configuration: configuration)
                        break // OC 继承 swift 可能有风险
                    } else {//swift
                        
                        reportAlog("swift class name that was detected by FB:" + NSStringFromClass(currentClass as! AnyClass));
                        
                        self.getSwiftClassTypeInstanceAllStrongReferance(of: currentMirror,  currentMeta: currentMeta, currentClass: currentClass as! AnyClass, strongClassTypeReferences: &strongClassTypeReferences, otherRetainedReferences: &otherRetainedReferences)
                    }
                    //取父类的属性
                    if currentMirror.superclassMirror != nil {
                        mirrorsList.append(currentMirror.superclassMirror!)
                    }
                    let supclass:Any.Type? = class_getSuperclass(currentClass as? AnyClass)
                    if supclass != nil {
                        classList.append(supclass!)
                    }
                    mirrorsList.removeFirst()
                    classList.removeFirst()
                }
            } else if(kind == MetaDataKind.SWIFT_OPTIONAL.rawValue){//可选类型
               self.getSwiftOptioanalTypeInstanceAllStrongReferance(of: instance,  instanceName: instanceName, strongClassTypeReferences: &strongClassTypeReferences, otherRetainedReferences: &otherRetainedReferences)
            } else if(kind == MetaDataKind.SWIFT_FUNCTION.rawValue) { //闭包
                //print("闭包暂时不处理")
            } else if(kind == MetaDataKind.SWIFT_STRUCT.rawValue) { //struct和容器类型，
                self.getSwiftStructTypeInstanceAllStrongReferance(of: instance, instanceName: instanceName, strongClassTypeReferences: &strongClassTypeReferences, otherRetainedReferences: &otherRetainedReferences)
            } else if(kind == MetaDataKind.SWIFT_TUPlE.rawValue) {//tuple类型处理
                self.getSwiftTupleTypeInstanceAllStrongReferance(of: instance, instanceName: instanceName, strongClassTypeReferences: &strongClassTypeReferences, otherRetainedReferences: &otherRetainedReferences)
            }else if(kind == MetaDataKind.SWIFT_ENUM.rawValue) {//enum类型,如果enum类型最终会转换成tuple，也肯定是strong
                self.getSwiftEnumTypeInstanceAllStrongReferance(of: instance, instanceName: instanceName, strongClassTypeReferences: &strongClassTypeReferences, otherRetainedReferences: &otherRetainedReferences)
            } else {
                //print("其他类型暂时不处理")
            }
            otherRetainedReferences.remove(at: 0)
        }
        return strongClassTypeReferences
    }
    
    
    class func getAllStrongRetainedReferences(of swiftInstance:Any) -> [Any] {
        return self.getAllStrongRetainedReferences(of: swiftInstance, with: FBObjectGraphConfiguration());
    }
    
}
