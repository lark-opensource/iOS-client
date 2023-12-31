import React, { memo } from "react";
import { Picker } from "@arco-design/mobile-react";

const EntityPicker = memo(({ visible, onSure, onHide }) => {
  const [singleValue] = React.useState(["chatter"]);
  const single = [
    { label: "人员", value: "chatter" },
    { label: "群组", value: "chat" },
    { label: "文档", value: "doc" },
    { label: "Wiki", value: "wiki" },
    { label: "知识空间", value: "wikiSpace" },
    { label: "用户组", value: "userGroup" },
    { label: "动态用户组", value: "dynamicUserGroup" },
  ];

  const handleAddEntity = (type) => {
    onSure(type);
  };

  const handleHide = () => {
    onHide();
  };
  return (
    <Picker
      visible={visible}
      cascade={false}
      data={single}
      maskClosable={true}
      onHide={handleHide}
      onChange={(value) => {
        console.log("onChange", value);
        handleAddEntity(value[0]);
      }}
      value={singleValue}
    />
  );
});

export default EntityPicker;
