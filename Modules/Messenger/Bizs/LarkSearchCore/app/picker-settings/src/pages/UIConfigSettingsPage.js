import React, { memo, useContext } from "react";
import NavBarComponent from "@/components/NavBarComponent";
import { ConfigContext } from "../Context";
import { Collapse, Checkbox } from "@arco-design/mobile-react";
import { useEffect, useState } from "react";

const UIConfigSettingsPage = memo(() => {
  const context = useContext(ConfigContext);
  const { state, dispatch } = context;
  const multiSelection = state.config.featureConfig.multiSelection;
  const targetPreview = state.config.featureConfig.targetPreview;
  console.log("-----multiSelection", state.config.featureConfig);
  const [check, setCheck] = useState(
    state.config.featureConfig.multiSelection.isOpen
  );

  useEffect(() => {
    console.log("check", state.config.featureConfig.multiSelection);
  }, [state]);

  const handleChange = (value, key) => {
    console.log("value", value);
    dispatch({
      event: "change_feature_config",
      payload: {
        key: key,
        value: value,
      },
    });
  };

  return (
    <>
      <NavBarComponent title="UI配置" hasBack={true} />
      <Collapse
        header="多选"
        value="1"
        defaultActive
        content={
          <div className="flex flex-row">
            <Checkbox
              style={{ display: "inline-flex" }}
              value={2}
              checked={multiSelection.isOpen}
              onChange={(value) => {
                handleChange(value, "multiSelection.isOpen");
              }}
            >
              多选
            </Checkbox>
          </div>
        }
      />
      <Collapse
        header="目标预览"
        value="2"
        defaultActive={true}
        content={
          <Checkbox
            style={{ display: "inline-flex" }}
            value={2}
            checked={targetPreview.isOpen}
            onChange={(value) => {
              handleChange(value, "targetPreview.isOpen");
            }}
          >
            是否有目标预览
          </Checkbox>
        }
      />
      <Collapse
        header="Disabled"
        value="3"
        content="here is content area, here is content area, here is content area, here is content area, here is content area, here is content area, here is content area, here is content area, here is content area, here is content area, here is the content area"
      />
    </>
  );
});

export default UIConfigSettingsPage;
