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
        p_room_id        IN NUMBER,
        p_check_in_date  IN DATE,
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
        p_guest_id        IN NUMBER,
        p_check_in_date   IN DATE,
        p_check_out_date  IN DATE,
        p_total_guests    IN NUMBER,
        p_reservation_id  OUT NUMBER
    )
    IS
        lv_guest_count NUMBER;
    BEGIN

        -- Validate guest exists and is not anonymized
        SELECT COUNT(*)
        INTO lv_guest_count
        FROM guest
        WHERE guest_id = p_guest_id
          AND is_anonymized = 'N';

        IF lv_guest_count = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20001,
                'Guest does not exist or has been anonymized.'
            );
        END IF;


        IF p_check_out_date <= p_check_in_date THEN
            RAISE_APPLICATION_ERROR(
                -20002,
                'Check-out date must be after check-in date.'
            );
        END IF;


        IF p_total_guests <= 0 THEN
            RAISE_APPLICATION_ERROR(
                -20003,
                'Reservation must include at least one guest.'
            );
        END IF;


        INSERT INTO hotel_reservation (
            guest_id,
            check_in_date,
            check_out_date,
            total_guests
        )
        VALUES (
            p_guest_id,
            p_check_in_date,
            p_check_out_date,
            p_total_guests
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
        lv_check_in_date   DATE;
        lv_check_out_date  DATE;
        lv_max_occupancy   NUMBER;
        lv_room_status     VARCHAR2(20);
    BEGIN

        -- Get reservation dates
        SELECT check_in_date,
               check_out_date
        INTO lv_check_in_date,
             lv_check_out_date
        FROM hotel_reservation
        WHERE reservation_id = p_reservation_id;


        -- Get room information
        SELECT rt.max_occupancy,
               r.operational_status
        INTO lv_max_occupancy,
             lv_room_status
        FROM room r
        JOIN room_type rt
            ON rt.room_type_id = r.room_type_id
        WHERE r.room_id = p_room_id;


        -- Room cannot be used if out of service
        IF lv_room_status IN (
            'MAINTENANCE',
            'OUT_OF_SERVICE'
        ) THEN
            RAISE_APPLICATION_ERROR(
                -20004,
                'Room is not currently available for booking.'
            );
        END IF;


        -- Validate occupancy
        IF p_occupants > lv_max_occupancy THEN
            RAISE_APPLICATION_ERROR(
                -20005,
                'Occupancy exceeds room maximum.'
            );
        END IF;


        IF p_occupants <= 0 THEN
            RAISE_APPLICATION_ERROR(
                -20006,
                'Room must contain at least one occupant.'
            );
        END IF;


        IF p_nightly_rate < 0 THEN
            RAISE_APPLICATION_ERROR(
                -20007,
                'Nightly rate cannot be negative.'
            );
        END IF;


        -- Validate date availability
        IF NOT is_room_available(
            p_room_id,
            lv_check_in_date,
            lv_check_out_date
        ) THEN
            RAISE_APPLICATION_ERROR(
                -20008,
                'Room is already reserved for the requested dates.'
            );
        END IF;


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

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20009,
                'Reservation or room could not be found.'
            );

    END add_room_to_reservation;



    -- =====================================================
    -- PROCEDURE: validate_guest_count
    -- =====================================================

    PROCEDURE validate_guest_count (
        p_reservation_id IN NUMBER
    )
    IS
        lv_total_guests      NUMBER;
        lv_total_occupants   NUMBER;
    BEGIN

        SELECT total_guests
        INTO lv_total_guests
        FROM hotel_reservation
        WHERE reservation_id = p_reservation_id;


        SELECT NVL(SUM(occupants), 0)
        INTO lv_total_occupants
        FROM reservation_room
        WHERE reservation_id = p_reservation_id;


        IF lv_total_guests != lv_total_occupants THEN
            RAISE_APPLICATION_ERROR(
                -20010,
                'Reservation guest count does not match room occupancy.'
            );
        END IF;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20011,
                'Reservation could not be found.'
            );

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