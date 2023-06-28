import { IoGridOutline, IoHomeOutline } from "react-icons/io5";
import { BsSpeedometer2, BsCloudUploadFill } from "react-icons/bs";
import { BiUserCircle } from "react-icons/bi";
import { AiOutlineBarChart } from "react-icons/ai";
import { PiStudentFill, PiChalkboardTeacher } from "react-icons/pi";
import { SiGoogleclassroom } from "react-icons/si";

export default [
  {
    to: "/",
    name: "Home",
    Icon: IoHomeOutline,
  },
  {
    to: "/dashboard",
    name: "Dashboard",
    Icon: BsSpeedometer2,
  },
  {
    to: "/students",
    name: "Students",
    Icon: PiStudentFill,
  },
  {
    to: "/mentors",
    name: "Mentors",
    Icon: PiChalkboardTeacher,
  },
  {
    to: "/attendance",
    name: "Attendance",
    Icon: SiGoogleclassroom,
  },
  {
    to: "/upload-students",
    name: "Upload Students",
    Icon: BsCloudUploadFill,
  },
  {
    to: "/profile",
    name: "Profile",
    Icon: BiUserCircle,
  },
  {
    to: "/statistics",
    name: "Statistics",
    Icon: AiOutlineBarChart,
  },
];