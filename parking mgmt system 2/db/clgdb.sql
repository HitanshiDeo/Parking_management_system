/*CREATE database ParkingSystem;*/
USE ParkingSystem;
CREATE TABLE Student (
    S_USN VARCHAR(10) PRIMARY KEY,
    S_Name VARCHAR(50),
    Phone_Number VARCHAR(15)
);
CREATE TABLE Vehicle (
    V_Number VARCHAR(15) PRIMARY KEY,
    V_Type VARCHAR(20),
    Date_and_Time DATETIME,
    S_USN VARCHAR(10),
    FOREIGN KEY (S_USN) REFERENCES Student(S_USN)
);
CREATE TABLE Slot (
    Slot_ID INT PRIMARY KEY,
    Slot_Type VARCHAR(20),
    Location VARCHAR(50),
    Availability ENUM('Available', 'Occupied', 'Reserved'),
    Date_and_Time DATETIME
);
CREATE TABLE Status (
    Slot_ID INT,
    Checkin_Time DATETIME,
    Checkout_Time DATETIME,
    PRIMARY KEY (Slot_ID, Checkin_Time, Checkout_Time),
    FOREIGN KEY (Slot_ID) REFERENCES Slot(Slot_ID)
);
CREATE TABLE Reserves (
    S_USN VARCHAR(10),
    Slot_ID INT,
    PRIMARY KEY (S_USN, Slot_ID),
    FOREIGN KEY (S_USN) REFERENCES Student(S_USN),
    FOREIGN KEY (Slot_ID) REFERENCES Slot(Slot_ID)
);
CREATE TABLE Parks (
    S_USN VARCHAR(10),
    V_Number VARCHAR(15),
    PRIMARY KEY (S_USN, V_Number),
    FOREIGN KEY (S_USN) REFERENCES Student(S_USN),
    FOREIGN KEY (V_Number) REFERENCES Vehicle(V_Number)
);

CREATE TABLE Updates (
    S_USN VARCHAR(10),
    Slot_ID INT,
    Checkin_Time DATETIME,
    Checkout_Time DATETIME,
    PRIMARY KEY (S_USN, Slot_ID, Checkin_Time, Checkout_Time),
    FOREIGN KEY (S_USN) REFERENCES Student(S_USN),
    FOREIGN KEY (Slot_ID) REFERENCES Slot(Slot_ID),
    FOREIGN KEY (Slot_ID, Checkin_Time, Checkout_Time) REFERENCES Status(Slot_ID, Checkin_Time, Checkout_Time)
);

CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    vehicle_type ENUM('2-wheeler', '4-wheeler') NOT NULL,
    password VARCHAR(255) NOT NULL
);
CREATE TABLE parking_slots (
    id INT AUTO_INCREMENT PRIMARY KEY,
    slot_number VARCHAR(10) NOT NULL UNIQUE,
    status ENUM('available', 'reserved', 'occupied') DEFAULT 'available'
);

CREATE TABLE reservations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    Slot_ID INT NOT NULL,
    timestamp DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (Slot_ID) REFERENCES Slot(Slot_ID) ON DELETE CASCADE
);

INSERT INTO users (name, email, vehicle_type, password)
VALUES
('John Doe', 'john.doe@example.com', '4-wheeler', 'hashed_password1'),
('Jane Smith', 'jane.smith@example.com', '2-wheeler', 'hashed_password2'),
('Alice Green', 'alice.green@example.com', '4-wheeler', 'hashed_password3');

INSERT INTO parking_slots (slot_number, status)
VALUES
('A1', 'available'),
('A2', 'available'),
('B1', 'reserved'),
('B2', 'occupied'),
('C1', 'available');

INSERT INTO Slot (Slot_ID, Slot_Type, Location, Availability, Date_and_Time)
VALUES 
(3, '4-wheeler', 'C1', 'Available', NOW()),
(4, '4-wheeler', 'C2', 'Available', NOW());

INSERT INTO reservations (user_id, Slot_ID, timestamp)
VALUES
(1, 3, '2025-01-15 09:00:00'),
(2, 4, '2025-01-15 10:00:00');



SHOW TABLES;

INSERT INTO Student (S_USN, S_Name, Phone_Number) 
VALUES 
('S001', 'James Na', '9876543210'),
('S002', 'Smith SA', '8765432109'),
('S003', 'Alice Ja', '7654321098'),
('S005', 'Emma Brown', '5432109876'),
('S006', 'Alice Green', '4321098765');


INSERT INTO Vehicle (V_Number, V_Type, Date_and_Time, S_USN) 
VALUES 
('KA01AB1234', 'Car', '2025-01-02 08:30:00', 'S001'),
('KA02CD5678', 'Bike', '2025-01-02 09:00:00', 'S002'),
('KA03EF9012', 'Scooter', '2025-01-02 09:30:00', 'S003');



/*SELECT V.V_Number, V.V_Type, V.Date_and_Time
FROM Vehicle V
JOIN Student S ON V.S_USN = S.S_USN
WHERE S.S_USN = 'S006';

SELECT Slot_ID, Slot_Type, Location
FROM Slot
WHERE Availability = 'Available';

SELECT S.Slot_ID, S.Checkin_Time, S.Checkout_Time
FROM Status S
JOIN Slot SL ON S.Slot_ID = SL.Slot_ID
WHERE SL.Availability = 'Occupied';

SELECT R.S_USN, S.S_Name, R.Slot_ID
FROM Reserves R
JOIN Student S ON R.S_USN = S.S_USN;

SELECT St.S_USN, St.S_Name, V.V_Number, V.V_Type
FROM Parks P
JOIN Student St ON P.S_USN = St.S_USN
JOIN Vehicle V ON P.V_Number = V.V_Number
JOIN Reserves R ON P.S_USN = R.S_USN AND P.V_Number = R.V_Number
WHERE EXISTS (
    SELECT 1
    FROM Slot SL
    WHERE SL.Slot_ID = R.Slot_ID AND SL.Slot_ID = 001
);


SELECT * FROM Student;
SELECT * FROM Vehicle;
SELECT * FROM Slot;
SELECT * FROM users;
SELECT * FROM reservations;
SELECT * FROM parking_slots;
SELECT * FROM users WHERE id=4;

SELECT * FROM Slot WHERE id = 5;*/
DROP TABLE IF EXISTS reservations;

CREATE TABLE reservations (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT NOT NULL,
    Slot_ID INT NOT NULL,
    timestamp DATETIME NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (Slot_ID) REFERENCES Slot(Slot_ID) ON DELETE CASCADE
);
SELECT * FROM reservations;




/*INSERT INTO slot (Slot_ID) VALUES (4), (5);*/



INSERT INTO reservations (user_id, Slot_ID, timestamp)
VALUES
(1, 4, '2025-01-15 09:00:00'),
(2, 5, '2025-01-15 10:00:00');

ALTER TABLE reservations
ADD COLUMN Checkin_Time DATETIME NULL;

ALTER TABLE reservations
ADD COLUMN Checkout_Time DATETIME NULL;

DELIMITER //

CREATE EVENT cancel_expired_reservations
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
    -- Identify reservations that have not been checked in within 15 minutes
    DELETE FROM reservations
    WHERE TIMESTAMPDIFF(MINUTE, timestamp, NOW()) > 2
      AND Checkin_Time IS NULL;

    -- Update the slot status to 'available' for cancelled reservations
    UPDATE Slot
    SET status = 'available'
    WHERE id IN (
        SELECT Slot_ID
        FROM reservations
        WHERE TIMESTAMPDIFF(MINUTE, timestamp, NOW()) > 2
          AND Checkin_Time IS NULL
    );
END //

DELIMITER ;

/*UPDATE reservations
SET Checkin_Time = NOW()
WHERE user_id = 'user_id'
  AND Slot_ID = 'Slot_ID';*/

/*SET @uid = 1;  -- Replace with actual user_id
SET @slot = 4; -- Replace with actual Slot_ID*/

UPDATE reservations 
SET Checkin_Time = NOW() 
WHERE user_id = @uid 
AND Slot_ID = @slot;




CREATE TABLE Location (
    Location_ID INT PRIMARY KEY,
    Location_Name VARCHAR(50),
    Slot_Type ENUM('2-wheeler', '4-wheeler', 'Faculty')
);

SHOW COLUMNS FROM Slot;

ALTER TABLE Slot ADD COLUMN Location_ID INT;

INSERT INTO Location (Location_ID, Location_Name) 
VALUES 
(1, 'ISE'),
(2, 'Ground'),
(3, 'Cauvery'),
(4, 'Opposite ECE');
select * from Location;
-- Location 1: ISE (60 slots for 2-wheelers)

DELETE FROM Slot WHERE Slot_ID IN (3);
DELETE FROM Slot WHERE Slot_ID IN (4);


INSERT INTO Slot (Slot_ID, Slot_Type, Location_ID, Availability, Date_and_Time)
VALUES 
(1, '2-wheeler', 1, 'Available', NOW()),
(2, '2-wheeler', 1, 'Available', NOW()),
(3, '2-wheeler', 1, 'Available', NOW()),
(4, '2-wheeler', 1, 'Available', NOW()),
(5, '2-wheeler', 1, 'Available', NOW()),
(6, '2-wheeler', 1, 'Available', NOW()),
(7, '2-wheeler', 1, 'Available', NOW()),
(8, '2-wheeler', 1, 'Available', NOW()),
(9, '2-wheeler', 1, 'Available', NOW()),
(10, '2-wheeler', 1, 'Available', NOW()),
(11, '2-wheeler', 1, 'Available', NOW()),
(12, '2-wheeler', 1, 'Available', NOW()),
(13, '2-wheeler', 1, 'Available', NOW()),
(14, '2-wheeler', 1, 'Available', NOW()),
(15, '2-wheeler', 1, 'Available', NOW()),
(16, '2-wheeler', 1, 'Available', NOW()),
(17, '2-wheeler', 1, 'Available', NOW()),
(18, '2-wheeler', 1, 'Available', NOW()),
(19, '2-wheeler', 1, 'Available', NOW()),
(20, '2-wheeler', 1, 'Available', NOW()),
(21, '2-wheeler', 1, 'Available', NOW()),
(22, '2-wheeler', 1, 'Available', NOW()),
(23, '2-wheeler', 1, 'Available', NOW()),
(24, '2-wheeler', 1, 'Available', NOW()),
(25, '2-wheeler', 1, 'Available', NOW()),
(26, '2-wheeler', 1, 'Available', NOW()),
(27, '2-wheeler', 1, 'Available', NOW()),
(28, '2-wheeler', 1, 'Available', NOW()),
(29, '2-wheeler', 1, 'Available', NOW()),
(30, '2-wheeler', 1, 'Available', NOW()),
(31, '2-wheeler', 1, 'Available', NOW()),
(32, '2-wheeler', 1, 'Available', NOW()),
(33, '2-wheeler', 1, 'Available', NOW()),
(34, '2-wheeler', 1, 'Available', NOW()),
(35, '2-wheeler', 1, 'Available', NOW()),
(36, '2-wheeler', 1, 'Available', NOW()),
(37, '2-wheeler', 1, 'Available', NOW()),
(38, '2-wheeler', 1, 'Available', NOW()),
(39, '2-wheeler', 1, 'Available', NOW()),
(40, '2-wheeler', 1, 'Available', NOW()),
(41, '2-wheeler', 1, 'Available', NOW()),
(42, '2-wheeler', 1, 'Available', NOW()),
(43, '2-wheeler', 1, 'Available', NOW()),
(44, '2-wheeler', 1, 'Available', NOW()),
(45, '2-wheeler', 1, 'Available', NOW()),
(46, '2-wheeler', 1, 'Available', NOW()),
(47, '2-wheeler', 1, 'Available', NOW()),
(48, '2-wheeler', 1, 'Available', NOW()),
(49, '2-wheeler', 1, 'Available', NOW()),
(50, '2-wheeler', 1, 'Available', NOW()),
(51, '2-wheeler', 1, 'Available', NOW()),
(52, '2-wheeler', 1, 'Available', NOW()),
(53, '2-wheeler', 1, 'Available', NOW()),
(54, '2-wheeler', 1, 'Available', NOW()),
(55, '2-wheeler', 1, 'Available', NOW()),
(56, '2-wheeler', 1, 'Available', NOW()),
(57, '2-wheeler', 1, 'Available', NOW()),
(58, '2-wheeler', 1, 'Available', NOW()),
(59, '2-wheeler', 1, 'Available', NOW()),
(60, '2-wheeler', 1, 'Available', NOW());
select * from Slot;
-- Location 2: Ground (60 slots for 2-wheelers, 20 for 4-wheelers)
INSERT INTO Slot (Slot_ID, Slot_Type, Location_ID, Availability, Date_and_Time)
VALUES 
(61, '2-wheeler', 2, 'Available', NOW()),
(62, '2-wheeler', 2, 'Available', NOW()),
(63, '2-wheeler', 2, 'Available', NOW()),
(64, '2-wheeler', 2, 'Available', NOW()),
(65, '2-wheeler', 2, 'Available', NOW()),
(66, '2-wheeler', 2, 'Available', NOW()),
(67, '2-wheeler', 2, 'Available', NOW()),
(68, '2-wheeler', 2, 'Available', NOW()),
(69, '2-wheeler', 2, 'Available', NOW()),
(70, '2-wheeler', 2, 'Available', NOW()),
(71, '2-wheeler', 2, 'Available', NOW()),
(72, '2-wheeler', 2, 'Available', NOW()),
(73, '2-wheeler', 2, 'Available', NOW()),
(74, '2-wheeler', 2, 'Available', NOW()),
(75, '2-wheeler', 2, 'Available', NOW()),
(76, '2-wheeler', 2, 'Available', NOW()),
(77, '2-wheeler', 2, 'Available', NOW()),
(78, '2-wheeler', 2, 'Available', NOW()),
(79, '2-wheeler', 2, 'Available', NOW()),
(80, '2-wheeler', 2, 'Available', NOW()),
(81, '2-wheeler', 2, 'Available', NOW()),
(82, '2-wheeler', 2, 'Available', NOW()),
(83, '2-wheeler', 2, 'Available', NOW()),
(84, '2-wheeler', 2, 'Available', NOW()),
(85, '2-wheeler', 2, 'Available', NOW()),
(86, '2-wheeler', 2, 'Available', NOW()),
(87, '2-wheeler', 2, 'Available', NOW()),
(88, '2-wheeler', 2, 'Available', NOW()),
(89, '2-wheeler', 2, 'Available', NOW()),
(90, '2-wheeler', 2, 'Available', NOW()),
(91, '2-wheeler', 2, 'Available', NOW()),
(92, '2-wheeler', 2, 'Available', NOW()),
(93, '2-wheeler', 2, 'Available', NOW()),
(94, '2-wheeler', 2, 'Available', NOW()),
(95, '2-wheeler', 2, 'Available', NOW()),
(96, '2-wheeler', 2, 'Available', NOW()),
(97, '2-wheeler', 2, 'Available', NOW()),
(98, '2-wheeler', 2, 'Available', NOW()),
(99, '2-wheeler', 2, 'Available', NOW()),
(100, '2-wheeler', 2, 'Available', NOW()),
(101, '2-wheeler', 2, 'Available', NOW()),
(102, '2-wheeler', 2, 'Available', NOW()),
(103, '2-wheeler', 2, 'Available', NOW()),
(104, '2-wheeler', 2, 'Available', NOW()),
(105, '2-wheeler', 2, 'Available', NOW()),
(106, '2-wheeler', 2, 'Available', NOW()),
(107, '2-wheeler', 2, 'Available', NOW()),
(108, '2-wheeler', 2, 'Available', NOW()),
(109, '2-wheeler', 2, 'Available', NOW()),
(110, '2-wheeler', 2, 'Available', NOW()),
(111, '2-wheeler', 2, 'Available', NOW()),
(112, '2-wheeler', 2, 'Available', NOW()),
(113, '2-wheeler', 2, 'Available', NOW()),
(114, '2-wheeler', 2, 'Available', NOW()),
(115, '2-wheeler', 2, 'Available', NOW()),
(116, '2-wheeler', 2, 'Available', NOW()),
(117, '2-wheeler', 2, 'Available', NOW()),
(118, '2-wheeler', 2, 'Available', NOW()),
(119, '2-wheeler', 2, 'Available', NOW()),
(120, '2-wheeler', 2, 'Available', NOW()),
(121, '4-wheeler', 2, 'Available', NOW()),
(122, '4-wheeler', 2, 'Available', NOW()),
-- 4-wheeler slots

(123, '4-wheeler', 2, 'Available', NOW()),
(124, '4-wheeler', 2, 'Available', NOW()),
(125, '4-wheeler', 2, 'Available', NOW()),
(126, '4-wheeler', 2, 'Available', NOW()),
(127, '4-wheeler', 2, 'Available', NOW()),
(128, '4-wheeler', 2, 'Available', NOW()),
(129, '4-wheeler', 2, 'Available', NOW()),
(130, '4-wheeler', 2, 'Available', NOW()),
(131, '4-wheeler', 2, 'Available', NOW()),
(132, '4-wheeler', 2, 'Available', NOW()),
(133, '4-wheeler', 2, 'Available', NOW()),
(134, '4-wheeler', 2, 'Available', NOW()),
(135, '4-wheeler', 2, 'Available', NOW()),
(136, '4-wheeler', 2, 'Available', NOW()),
(137, '4-wheeler', 2, 'Available', NOW()),
(138, '4-wheeler', 2, 'Available', NOW()),
(139, '4-wheeler', 2, 'Available', NOW()),
(140, '4-wheeler', 2, 'Available', NOW());

-- Location 3: Cauvery (50 faculty slots)
INSERT INTO Slot (Slot_ID, Slot_Type, Location_ID, Availability, Date_and_Time)
VALUES 
(141, 'Faculty', 3, 'Available', NOW()),
(142, 'Faculty', 3, 'Available', NOW()),
(143, 'Faculty', 3, 'Available', NOW()),
(144, 'Faculty', 3, 'Available', NOW()),
(145, 'Faculty', 3, 'Available', NOW()),
(146, 'Faculty', 3, 'Available', NOW()),
(147, 'Faculty', 3, 'Available', NOW()),
(148, 'Faculty', 3, 'Available', NOW()),
(149, 'Faculty', 3, 'Available', NOW()),
(150, 'Faculty', 3, 'Available', NOW()),
(151, 'Faculty', 3, 'Available', NOW()),
(152, 'Faculty', 3, 'Available', NOW()),
(153, 'Faculty', 3, 'Available', NOW()),
(154, 'Faculty', 3, 'Available', NOW()),
(155, 'Faculty', 3, 'Available', NOW()),
(156, 'Faculty', 3, 'Available', NOW()),
(157, 'Faculty', 3, 'Available', NOW()),
(158, 'Faculty', 3, 'Available', NOW()),
(159, 'Faculty', 3, 'Available', NOW()),
(160, 'Faculty', 3, 'Available', NOW()),
(161, 'Faculty', 3, 'Available', NOW()),
(162, 'Faculty', 3, 'Available', NOW()),
(163, 'Faculty', 3, 'Available', NOW()),
(164, 'Faculty', 3, 'Available', NOW()),
(165, 'Faculty', 3, 'Available', NOW()),
(166, 'Faculty', 3, 'Available', NOW()),
(167, 'Faculty', 3, 'Available', NOW()),
(168, 'Faculty', 3, 'Available', NOW()),
(169, 'Faculty', 3, 'Available', NOW()),
(170, 'Faculty', 3, 'Available', NOW()),
(171, 'Faculty', 3, 'Available', NOW()),
(172, 'Faculty', 3, 'Available', NOW()),
(173, 'Faculty', 3, 'Available', NOW()),
(174, 'Faculty', 3, 'Available', NOW()),
(175, 'Faculty', 3, 'Available', NOW()),
(176, 'Faculty', 3, 'Available', NOW()),
(177, 'Faculty', 3, 'Available', NOW()),
(178, 'Faculty', 3, 'Available', NOW()),
(179, 'Faculty', 3, 'Available', NOW()),
(180, 'Faculty', 3, 'Available', NOW()),
(181, 'Faculty', 3, 'Available', NOW()),
(182, 'Faculty', 3, 'Available', NOW()),
(183, 'Faculty', 3, 'Available', NOW()),
(184, 'Faculty', 3, 'Available', NOW()),
(185, 'Faculty', 3, 'Available', NOW()),
(186, 'Faculty', 3, 'Available', NOW()),
(187, 'Faculty', 3, 'Available', NOW()),
(188, 'Faculty', 3, 'Available', NOW()),
(189, 'Faculty', 3, 'Available', NOW()),
(190, 'Faculty', 3, 'Available', NOW());

-- Location 4: Opposite ECE (40 slots for 2-wheelers)
INSERT INTO Slot (Slot_ID, Slot_Type, Location_ID, Availability, Date_and_Time)
VALUES 
(191, '2-wheeler', 4, 'Available', NOW()),
(192, '2-wheeler', 4, 'Available', NOW()),
(193, '2-wheeler', 4, 'Available', NOW()),
(194, '2-wheeler', 4, 'Available', NOW()),
(195, '2-wheeler', 4, 'Available', NOW()),
(196, '2-wheeler', 4, 'Available', NOW()),
(197, '2-wheeler', 4, 'Available', NOW()),
(198, '2-wheeler', 4, 'Available', NOW()),
(199, '2-wheeler', 4, 'Available', NOW()),
(200, '2-wheeler', 4, 'Available', NOW()),
(201, '2-wheeler', 4, 'Available', NOW()),
(202, '2-wheeler', 4, 'Available', NOW()),
(203, '2-wheeler', 4, 'Available', NOW()),
(204, '2-wheeler', 4, 'Available', NOW()),
(205, '2-wheeler', 4, 'Available', NOW()),
(206, '2-wheeler', 4, 'Available', NOW()),
(207, '2-wheeler', 4, 'Available', NOW()),
(208, '2-wheeler', 4, 'Available', NOW()),
(209, '2-wheeler', 4, 'Available', NOW()),
(210, '2-wheeler', 4, 'Available', NOW()),
(211, '2-wheeler', 4, 'Available', NOW()),
(212, '2-wheeler', 4, 'Available', NOW()),
(213, '2-wheeler', 4, 'Available', NOW()),
(214, '2-wheeler', 4, 'Available', NOW()),
(215, '2-wheeler', 4, 'Available', NOW()),
(216, '2-wheeler', 4, 'Available', NOW()),
(217, '2-wheeler', 4, 'Available', NOW()),
(218, '2-wheeler', 4, 'Available', NOW()),
(219, '2-wheeler', 4, 'Available', NOW()),
(220, '2-wheeler', 4, 'Available', NOW()),
(221, '2-wheeler', 4, 'Available', NOW()),
(222, '2-wheeler', 4, 'Available', NOW()),
(223, '2-wheeler', 4, 'Available', NOW()),
(224, '2-wheeler', 4, 'Available', NOW()),
(225, '2-wheeler', 4, 'Available', NOW()),
(226, '2-wheeler', 4, 'Available', NOW()),
(227, '2-wheeler', 4, 'Available', NOW()),
(228, '2-wheeler', 4, 'Available', NOW()),
(229, '2-wheeler', 4, 'Available', NOW()),
(230, '2-wheeler', 4, 'Available', NOW());

ALTER TABLE Slot 
ADD CONSTRAINT fk_location
FOREIGN KEY (Location_ID) REFERENCES Location(Location_ID);
SELECT * FROM Slot;
SELECT * FROM Location;

SET SQL_SAFE_UPDATES = 0;

UPDATE Slot
SET Location = 'Math Dept'
WHERE Location_ID = 1;

UPDATE Slot
SET Location = 'Ground'
WHERE Location_ID = 2;

UPDATE Slot
SET Location = 'Cauvery Basement'
WHERE Location_ID = 3;

UPDATE Slot
SET Location= 'Opposite ECE'
WHERE Location_ID = 4;
DESCRIBE Location;
ALTER TABLE Location MODIFY Slot_Type VARCHAR(100);
UPDATE Location SET Slot_Type = '2-wheeler' WHERE Location_ID = 1;
UPDATE Location SET Slot_Type = '2, 4-wheeler' WHERE Location_ID = 2;
UPDATE Location SET Slot_Type = 'Faculty' WHERE Location_ID = 3;
UPDATE Location SET Slot_Type = '2-wheeler' WHERE Location_ID = 4;

select * from reservations;
select * from users;

ALTER TABLE users ADD usn VARCHAR(20) NOT NULL AFTER name;
ALTER TABLE users ADD phone_number VARCHAR(15) NOT NULL AFTER email;
DESCRIBE users;
describe reservations;

ALTER TABLE users DROP COLUMN phonenumber;

-- Add a column to indicate reservation status for 15 minutes
ALTER TABLE Slot
ADD COLUMN Reserved_For_15_Min ENUM('Yes', 'No') DEFAULT 'No';
SET SQL_SAFE_UPDATES = 0;

-- Update existing rows to set default value for Reserved_For_15_Min
UPDATE Slot
SET Reserved_For_15_Min = 'No';

-- Example query to mark a slot as reserved for 15 minutes
-- Assume Slot_ID = 1 is being reserved
UPDATE Slot
SET Reserved_For_15_Min = 'Yes'
WHERE Slot_ID = 1;

-- Example query to reset reservation after 15 minutes
UPDATE Slot
SET Reserved_For_15_Min = 'No'
WHERE Slot_ID = 1 AND TIMESTAMPDIFF(MINUTE, Date_and_Time, NOW()) > 15;

-- To automatically reset this column every minute, use an EVENT
DELIMITER //
CREATE EVENT reset_reserved_slots
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
    UPDATE Slot
    SET Reserved_For_15_Min = 'No'
    WHERE Reserved_For_15_Min = 'Yes'
      AND TIMESTAMPDIFF(MINUTE, Date_and_Time, NOW()) > 15;
END //
DELIMITER ;

select * from Slot;
select * from users;
select * from reservations;
DROP EVENT IF EXISTS reset_reserved_slots;
DELIMITER //
CREATE EVENT reset_reserved_slots
ON SCHEDULE EVERY 1 MINUTE
DO
BEGIN
    UPDATE Slot
    SET Reserved_For_15_Min = 'No', 
        Availability = 'Available'
    WHERE Reserved_For_15_Min = 'Yes'
      AND Availability = 'Reserved'
      AND TIMESTAMPDIFF(MINUTE, Date_and_Time, NOW()) > 15;
END //
DELIMITER ;


SET AUTOCOMMIT=1;


