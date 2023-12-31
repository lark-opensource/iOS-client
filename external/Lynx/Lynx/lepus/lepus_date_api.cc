
#include "lepus/lepus_date_api.h"

#include <map>

#include "lepus/exception.h"
#include "lepus/lepus_date.h"
namespace lynx {
namespace lepus {

int CDate::global_language = 1;  // default english

const std::map<std::string, int>& DateGlobalization() {
  static const std::map<std::string, int> date_globalization = {{"zh-cn", 0},
                                                                {"en", 1}};
  return date_globalization;
}

const std::vector<std::string>& DateContent() {
  static const std::vector<std::string> date_content = {"zh-cn", "en"};
  return date_content;
}

static Value ParseStringToDate(Context* context) {
  auto params_count = context->GetParamsSize();
  DCHECK(params_count == 1 || params_count == 2);
  Value* parsed = context->GetParam(0);
  DCHECK(parsed->IsNumber() || parsed->IsString());
  if (parsed->IsNumber()) {
    DCHECK(params_count == 1);
    int64_t parseNumber;
    if (parsed->IsInt64()) {
      parseNumber = parsed->Int64();
    } else if (parsed->IsInt32()) {
      parseNumber = parsed->Int32();
    } else {
      parseNumber = parsed->Number();
    }
    return Value(CDate::ParseNumberToDate(parseNumber));
  } else if (parsed->IsString()) {
    std::string date;
    std::string format;
    if (params_count == 1) {  // ISO8601 format "YYYY-MM-DDTHH-mm-ss.SSS+0800"
      date = context->GetParam(0)->String()->str();
    } else {
      date = context->GetParam(0)->String()->str();
      format = context->GetParam(1)->String()->str();
    }
    return Value(
        CDate::ParseStringToDate(static_cast<int>(params_count), date, format));
  } else {
    return Value();
  }
}

static std::string dateToString(Value* date, const std::string& format) {
  return CDate::dateToString(date, format);
}

static Value LepusNow(Context* context) { return CDate::LepusNow(); }

static Value LepusLocal(Context* context) {
  auto params_count = context->GetParamsSize();
  DCHECK(params_count == 1 || params_count == 0);
  if (params_count == 0) {
    return Value(StringImpl::Create(DateContent()[CDate::global_language]));
  }
  std::string setLanguage = context->GetParam(0)->String()->str();
  auto it = DateGlobalization().find(setLanguage);
  if (it != DateGlobalization().end()) {
    CDate::global_language = it->second;
  }
  return Value();
}

static Value Locale(Context* context) {
  auto params_count = context->GetParamsSize();
  DCHECK(params_count == 1 || params_count == 2);
  auto date = context->GetParam(params_count - 1)->Date();
  if (params_count == 1) {
    return Value(StringImpl::Create(DateContent()[date->get_language()]));
  }
  std::string setLanguage = context->GetParam(0)->String()->str();
  auto it = DateGlobalization().find(setLanguage);
  if (it != DateGlobalization().end()) {
    return Value(CDate::Create(date->get_date_(), date->get_ms_(), it->second));
  } else {
    return Value();
  }
}

static Value Unix(Context* context) {
  auto params_count_ = context->GetParamsSize();
  DCHECK(params_count_ == 1);
  auto date = context->GetParam(0)->Date();
  time_t time1 = date->get_time_t_();
  int64_t time1_v = static_cast<int64_t>(time1);
  int64_t ret = static_cast<int64_t>(time1_v * 1000 + date->get_ms_());
  if (ret == -1) return Value();
  return Value((int64_t(ret)));
}

static Value Format(Context* context) {
  auto params_count = context->GetParamsSize();
  if (params_count == 1) {
    char buf[64];
    const tm_extend t = context->GetParam(0)->Date()->get_date_();
    strftime(buf, 64, "%Y-%m-%dT%H:%M:%S", &t);
    return Value(StringImpl::Create(buf));
  }
  if (params_count != 2) {
    return Value();
  }
  Value* date = nullptr;
  std::string format;
  if (context->GetParam(0)->IsCDate()) {
    date = context->GetParam(0);
    format = context->GetParam(1)->String()->str();
  } else if (context->GetParam(0)->IsString()) {
    date = context->GetParam(1);
    format = context->GetParam(0)->String()->str();
  } else {
    return Value();
  }
  std::string ret = dateToString(date, format);
  return Value(StringImpl::Create(ret));
}

static Value Year(Context* context) {
  auto params_count_ = context->GetParamsSize();
  DCHECK(params_count_ == 1 || params_count_ == 2);
  auto date = context->GetParam(params_count_ - 1)->Date();
  int year = date->get_date_().tm_year + 1900;
  return Value(static_cast<uint32_t>(year));
}

static Value Month(Context* context) {
  auto params_count_ = context->GetParamsSize();
  DCHECK(params_count_ == 1 || params_count_ == 2);
  auto date = context->GetParam(params_count_ - 1)->Date();
  int month = date->get_date_().tm_mon;
  return Value(static_cast<uint32_t>(month));
}

static Value Date(Context* context) {
  auto params_count_ = context->GetParamsSize();
  DCHECK(params_count_ == 1 || params_count_ == 2);
  auto date = context->GetParam(params_count_ - 1)->Date();
  int dat = date->get_date_().tm_mday;
  return Value(static_cast<uint32_t>(dat));
}

static Value Day(Context* context) {
  auto params_count_ = context->GetParamsSize();
  DCHECK(params_count_ == 1 || params_count_ == 2);
  auto date = context->GetParam(params_count_ - 1)->Date();
  int day = date->get_date_().tm_wday;
  return Value(static_cast<uint32_t>(day));
}

static Value Hour(Context* context) {
  auto params_count_ = context->GetParamsSize();
  DCHECK(params_count_ == 1 || params_count_ == 2);
  auto date = context->GetParam(params_count_ - 1)->Date();
  int Hour = date->get_date_().tm_hour;
  return Value(static_cast<uint32_t>(Hour));
}

static Value Minute(Context* context) {
  auto params_count_ = context->GetParamsSize();
  DCHECK(params_count_ == 1 || params_count_ == 2);
  auto date = context->GetParam(params_count_ - 1)->Date();
  int Min = date->get_date_().tm_min;
  return Value(static_cast<uint32_t>(Min));
}

static Value Sec(Context* context) {
  auto params_count_ = context->GetParamsSize();
  DCHECK(params_count_ == 1 || params_count_ == 2);
  auto date = context->GetParam(params_count_ - 1)->Date();
  int second = date->get_date_().tm_sec;
  return Value(static_cast<uint32_t>(second));
}

static Value GetTimeZoneOffset(Context* ctx) {
  // return UTC - local / min
  return CDate::GetTimeZoneOffset();
}

void RegisterLepusDateAPI(Context* ctx) {
  lynx::base::scoped_refptr<Dictionary> table = Dictionary::Create();
  RegisterTableFunction(ctx, table, "now", &LepusNow);
  RegisterTableFunction(ctx, table, "parse", &ParseStringToDate);
  RegisterTableFunction(ctx, table, "locale", &LepusLocal);
  RegisterTableFunction(ctx, table, "format", &Format);
  RegisterTableFunction(ctx, table, "getTimezoneOffset", &GetTimeZoneOffset);
  RegisterBuiltinFunctionTable(ctx, "LepusDate", table);
}

void RegisterLepusDatePrototypeAPI(Context* ctx) {
  lynx::base::scoped_refptr<Dictionary> table = Dictionary::Create();
  RegisterTableFunction(ctx, table, "format", &Format);
  RegisterTableFunction(ctx, table, "unix", &Unix);
  RegisterTableFunction(ctx, table, "year", &Year);
  RegisterTableFunction(ctx, table, "month", &Month);
  RegisterTableFunction(ctx, table, "date", &Date);
  RegisterTableFunction(ctx, table, "day", &Day);
  RegisterTableFunction(ctx, table, "hour", &Hour);
  RegisterTableFunction(ctx, table, "minute", &Minute);
  RegisterTableFunction(ctx, table, "second", &Sec);
  RegisterTableFunction(ctx, table, "locale", &Locale);
  RegisterTableFunction(ctx, table, "format", &Format);
  RegisterTableFunction(ctx, table, "getTimezoneOffset", &GetTimeZoneOffset);
  reinterpret_cast<VMContext*>(ctx)->SetDatePrototype(Value(table));
}
}  // namespace lepus
}  // namespace lynx
