//
// Created by zhangyeqi on 2019-11-18.
//

#ifndef CUTSAMEAPP_COMOBJ_H
#define CUTSAMEAPP_COMOBJ_H

#include <map>
#include <string>


namespace cut {
    using namespace std;
    class ComPrivateData;

    class ComObj {
    public:
        virtual ~ComObj();
        void addPrivateData(const string &dataKey, void* dataPointer);
        void addPrivateData(const string &dataKey, void* dataPointer, std::function<void (void*)>& cleaner);

        void* getPrivateData(const string &dataKey);

    private:
        map<string, ComPrivateData*> privateDatas;
    };
}



#endif //CUTSAMEAPP_COMOBJ_H
