//
// Created by Xuanyi Huang on 6/8/21.
//
#ifndef NLEPLATFORM_SWIGDOCEXAMPLE_H
#define NLEPLATFORM_SWIGDOCEXAMPLE_H

#include <cstdint>

/**
 * This is an example class for demonstrating code comments handling capabilities of SWIG.
 * 这是一个示例类，用于演示 SWIG 的代码注释处理功能。
 */
class SwigDocExample {
public:
    /**
     * Default constructor of SwigDocExample.
     * SwigDocExample 的默认构造函数。
     */
    SwigDocExample() = default;

    /**
     * Default destructor of SwigDocExample.
     * A Java class has no destructor, so this comment will not exist in SwigDocExample.java.
     * SwigDocExample 的默认析构函数。
     * Java 类没有析构函数，因此 SwigDocExample.java 中将不存在此注释。
     */
    virtual ~SwigDocExample() = default;

    /**
     * @beginCppOnly
     * This is for cpp.
     * @endCppOnly
     * This is funA.
     * 这是 funA。
     * @return always true. 永远是true。
     */
    bool funA();

    /**
     * comment over varA.
     * varA的注释。
     */
    int varA;

    bool varB; ///<comment over varB. varB的注释。

    int64_t varC; /**<comment over varC. varC的注释。*/

    char varD; /*!<comment over varD. varD的注释。*/

    virtual double funB(void) = 0; /**< @return the value of B. */

    virtual double funC() = 0; /*!< \return the value of C. */

    /**
     * This is funD.
     * @param param1 means the first passed-in parameter.
     * @return the result.
     */
    virtual bool funD(int param1) = 0;

    /**
     * This is funE.
     * @param param1 means the first passed-in parameter.
     * @return the result.
     * @see SwigDocExample2::getMoney()
     */
    virtual float funE(bool param1) = 0;

    /**
     * This is FunF.
     * \link SwigDocExample\endlink is the second example class.
     * \link SwigDocExample2#funA(int, float)\endlink is a method in \link SwigDocExample2\endlink.
     * @param param1 means the first passed-in parameter.
     * @return the result
     * @see SwigDocExample2::funA(int, float)
     */
    virtual float funF(int64_t param1) = 0;

};

namespace swig::doc::test {
    /**
     * This is SwigDocExample2
     */
    class SwigDocExample2 {
    public:
        int money; /**<comment over money.*/

        /**
         * @param param1 means the first passed-in parameter.
         * @param param2 means the second passed-in parameter.
         * @return the calculating result.
         */
        virtual bool funA(int param1, float param2) = 0;

        /**
         * This is funB.
         * @param param1 means the first passed-in parameter.
         * @return the result.
         */
        virtual int64_t funB(bool param1) = 0;

        /**
         * This is funC.
         * @return the result.
         */
        virtual double funC() = 0;
    };
}

#endif //NLEPLATFORM_SWIGDOCEXAMPLE_H