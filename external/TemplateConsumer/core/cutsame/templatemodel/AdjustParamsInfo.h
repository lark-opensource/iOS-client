//  该文件根据模型描述自动生成，请不要手动改写！！

#pragma once

#include <vector>
#include <string>
#include <memory>

namespace CutSame {
    class AdjustParamsInfo {
        public:
        AdjustParamsInfo();
        virtual ~AdjustParamsInfo();

        private:
        double default_value;
        std::string name;
        double value;

        public:
        const double & get_default_value() const;
        double & get_mut_default_value();
        void set_default_value(const double & value) ;

        const std::string & get_name() const;
        std::string & get_mut_name();
        void set_name(const std::string & value) ;

        const double & get_value() const;
        double & get_mut_value();
        void set_value(const double & value) ;
    };
}
