import React, { memo, useState, useContext, useEffect } from "react";
import { IconDelete } from "@arco-design/mobile-react/esm/icon";
import { ConfigContext } from "@/Context";
import CheckBoxComponent from "@/components/forms/CheckBoxComponent";

const ContactSettings = memo(({ config }) => {
  const context = useContext(ConfigContext);
  const { state, dispatch } = context;
  const [entries, setEntries] = useState([]);
  let entities = state?.config?.contactConfig?.entries ?? [];

  const ownedGroup = entities.ownedGroup?.length > 0;
  const external = entities.external?.length > 0;
  const organization = entities.organization?.length > 0;
  const relatedOrganization = entities.relatedOrganization?.length > 0;
  const emailContact = entities.emailContact?.length > 0;
  const userGroup = entities.userGroup?.length > 0;

  const options = [
    { label: "我管理的群组", type: "ownedGroup", value: ownedGroup },
    { label: "外部联系人", type: "external", value: external },
    { label: "组织架构", type: "organization", value: organization },
    {
      label: "相关组织架构",
      type: "relatedOrganization",
      value: relatedOrganization,
    },
    { label: "邮件联系人", type: "emailContact", value: emailContact },
    { label: "用户组", type: "userGroup", value: userGroup },
  ];

  useEffect(() => {
    console.log("ContactSettings", entities);
  }, []);

  const handleCheckBoxChange = (e, value) => {
    console.log("handleCheckBoxChange", e, value);
    dispatch({
      event: "switchContactEntry",
      payload: {
        type: value,
      },
    });
  };

  const OrganizationComponent = ({ config }) => {
    return (
      <div className="cell flex flex-row justify-between px-2 h-4 items-center">
        <div className="text-[16px]">组织架构</div>
        <IconDelete className="text-[18px]" />
      </div>
    );
  };

  return (
    <div className="contact_settings p-2 flex flex-col space-y-1">
      {options.map((option, i) => {
        return (
          <div key={i} className="">
            <CheckBoxComponent
              label={option.label}
              value={option.value}
              setValue={(v) => handleCheckBoxChange(v, option.type)}
            />
          </div>
        );
      })}
    </div>
  );
});

export default ContactSettings;
