import React, { memo } from "react";
import { Link, Routes, Route, useNavigate } from "react-router-dom";
import { NavBar } from "@arco-design/mobile-react";
import { IconArrowBack } from "@arco-design/mobile-react/esm/icon";

const NavBarComponent = memo(
  ({ title, left = null, right, hasBack = false }) => {
    const navigate = useNavigate();

    const handleBack = () => {
      navigate(-1);
    };

    const BackButton = ({}) => {
      return (
        <div
          className="w-4 h-4 flex justify-center items-center pr-2"
          onClick={handleBack}
        >
          <IconArrowBack />
        </div>
      );
    };
    return (
      <NavBar
        title={title}
        leftContent={hasBack ? <BackButton /> : null}
        rightContent={right}
        style={{ color: "white", background: "#165dff" }}
        onClickRight={() => {}}
      />
    );
  }
);

export default NavBarComponent;
