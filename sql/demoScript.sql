DROP PROCEDURE IF EXISTS sp_seed_full_demo_environment;
DELIMITER //

-- ==============================================
-- Procedure: sp_seed_full_demo_environment
-- Purpose  : Massive random-controlled DEMO seeding
--           (users, labs, equipment, reservations,
--            loans, maintenance, movements, incidents)
-- ==============================================

CREATE PROCEDURE sp_seed_full_demo_environment()
BEGIN
    /* ==============================
       1. Declare variables
       ============================== */
    DECLARE v_now               DATETIME;
    DECLARE v_semester_start    DATE;
    DECLARE v_days_range        INT;

    DECLARE i                   INT;
    DECLARE v_user_id           INT;
    DECLARE v_phone_base        INT;

    DECLARE v_eq_counter        INT;
    DECLARE v_equipment_type_id INT;
    DECLARE v_equipment_status_id INT;
    DECLARE v_equipment_lab_id  INT;
    DECLARE v_retirement_cause_id INT;
    DECLARE v_inventory_tag     VARCHAR(120);
    DECLARE v_serial            VARCHAR(120);
    DECLARE v_purchase_date     DATE;
    DECLARE v_cost              DECIMAL(12,2);
    DECLARE v_decomissioned     BOOLEAN;
    DECLARE v_retirement_date   DATETIME;

    DECLARE v_status_available_id      INT;
    DECLARE v_status_on_loan_id        INT;
    DECLARE v_status_in_maintenance_id INT;
    DECLARE v_status_retired_id        INT;

    DECLARE v_res_counter        INT;
    DECLARE v_res_lab_id         INT;
    DECLARE v_res_user_id        INT;
    DECLARE v_res_reason_id      INT;
    DECLARE v_res_start          DATETIME;
    DECLARE v_res_end            DATETIME;
    DECLARE v_random_day         INT;
    DECLARE v_random_hour        INT;
    DECLARE v_duration_hours     INT;
    DECLARE v_res_status         VARCHAR(20);

    DECLARE v_loan_counter       INT;
    DECLARE v_loan_equipment_id  INT;
    DECLARE v_loan_requester_id  INT;
    DECLARE v_loan_issuer_id     INT;
    DECLARE v_loan_receiver_id   INT;
    DECLARE v_loan_date          DATETIME;
    DECLARE v_due_date           DATETIME;
    DECLARE v_return_date        DATETIME;
    DECLARE v_loan_status        VARCHAR(20);
    DECLARE v_r                  DOUBLE;

    DECLARE v_maint_counter      INT;
    DECLARE v_maint_equipment_id INT;
    DECLARE v_maint_start        DATETIME;
    DECLARE v_maint_end          DATETIME;
    DECLARE v_maint_cost         DECIMAL(12,2);
    DECLARE v_maint_performed_by VARCHAR(150);
    DECLARE v_maint_desc         TEXT;
    DECLARE v_maint_type         VARCHAR(20);

    DECLARE v_move_counter       INT;
    DECLARE v_move_equipment_id  INT;
    DECLARE v_move_lab_origin_id INT;
    DECLARE v_move_lab_dest_id   INT;
    DECLARE v_move_loan_origin_id INT;
    DECLARE v_move_loan_dest_id   INT;
    DECLARE v_move_note          VARCHAR(255);

    DECLARE v_inc_counter        INT;
    DECLARE v_inc_equipment_id   INT;
    DECLARE v_inc_lab_id         INT;
    DECLARE v_inc_reporter_id    INT;
    DECLARE v_inc_assigned_id    INT;
    DECLARE v_inc_loan_id        INT;
    DECLARE v_inc_type_id        INT;
    DECLARE v_inc_severity_id    INT;
    DECLARE v_inc_desc           TEXT;
    DECLARE v_inc_reported_at    DATETIME;
    DECLARE v_inc_status         VARCHAR(20);
    DECLARE v_inc_closed_at      DATETIME;
    DECLARE v_inc_resolution     TEXT;

    /* ==============================
       2. Initialize time range
       ============================== */
    SET v_now = CURRENT_TIMESTAMP;
    SET v_semester_start = DATE('2025-01-10');
    SET v_days_range = DATEDIFF(DATE(v_now), v_semester_start);
    IF v_days_range < 30 THEN
        SET v_days_range = 90;
    END IF;

    /* ==============================
       3. Base seed: security + catalogs + base labs/equipment
       ============================== */
    CALL sp_seed_all_security();
    CALL sp_seed_all_catalogs();
    CALL sp_seed_test_labs();
    CALL sp_seed_test_equipment();

    /* ==============================
       4. Cache equipment_status IDs
       ============================== */
    SELECT id INTO v_status_available_id
    FROM equipment_status
    WHERE name = 'available'
    LIMIT 1;

    SELECT id INTO v_status_on_loan_id
    FROM equipment_status
    WHERE name = 'on_loan'
    LIMIT 1;

    SELECT id INTO v_status_in_maintenance_id
    FROM equipment_status
    WHERE name = 'in_maintenance'
    LIMIT 1;

    SELECT id INTO v_status_retired_id
    FROM equipment_status
    WHERE name = 'retired'
    LIMIT 1;

    /* ==============================
       5. Extra demo users (admins, labtechs, professors, students)
       ============================== */
    SET v_phone_base = 550000000;

    /* --- Extra admins (2) --- */
    SET i = 1;
    WHILE i <= 2 DO
        INSERT INTO `user`(`name`, first_lastname, second_lastname, `active`, `password`)
        VALUES (
            CONCAT('Admin Demo ', i),
            'Demo',
            NULL,
            TRUE,
            CONCAT('admin_demo_', i)
        );
        SET v_user_id = LAST_INSERT_ID();

        INSERT INTO user_mail(user_id, mail)
        VALUES (v_user_id, CONCAT('admin.demo', i, '@demo.uni'));

        INSERT INTO user_phone(user_id, phone)
        VALUES (v_user_id, v_phone_base + i);

        CALL sp_assign_role_to_user(v_user_id, 'admin');

        SET i = i + 1;
    END WHILE;

    /* --- Extra labtechs (4) --- */
    SET i = 1;
    WHILE i <= 4 DO
        INSERT INTO `user`(`name`, first_lastname, second_lastname, `active`, `password`)
        VALUES (
            CONCAT('LabTech Demo ', i),
            'Demo',
            NULL,
            TRUE,
            CONCAT('labtech_demo_', i)
        );
        SET v_user_id = LAST_INSERT_ID();

        INSERT INTO user_mail(user_id, mail)
        VALUES (v_user_id, CONCAT('labtech.demo', i, '@demo.uni'));

        INSERT INTO user_phone(user_id, phone)
        VALUES (v_user_id, v_phone_base + 100 + i);

        CALL sp_assign_role_to_user(v_user_id, 'labtech');

        SET i = i + 1;
    END WHILE;

    /* --- Extra professors (6) --- */
    SET i = 1;
    WHILE i <= 6 DO
        INSERT INTO `user`(`name`, first_lastname, second_lastname, `active`, `password`)
        VALUES (
            CONCAT('Professor Demo ', i),
            'Faculty',
            NULL,
            TRUE,
            CONCAT('prof_demo_', i)
        );
        SET v_user_id = LAST_INSERT_ID();

        INSERT INTO user_mail(user_id, mail)
        VALUES (v_user_id, CONCAT('professor.demo', i, '@demo.uni'));

        INSERT INTO user_phone(user_id, phone)
        VALUES (v_user_id, v_phone_base + 200 + i);

        CALL sp_assign_role_to_user(v_user_id, 'professor');

        SET i = i + 1;
    END WHILE;

    /* --- Extra students (18, últimos 2 inactivos) --- */
    SET i = 1;
    WHILE i <= 18 DO
        INSERT INTO `user`(`name`, first_lastname, second_lastname, `active`, `password`)
        VALUES (
            CONCAT('Student Demo ', i),
            'Student',
            NULL,
            (i <= 16),  -- últimos 2 inactivos
            CONCAT('student_demo_', i)
        );
        SET v_user_id = LAST_INSERT_ID();

        INSERT INTO user_mail(user_id, mail)
        VALUES (v_user_id, CONCAT('student.demo', i, '@demo.uni'));

        INSERT INTO user_phone(user_id, phone)
        VALUES (v_user_id, v_phone_base + 300 + i);

        CALL sp_assign_role_to_user(v_user_id, 'student');

        SET i = i + 1;
    END WHILE;

    /* ==============================
       6. Extra labs (7 nuevos)
       ============================== */
    INSERT IGNORE INTO lab(`name`, building, `floor`, capacity, `description`, `active`) VALUES
        ('Chemistry Lab 1', 'Science Block', 1, 24, 'Basic chemistry experiments', TRUE),
        ('Chemistry Lab 2', 'Science Block', 2, 24, 'Advanced chemistry and analysis', TRUE),
        ('Robotics Lab', 'Engineering Center', 1, 20, 'Robotics and automation projects', TRUE),
        ('Materials Lab', 'Engineering Center', 2, 18, 'Materials testing and characterization', TRUE),
        ('Computer Lab B', 'Tech Center', 3, 35, 'Programming and simulations', TRUE),
        ('Networks Lab', 'Tech Center', 2, 22, 'Networking and communication systems', TRUE),
        ('IoT Lab', 'Innovation Hub', 1, 16, 'Internet of Things prototypes', TRUE);

    /* ==============================
       7. Extra equipment (60 equipos aleatorios)
       ============================== */
    SET v_eq_counter = 1;
    WHILE v_eq_counter <= 60 DO
        /* 7.1 random type, lab */
        SELECT id INTO v_equipment_type_id
        FROM equipment_type
        ORDER BY RAND()
        LIMIT 1;

        SELECT id INTO v_equipment_lab_id
        FROM lab
        ORDER BY RAND()
        LIMIT 1;

        /* 7.2 random status & decomissioned flag */
        SET v_r = RAND();
        IF v_r < 0.10 THEN
            SET v_decomissioned = TRUE;
            SET v_equipment_status_id = v_status_retired_id;
        ELSEIF v_r < 0.25 THEN
            SET v_decomissioned = FALSE;
            SET v_equipment_status_id = v_status_in_maintenance_id;
        ELSE
            SET v_decomissioned = FALSE;
            SET v_equipment_status_id = v_status_available_id;
        END IF;

        /* 7.3 retirement cause if decomissioned */
        IF v_decomissioned THEN
            SELECT id INTO v_retirement_cause_id
            FROM retirement_cause
            ORDER BY RAND()
            LIMIT 1;
        ELSE
            SET v_retirement_cause_id = NULL;
        END IF;

        /* 7.4 inventory/serial unique-like */
        SET v_inventory_tag = CONCAT('EQ-DEMO-', LPAD(v_eq_counter, 4, '0'));
        SET v_serial        = CONCAT('SN-DEMO-', LPAD(v_eq_counter, 4, '0'));

        /* 7.5 purchase_date, cost, retirement_date */
        SET v_random_day    = FLOOR(RAND() * v_days_range);
        SET v_purchase_date = DATE_ADD(v_semester_start, INTERVAL v_random_day DAY);

        SET v_cost = 500 + FLOOR(RAND() * 19500); -- 500 a ~20000

        IF v_decomissioned THEN
            SET v_retirement_date = DATE_ADD(v_purchase_date, INTERVAL 365 DAY);
            IF v_retirement_date > v_now THEN
                SET v_retirement_date = v_now;
            END IF;
        ELSE
            SET v_retirement_date = NULL;
        END IF;

        /* 7.6 insert equipment */
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
        VALUES (
            v_equipment_type_id,
            v_equipment_lab_id,
            v_equipment_status_id,
            v_retirement_cause_id,
            v_inventory_tag,
            v_serial,
            v_purchase_date,
            v_cost,
            v_decomissioned,
            v_retirement_date
        );

        SET v_eq_counter = v_eq_counter + 1;
    END WHILE;

    /* ==============================
       8. Lab reservations (50 aleatorias)
       ============================== */
    SET v_res_counter = 1;
    WHILE v_res_counter <= 50 DO
        /* 8.1 random lab */
        SELECT id INTO v_res_lab_id
        FROM lab
        ORDER BY RAND()
        LIMIT 1;

        /* 8.2 random user (professor or student) */
        SELECT u.id INTO v_res_user_id
        FROM `user` u
        JOIN user_role ur ON ur.user_id = u.id
        JOIN `role`  r  ON r.id = ur.role_id
        WHERE r.name IN ('professor','student')
        ORDER BY RAND()
        LIMIT 1;

        /* 8.3 random reservation reason */
        SELECT id INTO v_res_reason_id
        FROM reservation_reason
        ORDER BY RAND()
        LIMIT 1;

        /* 8.4 time window: random day & hour */
        SET v_random_day   = FLOOR(RAND() * v_days_range);
        SET v_random_hour  = 8 + FLOOR(RAND() * 10);  -- 8 to 17
        SET v_duration_hours = 1 + FLOOR(RAND() * 3); -- 1 to 3h

        SET v_res_start = DATE_ADD(
                            DATE_ADD(v_semester_start, INTERVAL v_random_day DAY),
                            INTERVAL v_random_hour HOUR
                          );
        SET v_res_end   = DATE_ADD(v_res_start, INTERVAL v_duration_hours HOUR);

        /* 8.5 reservation_status distribution */
        SET v_r = RAND();
        IF v_r < 0.60 THEN
            SET v_res_status = 'approved';
        ELSEIF v_r < 0.80 THEN
            SET v_res_status = 'pending';
        ELSEIF v_r < 0.90 THEN
            SET v_res_status = 'canceled';
        ELSE
            SET v_res_status = 'rejected';
        END IF;

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
            v_res_lab_id,
            v_res_user_id,
            v_res_reason_id,
            v_res_start,
            v_res_end,
            v_res_status,
            CONCAT('Demo reservation #', v_res_counter)
        );

        SET v_res_counter = v_res_counter + 1;
    END WHILE;

    /* ==============================
       9. Equipment loans (80 aleatorios)
       ============================== */
    SET v_loan_counter = 1;
    WHILE v_loan_counter <= 80 DO
        /* 9.1 random active equipment (not decomissioned) */
        SELECT id INTO v_loan_equipment_id
        FROM equipment
        WHERE decomissioned = FALSE
        ORDER BY RAND()
        LIMIT 1;

        /* 9.2 requester (professor or student) */
        SELECT u.id INTO v_loan_requester_id
        FROM `user` u
        JOIN user_role ur ON ur.user_id = u.id
        JOIN `role`  r  ON r.id = ur.role_id
        WHERE r.name IN ('professor','student')
        ORDER BY RAND()
        LIMIT 1;

        /* 9.3 issuer (labtech or admin) */
        SELECT u.id INTO v_loan_issuer_id
        FROM `user` u
        JOIN user_role ur ON ur.user_id = u.id
        JOIN `role`  r  ON r.id = ur.role_id
        WHERE r.name IN ('labtech','admin')
        ORDER BY RAND()
        LIMIT 1;

        /* 9.4 loan_date & due_date */
        SET v_random_day = FLOOR(RAND() * v_days_range);
        SET v_loan_date  = DATE_ADD(
                             v_semester_start,
                             INTERVAL v_random_day DAY
                           );
        SET v_due_date   = DATE_ADD(v_loan_date, INTERVAL (3 + FLOOR(RAND() * 10)) DAY);

        /* 9.5 status & return_date, receiver */
        SET v_r = RAND();
        IF v_r < 0.50 THEN
            SET v_loan_status = 'active';
            SET v_return_date = NULL;
            SET v_loan_receiver_id = NULL;
        ELSEIF v_r < 0.80 THEN
            SET v_loan_status = 'returned';
            SET v_return_date = DATE_ADD(v_loan_date, INTERVAL (1 + FLOOR(RAND() * 12)) DAY);
            IF v_return_date > v_now THEN
                SET v_return_date = v_now;
            END IF;

            SELECT u.id INTO v_loan_receiver_id
            FROM `user` u
            JOIN user_role ur ON ur.user_id = u.id
            JOIN `role`  r  ON r.id = ur.role_id
            WHERE r.name IN ('labtech','admin')
            ORDER BY RAND()
            LIMIT 1;
        ELSEIF v_r < 0.95 THEN
            SET v_loan_status = 'overdue';
            SET v_return_date = NULL;
            SET v_loan_receiver_id = NULL;
        ELSE
            SET v_loan_status = 'canceled';
            SET v_return_date = NULL;
            SET v_loan_receiver_id = NULL;
        END IF;

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
            v_loan_equipment_id,
            v_loan_requester_id,
            v_loan_issuer_id,
            v_loan_receiver_id,
            v_loan_date,
            v_due_date,
            v_return_date,
            v_loan_status,
            CONCAT('Demo loan #', v_loan_counter)
        );

        /* 9.6 if active, mark equipment as on_loan */
        IF v_loan_status = 'active' THEN
            UPDATE equipment
            SET equipment_status_id = v_status_on_loan_id
            WHERE id = v_loan_equipment_id;
        END IF;

        SET v_loan_counter = v_loan_counter + 1;
    END WHILE;

    /* ==============================
       10. Maintenance records (25 aleatorios)
       ============================== */
    SET v_maint_counter = 1;
    WHILE v_maint_counter <= 25 DO
        SELECT id INTO v_maint_equipment_id
        FROM equipment
        ORDER BY RAND()
        LIMIT 1;

        SET v_random_day  = FLOOR(RAND() * v_days_range);
        SET v_maint_start = DATE_ADD(
                              v_semester_start,
                              INTERVAL v_random_day DAY
                            );
        SET v_maint_end   = DATE_ADD(v_maint_start, INTERVAL (1 + FLOOR(RAND() * 3)) DAY);

        SET v_maint_cost  = 200 + FLOOR(RAND() * 4800); -- 200 a ~5000

        IF RAND() < 0.5 THEN
            SET v_maint_type = 'preventive';
            SET v_maint_desc = 'Routine preventive maintenance and calibration.';
        ELSE
            SET v_maint_type = 'corrective';
            SET v_maint_desc = 'Corrective maintenance to fix reported issues.';
        END IF;

        SET v_maint_performed_by = CONCAT('Tech Team ', 1 + FLOOR(RAND()*5));

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
            v_maint_equipment_id,
            v_maint_type,
            v_maint_desc,
            v_maint_start,
            v_maint_end,
            v_maint_cost,
            v_maint_performed_by
        );

        SET v_maint_counter = v_maint_counter + 1;
    END WHILE;

    /* ==============================
       11. Equipment movements (30 aleatorios)
       ============================== */
    SET v_move_counter = 1;
    WHILE v_move_counter <= 30 DO
        SELECT id INTO v_move_equipment_id
        FROM equipment
        ORDER BY RAND()
        LIMIT 1;

        /* random origin & destination labs (pueden coincidir a veces) */
        SELECT id INTO v_move_lab_origin_id
        FROM lab
        ORDER BY RAND()
        LIMIT 1;

        SELECT id INTO v_move_lab_dest_id
        FROM lab
        ORDER BY RAND()
        LIMIT 1;

        /* random loans as origin/dest (muchas veces NULL) */
        IF RAND() < 0.4 THEN
            SELECT id INTO v_move_loan_origin_id
            FROM loan
            ORDER BY RAND()
            LIMIT 1;
        ELSE
            SET v_move_loan_origin_id = NULL;
        END IF;

        IF RAND() < 0.3 THEN
            SELECT id INTO v_move_loan_dest_id
            FROM loan
            ORDER BY RAND()
            LIMIT 1;
        ELSE
            SET v_move_loan_dest_id = NULL;
        END IF;

        SET v_move_note = CONCAT('Demo movement #', v_move_counter);

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
            v_move_equipment_id,
            v_move_lab_origin_id,
            v_move_loan_origin_id,
            v_move_lab_dest_id,
            v_move_loan_dest_id,
            DATE_ADD(
                v_semester_start,
                INTERVAL FLOOR(RAND() * v_days_range) DAY
            ),
            v_move_note
        );

        SET v_move_counter = v_move_counter + 1;
    END WHILE;

    /* ==============================
       12. Incidents (40 aleatorios)
       ============================== */
    SET v_inc_counter = 1;
    WHILE v_inc_counter <= 40 DO
        /* 12.1 random equipment + lab */
        SELECT e.id, e.lab_id
        INTO v_inc_equipment_id, v_inc_lab_id
        FROM equipment e
        ORDER BY RAND()
        LIMIT 1;

        /* 12.2 reporter (cualquier user activo) */
        SELECT u.id INTO v_inc_reporter_id
        FROM `user` u
        WHERE u.active = TRUE
        ORDER BY RAND()
        LIMIT 1;

        /* 12.3 assigned (labtech/admin, o NULL) */
        IF RAND() < 0.7 THEN
            SELECT u.id INTO v_inc_assigned_id
            FROM `user` u
            JOIN user_role ur ON ur.user_id = u.id
            JOIN `role`  r  ON r.id = ur.role_id
            WHERE r.name IN ('labtech','admin')
            ORDER BY RAND()
            LIMIT 1;
        ELSE
            SET v_inc_assigned_id = NULL;
        END IF;

        /* 12.4 random loan id (cualquiera, no necesariamente del equipo) */
        IF RAND() < 0.7 THEN
            SELECT id INTO v_inc_loan_id
            FROM loan
            ORDER BY RAND()
            LIMIT 1;
        ELSE
            SET v_inc_loan_id = NULL;
        END IF;

        /* 12.5 type & severity */
        SELECT id INTO v_inc_type_id
        FROM incident_type
        ORDER BY RAND()
        LIMIT 1;

        SELECT id INTO v_inc_severity_id
        FROM severity
        ORDER BY RAND()
        LIMIT 1;

        /* 12.6 tiempos y estado */
        SET v_random_day    = FLOOR(RAND() * v_days_range);
        SET v_inc_reported_at = DATE_ADD(
                                   v_semester_start,
                                   INTERVAL v_random_day DAY
                                );

        SET v_r = RAND();
        IF v_r < 0.4 THEN
            SET v_inc_status    = 'open';
            SET v_inc_closed_at = NULL;
            SET v_inc_resolution = NULL;
        ELSEIF v_r < 0.7 THEN
            SET v_inc_status    = 'in_progress';
            SET v_inc_closed_at = NULL;
            SET v_inc_resolution = NULL;
        ELSE
            SET v_inc_status    = 'closed';
            SET v_inc_closed_at = DATE_ADD(v_inc_reported_at, INTERVAL (1 + FLOOR(RAND()*5)) DAY);
            IF v_inc_closed_at > v_now THEN
                SET v_inc_closed_at = v_now;
            END IF;
            SET v_inc_resolution = 'Issue resolved during demo incident workflow.';
        END IF;

        SET v_inc_desc = CONCAT('Demo incident #', v_inc_counter, ' generated for testing.');

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
        VALUES (
            v_inc_equipment_id,
            v_inc_lab_id,
            v_inc_reporter_id,
            v_inc_assigned_id,
            v_inc_loan_id,
            v_inc_type_id,
            v_inc_severity_id,
            v_inc_desc,
            v_inc_reported_at,
            v_inc_status,
            v_inc_closed_at,
            v_inc_resolution
        );

        SET v_inc_counter = v_inc_counter + 1;
    END WHILE;

    /* ==============================
       13. Final small consistency fix:
           retired equipment -> status retired
       ============================== */
    UPDATE equipment
    SET equipment_status_id = v_status_retired_id
    WHERE decomissioned = TRUE;

-- CALL sp_seed_full_demo_environment();
END
//

DELIMITER ;

CALL sp_seed_full_demo_environment();
