CREATE TABLE equipment(
  id INT NOT NULL AUTO_INCREMENT,
  equipment_type_id INT NOT NULL,
  lab_id INT,
  equipment_status_id INT NOT NULL,
  retirement_cause_id INT,
  inventory_tag VARCHAR(120) NOT NULL UNIQUE,
  serial_number VARCHAR(120) UNIQUE,
  purchase_date DATE,
  cost DECIMAL(12,2),
  decomissioned BOOLEAN NOT NULL DEFAULT FALSE,
  retirement_date DATETIME,
  PRIMARY KEY(id)
);


CREATE TABLE equipment_movements(
  id INT NOT NULL AUTO_INCREMENT,
  equipment_id INT NOT NULL,
  lab_origin_id INT,
  loan_origin_id INT,
  lab_destination_id INT,
  loan_destination_id INT,
  movement_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  note VARCHAR(255),
  PRIMARY KEY(id)
);


CREATE TABLE equipment_status(
id INT NOT NULL AUTO_INCREMENT, `name` VARCHAR(50) NOT NULL UNIQUE,
  PRIMARY KEY(id)
);


CREATE TABLE equipment_type(
  id INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(120) NOT NULL UNIQUE,
  requires_calibration BOOLEAN NOT NULL DEFAULT FALSE,
  PRIMARY KEY(id)
);


CREATE TABLE incident(
  id INT NOT NULL AUTO_INCREMENT,
  equipment_id INT,
  lab_id INT,
  user_reporter_id INT NOT NULL,
  user_assigned_id INT,
  loan_id INT NOT NULL,
  incident_type_id INT NOT NULL,
  severity_id INT NOT NULL,
  `description` TEXT NOT NULL,
  reported_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  incident_status ENUM('open','in_progress','closed') NOT NULL DEFAULT 'open',
  closed_at DATETIME,
  resolution TEXT,
  PRIMARY KEY(id)
);


CREATE TABLE incident_type(
  id INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(120) NOT NULL,
  `description` VARCHAR(255),
  PRIMARY KEY(id)
);


CREATE TABLE lab(
  id INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(120) NOT NULL,
  building VARCHAR(120),
  `floor` INT,
  capacity INT,
  `description` VARCHAR(255),
  `active` BOOLEAN NOT NULL DEFAULT TRUE,
  PRIMARY KEY(id)
);


CREATE TABLE lab_reservation(
  id INT NOT NULL AUTO_INCREMENT,
  lab_id INT NOT NULL,
  user_id INT NOT NULL,
  reservation_reason_id INT NOT NULL,
  start_time DATETIME NOT NULL,
  end_time DATETIME NOT NULL,
  reservation_status ENUM('pending','approved','rejected','canceled') NOT NULL,
  `comment` VARCHAR(255),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(id)
);


CREATE TABLE loan(
  id INT NOT NULL AUTO_INCREMENT,
  equipment_id INT NOT NULL,
  user_requester__id INT NOT NULL,
  user_issuer__id INT NOT NULL,
  user_receiver_id INT,
  loan_date DATETIME NOT NULL,
  due_date DATETIME NOT NULL,
  return_date DATETIME,
  loan_status ENUM('active','returned','overdue','canceled') NOT NULL
    DEFAULT 'active',
  remarks VARCHAR(255),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(id)
);


CREATE TABLE maintenance(
  id INT NOT NULL AUTO_INCREMENT,
  equipment_id INT NOT NULL,
  maintenance_type ENUM('preventive','corrective') NOT NULL,
  `description` TEXT,
  start_date DATETIME NOT NULL,
  end_date DATETIME,
  cost DECIMAL(12,2),
  performed_by VARCHAR(150),
  PRIMARY KEY(id)
);


CREATE TABLE permission(
id INT NOT NULL AUTO_INCREMENT, `name` VARCHAR(50) NOT NULL UNIQUE,
  PRIMARY KEY(id)
);


CREATE TABLE reservation_conflict(
  id INT NOT NULL AUTO_INCREMENT,
  lab_reservation_a_id INT NOT NULL,
  lab_reservation_b_id INT NOT NULL,
  detected_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY(id)
);


CREATE TABLE reservation_reason(
id INT NOT NULL AUTO_INCREMENT, `name` VARCHAR(120) NOT NULL UNIQUE,
  PRIMARY KEY(id)
);


CREATE TABLE retirement_cause(
  id INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(120) NOT NULL UNIQUE,
  `description` VARCHAR(250),
  PRIMARY KEY(id)
);


CREATE TABLE `role`(
id INT NOT NULL AUTO_INCREMENT, `name` VARCHAR(50) NOT NULL UNIQUE,
  PRIMARY KEY(id)
);


CREATE TABLE role_permission(
role_id INT NOT NULL, permission_id INT NOT NULL,
  PRIMARY KEY(role_id, permission_id)
);


CREATE TABLE severity(
  id INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL,
  sla_hours INT NOT NULL,
  PRIMARY KEY(id)
);


CREATE TABLE `user`(
  id INT NOT NULL AUTO_INCREMENT,
  `name` VARCHAR(50) NOT NULL,
  first_lastname VARCHAR(50) NOT NULL,
  second_lastname VARCHAR(50),
  `active` BOOLEAN NOT NULL DEFAULT TRUE,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `password` VARCHAR(120) NOT NULL,
  PRIMARY KEY(id)
);


CREATE TABLE user_mail(
  id INT NOT NULL AUTO_INCREMENT,
  user_id INT NOT NULL,
  mail VARCHAR(50) NOT NULL UNIQUE,
  PRIMARY KEY(id)
);


CREATE TABLE user_phone(
  id INT NOT NULL AUTO_INCREMENT,
  user_id INT NOT NULL,
  phone INT UNIQUE,
  PRIMARY KEY(id)
);


CREATE TABLE user_role
  (user_id INT NOT NULL, role_id INT NOT NULL, PRIMARY KEY(user_id, role_id))
;


ALTER TABLE equipment_movements
  ADD CONSTRAINT equipment_equipment_movements
    FOREIGN KEY (equipment_id) REFERENCES equipment (id) ON DELETE Cascade
      ON UPDATE Cascade
;


ALTER TABLE incident
  ADD CONSTRAINT equipment_incidents
    FOREIGN KEY (equipment_id) REFERENCES equipment (id) ON DELETE Cascade
      ON UPDATE Cascade
;


ALTER TABLE loan
  ADD CONSTRAINT equipment_loan
    FOREIGN KEY (equipment_id) REFERENCES equipment (id) ON DELETE Cascade
      ON UPDATE Cascade
;


ALTER TABLE maintenance
  ADD CONSTRAINT equipment_maintenance
    FOREIGN KEY (equipment_id) REFERENCES equipment (id) ON DELETE Cascade
      ON UPDATE Cascade
;


ALTER TABLE equipment
  ADD CONSTRAINT equipment_status_equipment
    FOREIGN KEY (equipment_status_id) REFERENCES equipment_status (id)
      ON DELETE Cascade ON UPDATE Cascade
;


ALTER TABLE equipment
  ADD CONSTRAINT equipment_type_equipment
    FOREIGN KEY (equipment_type_id) REFERENCES equipment_type (id) ON DELETE Cascade
      ON UPDATE Cascade
;


ALTER TABLE incident
  ADD CONSTRAINT incident_type_incident
    FOREIGN KEY (incident_type_id) REFERENCES incident_type (id) ON DELETE Cascade
      ON UPDATE Cascade
;


ALTER TABLE equipment_movements
  ADD CONSTRAINT lab_destination_equipment_movements
    FOREIGN KEY (lab_destination_id) REFERENCES lab (id) ON DELETE Cascade
      ON UPDATE Cascade
;


ALTER TABLE equipment
  ADD CONSTRAINT lab_equipment
    FOREIGN KEY (lab_id) REFERENCES lab (id) ON DELETE Cascade ON UPDATE Cascade
;


ALTER TABLE incident
  ADD CONSTRAINT lab_incidents
    FOREIGN KEY (lab_id) REFERENCES lab (id) ON DELETE Cascade ON UPDATE Cascade
;


ALTER TABLE lab_reservation
  ADD CONSTRAINT lab_lab_reservations
    FOREIGN KEY (lab_id) REFERENCES lab (id) ON DELETE Cascade ON UPDATE Cascade
;


ALTER TABLE equipment_movements
  ADD CONSTRAINT lab_origin_equipment_movements
    FOREIGN KEY (lab_origin_id) REFERENCES lab (id) ON DELETE Cascade
      ON UPDATE Cascade
;


ALTER TABLE reservation_conflict
  ADD CONSTRAINT lab_reservation_a_reservation_conflicts
    FOREIGN KEY (lab_reservation_a_id) REFERENCES lab_reservation (id)
      ON DELETE Cascade ON UPDATE Cascade
;


ALTER TABLE reservation_conflict
  ADD CONSTRAINT lab_reservation_b_reservation_conflicts
    FOREIGN KEY (lab_reservation_b_id) REFERENCES lab_reservation (id)
      ON DELETE Cascade ON UPDATE Cascade
;


ALTER TABLE equipment_movements
  ADD CONSTRAINT loan_destination_equipment_movements
    FOREIGN KEY (loan_destination_id) REFERENCES loan (id) ON DELETE Cascade
      ON UPDATE Cascade
;


ALTER TABLE incident
  ADD CONSTRAINT loan_incident
    FOREIGN KEY (loan_id) REFERENCES loan (id) ON DELETE Cascade ON UPDATE Cascade
;


ALTER TABLE equipment_movements
  ADD CONSTRAINT loan_origin_equipment_movements
    FOREIGN KEY (loan_origin_id) REFERENCES loan (id) ON DELETE Cascade
      ON UPDATE Cascade
;


ALTER TABLE role_permission
  ADD CONSTRAINT permissions_role_permissions
    FOREIGN KEY (permission_id) REFERENCES permission (id) ON DELETE Cascade
      ON UPDATE Cascade
;


ALTER TABLE lab_reservation
  ADD CONSTRAINT reservation_reasons_lab_reservations
    FOREIGN KEY (reservation_reason_id) REFERENCES reservation_reason (id)
      ON DELETE Cascade ON UPDATE Cascade
;


ALTER TABLE equipment
  ADD CONSTRAINT retirement_cause_equipment
    FOREIGN KEY (retirement_cause_id) REFERENCES retirement_cause (id)
      ON DELETE Cascade ON UPDATE Cascade
;


ALTER TABLE user_role
  ADD CONSTRAINT role_id
    FOREIGN KEY (role_id) REFERENCES `role` (id) ON DELETE Cascade ON UPDATE Cascade
;


ALTER TABLE role_permission
  ADD CONSTRAINT role_role_permissions
    FOREIGN KEY (role_id) REFERENCES `role` (id) ON DELETE Cascade ON UPDATE Cascade
;


ALTER TABLE incident
  ADD CONSTRAINT severities_incident
    FOREIGN KEY (severity_id) REFERENCES severity (id) ON DELETE Cascade
      ON UPDATE Cascade
;


ALTER TABLE incident
  ADD CONSTRAINT user_assigned_incidents
    FOREIGN KEY (user_assigned_id) REFERENCES `user` (id) ON DELETE Cascade
      ON UPDATE Cascade
;


ALTER TABLE loan
  ADD CONSTRAINT user_issuer_loan
    FOREIGN KEY (user_issuer__id) REFERENCES `user` (id) ON DELETE Cascade
      ON UPDATE Cascade
;


ALTER TABLE lab_reservation
  ADD CONSTRAINT user_lab_reservations
    FOREIGN KEY (user_id) REFERENCES `user` (id) ON DELETE Cascade ON UPDATE Cascade
;


ALTER TABLE loan
  ADD CONSTRAINT user_receiver_loan
    FOREIGN KEY (user_receiver_id) REFERENCES `user` (id) ON DELETE Cascade
      ON UPDATE Cascade
;


ALTER TABLE incident
  ADD CONSTRAINT user_reporter_incidents
    FOREIGN KEY (user_reporter_id) REFERENCES `user` (id) ON DELETE Cascade
      ON UPDATE Cascade
;


ALTER TABLE loan
  ADD CONSTRAINT user_requester_loan
    FOREIGN KEY (user_requester__id) REFERENCES `user` (id) ON DELETE Cascade
      ON UPDATE Cascade
;


ALTER TABLE user_mail
  ADD CONSTRAINT user_user_mail
    FOREIGN KEY (user_id) REFERENCES `user` (id) ON DELETE Cascade ON UPDATE Cascade
;


ALTER TABLE user_role
  ADD CONSTRAINT user_user_role
    FOREIGN KEY (user_id) REFERENCES `user` (id) ON DELETE Cascade ON UPDATE Cascade
;


ALTER TABLE user_phone
  ADD CONSTRAINT usuarios_usuarios_telefono
    FOREIGN KEY (user_id) REFERENCES `user` (id) ON DELETE Cascade ON UPDATE Cascade
;


DELIMITER //

-- ==============================================
-- Procedure: sp_activate_user
-- Purpose  : Activate a user (set active = TRUE)
-- ==============================================

CREATE PROCEDURE sp_activate_user(IN p_user_id INT)
BEGIN
    /* ==============================
       1. Update user active status
       ============================== */
    UPDATE `user`
    SET `active` = TRUE
    WHERE id = p_user_id;

-- CALL sp_activate_user(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_add_user_mail
-- Purpose  : Add an email to a given user
-- ==============================================

CREATE PROCEDURE sp_add_user_mail(
    IN p_user_id INT,
    IN p_mail VARCHAR(50)
)
BEGIN
    /* ==============================
       1. Insert user email
       ============================== */
    INSERT INTO user_mail(user_id, mail)
    VALUES (p_user_id, p_mail);

-- CALL sp_add_user_mail(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_add_user_phone
-- Purpose  : Add a phone number to a user
-- ==============================================

CREATE PROCEDURE sp_add_user_phone(
    IN p_user_id INT,
    IN p_phone INT
)
BEGIN
    /* ==============================
       1. Insert user phone
       ============================== */
    INSERT INTO user_phone(user_id, phone)
    VALUES (p_user_id, p_phone);

-- CALL sp_add_user_phone(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_assign_role_to_user
-- Purpose  : Assign a role to a user
-- ==============================================

CREATE PROCEDURE sp_assign_role_to_user(
    IN p_user_id INT,
    IN p_role_name VARCHAR(50)
)
BEGIN
    /* ==============================
       1. Insert user-role mapping
       ============================== */
    INSERT IGNORE INTO user_role (user_id, role_id)
    SELECT p_user_id, r.id
    FROM role r
    WHERE r.name = p_role_name;

-- CALL sp_assign_role_to_user(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_create_lab
-- Purpose  : Create a new lab
-- ==============================================

CREATE PROCEDURE sp_create_lab(
    IN p_name VARCHAR(120),
    IN p_building VARCHAR(120),
    IN p_floor INT,
    IN p_capacity INT,
    IN p_description VARCHAR(255),
    IN p_active BOOLEAN
)
BEGIN
    /* ==============================
       1. Insert new lab
       ============================== */
    INSERT INTO lab(`name`, building, `floor`, capacity, `description`, `active`)
    VALUES (p_name, p_building, p_floor, p_capacity, p_description, p_active);

-- CALL sp_create_lab(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_create_user
-- Purpose  : Create a new user
-- ==============================================

CREATE PROCEDURE sp_create_user(
    IN p_name VARCHAR(50),
    IN p_first_lastname VARCHAR(50),
    IN p_second_lastname VARCHAR(50),
    IN p_active BOOLEAN,
    IN p_password VARCHAR(120)
)
BEGIN
    /* ==============================
       1. Insert new user
       ============================== */
    INSERT INTO `user`(`name`, first_lastname, second_lastname, `active`, `password`)
    VALUES (p_name, p_first_lastname, p_second_lastname, p_active, p_password);

-- CALL sp_create_user(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_deactivate_lab
-- Purpose  : Deactivate a lab
-- ==============================================

CREATE PROCEDURE sp_deactivate_lab(IN p_lab_id INT)
BEGIN
    /* ==============================
       1. Update lab active status
       ============================== */
    UPDATE lab
    SET `active` = FALSE
    WHERE id = p_lab_id;

-- CALL sp_deactivate_lab(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_activate_lab
-- Purpose  : Activate a lab
-- ==============================================

CREATE PROCEDURE sp_activate_lab(IN p_lab_id INT)
BEGIN
    /* ==============================
       1. Update lab active status
       ============================== */
    UPDATE lab
    SET `active` = TRUE
    WHERE id = p_lab_id;

-- CALL sp_activate_lab(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_deactivate_user
-- Purpose  : Deactivate a user (set active = FALSE)
-- ==============================================

CREATE PROCEDURE sp_deactivate_user(IN p_user_id INT)
BEGIN
    /* ==============================
       1. Update user active status
       ============================== */
    UPDATE `user`
    SET `active` = FALSE
    WHERE id = p_user_id;

-- CALL sp_deactivate_user(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_all_users
-- Purpose  : Retrieve all users
-- ==============================================

CREATE PROCEDURE sp_get_all_users()
BEGIN
    /* ==============================
       1. Select all users
       ============================== */
    SELECT 
        id,
        `name`,
        first_lastname,
        second_lastname,
        `active`,
        created_at
    FROM `user`;

-- CALL sp_get_all_users();
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_equipment_statuses
-- Purpose  : Retrieve all equipment statuses
-- ==============================================

CREATE PROCEDURE sp_get_equipment_statuses()
BEGIN
    /* ==============================
       1. Select equipment statuses
       ============================== */
    SELECT 
        id,
        `name`
    FROM equipment_status;

-- CALL sp_get_equipment_statuses();
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_equipment_types
-- Purpose  : Retrieve all equipment types
-- ==============================================

CREATE PROCEDURE sp_get_equipment_types()
BEGIN
    /* ==============================
       1. Select equipment types
       ============================== */
    SELECT 
        id,
        `name`,
        requires_calibration
    FROM equipment_type;

-- CALL sp_get_equipment_types();
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_incident_types
-- Purpose  : Retrieve all incident types
-- ==============================================

CREATE PROCEDURE sp_get_incident_types()
BEGIN
    /* ==============================
       1. Select incident types
       ============================== */
    SELECT 
        id,
        `name`,
        `description`
    FROM incident_type;

-- CALL sp_get_incident_types();
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_labs
-- Purpose  : Retrieve all active labs
-- ==============================================

CREATE PROCEDURE sp_get_labs()
BEGIN
    /* ==============================
       1. Select active labs
       ============================== */
    SELECT 
        id,
        `name`,
        building,
        `floor`,
        capacity,
        `description`,
        `active`
    FROM lab
    WHERE `active` = TRUE;

-- CALL sp_get_labs();
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_reservation_reasons
-- Purpose  : Retrieve all lab reservation reasons
-- ==============================================

CREATE PROCEDURE sp_get_reservation_reasons()
BEGIN
    /* ==============================
       1. Select reservation reasons
       ============================== */
    SELECT 
        id,
        `name`
    FROM reservation_reason;

-- CALL sp_get_reservation_reasons();
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_retirement_causes
-- Purpose  : Retrieve all equipment retirement causes
-- ==============================================

CREATE PROCEDURE sp_get_retirement_causes()
BEGIN
    /* ==============================
       1. Select retirement causes
       ============================== */
    SELECT 
        id,
        `name`,
        `description`
    FROM retirement_cause;

-- CALL sp_get_retirement_causes();
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_role_permissions
-- Purpose  : Retrieve all permissions mapped to each role
-- ==============================================

CREATE PROCEDURE sp_get_role_permissions()
BEGIN
    SELECT 
        r.name AS role,
        p.name AS permission
    FROM role_permission rp
    JOIN role r ON rp.role_id = r.id
    JOIN permission p ON rp.permission_id = p.id
    ORDER BY r.name, p.name;
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_severities
-- Purpose  : Retrieve all incident severities
-- ==============================================

CREATE PROCEDURE sp_get_severities()
BEGIN
    /* ==============================
       1. Select severities
       ============================== */
    SELECT 
        id,
        `name`,
        sla_hours
    FROM severity;

-- CALL sp_get_severities();
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_user_by_mail
-- Purpose  : Retrieve user data and password via email
-- ==============================================

CREATE PROCEDURE sp_get_user_by_mail(IN p_mail VARCHAR(50))
BEGIN
    SELECT 
        u.id,
        u.name,
        u.first_lastname,
        u.second_lastname,
        u.active,
        u.created_at,
        u.password
    FROM `user` u
    JOIN user_mail um ON um.user_id = u.id
    WHERE um.mail = p_mail;
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_user_permissions
-- Purpose  : Retrieve all permissions granted to a user
-- ==============================================

CREATE PROCEDURE sp_get_user_permissions(IN p_user_id INT)
BEGIN
    SELECT DISTINCT
        p.name AS permission
    FROM user_role ur
    JOIN role_permission rp ON rp.role_id = ur.role_id
    JOIN permission p ON p.id = rp.permission_id
    WHERE ur.user_id = p_user_id;
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_user_roles
-- Purpose  : Retrieve roles assigned to a given user
-- ==============================================

CREATE PROCEDURE sp_get_user_roles(IN p_user_id INT)
BEGIN
    SELECT 
        r.name AS role
    FROM user_role ur
    JOIN role r ON r.id = ur.role_id
    WHERE ur.user_id = p_user_id;
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_users_with_roles
-- Purpose  : Retrieve all users with all their roles
-- ==============================================

CREATE PROCEDURE sp_get_users_with_roles()
BEGIN
    SELECT 
        u.id AS user_id,
        u.name AS user_name,
        u.first_lastname,
        u.second_lastname,
        u.active,
        r.name AS role
    FROM `user` u
    LEFT JOIN user_role ur ON ur.user_id = u.id
    LEFT JOIN role r ON r.id = ur.role_id
    ORDER BY u.id, r.name;
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_initialize_test_users
-- Purpose  : Create test users for all base roles
-- ==============================================

CREATE PROCEDURE sp_initialize_test_users()
BEGIN
    /* ==============================
       1. Declare variables
       ============================== */
    DECLARE v_admin_role_id     INT;
    DECLARE v_labtech_role_id   INT;
    DECLARE v_prof_role_id      INT;
    DECLARE v_student_role_id   INT;

    DECLARE v_admin_user_id     INT;
    DECLARE v_labtech_user_id   INT;
    DECLARE v_prof_user_id      INT;
    DECLARE v_student_user_id   INT;
    DECLARE v_allroles_user_id  INT;

    /* ==============================
       2. Get role IDs by name
       ============================== */
    SELECT id INTO v_admin_role_id     FROM role WHERE name = 'admin';
    SELECT id INTO v_labtech_role_id   FROM role WHERE name = 'labtech';
    SELECT id INTO v_prof_role_id      FROM role WHERE name = 'professor';
    SELECT id INTO v_student_role_id   FROM role WHERE name = 'student';

    /* ==============================
       3. Insert test users
       ============================== */
    INSERT INTO `user`(`name`, first_lastname, second_lastname, `password`)
    VALUES ('Admin Test', 'User', NULL, 'admin123');
    SET v_admin_user_id = LAST_INSERT_ID();

    INSERT INTO `user`(`name`, first_lastname, second_lastname, `password`)
    VALUES ('LabTech Test', 'User', NULL, 'labtech123');
    SET v_labtech_user_id = LAST_INSERT_ID();

    INSERT INTO `user`(`name`, first_lastname, second_lastname, `password`)
    VALUES ('Professor Test', 'User', NULL, 'prof123');
    SET v_prof_user_id = LAST_INSERT_ID();

    INSERT INTO `user`(`name`, first_lastname, second_lastname, `password`)
    VALUES ('Student Test', 'User', NULL, 'student123');
    SET v_student_user_id = LAST_INSERT_ID();

    INSERT INTO `user`(`name`, first_lastname, second_lastname, `password`)
    VALUES ('AllRoles Test', 'User', NULL, 'allroles123');
    SET v_allroles_user_id = LAST_INSERT_ID();

    /* ==============================
       4. Assign roles to users
       ============================== */
    INSERT INTO user_role (user_id, role_id)
    VALUES (v_admin_user_id, v_admin_role_id);

    INSERT INTO user_role (user_id, role_id)
    VALUES (v_labtech_user_id, v_labtech_role_id);

    INSERT INTO user_role (user_id, role_id)
    VALUES (v_prof_user_id, v_prof_role_id);

    INSERT INTO user_role (user_id, role_id)
    VALUES (v_student_user_id, v_student_role_id);

    INSERT INTO user_role (user_id, role_id) VALUES
        (v_allroles_user_id, v_admin_role_id),
        (v_allroles_user_id, v_labtech_role_id),
        (v_allroles_user_id, v_prof_role_id),
        (v_allroles_user_id, v_student_role_id);

-- CALL sp_initialize_test_users();
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_remove_role_from_user
-- Purpose  : Remove a role from a user
-- ==============================================

CREATE PROCEDURE sp_remove_role_from_user(
    IN p_user_id INT,
    IN p_role_name VARCHAR(50)
)
BEGIN
    /* ==============================
       1. Delete user-role relation
       ============================== */
    DELETE ur
    FROM user_role ur
    JOIN role r ON r.id = ur.role_id
    WHERE ur.user_id = p_user_id
      AND r.name = p_role_name;

-- CALL sp_remove_role_from_user(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_seed_all_catalogs
-- Purpose  : Execute all catalog seeding procedures
-- ==============================================

CREATE PROCEDURE sp_seed_all_catalogs()
BEGIN
    /* ==============================
       1. Seed all catalog tables
       ============================== */
    CALL sp_seed_equipment_types();
    CALL sp_seed_equipment_statuses();
    CALL sp_seed_retirement_causes();
    CALL sp_seed_reservation_reasons();
    CALL sp_seed_incident_types();
    CALL sp_seed_severities();

-- CALL sp_seed_all_catalogs();
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_seed_all_security
-- Purpose  : Execute all security-related seed processes
-- ==============================================

CREATE PROCEDURE sp_seed_all_security()
BEGIN
    CALL sp_seed_roles_permissions();
    CALL sp_initialize_test_users();
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_seed_equipment_statuses
-- Purpose  : Seed base equipment statuses
-- ==============================================

CREATE PROCEDURE sp_seed_equipment_statuses()
BEGIN
    /* ==============================
       1. Insert base equipment statuses
       ============================== */
    INSERT IGNORE INTO equipment_status(`name`) VALUES
        ('available'),
        ('on_loan'),
        ('in_maintenance'),
        ('retired');

-- CALL sp_seed_equipment_statuses();
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_seed_equipment_types
-- Purpose  : Seed base equipment types
-- ==============================================

CREATE PROCEDURE sp_seed_equipment_types()
BEGIN
    /* ==============================
       1. Insert base equipment types
       ============================== */
    INSERT IGNORE INTO equipment_type(`name`, requires_calibration) VALUES
        ('Multimeter', TRUE),
        ('Oscilloscope', TRUE),
        ('Power Supply', TRUE),
        ('Function Generator', TRUE),
        ('PC', FALSE),
        ('Projector', FALSE);

-- CALL sp_seed_equipment_types();
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_seed_incident_types
-- Purpose  : Seed base incident types
-- ==============================================

CREATE PROCEDURE sp_seed_incident_types()
BEGIN
    /* ==============================
       1. Insert base incident types
       ============================== */
    INSERT IGNORE INTO incident_type(`name`, `description`) VALUES
        ('Physical damage', 'Broken parts, cracks, or visible external damage'),
        ('Electrical failure', 'Power, wiring, or circuitry related failure'),
        ('Software issue', 'Configuration or software malfunction'),
        ('Misuse', 'Improper or unsafe usage by the user'),
        ('Loss', 'Equipment lost or not returned');

-- CALL sp_seed_incident_types();
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_seed_reservation_reasons
-- Purpose  : Seed base lab reservation reasons
-- ==============================================

CREATE PROCEDURE sp_seed_reservation_reasons()
BEGIN
    /* ==============================
       1. Insert base reservation reasons
       ============================== */
    INSERT IGNORE INTO reservation_reason(`name`) VALUES
        ('Class'),
        ('Lab practice'),
        ('Exam'),
        ('Project'),
        ('Special event');

-- CALL sp_seed_reservation_reasons();
END

//

DELIMITER ;


DELIMITER //

CREATE PROCEDURE sp_seed_retirement_causes()
BEGIN
    /* ==============================
       1. Insert base retirement causes
       ============================== */
    INSERT IGNORE INTO retirement_cause(`name`, `description`) VALUES
        ('Obsolescence', 'Equipment is obsolete and no longer in use'),
        ('Irreparable damage', 'Equipment cannot be repaired at reasonable cost'),
        ('Lost or stolen', 'Equipment was reported lost or stolen'),
        ('Donation', 'Equipment was donated or transferred');

-- CALL sp_seed_retirement_causes();
END
//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_seed_roles_permissions
-- Purpose  : Seed base roles and permissions
-- ==============================================

CREATE PROCEDURE sp_seed_roles_permissions()
BEGIN
    /* ==============================
       1. Insert base roles
       ============================== */
    INSERT IGNORE INTO role (`name`) VALUES
        ('admin'),
        ('labtech'),
        ('professor'),
        ('student');

    /* ==============================
       2. Insert permissions
       (atomic actions in the system)
       ============================== */
    INSERT IGNORE INTO permission (`name`) VALUES
        ('manage_labs'),
        ('manage_equipment'),
        ('manage_users'),
        ('view_global_reports'),
        ('view_incidents'),
        ('create_incident'),
        ('update_incident'),
        ('create_lab_reservation'),
        ('view_lab_availability'),
        ('create_equipment_loan'),
        ('receive_equipment_return'),
        ('update_equipment_status'),
        ('view_usage_history');

    /* ==============================
       3. Map roles to permissions
       ============================== */

    /* --- Permissions for admin --- */
    INSERT IGNORE INTO role_permission (role_id, permission_id)
    SELECT r.id, p.id
    FROM role r
    JOIN permission p ON p.name IN (
        'manage_labs',
        'manage_equipment',
        'manage_users',
        'view_global_reports',
        'view_incidents',
        'view_lab_availability',
        'view_usage_history'
    )
    WHERE r.name = 'admin';

    /* --- Permissions for labtech --- */
    INSERT IGNORE INTO role_permission (role_id, permission_id)
    SELECT r.id, p.id
    FROM role r
    JOIN permission p ON p.name IN (
        'create_equipment_loan',
        'receive_equipment_return',
        'update_equipment_status',
        'view_lab_availability',
        'view_usage_history',
        'create_incident',
        'update_incident',
        'view_incidents'
    )
    WHERE r.name = 'labtech';

    /* --- Permissions for professor --- */
    INSERT IGNORE INTO role_permission (role_id, permission_id)
    SELECT r.id, p.id
    FROM role r
    JOIN permission p ON p.name IN (
        'create_lab_reservation',
        'view_lab_availability',
        'create_equipment_loan',
        'view_usage_history',
        'create_incident',
        'view_incidents'
    )
    WHERE r.name = 'professor';

    /* --- Permissions for student --- */
    INSERT IGNORE INTO role_permission (role_id, permission_id)
    SELECT r.id, p.id
    FROM role r
    JOIN permission p ON p.name IN (
        'view_lab_availability',
        'create_equipment_loan',
        'create_incident'
    )
    WHERE r.name = 'student';

-- CALL sp_seed_roles_permissions();
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_seed_severities
-- Purpose  : Seed base severities with SLA hours
-- ==============================================

CREATE PROCEDURE sp_seed_severities()
BEGIN
    /* ==============================
       1. Insert base severities
       ============================== */
    INSERT IGNORE INTO severity(`name`, sla_hours) VALUES
        ('low', 72),
        ('medium', 48),
        ('high', 24),
        ('critical', 4);

-- CALL sp_seed_severities();
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_update_lab
-- Purpose  : Update an existing lab
-- ==============================================

CREATE PROCEDURE sp_update_lab(
    IN p_lab_id INT,
    IN p_name VARCHAR(120),
    IN p_building VARCHAR(120),
    IN p_floor INT,
    IN p_capacity INT,
    IN p_description VARCHAR(255),
    IN p_active BOOLEAN
)
BEGIN
    /* ==============================
       1. Update lab fields
       ============================== */
    UPDATE lab
    SET
        `name` = p_name,
        building = p_building,
        `floor` = p_floor,
        capacity = p_capacity,
        `description` = p_description,
        `active` = p_active
    WHERE id = p_lab_id;

-- CALL sp_update_lab(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_update_user
-- Purpose  : Update an existing user's information
-- ==============================================

CREATE PROCEDURE sp_update_user(
    IN p_user_id INT,
    IN p_name VARCHAR(50),
    IN p_first_lastname VARCHAR(50),
    IN p_second_lastname VARCHAR(50),
    IN p_active BOOLEAN,
    IN p_password VARCHAR(120)
)
BEGIN
    /* ==============================
       1. Update user fields
       ============================== */
    UPDATE `user`
    SET
        `name` = p_name,
        first_lastname = p_first_lastname,
        second_lastname = p_second_lastname,
        `active` = p_active,
        `password` = p_password
    WHERE id = p_user_id;

-- CALL sp_update_user(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_create_lab_reservation
-- Purpose  : Create a new lab reservation
-- ==============================================

CREATE PROCEDURE sp_create_lab_reservation(
    IN p_lab_id INT,
    IN p_user_id INT,
    IN p_reservation_reason_id INT,
    IN p_start_time DATETIME,
    IN p_end_time DATETIME,
    IN p_comment VARCHAR(255)
)
BEGIN
    /* ==============================
       1. Insert reservation
       ============================== */
    INSERT INTO lab_reservation(
        lab_id,
        user_id,
        reservation_reason_id,
        start_time,
        end_time,
        reservation_status,
        `comment`
    )
    VALUES (
        p_lab_id,
        p_user_id,
        p_reservation_reason_id,
        p_start_time,
        p_end_time,
        'pending',
        p_comment
    );

-- CALL sp_create_lab_reservation(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_lab_reservations_by_lab
-- Purpose  : Retrieve reservations for a lab by date range
-- ==============================================

CREATE PROCEDURE sp_get_lab_reservations_by_lab(
    IN p_lab_id INT,
    IN p_start DATETIME,
    IN p_end DATETIME
)
BEGIN
    /* ==============================
       1. Select reservations by lab
       ============================== */
    SELECT
        lr.id,
        lr.lab_id,
        lr.user_id,
        lr.reservation_reason_id,
        lr.start_time,
        lr.end_time,
        lr.reservation_status,
        lr.`comment`,
        lr.created_at
    FROM lab_reservation lr
    WHERE lr.lab_id = p_lab_id
      AND lr.start_time >= p_start
      AND lr.end_time <= p_end
    ORDER BY lr.start_time;

-- CALL sp_get_lab_reservations_by_lab(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_lab_reservations_by_user
-- Purpose  : Retrieve all lab reservations made by a specific user
-- ==============================================

CREATE PROCEDURE sp_get_lab_reservations_by_user(IN p_user_id INT)
BEGIN
    /* ==============================
       1. Select reservations by user
       ============================== */
    SELECT 
        id,
        lab_id,
        user_id,
        reservation_reason_id,
        start_time,
        end_time,
        reservation_status,
        `comment`,
        created_at
    FROM lab_reservation
    WHERE user_id = p_user_id;

-- CALL sp_get_lab_reservations_by_user(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_cancel_lab_reservation
-- Purpose  : Cancel a lab reservation
-- ==============================================

CREATE PROCEDURE sp_cancel_lab_reservation(
    IN p_reservation_id INT,
    IN p_user_id INT
)
BEGIN
    /* ==============================
       1. Cancel reservation
       ============================== */
    UPDATE lab_reservation
    SET reservation_status = 'canceled'
    WHERE id = p_reservation_id;

-- CALL sp_cancel_lab_reservation(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_reservation_conflicts
-- Purpose  : Retrieve conflicting lab reservations
-- ==============================================

CREATE PROCEDURE sp_get_reservation_conflicts(
    IN p_lab_id INT,
    IN p_start DATETIME,
    IN p_end DATETIME
)
BEGIN
    /* ==============================
       1. Select conflicting reservations
       ============================== */
    SELECT 
        lr.id,
        lr.lab_id,
        lr.start_time,
        lr.end_time,
        lr.reservation_status,
        lr.user_id
    FROM lab_reservation lr
    WHERE lr.lab_id = p_lab_id
      AND (
           lr.start_time < p_end
       AND lr.end_time > p_start
      );

-- CALL sp_get_reservation_conflicts(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_seed_test_labs
-- Purpose  : Seed test labs for development environment
-- ==============================================

CREATE PROCEDURE sp_seed_test_labs()
BEGIN
    /* ==============================
       1. Insert test labs
       ============================== */
    INSERT IGNORE INTO lab(`name`, building, `floor`, capacity, `description`, `active`) VALUES
        ('Electronics Lab 1', 'Main Building', 1, 30, 'Electronics practice room', TRUE),
        ('Physics Lab 2', 'Science Block', 2, 25, 'Physics equipment and experiments', TRUE),
        ('Computer Lab A', 'Tech Center', 3, 40, 'Computer workstations', TRUE);

-- CALL sp_seed_test_labs();
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_seed_test_lab_reservations
-- Purpose  : Seed test lab reservations
-- ==============================================

CREATE PROCEDURE sp_seed_test_lab_reservations(
    IN p_start DATETIME,
    IN p_end DATETIME
)
BEGIN
    /* ==============================
       1. Insert test reservations
       ============================== */
    INSERT INTO lab_reservation(
        lab_id,
        user_id,
        reservation_reason_id,
        start_time,
        end_time,
        reservation_status,
        `comment`
    )
    VALUES
        (1, 1, 1, p_start, DATE_ADD(p_start, INTERVAL 2 HOUR), 'approved', 'Test reservation 1'),
        (2, 2, 2, p_end, DATE_ADD(p_end, INTERVAL 1 HOUR), 'approved', 'Test reservation 2');

-- CALL sp_seed_test_lab_reservations('2025-01-01 08:00', '2025-01-01 10:00');
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_create_equipment
-- Purpose  : Create a new equipment record
-- ==============================================

CREATE PROCEDURE sp_create_equipment(
    IN p_equipment_type_id INT,
    IN p_lab_id INT,
    IN p_equipment_status_id INT,
    IN p_retirement_cause_id INT,
    IN p_inventory_tag VARCHAR(120),
    IN p_serial_number VARCHAR(120),
    IN p_purchase_date DATE,
    IN p_cost DECIMAL(12,2),
    IN p_decomissioned BOOLEAN,
    IN p_retirement_date DATETIME
)
BEGIN
    /* ==============================
       1. Insert new equipment
       ============================== */
    INSERT INTO equipment(
        equipment_type_id,
        lab_id,
        equipment_status_id,
        retirement_cause_id,
        inventory_tag,
        serial_number,
        purchase_date,
        cost,
        decomissioned,
        retirement_date
    )
    VALUES (
        p_equipment_type_id,
        p_lab_id,
        p_equipment_status_id,
        p_retirement_cause_id,
        p_inventory_tag,
        p_serial_number,
        p_purchase_date,
        p_cost,
        p_decomissioned,
        p_retirement_date
    );

-- CALL sp_create_equipment(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_update_equipment
-- Purpose  : Update an existing equipment record
-- ==============================================

CREATE PROCEDURE sp_update_equipment(
    IN p_equipment_id INT,
    IN p_equipment_type_id INT,
    IN p_lab_id INT,
    IN p_equipment_status_id INT,
    IN p_retirement_cause_id INT,
    IN p_inventory_tag VARCHAR(120),
    IN p_serial_number VARCHAR(120),
    IN p_purchase_date DATE,
    IN p_cost DECIMAL(12,2),
    IN p_decomissioned BOOLEAN,
    IN p_retirement_date DATETIME
)
BEGIN
    /* ==============================
       1. Update equipment fields
       ============================== */
    UPDATE equipment
    SET
        equipment_type_id   = p_equipment_type_id,
        lab_id              = p_lab_id,
        equipment_status_id = p_equipment_status_id,
        retirement_cause_id = p_retirement_cause_id,
        inventory_tag       = p_inventory_tag,
        serial_number       = p_serial_number,
        purchase_date       = p_purchase_date,
        cost                = p_cost,
        decomissioned       = p_decomissioned,
        retirement_date     = p_retirement_date
    WHERE id = p_equipment_id;

-- CALL sp_update_equipment(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_equipment_by_lab
-- Purpose  : Retrieve equipment assigned to a given lab
-- ==============================================

CREATE PROCEDURE sp_get_equipment_by_lab(IN p_lab_id INT)
BEGIN
    /* ==============================
       1. Select equipment by lab
       ============================== */
    SELECT
        e.id,
        e.equipment_type_id,
        e.lab_id,
        e.equipment_status_id,
        e.retirement_cause_id,
        e.inventory_tag,
        e.serial_number,
        e.purchase_date,
        e.cost,
        e.decomissioned,
        e.retirement_date
    FROM equipment e
    WHERE e.lab_id = p_lab_id;

-- CALL sp_get_equipment_by_lab(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_equipment_detail
-- Purpose  : Retrieve detailed information for a given equipment
-- ==============================================

CREATE PROCEDURE sp_get_equipment_detail(IN p_equipment_id INT)
BEGIN
    /* ==============================
       1. Select equipment detail
       ============================== */
    SELECT
        e.id,
        e.equipment_type_id,
        e.lab_id,
        e.equipment_status_id,
        e.retirement_cause_id,
        e.inventory_tag,
        e.serial_number,
        e.purchase_date,
        e.cost,
        e.decomissioned,
        e.retirement_date
    FROM equipment e
    WHERE e.id = p_equipment_id;

-- CALL sp_get_equipment_detail(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_available_equipment_by_type
-- Purpose  : Retrieve available equipment by type
-- ==============================================

CREATE PROCEDURE sp_get_available_equipment_by_type(IN p_equipment_type_id INT)
BEGIN
    /* ==============================
       1. Select available equipment
       ============================== */
    SELECT
        e.id,
        e.equipment_type_id,
        e.lab_id,
        e.equipment_status_id,
        e.retirement_cause_id,
        e.inventory_tag,
        e.serial_number,
        e.purchase_date,
        e.cost,
        e.decomissioned,
        e.retirement_date
    FROM equipment e
    WHERE e.equipment_type_id = p_equipment_type_id
      AND e.decomissioned = FALSE;

-- CALL sp_get_available_equipment_by_type(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_register_equipment_movement
-- Purpose  : Register an equipment movement
-- ==============================================

CREATE PROCEDURE sp_register_equipment_movement(
    IN p_equipment_id INT,
    IN p_lab_origin_id INT,
    IN p_loan_origin_id INT,
    IN p_lab_destination_id INT,
    IN p_loan_destination_id INT,
    IN p_note VARCHAR(255)
)
BEGIN
    /* ==============================
       1. Insert equipment movement
       ============================== */
    INSERT INTO equipment_movements(
        equipment_id,
        lab_origin_id,
        loan_origin_id,
        lab_destination_id,
        loan_destination_id,
        movement_date,
        note
    )
    VALUES (
        p_equipment_id,
        p_lab_origin_id,
        p_loan_origin_id,
        p_lab_destination_id,
        p_loan_destination_id,
        CURRENT_TIMESTAMP,
        p_note
    );

-- CALL sp_register_equipment_movement(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_create_maintenance
-- Purpose  : Create a maintenance record for an equipment
-- ==============================================

CREATE PROCEDURE sp_create_maintenance(
    IN p_equipment_id INT,
    IN p_maintenance_type ENUM('preventive','corrective'),
    IN p_description TEXT,
    IN p_start_date DATETIME,
    IN p_end_date DATETIME,
    IN p_cost DECIMAL(12,2),
    IN p_performed_by VARCHAR(150)
)
BEGIN
    /* ==============================
       1. Insert maintenance record
       ============================== */
    INSERT INTO maintenance(
        equipment_id,
        maintenance_type,
        `description`,
        start_date,
        end_date,
        cost,
        performed_by
    )
    VALUES (
        p_equipment_id,
        p_maintenance_type,
        p_description,
        p_start_date,
        p_end_date,
        p_cost,
        p_performed_by
    );

-- CALL sp_create_maintenance(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_close_maintenance
-- Purpose  : Close an existing maintenance record
-- ==============================================

CREATE PROCEDURE sp_close_maintenance(
    IN p_maintenance_id INT,
    IN p_end_date DATETIME,
    IN p_cost DECIMAL(12,2),
    IN p_performed_by VARCHAR(150),
    IN p_description TEXT
)
BEGIN
    /* ==============================
       1. Update maintenance as closed
       ============================== */
    UPDATE maintenance
    SET
        end_date    = p_end_date,
        cost        = p_cost,
        performed_by = p_performed_by,
        `description` = p_description
    WHERE id = p_maintenance_id;

-- CALL sp_close_maintenance(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_maintenance_by_equipment
-- Purpose  : Retrieve maintenance history for an equipment
-- ==============================================

CREATE PROCEDURE sp_get_maintenance_by_equipment(IN p_equipment_id INT)
BEGIN
    /* ==============================
       1. Select maintenance records
       ============================== */
    SELECT
        m.id,
        m.equipment_id,
        m.maintenance_type,
        m.`description`,
        m.start_date,
        m.end_date,
        m.cost,
        m.performed_by
    FROM maintenance m
    WHERE m.equipment_id = p_equipment_id
    ORDER BY m.start_date DESC;

-- CALL sp_get_maintenance_by_equipment(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_seed_test_equipment
-- Purpose  : Seed test equipment for development
-- ==============================================

CREATE PROCEDURE sp_seed_test_equipment()
BEGIN
    /* ==============================
       1. Insert test equipment
       ============================== */
    INSERT IGNORE INTO equipment(
        equipment_type_id,
        lab_id,
        equipment_status_id,
        retirement_cause_id,
        inventory_tag,
        serial_number,
        purchase_date,
        cost,
        decomissioned,
        retirement_date
    )
    VALUES
        (1, 1, 1, NULL, 'EQ-EL-0001', 'SN-EL-0001', '2023-01-15', 1500.00, FALSE, NULL),
        (2, 1, 1, NULL, 'EQ-EL-0002', 'SN-EL-0002', '2023-02-10', 3000.00, FALSE, NULL),
        (3, 2, 1, NULL, 'EQ-PH-0001', 'SN-PH-0001', '2022-11-05', 2000.00, FALSE, NULL),
        (5, 3, 1, NULL, 'EQ-PC-0001', 'SN-PC-0001', '2024-03-20', 18000.00, FALSE, NULL);

-- CALL sp_seed_test_equipment();
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_create_equipment_loan
-- Purpose  : Create a new equipment loan
-- ==============================================

CREATE PROCEDURE sp_create_equipment_loan(
    IN p_equipment_id INT,
    IN p_user_requester_id INT,
    IN p_user_issuer_id INT,
    IN p_due_date DATETIME,
    IN p_remarks VARCHAR(255)
)
BEGIN
    /* ==============================
       1. Insert new loan
       ============================== */
    INSERT INTO loan(
        equipment_id,
        user_requester__id,
        user_issuer__id,
        user_receiver_id,
        loan_date,
        due_date,
        return_date,
        loan_status,
        remarks
    )
    VALUES (
        p_equipment_id,
        p_user_requester_id,
        p_user_issuer_id,
        NULL,
        CURRENT_TIMESTAMP,
        p_due_date,
        NULL,
        'active',
        p_remarks
    );

-- CALL sp_create_equipment_loan(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_close_equipment_loan
-- Purpose  : Close an existing equipment loan
-- ==============================================

CREATE PROCEDURE sp_close_equipment_loan(
    IN p_loan_id INT,
    IN p_return_date DATETIME,
    IN p_user_receiver_id INT,
    IN p_remarks VARCHAR(255)
)
BEGIN
    /* ==============================
       1. Update loan as returned
       ============================== */
    UPDATE loan
    SET
        return_date      = p_return_date,
        user_receiver_id = p_user_receiver_id,
        loan_status      = 'returned',
        remarks          = p_remarks
    WHERE id = p_loan_id;

-- CALL sp_close_equipment_loan(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_active_loans
-- Purpose  : Retrieve all active loans
-- ==============================================

CREATE PROCEDURE sp_get_active_loans()
BEGIN
    /* ==============================
       1. Select active loans
       ============================== */
    SELECT
        id,
        equipment_id,
        user_requester__id,
        user_issuer__id,
        user_receiver_id,
        loan_date,
        due_date,
        return_date,
        loan_status,
        remarks,
        created_at
    FROM loan
    WHERE loan_status = 'active';

-- CALL sp_get_active_loans();
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_user_loans
-- Purpose  : Retrieve all loans requested by a given user
-- ==============================================

CREATE PROCEDURE sp_get_user_loans(IN p_user_id INT)
BEGIN
    /* ==============================
       1. Select loans by requester user
       ============================== */
    SELECT
        id,
        equipment_id,
        user_requester__id,
        user_issuer__id,
        user_receiver_id,
        loan_date,
        due_date,
        return_date,
        loan_status,
        remarks,
        created_at
    FROM loan
    WHERE user_requester__id = p_user_id
    ORDER BY loan_date DESC;

-- CALL sp_get_user_loans(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_equipment_loans_history
-- Purpose  : Retrieve loan history for a given equipment
-- ==============================================

CREATE PROCEDURE sp_get_equipment_loans_history(IN p_equipment_id INT)
BEGIN
    /* ==============================
       1. Select loans by equipment
       ============================== */
    SELECT
        id,
        equipment_id,
        user_requester__id,
        user_issuer__id,
        user_receiver_id,
        loan_date,
        due_date,
        return_date,
        loan_status,
        remarks,
        created_at
    FROM loan
    WHERE equipment_id = p_equipment_id
    ORDER BY loan_date DESC;

-- CALL sp_get_equipment_loans_history(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_seed_test_loans
-- Purpose  : Seed test loans for development
-- ==============================================

CREATE PROCEDURE sp_seed_test_loans(IN p_reference_date DATETIME)
BEGIN
    /* ==============================
       1. Insert test loans
       ============================== */
    INSERT INTO loan(
        equipment_id,
        user_requester__id,
        user_issuer__id,
        user_receiver_id,
        loan_date,
        due_date,
        return_date,
        loan_status,
        remarks
    )
    VALUES
        -- Active loan
        (1, 1, 2, NULL,
         DATE_SUB(p_reference_date, INTERVAL 1 DAY),
         DATE_ADD(p_reference_date, INTERVAL 6 DAY),
         NULL,
         'active',
         'Test active loan'),

        -- Returned loan
        (2, 2, 1, 3,
         DATE_SUB(p_reference_date, INTERVAL 10 DAY),
         DATE_SUB(p_reference_date, INTERVAL 5 DAY),
         DATE_SUB(p_reference_date, INTERVAL 4 DAY),
         'returned',
         'Test returned loan'),

        -- Overdue loan
        (3, 3, 2, NULL,
         DATE_SUB(p_reference_date, INTERVAL 7 DAY),
         DATE_SUB(p_reference_date, INTERVAL 1 DAY),
         NULL,
         'overdue',
         'Test overdue loan');

-- CALL sp_seed_test_loans('2025-01-15 10:00:00');
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_create_incident
-- Purpose  : Create a new incident (status = 'open')
-- ==============================================

CREATE PROCEDURE sp_create_incident(
    IN p_equipment_id INT,
    IN p_lab_id INT,
    IN p_user_reporter_id INT,
    IN p_loan_id INT,
    IN p_incident_type_id INT,
    IN p_severity_id INT,
    IN p_description TEXT
)
BEGIN
    /* ==============================
       1. Insert new incident
       ============================== */
    INSERT INTO incident(
        equipment_id,
        lab_id,
        user_reporter_id,
        user_assigned_id,
        loan_id,
        incident_type_id,
        severity_id,
        `description`,
        incident_status,
        closed_at,
        resolution
    )
    VALUES (
        p_equipment_id,
        p_lab_id,
        p_user_reporter_id,
        NULL,
        p_loan_id,
        p_incident_type_id,
        p_severity_id,
        p_description,
        'open',
        NULL,
        NULL
    );

-- CALL sp_create_incident(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_update_incident
-- Purpose  : Update incident status, severity, type, assignee and resolution
-- ==============================================

CREATE PROCEDURE sp_update_incident(
    IN p_incident_id INT,
    IN p_incident_status ENUM('open','in_progress','closed'),
    IN p_severity_id INT,
    IN p_incident_type_id INT,
    IN p_user_assigned_id INT,
    IN p_resolution TEXT,
    IN p_closed_at DATETIME
)
BEGIN
    /* ==============================
       1. Update incident fields
       ============================== */
    UPDATE incident
    SET
        incident_status   = p_incident_status,
        severity_id       = p_severity_id,
        incident_type_id  = p_incident_type_id,
        user_assigned_id  = p_user_assigned_id,
        resolution        = p_resolution,
        closed_at         = p_closed_at
    WHERE id = p_incident_id;

-- CALL sp_update_incident(...);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_get_incidents
-- Purpose  : Retrieve incidents using optional filters
-- ==============================================

CREATE PROCEDURE sp_get_incidents(
    IN p_lab_id INT,
    IN p_equipment_id INT,
    IN p_severity_id INT,
    IN p_status VARCHAR(20),
    IN p_date_from DATETIME,
    IN p_date_to DATETIME
)
BEGIN
    /* ==============================
       1. Select incidents with optional filters
       ============================== */
    SELECT
        i.id,
        i.equipment_id,
        i.lab_id,
        i.user_reporter_id,
        i.user_assigned_id,
        i.loan_id,
        i.incident_type_id,
        i.severity_id,
        i.`description`,
        i.reported_at,
        i.incident_status,
        i.closed_at,
        i.resolution
    FROM incident i
    WHERE (p_lab_id IS NULL OR i.lab_id = p_lab_id)
      AND (p_equipment_id IS NULL OR i.equipment_id = p_equipment_id)
      AND (p_severity_id IS NULL OR i.severity_id = p_severity_id)
      AND (p_status IS NULL OR i.incident_status = p_status)
      AND (p_date_from IS NULL OR i.reported_at >= p_date_from)
      AND (p_date_to IS NULL OR i.reported_at <= p_date_to)
    ORDER BY i.reported_at DESC;

-- CALL sp_get_incidents(NULL, NULL, NULL, 'open', '2025-01-01', '2025-01-31');
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_seed_test_incidents
-- Purpose  : Seed test incidents for development
-- ==============================================

CREATE PROCEDURE sp_seed_test_incidents(IN p_reference_date DATETIME)
BEGIN
    /* ==============================
       1. Insert test incidents
       ============================== */
    INSERT INTO incident(
        equipment_id,
        lab_id,
        user_reporter_id,
        user_assigned_id,
        loan_id,
        incident_type_id,
        severity_id,
        `description`,
        reported_at,
        incident_status,
        closed_at,
        resolution
    )
    VALUES
        -- Open incident, high severity
        (1, 1, 1, NULL,
         1,
         1,   -- incident_type_id (e.g. Physical damage)
         3,   -- severity_id (e.g. high)
         'Test incident: physical damage on oscilloscope',
         DATE_SUB(p_reference_date, INTERVAL 1 DAY),
         'open',
         NULL,
         NULL),

        -- In progress incident, medium severity
        (2, 1, 2, 2,
         2,
         2,   -- incident_type_id (e.g. Electrical failure)
         2,   -- severity_id (e.g. medium)
         'Test incident: intermittent power failure',
         DATE_SUB(p_reference_date, INTERVAL 2 DAY),
         'in_progress',
         NULL,
         NULL),

        -- Closed incident, critical severity
        (3, 2, 3, 1,
         3,
         3,   -- incident_type_id (e.g. Software issue)
         4,   -- severity_id (e.g. critical)
         'Test incident: critical software malfunction during exam',
         DATE_SUB(p_reference_date, INTERVAL 5 DAY),
         'closed',
         DATE_SUB(p_reference_date, INTERVAL 4 DAY),
         'Reinstalled software and restored configuration from backup');

-- CALL sp_seed_test_incidents('2025-01-15 10:00:00');
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_report_lab_usage
-- Purpose  : Report lab usage (reservations and loans) in a date range
-- ==============================================

CREATE PROCEDURE sp_report_lab_usage(
    IN p_lab_id INT,
    IN p_date_from DATETIME,
    IN p_date_to DATETIME
)
BEGIN
    /* ==============================
       1. Lab reservations in range
       ============================== */
    SELECT
        'reservation' AS activity_type,
        lr.id         AS activity_id,
        lr.lab_id,
        lr.user_id,
        lr.reservation_reason_id,
        lr.start_time AS activity_start,
        lr.end_time   AS activity_end,
        lr.reservation_status AS status,
        lr.comment,
        lr.created_at
    FROM lab_reservation lr
    WHERE lr.lab_id = p_lab_id
      AND lr.start_time >= p_date_from
      AND lr.start_time <= p_date_to

    UNION ALL

    /* ==============================
       2. Equipment loans in range
          (for equipment in the lab)
       ============================== */
    SELECT
        'loan' AS activity_type,
        l.id   AS activity_id,
        e.lab_id,
        l.user_requester__id AS user_id,
        NULL AS reservation_reason_id,
        l.loan_date  AS activity_start,
        l.due_date   AS activity_end,
        l.loan_status AS status,
        l.remarks     AS comment,
        l.created_at
    FROM loan l
    JOIN equipment e ON e.id = l.equipment_id
    WHERE e.lab_id = p_lab_id
      AND l.loan_date >= p_date_from
      AND l.loan_date <= p_date_to
    ORDER BY activity_start;

-- CALL sp_report_lab_usage(1, '2025-01-01 00:00:00', '2025-01-31 23:59:59');
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_report_equipment_usage
-- Purpose  : Report equipment usage and related events in a date range
-- ==============================================

CREATE PROCEDURE sp_report_equipment_usage(
    IN p_equipment_id INT,
    IN p_date_from DATETIME,
    IN p_date_to DATETIME
)
BEGIN
    /* ==============================
       1. Loans for this equipment
       ============================== */
    SELECT
        'loan' AS event_type,
        l.id   AS event_id,
        l.equipment_id,
        l.user_requester__id AS main_user_id,
        l.loan_date  AS event_start,
        l.due_date   AS event_end,
        l.loan_status AS status,
        l.remarks     AS notes
    FROM loan l
    WHERE l.equipment_id = p_equipment_id
      AND l.loan_date >= p_date_from
      AND l.loan_date <= p_date_to

    UNION ALL

    /* ==============================
       2. Incidents for this equipment
       ============================== */
    SELECT
        'incident' AS event_type,
        i.id       AS event_id,
        i.equipment_id,
        i.user_reporter_id AS main_user_id,
        i.reported_at      AS event_start,
        i.closed_at        AS event_end,
        i.incident_status  AS status,
        i.description      AS notes
    FROM incident i
    WHERE i.equipment_id = p_equipment_id
      AND i.reported_at >= p_date_from
      AND i.reported_at <= p_date_to

    UNION ALL

    /* ==============================
       3. Maintenance records
       ============================== */
    SELECT
        'maintenance' AS event_type,
        m.id          AS event_id,
        m.equipment_id,
        NULL          AS main_user_id,
        m.start_date  AS event_start,
        m.end_date    AS event_end,
        NULL          AS status,
        m.description AS notes
    FROM maintenance m
    WHERE m.equipment_id = p_equipment_id
      AND m.start_date >= p_date_from
      AND m.start_date <= p_date_to

    ORDER BY event_start;

-- CALL sp_report_equipment_usage(1, '2025-01-01 00:00:00', '2025-01-31 23:59:59');
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_report_incidents_by_severity
-- Purpose  : Report incidents aggregated by severity in a date range
-- ==============================================

CREATE PROCEDURE sp_report_incidents_by_severity(
    IN p_date_from DATETIME,
    IN p_date_to DATETIME
)
BEGIN
    /* ==============================
       1. Aggregate incidents by severity
       ============================== */
    SELECT
        s.id   AS severity_id,
        s.name AS severity_name,
        COUNT(i.id) AS total_incidents,
        SUM(CASE WHEN i.incident_status = 'closed' THEN 1 ELSE 0 END) AS closed_incidents,
        AVG(
            CASE 
                WHEN i.incident_status = 'closed'
                     AND i.closed_at IS NOT NULL
                THEN TIMESTAMPDIFF(HOUR, i.reported_at, i.closed_at)
                ELSE NULL
            END
        ) AS avg_resolution_hours
    FROM severity s
    LEFT JOIN incident i
        ON i.severity_id = s.id
       AND i.reported_at >= p_date_from
       AND i.reported_at <= p_date_to
    GROUP BY
        s.id,
        s.name
    ORDER BY s.id;

-- CALL sp_report_incidents_by_severity('2025-01-01 00:00:00', '2025-01-31 23:59:59');
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_report_reservation_conflicts
-- Purpose  : Report lab reservation conflicts in a date range
-- ==============================================

CREATE PROCEDURE sp_report_reservation_conflicts(
    IN p_date_from DATETIME,
    IN p_date_to DATETIME,
    IN p_lab_id INT
)
BEGIN
    /* ==============================
       1. Select reservation conflicts
       ============================== */
    SELECT
        rc.id            AS conflict_id,
        rc.detected_at,

        -- Reservation A
        ra.id            AS reservation_a_id,
        ra.lab_id        AS reservation_a_lab_id,
        ra.user_id       AS reservation_a_user_id,
        ra.start_time    AS reservation_a_start,
        ra.end_time      AS reservation_a_end,
        ra.reservation_status AS reservation_a_status,

        -- Reservation B
        rb.id            AS reservation_b_id,
        rb.lab_id        AS reservation_b_lab_id,
        rb.user_id       AS reservation_b_user_id,
        rb.start_time    AS reservation_b_start,
        rb.end_time      AS reservation_b_end,
        rb.reservation_status AS reservation_b_status

    FROM reservation_conflict rc
    JOIN lab_reservation ra ON ra.id = rc.lab_reservation_a_id
    JOIN lab_reservation rb ON rb.id = rc.lab_reservation_b_id
    WHERE rc.detected_at >= p_date_from
      AND rc.detected_at <= p_date_to
      AND (p_lab_id IS NULL 
           OR ra.lab_id = p_lab_id
           OR rb.lab_id = p_lab_id)
    ORDER BY rc.detected_at DESC;

-- CALL sp_report_reservation_conflicts('2025-01-01 00:00:00', '2025-01-31 23:59:59', 1);
END

//

DELIMITER ;


DELIMITER //

-- ==============================================
-- Procedure: sp_initialize_demo_environment
-- Purpose  : Full initialization of demo environment
--            (security, catalogs, test labs,
--             test equipment, test reservations,
--             test loans and test incidents)
-- ==============================================

CREATE PROCEDURE sp_initialize_demo_environment()
BEGIN
    /* ==============================
       1. Declare local variables
       ============================== */
    DECLARE v_reference_date DATETIME;
    DECLARE v_range_start   DATETIME;
    DECLARE v_range_end     DATETIME;

    /* ==============================
       2. Initialize reference dates
       ============================== */
    SET v_reference_date = CURRENT_TIMESTAMP;
    SET v_range_start    = DATE_SUB(v_reference_date, INTERVAL 7 DAY);
    SET v_range_end      = DATE_ADD(v_reference_date, INTERVAL 7 DAY);

    /* ==============================
       3. Seed security (roles, permissions, test users)
       ============================== */
    CALL sp_seed_all_security();

    /* ==============================
       4. Seed catalog tables
          (equipment types, statuses,
           retirement causes, reasons,
           incident types, severities)
       ============================== */
    CALL sp_seed_all_catalogs();

    /* ==============================
       5. Seed test labs and equipment
       ============================== */
    CALL sp_seed_test_labs();
    CALL sp_seed_test_equipment();

    /* ==============================
       6. Seed test lab reservations
          using date range
       ============================== */
    CALL sp_seed_test_lab_reservations(v_range_start, v_range_end);

    /* ==============================
       7. Seed test loans
          using reference date
       ============================== */
    CALL sp_seed_test_loans(v_reference_date);

    /* ==============================
       8. Seed test incidents
          using reference date
       ============================== */
    CALL sp_seed_test_incidents(v_reference_date);

-- CALL sp_initialize_demo_environment();
END

//

DELIMITER ;

