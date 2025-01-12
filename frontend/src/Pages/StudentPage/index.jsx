import { useEffect, useState } from "react";
import { BsFillDropletFill } from "react-icons/bs";
import HeaderSection from "../../ui-components/HeaderSection";
import ActionButton from "../../ui-components/ActionButton";
import Section from "../../ui-components/Section";
import Modal from "../../ui-components/Modal";

import { toast } from "react-toastify";
import ChildABI from "../../../utils/childABI.json";

import {
  useContractWrite,
  usePrepareContractWrite,
  useWaitForTransaction,
  useAccount,
  useContractRead,
} from "wagmi";
import StudCard from "../../ui-components/StudCard";
import DataCard from "@/src/ui-components/DataCard";
import { JsonRpcProvider, ethers } from "ethers";
import Link from "next/link";

const StudentPage = () => {
  const [id, setId] = useState();
  const [programAddress, setProgramAddress] = useState();
  const [visible, setVisible] = useState(6);
  const [classIds, setClassIds] = useState();
  const [classesMarked, setClassesMarked] = useState([]);
  const [studentClass, setStudentClass] = useState();
  const [name, setName] = useState("");

  const { address } = useAccount();

  const [modal, setModal] = useState(false);

  const showAttendance = async () => {
    try {
      const provider = new JsonRpcProvider(process.env.NEXT_PUBLIC_ALCHEMY_KEY);
      const attendanceContract = new ethers.Contract(
        programAddress,
        ChildABI,
        provider
      );
      const attendedClasses = await attendanceContract.listClassesAttended(
        address
      );
      console.log("classes", attendedClasses);
      setClassesMarked(attendedClasses);
    } catch (error) {
      console.log(error);
    }
  };

  const { config: config1 } = usePrepareContractWrite({
    address: programAddress,
    abi: ChildABI,
    functionName: "signAttendance",
    args: [id],
  });

  const {
    data: signAttendanceData,
    isLoading: signAttendanceIsLoading,
    write: sign,
  } = useContractWrite(config1);

  const {
    data: signwaitData,
    isLoading: signwaitIsLoading,
    isError,
    isSuccess,
  } = useWaitForTransaction({
    hash: signAttendanceData?.hash,

    onSuccess: async () => {
      toast.success("ID Submitted Successfully");
      showAttendance();
    },

    onError(error) {
      toast.error("ID Submission Error: ", error);
    },
  });

  const { data: classIdsData } = useContractRead({
    address: programAddress,
    abi: ChildABI,
    functionName: "listClassesAttended",
    args: [address],
  });

  const { data: studentData } = useContractRead({
    address: programAddress,
    abi: ChildABI,
    watch: true,
    functionName: "getStudentAttendanceRatio",
    args: [address],
  });

  const { data: studentName } = useContractRead({
    address: programAddress,
    abi: ChildABI,
    watch: true,
    functionName: "getStudentName",
    args: [address],
  });

  const handleClose = () => {
    //alert('closing');
    setModal(false);
  };

  const handleCancel = () => {
    setModal(false);
  };

  const handleSubmit = () => {
    sign?.();
    //toast.success("Submitted");
    handleClose();
  };

  useEffect(() => {
    if (typeof window !== "undefined") {
      let res = localStorage.getItem("programAddress");
      setProgramAddress(res);
    }

    showAttendance();
    setName(studentName);
    setStudentClass(studentData);
    setClassIds(classIdsData);
  }, [classIdsData, studentData, studentName]);

  const showMoreItems = () => {
    setVisible((prevValue) => prevValue + 6);
  };

  //const reversedClasses = classesMarked?.reverse();

  return (
    <div className=" px-5">
      <HeaderSection
        heading={`Welcome ${name}`}
        subHeading={""}
        rightItem={() => (
          <div className=" flex items-center justify-between">
            <div>
              <ActionButton
                onClick={() => setModal(true)}
                Icon={BsFillDropletFill}
                label="Submit ID"
              />
            </div>

            <div className=" ml-6 md:ml-10">
              <Link href="/view-certificate">
                <button className=" bg-black text-white p-[2px] md:px-4 md:py-2 rounded-lg ">
                  View Certificate
                </button>
              </Link>
            </div>
          </div>
        )}
      />
      <div className=" flex items-center justify-start ml-12">
        <Section>
          <div>
            <DataCard
              label={"Total Classes"}
              value={studentData ? studentData[1].toString() : `00`}
              inverse={true}
            />
          </div>

          <div className=" md:ml-12">
            <DataCard
              label={"Your Attended Classes"}
              value={studentData ? studentData[0].toString() : `00`}
            />
          </div>

          <div className=" md:ml-12">
            <DataCard
              label={"Class Percentage"}
              value={
                studentData
                  ? (
                      (Number(studentData?.[0]) / Number(studentData?.[1])) *
                      100
                    ).toFixed(2) + "%"
                  : "00%"
              }
            />
          </div>
        </Section>
      </div>

      <Section>
        <div className=" grid grid-cols-1 sm:grid-cols-1 md:grid-cols-3 gap-8 ml-12">
          {classesMarked &&
            classesMarked.slice(0, visible).map((class_attended, i) => {
              return (
                <div key={i}>
                  <StudCard classId={class_attended} />
                </div>
              );
            })}
        </div>
      </Section>

      {classIds?.length > 6 && (
        <div className=" flex flex-row items-center justify-center pt-4 mt-4	">
          <button
            className=" bg-[#080E26] text-white rounded-full p-4 text-dimWhite w-36 font-semibold"
            onClick={showMoreItems}
          >
            Load More
          </button>
        </div>
      )}

      <Modal
        isOpen={modal}
        onClose={handleClose}
        heading={"Classmate+ Student Form"}
        positiveText={"Submit"}
        type={"submit"}
        onCancel={handleCancel}
        onSubmit={handleSubmit}
      >
        <div>
          <form onSubmit={handleSubmit}>
            <label>
              Enter ID:
              <br />
              <input
                className="py-2 px-2 border border-blue-950 rounded-lg w-full mb-2"
                type="number"
                placeholder="Enter today's ID"
                onChange={(e) => setId(e.target.value)}
              />
            </label>
          </form>
        </div>
      </Modal>
    </div>
  );
};

export default StudentPage;
