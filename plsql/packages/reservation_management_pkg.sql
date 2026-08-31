-- =========================================================
-- Hospitality Management System
-- plsql/packages/reservation_management_pkg.sql
-- =========================================================


CREATE OR REPLACE PACKAGE reservation_management_pkg AS

    FUNCTION is_room_available (
        p_room_id        IN NUMBER,
        p_check_in_date  IN DATE,
        p_check_out_date IN DATE
    ) RETURN BOOLEAN;


    PROCEDURE create_reservation (
        p_guest_id        IN NUMBER,
        p_check_in_date   IN DATE,
        p_check_out_date  IN DATE,
        p_total_guests    IN NUMBER,
        p_reservation_id  OUT NUMBER
    );


    PROCEDURE add_room_to_reservation (
        p_reservation_id IN NUMBER,
        p_room_id        IN NUMBER,
        p_nightly_rate   IN NUMBER,
        p_occupants      IN NUMBER
    );


    PROCEDURE validate_guest_count (
        p_reservation_id IN NUMBER
    );

END reservation_management_pkg;
/

CREATE OR REPLACE PACKAGE BODY reservation_management_pkg AS


    -- =====================================================
    -- FUNCTION: is_room_available
    -- =====================================================

    FUNCTION is_room_available (
        p_room_id       IN NUMBER,
        p_check_in_date IN DATE,
        p_check_out_date IN DATE
    ) RETURN BOOLEAN
    IS
        lv_count NUMBER;
    BEGIN

        SELECT COUNT(*)
        INTO lv_count
        FROM reservation_room rr
        JOIN hotel_reservation hr
            ON hr.reservation_id = rr.reservation_id
        WHERE rr.room_id = p_room_id
          AND hr.reservation_status NOT IN (
              'CANCELLED',
              'NO_SHOW'
          )
          AND p_check_in_date < hr.check_out_date
          AND p_check_out_date > hr.check_in_date;

        RETURN lv_count = 0;

    END is_room_available;



    -- =====================================================
    -- PROCEDURE: create_reservation
    -- =====================================================

    PROCEDURE create_reservation (
        p_guest_id       IN NUMBER,
        p_check_in_date  IN DATE,
        p_check_out_date IN DATE,
        p_total_guests   IN NUMBER,
        p_reservation_id OUT NUMBER
    )
    IS
        lv_guest_anonymized guest.is_anonymized%TYPE;
    BEGIN

        -- ---------------------------------------------
        -- Validate guest
        -- ---------------------------------------------

        BEGIN
            SELECT is_anonymized
            INTO lv_guest_anonymized
            FROM guest
            WHERE guest_id = p_guest_id;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(
                    -20001,
                    'Guest could not be found.'
                );
        END;


        IF lv_guest_anonymized = 'Y' THEN
            RAISE_APPLICATION_ERROR(
                -20002,
                'Anonymized guests cannot create reservations.'
            );
        END IF;


        -- ---------------------------------------------
        -- Validate dates
        -- ---------------------------------------------

        IF p_check_in_date IS NULL
           OR p_check_out_date IS NULL
        THEN
            RAISE_APPLICATION_ERROR(
                -20003,
                'Check-in and check-out dates are required.'
            );
        END IF;


        IF p_check_out_date <= p_check_in_date THEN
            RAISE_APPLICATION_ERROR(
                -20004,
                'Check-out date must be after check-in date.'
            );
        END IF;


        -- ---------------------------------------------
        -- Validate guest count
        -- ---------------------------------------------

        IF p_total_guests IS NULL
           OR p_total_guests <= 0
        THEN
            RAISE_APPLICATION_ERROR(
                -20005,
                'Total guests must be greater than zero.'
            );
        END IF;


        -- ---------------------------------------------
        -- Create reservation
        -- ---------------------------------------------

        INSERT INTO hotel_reservation (
            guest_id,
            check_in_date,
            check_out_date,
            total_guests,
            reservation_status
        )
        VALUES (
            p_guest_id,
            p_check_in_date,
            p_check_out_date,
            p_total_guests,
            'BOOKED'
        )
        RETURNING reservation_id
        INTO p_reservation_id;

    END create_reservation;



    -- =====================================================
    -- PROCEDURE: add_room_to_reservation
    -- =====================================================

    PROCEDURE add_room_to_reservation (
        p_reservation_id IN NUMBER,
        p_room_id        IN NUMBER,
        p_nightly_rate   IN NUMBER,
        p_occupants      IN NUMBER
    )
    IS
        lv_check_in_date      DATE;
        lv_check_out_date     DATE;
        lv_res_status         hotel_reservation.reservation_status%TYPE;

        lv_max_occupancy      NUMBER;
        lv_room_status        room.operational_status%TYPE;

        lv_duplicate_count    NUMBER;
    BEGIN

        -- ---------------------------------------------
        -- Validate reservation
        -- ---------------------------------------------

        BEGIN
            SELECT
                check_in_date,
                check_out_date,
                reservation_status
            INTO
                lv_check_in_date,
                lv_check_out_date,
                lv_res_status
            FROM hotel_reservation
            WHERE reservation_id = p_reservation_id;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(
                    -20006,
                    'Reservation could not be found.'
                );
        END;


        IF lv_res_status != 'BOOKED' THEN
            RAISE_APPLICATION_ERROR(
                -20007,
                'Rooms can only be added to booked reservations.'
            );
        END IF;


        -- ---------------------------------------------
        -- Validate room
        -- ---------------------------------------------

        BEGIN
            SELECT
                rt.max_occupancy,
                r.operational_status
            INTO
                lv_max_occupancy,
                lv_room_status
            FROM room r
            JOIN room_type rt
                ON rt.room_type_id = r.room_type_id
            WHERE r.room_id = p_room_id;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(
                    -20008,
                    'Room could not be found.'
                );
        END;


        IF lv_room_status IN (
            'MAINTENANCE',
            'OUT_OF_SERVICE'
        ) THEN
            RAISE_APPLICATION_ERROR(
                -20009,
                'Room is not operationally available.'
            );
        END IF;


        -- ---------------------------------------------
        -- Validate occupants
        -- ---------------------------------------------

        IF p_occupants IS NULL
           OR p_occupants <= 0
        THEN
            RAISE_APPLICATION_ERROR(
                -20010,
                'Occupants must be greater than zero.'
            );
        END IF;


        IF p_occupants > lv_max_occupancy THEN
            RAISE_APPLICATION_ERROR(
                -20011,
                'Occupants exceed room maximum occupancy of '
                || lv_max_occupancy || '.'
            );
        END IF;


        -- ---------------------------------------------
        -- Validate nightly rate
        -- ---------------------------------------------

        IF p_nightly_rate IS NULL
           OR p_nightly_rate < 0
        THEN
            RAISE_APPLICATION_ERROR(
                -20012,
                'Nightly rate cannot be negative.'
            );
        END IF;


        -- ---------------------------------------------
        -- Prevent same room being attached twice
        -- ---------------------------------------------

        SELECT COUNT(*)
        INTO lv_duplicate_count
        FROM reservation_room
        WHERE reservation_id = p_reservation_id
          AND room_id = p_room_id;


        IF lv_duplicate_count > 0 THEN
            RAISE_APPLICATION_ERROR(
                -20013,
                'Room is already assigned to this reservation.'
            );
        END IF;


        -- ---------------------------------------------
        -- Validate date availability
        -- ---------------------------------------------

        IF NOT is_room_available(
            p_room_id,
            lv_check_in_date,
            lv_check_out_date
        ) THEN
            RAISE_APPLICATION_ERROR(
                -20014,
                'Room is not available for the requested dates.'
            );
        END IF;


        -- ---------------------------------------------
        -- Assign room
        -- ---------------------------------------------

        INSERT INTO reservation_room (
            reservation_id,
            room_id,
            nightly_rate,
            occupants
        )
        VALUES (
            p_reservation_id,
            p_room_id,
            p_nightly_rate,
            p_occupants
        );

    END add_room_to_reservation;



    -- =====================================================
    -- PROCEDURE: validate_guest_count
    -- =====================================================

    PROCEDURE validate_guest_count (
        p_reservation_id IN NUMBER
    )
    IS
        lv_total_guests       NUMBER;
        lv_assigned_occupants NUMBER;
    BEGIN

        -- ---------------------------------------------
        -- Validate reservation
        -- ---------------------------------------------

        BEGIN
            SELECT total_guests
            INTO lv_total_guests
            FROM hotel_reservation
            WHERE reservation_id = p_reservation_id;

        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE_APPLICATION_ERROR(
                    -20015,
                    'Reservation could not be found.'
                );
        END;


        SELECT NVL(SUM(occupants), 0)
        INTO lv_assigned_occupants
        FROM reservation_room
        WHERE reservation_id = p_reservation_id;


        IF lv_assigned_occupants != lv_total_guests THEN
            RAISE_APPLICATION_ERROR(
                -20016,
                'Assigned occupants ('
                || lv_assigned_occupants
                || ') do not match reservation guest count ('
                || lv_total_guests
                || ').'
            );
        END IF;

    END validate_guest_count;


END reservation_management_pkg;
/

DECLARE
    lv_reservation_id NUMBER;
BEGIN

    reservation_management_pkg.create_reservation(
        p_guest_id       => 1,
        p_check_in_date  => DATE '2026-09-10',
        p_check_out_date => DATE '2026-09-13',
        p_total_guests   => 3,
        p_reservation_id => lv_reservation_id
    );

    reservation_management_pkg.add_room_to_reservation(
        p_reservation_id => lv_reservation_id,
        p_room_id        => 1,
        p_nightly_rate   => 220,
        p_occupants      => 2
    );

    reservation_management_pkg.add_room_to_reservation(
        p_reservation_id => lv_reservation_id,
        p_room_id        => 5,
        p_nightly_rate   => 310,
        p_occupants      => 1
    );

    reservation_management_pkg.validate_guest_count(
        lv_reservation_id
    );

    DBMS_OUTPUT.PUT_LINE(
        'Reservation created: ' || lv_reservation_id
    );

END;
/

COMMIT;

SELECT
    hr.reservation_id,
    g.first_name,
    g.last_name,
    hr.check_in_date,
    hr.check_out_date,
    r.room_number,
    rr.occupants,
    rr.nightly_rate
FROM hotel_reservation hr
JOIN guest g
    ON g.guest_id = hr.guest_id
JOIN reservation_room rr
    ON rr.reservation_id = hr.reservation_id
JOIN room r
    ON r.room_id = rr.room_id
ORDER BY hr.reservation_id, r.room_number;
