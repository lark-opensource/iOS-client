import React, { memo } from "react";
import { Select, Divider } from "@arco-design/web-react";
const Option = Select.Option;
const SelectComponent = memo(({ item }) => {
  const { options, label, callback, value } = item;
  return (
    <div>
      <div className="font-bold pb-0.5">{label}</div>
      <Select
        placeholder={label}
        onChange={(value) => callback(value)}
        value={value}
      >
        {options.map((option, index) => (
          <Option key={option.label} value={option.value}>
            {option.label}
          </Option>
        ))}
      </Select>
    </div>
  );
});

export default SelectComponent;
