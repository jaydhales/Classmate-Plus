import { useState } from "react";
import { useContractRead } from "wagmi";
import { addressState } from "../../../atoms/addressAtom";
import { useRecoilValue } from "recoil";
import ChildABI from "../../../utils/childABI.json";

const BarYaxis = (klass) => {
  const [classData, setClassData] = useState("");

  const programAddress = useRecoilValue(addressState);

  useContractRead({
    address: programAddress,
    abi: ChildABI,
    functionName: "getLectureData",
    watch: true,
    args: [klass],
    onSuccess(data) {
      setClassData(data);
    },
  });

  console.log("classData", classData);

  return <div>{classData}</div>;
};

export default BarYaxis;