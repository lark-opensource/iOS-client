//
//  StructMetadataExtension.swift
//  StructMetadata
//
//  Created by HarryPhone on 2021/1/21.
//

import Foundation

// 进程内的本机运行时目标。对于运行时中的交互，这应该等同于使用普通的老式指针类型。
// 个人理解下来就是一个指针大小的空间，在OC的Class中就是isa指针，在swift原生类型中放的是MetaKind。相当于在swift中的所有Type，首个指针大小的空间中，存放了区分Type的数据
struct InProcessStuct {
    var PointerSize: UInt
}

struct StructMetadata {
    var Kind: InProcessStuct   // MetadataKind，结构体的枚举值是0x200
    var Description: UnsafeMutablePointer<TargetStructDescriptor>// 结构体的描述，包含了结构体的所有信息，是一个指针

    //获得每个属性的在结构体中内存的起始位置
    mutating func getFieldOffset(index: Int) -> Int {
        if Description.pointee.NumFields == 0 {
            return 0
        }
        let fieldOffsetVectorOffset = self.Description.pointee.FieldOffsetVectorOffset
        return withUnsafeMutablePointer(to: &self) {
            //获得自己本身的起始位置
            let selfPtr = UnsafeMutableRawPointer($0).assumingMemoryBound(to: InProcessStuct.self)
            //以指针的步长偏移FieldOffsetVectorOffset
            let fieldOffsetVectorOffsetPtr = selfPtr.advanced(by: numericCast(fieldOffsetVectorOffset))
            //属性的起始偏移量已32位整形存储的，转一下指针
            let tramsformPtr = UnsafeMutableRawPointer(fieldOffsetVectorOffsetPtr).assumingMemoryBound(to: UInt32.self)
            return numericCast(tramsformPtr.advanced(by: index).pointee)
        }
    }
//    const uint32_t *getFieldOffsets() const {
//      auto offset = getDescription()->FieldOffsetVectorOffset;
//      if (offset == 0)
//        return nullptr;
//      auto asWords = reinterpret_cast<const void * const*>(this);
//      return reinterpret_cast<const uint32_t *>(asWords + offset);//uint32_t说明上面应该是32
//    }
}


struct TargetStructDescriptor {
    // 存储在任何上下文描述符的第一个公共标记
    var Flags: ContextDescriptorFlags

    // 复用的RelativeDirectPointer这个类型，其实并不是，但看下来原理一样
    // 父级上下文，如果是顶级上下文则为null。获得的类型为InProcess，里面存放的应该是一个指针，测下来结构体里为0，相当于null了
    var Parent: RelativeDirectPointer<InProcessStuct>

    // 获取Struct的名称
    var Name: RelativeDirectPointer<CChar>

    // 这里的函数类型是一个替身，需要调用getAccessFunction()拿到真正的函数指针（这里没有封装），会得到一个MetadataAccessFunction元数据访问函数的指针的包装器类，该函数提供operator()重载以使用正确的调用约定来调用它（可变长参数），意外发现命名重整会调用这边的方法（目前不太了解这块内容）。
    var AccessFunctionPtr: RelativeDirectPointer<UnsafeRawPointer>

    // 一个指向类型的字段描述符的指针(如果有的话)。类型字段的描述，可以从里面获取结构体的属性。
    var Fields: RelativeDirectPointer<FieldDescriptor>
    
    // 下面 struct 自己的
    // 结构体属性个数
    var NumFields: Int32
    // 存储这个结构的字段偏移向量的偏移量（记录你属性起始位置的开始的一个相对于metadata的偏移量，具体看metadata的getFieldOffsets方法），如果为0，说明你没有属性
    var FieldOffsetVectorOffset: Int32

}






