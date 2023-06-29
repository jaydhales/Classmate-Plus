// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "../Interfaces/INFT.sol";
import "../Interfaces/IFactory.sol";

contract organisation {
    /**
     * ============================================================ *
     * --------------------- ORGANIZATION RECORD------------------- *
     * ============================================================ *
     */
    string organization;
    string cohort;
    address organisationFactory;
    address NftContract;
    mapping(address => bool) requestNameCorrection;

    /**
     * ============================================================ *
     * --------------------- ATTENDANCE RECORD--------------------- *
     * ============================================================ *
     */
    uint[] LectureIdCollection;
    mapping(uint => lectureData) lectureInstance;
    mapping(uint => bool) lectureIdUsed;
    struct lectureData {
        address mentorOnDuty;
        string topic;
        string uri;
        uint attendanceStartTime;
        uint studentsPresent;
        bool status;
    }

    /**
     * ============================================================ *
     * --------------------- STUDENTS RECORD------------------- *
     * ============================================================ *
     */
    address[] students;
    mapping(address => individual) studentsData;
    mapping(address => uint) indexInStudentsArray;
    mapping(address => uint) studentsTotalAttendance;
    mapping(address => bool) isStudent;
    mapping(address => uint[]) classesAttended;
    mapping(address => mapping(uint => bool)) IndividualAttendanceRecord;

    /**
     * ============================================================ *
     * --------------------- STAFFS RECORD------------------------- *
     * ============================================================ *
     */
    address moderator;
    address mentorOnDuty;
    address[] mentors;
    mapping(address => uint) indexInMentorsArray;
    mapping(address => uint[]) moderatorsTopic;
    mapping(address => bool) isStaff;
    mapping(address => individual) mentorsData;

    // EVENTS
    event staffsRegistered(uint noOfStaffs);
    event nameChangeRequested(address changer);
    event StaffNamesChanged(uint noOfStaffs);
    event studentsRegistered(uint noOfStudents);
    event studentNamesChanged(uint noOfStudents);
    event attendanceCreated(
        uint indexed lectureId,
        string indexed uri,
        string topic,
        address indexed staff
    );
    event topicEditted(uint Id, string oldTopic, string newTopic);
    event AttendanceSigned(uint Id, address signer);
    event Handover(address oldMentor, address newMentor);
    event attendanceOpened(uint Id, address mentor);
    event attendanceClosed(uint Id, address mentor);
    event studentsEvicted(uint noOfStudents);

    // MODIFIERS
    modifier onlyModerator() {
        require(msg.sender == moderator, "NOT MODERATOR");
        _;
    }
    modifier onlyMentorOnDuty() {
        require(msg.sender == mentorOnDuty, "NOT MODERATOR ON DUTY");
        _;
    }
    modifier onlyStudents() {
        require(isStudent[msg.sender] == true, "NOT A VALID STUDENT");
        _;
    }

    modifier onlyStaff() {
        require(
            msg.sender == moderator || isStaff[msg.sender] == true,
            "NOT MODERATOR"
        );
        _;
    }

    // ERRORS
    error lecture_id_already_used();
    error not_Autorized_Caller();
    error Invalid_Lecture_Id();
    error Lecture_id_closed();
    error Attendance_compilation_started();
    error Already_Signed_Attendance_For_Id();
    error already_requested();
    error not_valid_student();
    error not_valid_Moderator();
    error not_valid_lecture_id();

    // @dev: constructor initialization
    // @params: _organization: Name of company,
    // @params: _cohort: Name of specific Cohort/ Program,
    constructor(
        string memory _organization,
        string memory _cohort,
        address _moderator
    ) {
        moderator = _moderator;
        organization = _organization;
        cohort = _cohort;
        organisationFactory = msg.sender;
        mentorOnDuty = _moderator;
        indexInMentorsArray[_moderator] = mentors.length;
        mentors.push(_moderator);
        isStaff[_moderator] = true;
    }

    function initialize(address _NftContract) external {
        if (msg.sender != organisationFactory) revert not_Autorized_Caller();
        NftContract = _NftContract;
    }

    // @dev: Function to register staffs to be called only by the moderator
    // @params: staffList: An array of structs(individuals) consisting of name and wallet address of staffs.
    function registerStaffs(
        individual[] calldata staffList
    ) external onlyModerator {
        uint staffLength = staffList.length;
        for (uint i; i < staffLength; i++) {
            if (isStaff[staffList[i]._address] == false) {
                mentorsData[staffList[i]._address] = staffList[i];
                isStaff[staffList[i]._address] = true;
                indexInMentorsArray[staffList[i]._address] = mentors.length;
                mentors.push(staffList[i]._address);
            }
        }
        // UCHE
        IFACTORY(organisationFactory).register(staffList);
        emit staffsRegistered(staffList.length);
    }

    function StaffRequestNameCorrection() external onlyStaff {
        if (requestNameCorrection[msg.sender] == true)
            revert already_requested();
        requestNameCorrection[msg.sender] == true;
        emit nameChangeRequested(msg.sender);
    }

    function StaffNameCorrection(
        individual[] memory _staffList
    ) external onlyModerator {
        uint staffLength = _staffList.length;
        for (uint i; i < staffLength; i++) {
            if (requestNameCorrection[_staffList[i]._address] == true) {
                mentorsData[_staffList[i]._address] = _staffList[i];
                requestNameCorrection[_staffList[i]._address] = false;
            }
        }
        emit StaffNamesChanged(_staffList.length);
    }

    // @dev: Function to register students to be called only by the moderator
    // @params: _studentList: An array of structs(individuals) consisting of name and wallet address of students.
    function registerStudents(
        individual[] calldata _studentList
    ) external onlyModerator {
        uint studentLength = _studentList.length;
        for (uint i; i < studentLength; i++) {
            studentsData[_studentList[i]._address] = _studentList[i];
            indexInStudentsArray[_studentList[i]._address] = students.length;
            students.push(_studentList[i]._address);
            isStudent[_studentList[i]._address] = true;
        }
        // UCHE
        IFACTORY(organisationFactory).register(_studentList);
        emit studentsRegistered(_studentList.length);
    }

    function StudentsRequestNameCorrection() external onlyStudents {
        if (requestNameCorrection[msg.sender] == true)
            revert already_requested();
        requestNameCorrection[msg.sender] == true;
        emit nameChangeRequested(msg.sender);
    }

    function editStudentName(
        individual[] memory _studentList
    ) external onlyModerator {
        uint studentLength = _studentList.length;
        for (uint i; i < studentLength; i++) {
            if (requestNameCorrection[_studentList[i]._address] == true) {
                studentsData[_studentList[i]._address] = _studentList[i];
                requestNameCorrection[_studentList[i]._address] = false;
            }
        }
        emit studentNamesChanged(_studentList.length);
    }

    // @dev: Function to Create Id for a particular Lecture Day, this Id is to serve as Nft Id. Only callable by mentor on duty.
    // @params:  _lectureId: Lecture Id of chaice, selected by mentor on duty.
    // @params:  _uri: Uri for the particular Nft issued to students that attended class for that day.
    // @params:  _topic: Topic covered for that particular day, its recorded so as to be displayed on students dashboard.
    function createAttendance(
        uint _lectureId,
        string calldata _uri,
        string calldata _topic
    ) external onlyMentorOnDuty {
        if (lectureIdUsed[_lectureId] == true) revert lecture_id_already_used();
        lectureIdUsed[_lectureId] = true;
        LectureIdCollection.push(_lectureId);
        lectureInstance[_lectureId].uri = _uri;
        lectureInstance[_lectureId].topic = _topic;
        lectureInstance[_lectureId].mentorOnDuty = msg.sender;
        moderatorsTopic[msg.sender].push(_lectureId);

        // NONSO GENESIS
        INFT(NftContract).setDayUri(_lectureId, _uri);
        emit attendanceCreated(_lectureId, _uri, _topic, msg.sender);
    }

    function editTopic(uint _lectureId, string calldata _topic) external {
        if (msg.sender != lectureInstance[_lectureId].mentorOnDuty)
            revert not_Autorized_Caller();
        if (lectureInstance[_lectureId].attendanceStartTime != 0)
            revert Attendance_compilation_started();
        string memory oldTopic = lectureInstance[_lectureId].topic;
        lectureInstance[_lectureId].topic = _topic;
        emit topicEditted(_lectureId, oldTopic, _topic);
    }

    function signAttendance(uint _lectureId) external onlyStudents {
        if (lectureIdUsed[_lectureId] == false) revert Invalid_Lecture_Id();
        if (lectureInstance[_lectureId].status == false)
            revert Lecture_id_closed();
        if (IndividualAttendanceRecord[msg.sender][_lectureId] == true)
            revert Already_Signed_Attendance_For_Id();
        if (lectureInstance[_lectureId].attendanceStartTime == 0) {
            lectureInstance[_lectureId].attendanceStartTime = block.timestamp;
        }
        IndividualAttendanceRecord[msg.sender][_lectureId] = true;
        studentsTotalAttendance[msg.sender] =
            studentsTotalAttendance[msg.sender] +
            1;
        lectureInstance[_lectureId].studentsPresent =
            lectureInstance[_lectureId].studentsPresent +
            1;
        classesAttended[msg.sender].push(_lectureId);

        // NONSO GENESIS
        INFT(NftContract).mint(msg.sender, _lectureId, 1);
        emit AttendanceSigned(_lectureId, msg.sender);
    }

    // @dev Function for mentors to hand over to the next mentor to take the class

    function mentorHandover(address newMentor) external {
        if (msg.sender != mentorOnDuty) revert not_Autorized_Caller();
        mentorOnDuty = newMentor;
        emit Handover(msg.sender, newMentor);
    }

    function openAttendance(uint _lectureId) external onlyMentorOnDuty {
        if (lectureIdUsed[_lectureId] == false) revert Invalid_Lecture_Id();
        if (lectureInstance[_lectureId].status == true)
            revert("Attendance already open");
        if (msg.sender != lectureInstance[_lectureId].mentorOnDuty)
            revert not_Autorized_Caller();

        lectureInstance[_lectureId].status = true;
        emit attendanceOpened(_lectureId, msg.sender);
    }

    function closeAttendance(uint _lectureId) external onlyMentorOnDuty {
        if (lectureIdUsed[_lectureId] == false) revert Invalid_Lecture_Id();
        if (lectureInstance[_lectureId].status == false)
            revert("Attendance already closed");
        if (msg.sender != lectureInstance[_lectureId].mentorOnDuty)
            revert not_Autorized_Caller();

        lectureInstance[_lectureId].status = false;
        emit attendanceClosed(_lectureId, msg.sender);
    }

    function EvictStudents(
        address[] calldata studentsToRevoke
    ) external onlyModerator {
        uint studentsToRevokeList = studentsToRevoke.length;
        for (uint i; i < studentsToRevokeList; i++) {
            delete studentsData[studentsToRevoke[i]];

            students[indexInStudentsArray[studentsToRevoke[i]]] = students[
                students.length - 1
            ];
            students.pop();
            isStudent[studentsToRevoke[i]] = false;
        }

        // UCHE
        IFACTORY(organisationFactory).revoke(studentsToRevoke);
        emit studentsEvicted(studentsToRevoke.length);
    }

    //VIEW FUNCTION
    function liststudents() external view returns (address[] memory) {
        return students;
    }

    function VerifyStudent(address _student) external view returns (bool) {
        return isStudent[_student];
    }

    function getStudentName(
        address _student
    ) external view returns (string memory name) {
        if (isStudent[_student] == false) revert not_valid_student();
        return studentsData[_student]._name;
    }

    function getStudentAttendanceRatio(
        address _student
    ) external view returns (uint attendace, uint TotalClasses) {
        if (isStudent[_student] == false) revert not_valid_student();
        attendace = studentsTotalAttendance[_student];
        TotalClasses = LectureIdCollection.length;
    }

    function listClassesAttended(
        address _student
    ) external view returns (uint[] memory) {
        if (isStudent[_student] == false) revert not_valid_student();
        return classesAttended[_student];
    }

    function getLectureIds() external view returns (uint[] memory) {
        return LectureIdCollection;
    }

    function getLectureData(
        uint _lectureId
    ) external view returns (lectureData memory) {
        if (lectureIdUsed[_lectureId] == false) revert not_valid_lecture_id();
        return lectureInstance[_lectureId];
    }

    function listMentors() external view returns (address[] memory) {
        return mentors;
    }

    function VerifyMentor(address _mentor) external view returns (bool) {
        return isStaff[_mentor];
    }

    function getMentorsName(
        address _Mentor
    ) external view returns (string memory name) {
        if (isStaff[_Mentor] == false) revert not_valid_Moderator();
        return mentorsData[_Mentor]._name;
    }

    function getClassesTaugth(
        address _Mentor
    ) external view returns (uint[] memory) {
        if (isStaff[_Mentor] == false) revert not_valid_Moderator();
        return moderatorsTopic[_Mentor];
    }

    function getMentorOnDuty() external view returns (address) {
        return mentorOnDuty;
    }

    function getModerator() external view returns (address) {
        return moderator;
    }

    function getOrganizationName() external view returns (string memory) {
        return organization;
    }

    function getCohortName() external view returns (string memory) {
        return cohort;
    }
}
