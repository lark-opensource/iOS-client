import React, { memo } from "react";
import { Checkbox } from "@arco-design/web-react";

const CheckBoxComponent = memo(({ label, value, setValue }) => {
  return (
    <Checkbox checked={value} onChange={(v) => setValue(v)}>
      {label}
    </Checkbox>
  );
});

export default CheckBoxComponent;
