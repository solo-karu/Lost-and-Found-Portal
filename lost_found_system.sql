-- ==========================================================
-- LOST & FOUND SYSTEM - FULL SQL (ALL FILES COMBINED)
-- ==========================================================

DROP DATABASE IF EXISTS LostAndFoundDB;
CREATE DATABASE LostAndFoundDB;
USE LostAndFoundDB;

-- ==========================================================
-- CATEGORY TABLE
-- ==========================================================
CREATE TABLE Category (
    CategoryID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL
);

-- ==========================================================
-- LOCATION TABLE
-- ==========================================================
CREATE TABLE Location (
    LocationID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL
);

-- ==========================================================
-- USER TABLE
-- ==========================================================
CREATE TABLE User (
    UserID INT PRIMARY KEY AUTO_INCREMENT,
    Name VARCHAR(100) NOT NULL,
    Email VARCHAR(100) NOT NULL UNIQUE,
    Phone VARCHAR(15),
    Role VARCHAR(50) DEFAULT 'User',
    Password VARCHAR(255) NOT NULL
);

-- ==========================================================
-- LOST ITEM TABLE
-- ==========================================================
CREATE TABLE LostItem (
    LostItemID INT PRIMARY KEY AUTO_INCREMENT,
    UserID INT NOT NULL,
    DateLost DATE DEFAULT CURDATE(),
    Description TEXT NOT NULL,
    LocationID INT NOT NULL,
    CategoryID INT NOT NULL,
    Status VARCHAR(50) DEFAULT 'Pending',
    FOREIGN KEY (UserID) REFERENCES User(UserID),
    FOREIGN KEY (LocationID) REFERENCES Location(LocationID),
    FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID)
);

-- ==========================================================
-- FOUND ITEM TABLE
-- ==========================================================
CREATE TABLE FoundItem (
    FoundItemID INT PRIMARY KEY AUTO_INCREMENT,
    FoundBy INT NOT NULL,
    DateFound DATE DEFAULT CURDATE(),
    Description TEXT NOT NULL,
    LocationID INT NOT NULL,
    CategoryID INT NOT NULL,
    Status VARCHAR(50) DEFAULT 'Pending',
    FOREIGN KEY (FoundBy) REFERENCES User(UserID),
    FOREIGN KEY (LocationID) REFERENCES Location(LocationID),
    FOREIGN KEY (CategoryID) REFERENCES Category(CategoryID)
);

-- ==========================================================
-- CLAIM TABLE
-- ==========================================================
CREATE TABLE Claim (
    ClaimID INT PRIMARY KEY AUTO_INCREMENT,
    LostItemID INT NOT NULL,
    FoundItemID INT NOT NULL,
    ClaimedBy INT NOT NULL,
    ClaimDate DATE DEFAULT CURDATE(),
    Status VARCHAR(50) DEFAULT 'Under Review',
    FOREIGN KEY (LostItemID) REFERENCES LostItem(LostItemID),
    FOREIGN KEY (FoundItemID) REFERENCES FoundItem(FoundItemID),
    FOREIGN KEY (ClaimedBy) REFERENCES User(UserID)
);

-- ==========================================================
-- SYSTEM LOG TABLE
-- ==========================================================
CREATE TABLE SystemLog (
    LogID INT PRIMARY KEY AUTO_INCREMENT,
    Action VARCHAR(255) NOT NULL,
    CreatedAt DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- ==========================================================
-- FUNCTIONS
-- ==========================================================
DELIMITER //
CREATE FUNCTION GenerateLostItemID()
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE newID INT;
  SELECT IFNULL(MAX(LostItemID),0)+1 INTO newID FROM LostItem;
  RETURN newID;
END;
//

CREATE FUNCTION CountLostItemsByUser(uid INT)
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE total INT;
  SELECT COUNT(*) INTO total FROM LostItem WHERE UserID=uid;
  RETURN total;
END;
//

CREATE FUNCTION GetCategoryName(cid INT)
RETURNS VARCHAR(100) DETERMINISTIC
BEGIN
  DECLARE cname VARCHAR(100);
  SELECT Name INTO cname FROM Category WHERE CategoryID=cid;
  RETURN cname;
END;
//

CREATE FUNCTION IsItemClaimed(itemId INT)
RETURNS VARCHAR(10) DETERMINISTIC
BEGIN
  DECLARE statusOut VARCHAR(10);
  IF EXISTS(SELECT 1 FROM Claim WHERE LostItemID=itemId) THEN
    SET statusOut='Yes';
  ELSE
    SET statusOut='No';
  END IF;
  RETURN statusOut;
END;
//

CREATE FUNCTION FindPotentialMatches(c INT,l INT)
RETURNS INT DETERMINISTIC
BEGIN
  DECLARE n INT;
  SELECT COUNT(*) INTO n FROM FoundItem WHERE CategoryID=c AND LocationID=l;
  RETURN n;
END;
//
DELIMITER ;

-- ==========================================================
-- TRIGGERS
-- ==========================================================
DELIMITER //
CREATE TRIGGER SetLostItemStatusBeforeInsert
BEFORE INSERT ON LostItem
FOR EACH ROW
BEGIN
  IF NEW.Status IS NULL THEN SET NEW.Status='Pending'; END IF;
END;
//

CREATE TRIGGER SetFoundItemStatusBeforeInsert
BEFORE INSERT ON FoundItem
FOR EACH ROW
BEGIN
  IF NEW.Status IS NULL THEN SET NEW.Status='Pending'; END IF;
END;
//

CREATE TRIGGER UpdateLostStatusAfterClaim
AFTER INSERT ON Claim
FOR EACH ROW
BEGIN
  UPDATE LostItem SET Status='Claimed' WHERE LostItemID=NEW.LostItemID;
END;
//

CREATE TRIGGER UpdateFoundStatusAfterClaim
AFTER INSERT ON Claim
FOR EACH ROW
BEGIN
  UPDATE FoundItem SET Status='Claimed' WHERE FoundItemID=NEW.FoundItemID;
END;
//

CREATE TRIGGER LogNewFoundItem
AFTER INSERT ON FoundItem
FOR EACH ROW
BEGIN
  INSERT INTO SystemLog(Action)
  VALUES(CONCAT('New Found Item Added - ID ',NEW.FoundItemID));
END;
//
DELIMITER ;

-- ==========================================================
-- STORED PROCEDURES
-- ==========================================================
DELIMITER //
CREATE PROCEDURE AddNewUser(
  IN uname VARCHAR(100),
  IN uemail VARCHAR(100),
  IN uphone VARCHAR(15),
  IN urole VARCHAR(50),
  IN upass VARCHAR(255)
)
BEGIN
  INSERT INTO User(Name,Email,Phone,Role,Password)
  VALUES(uname,uemail,uphone,urole,upass);
END;
//

CREATE PROCEDURE AddLostItem(
  IN uid INT,
  IN descp TEXT,
  IN loc INT,
  IN cat INT
)
BEGIN
  INSERT INTO LostItem(UserID,DateLost,Description,LocationID,CategoryID,Status)
  VALUES(uid,CURDATE(),descp,loc,cat,'Pending');
END;
//

CREATE PROCEDURE AddFoundItem(
  IN fby INT,
  IN descp TEXT,
  IN loc INT,
  IN cat INT
)
BEGIN
  INSERT INTO FoundItem(FoundBy,DateFound,Description,LocationID,CategoryID,Status)
  VALUES(fby,CURDATE(),descp,loc,cat,'Pending');
END;
//

CREATE PROCEDURE CreateClaim(
  IN lid INT,
  IN fid INT,
  IN uid INT
)
BEGIN
  INSERT INTO Claim(LostItemID,FoundItemID,ClaimedBy,ClaimDate,Status)
  VALUES(lid,fid,uid,CURDATE(),'Under Review');
END;
//
DELIMITER ;

-- ==========================================================
-- DML SAMPLE DATA
-- ==========================================================
INSERT INTO Category(Name) VALUES ('Wallet'), ('Mobile'), ('Watch');
INSERT INTO Location(Name) VALUES ('Library'), ('Cafeteria'), ('Auditorium');

INSERT INTO User(Name,Email,Phone,Role,Password)
VALUES ('John Doe','john@example.com','9876543210','User','pass123');

INSERT INTO LostItem(UserID,Description,LocationID,CategoryID)
VALUES (1,'Black leather wallet',1,1);

INSERT INTO FoundItem(FoundBy,Description,LocationID,CategoryID)
VALUES (1,'Found black wallet',1,1);

CALL CreateClaim(1,1,1);

-- ==========================================================
-- SQL QUERIES USED
-- ==========================================================
SELECT * FROM User;
SELECT * FROM LostItem;
SELECT * FROM FoundItem;
SELECT * FROM Claim;
SELECT * FROM SystemLog;

SELECT l.LostItemID,l.Description,u.Name FROM LostItem l JOIN User u ON l.UserID=u.UserID;
SELECT COUNT(*) AS TotalLost FROM LostItem;
SELECT LostItemID FROM LostItem WHERE LostItemID NOT IN (SELECT LostItemID FROM Claim);
