CREATE OR REPLACE PACKAGE stay_folio_management_pkg AS

    FUNCTION calculate_room_charges (
        p_reservation_id IN NUMBER
    ) RETURN NUMBER;


    FUNCTION get_folio_balance (
        p_folio_id IN NUMBER
    ) RETURN NUMBER;


    PROCEDURE check_in_reservation (
        p_reservation_id IN NUMBER,
        p_stay_id        OUT NUMBER,
        p_folio_id       OUT NUMBER
    );


    PROCEDURE post_room_charges (
        p_reservation_id IN NUMBER
    );


    PROCEDURE checkout_reservation (
        p_reservation_id IN NUMBER
    );

END stay_folio_management_pkg;
/

CREATE OR REPLACE PACKAGE BODY stay_folio_management_pkg AS


    -- =====================================================
    -- FUNCTION: calculate_room_charges
    -- =====================================================

    FUNCTION calculate_room_charges (
        p_reservation_id IN NUMBER
    ) RETURN NUMBER
    IS
        lv_total NUMBER(10,2);
    BEGIN

        SELECT NVL(
                   SUM(
                       rr.nightly_rate *
                       (hr.check_out_date - hr.check_in_date)
                   ),
                   0
               )
        INTO lv_total
        FROM hotel_reservation hr
        JOIN reservation_room rr
            ON rr.reservation_id = hr.reservation_id
        WHERE hr.reservation_id = p_reservation_id;

        RETURN lv_total;

    END calculate_room_charges;



    -- =====================================================
    -- FUNCTION: get_folio_balance
    -- =====================================================

    FUNCTION get_folio_balance (
        p_folio_id IN NUMBER
    ) RETURN NUMBER
    IS
        lv_charges  NUMBER(10,2);
        lv_payments NUMBER(10,2);
    BEGIN

        SELECT NVL(SUM(amount), 0)
        INTO lv_charges
        FROM folio_charge
        WHERE folio_id = p_folio_id;


        SELECT NVL(SUM(amount), 0)
        INTO lv_payments
        FROM payment
        WHERE folio_id = p_folio_id
          AND payment_status = 'COMPLETED';


        RETURN lv_charges - lv_payments;

    END get_folio_balance;



    -- =====================================================
    -- PROCEDURE: check_in_reservation
    -- =====================================================

    PROCEDURE check_in_reservation (
        p_reservation_id IN NUMBER,
        p_stay_id        OUT NUMBER,
        p_folio_id       OUT NUMBER
    )
    IS
        lv_status      hotel_reservation.reservation_status%TYPE;
        lv_room_count  NUMBER;
        lv_stay_count  NUMBER;
    BEGIN

        -- Retrieve reservation status
        SELECT reservation_status
        INTO lv_status
        FROM hotel_reservation
        WHERE reservation_id = p_reservation_id
        FOR UPDATE;


        IF lv_status != 'BOOKED' THEN
            RAISE_APPLICATION_ERROR(
                -20101,
                'Only booked reservations can be checked in.'
            );
        END IF;


        -- Make sure rooms were assigned
        SELECT COUNT(*)
        INTO lv_room_count
        FROM reservation_room
        WHERE reservation_id = p_reservation_id;


        IF lv_room_count = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20102,
                'Reservation has no rooms assigned.'
            );
        END IF;


        -- Validate room occupants against reservation total
        reservation_management_pkg.validate_guest_count(
            p_reservation_id
        );


        -- Make sure a stay does not already exist
        SELECT COUNT(*)
        INTO lv_stay_count
        FROM stay
        WHERE reservation_id = p_reservation_id;


        IF lv_stay_count > 0 THEN
            RAISE_APPLICATION_ERROR(
                -20103,
                'A stay already exists for this reservation.'
            );
        END IF;


        -- Create stay
        INSERT INTO stay (
            reservation_id,
            actual_check_in,
            stay_status
        )
        VALUES (
            p_reservation_id,
            SYSTIMESTAMP,
            'CHECKED_IN'
        )
        RETURNING stay_id
        INTO p_stay_id;


        -- Open guest folio
        INSERT INTO guest_folio (
            stay_id,
            folio_status
        )
        VALUES (
            p_stay_id,
            'OPEN'
        )
        RETURNING folio_id
        INTO p_folio_id;


        -- Update reservation
        UPDATE hotel_reservation
        SET reservation_status = 'CHECKED_IN'
        WHERE reservation_id = p_reservation_id;


        -- Mark all assigned rooms as occupied
        UPDATE room
        SET operational_status = 'OCCUPIED'
        WHERE room_id IN (
            SELECT room_id
            FROM reservation_room
            WHERE reservation_id = p_reservation_id
        );


    EXCEPTION

        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20104,
                'Reservation could not be found.'
            );

    END check_in_reservation;



    -- =====================================================
    -- PROCEDURE: post_room_charges
    -- =====================================================

    PROCEDURE post_room_charges (
        p_reservation_id IN NUMBER
    )
    IS
        lv_folio_id      NUMBER;
        lv_room_charges  NUMBER(10,2);
        lv_charge_count  NUMBER;
    BEGIN

        -- Find active folio
        SELECT gf.folio_id
        INTO lv_folio_id
        FROM guest_folio gf
        JOIN stay s
            ON s.stay_id = gf.stay_id
        WHERE s.reservation_id = p_reservation_id
          AND gf.folio_status = 'OPEN';


        -- Prevent room charges being posted twice
        SELECT COUNT(*)
        INTO lv_charge_count
        FROM folio_charge
        WHERE folio_id = lv_folio_id
          AND charge_type = 'ROOM'
          AND reference_id = p_reservation_id;


        IF lv_charge_count > 0 THEN
            RAISE_APPLICATION_ERROR(
                -20105,
                'Room charges have already been posted.'
            );
        END IF;


        lv_room_charges :=
            calculate_room_charges(p_reservation_id);


        IF lv_room_charges <= 0 THEN
            RAISE_APPLICATION_ERROR(
                -20106,
                'No room charges were calculated.'
            );
        END IF;


        INSERT INTO folio_charge (
            folio_id,
            charge_type,
            description,
            amount,
            reference_id
        )
        VALUES (
            lv_folio_id,
            'ROOM',
            'Accommodation charges',
            lv_room_charges,
            p_reservation_id
        );


    EXCEPTION

        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20107,
                'Open folio could not be found.'
            );

    END post_room_charges;



    -- =====================================================
    -- PROCEDURE: checkout_reservation
    -- =====================================================

    PROCEDURE checkout_reservation (
        p_reservation_id IN NUMBER
    )
    IS
        lv_stay_id       NUMBER;
        lv_folio_id      NUMBER;
        lv_status        hotel_reservation.reservation_status%TYPE;
        lv_balance       NUMBER(10,2);
        lv_charge_count  NUMBER;
    BEGIN

        SELECT
            s.stay_id,
            gf.folio_id,
            hr.reservation_status
        INTO
            lv_stay_id,
            lv_folio_id,
            lv_status
        FROM hotel_reservation hr
        JOIN stay s
            ON s.reservation_id = hr.reservation_id
        JOIN guest_folio gf
            ON gf.stay_id = s.stay_id
        WHERE hr.reservation_id = p_reservation_id
          AND s.stay_status = 'CHECKED_IN'
          AND gf.folio_status = 'OPEN'
        FOR UPDATE;


        IF lv_status != 'CHECKED_IN' THEN
            RAISE_APPLICATION_ERROR(
                -20108,
                'Reservation is not currently checked in.'
            );
        END IF;


        -- Check whether room charge already exists
        SELECT COUNT(*)
        INTO lv_charge_count
        FROM folio_charge
        WHERE folio_id = lv_folio_id
          AND charge_type = 'ROOM'
          AND reference_id = p_reservation_id;


        -- Automatically post it if necessary
        IF lv_charge_count = 0 THEN
            post_room_charges(p_reservation_id);
        END IF;


        -- Calculate outstanding balance
        lv_balance := get_folio_balance(lv_folio_id);


        IF lv_balance > 0 THEN
            RAISE_APPLICATION_ERROR(
                -20109,
                'Outstanding folio balance: $'
                || TO_CHAR(lv_balance, 'FM9999990.00')
            );
        END IF;


        -- Close stay
        UPDATE stay
        SET actual_check_out = SYSTIMESTAMP,
            stay_status = 'CHECKED_OUT'
        WHERE stay_id = lv_stay_id;


        -- Close folio
        UPDATE guest_folio
        SET folio_status = 'CLOSED',
            closed_at = SYSTIMESTAMP
        WHERE folio_id = lv_folio_id;


        -- Complete reservation
        UPDATE hotel_reservation
        SET reservation_status = 'COMPLETED'
        WHERE reservation_id = p_reservation_id;


        -- Rooms now require housekeeping
        UPDATE room
        SET operational_status = 'CLEANING'
        WHERE room_id IN (
            SELECT room_id
            FROM reservation_room
            WHERE reservation_id = p_reservation_id
        );


    EXCEPTION

        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20110,
                'Active stay or folio could not be found.'
            );

    END checkout_reservation;


END stay_folio_management_pkg;
/

DECLARE
    lv_stay_id  NUMBER;
    lv_folio_id NUMBER;
BEGIN

    stay_folio_management_pkg.check_in_reservation(
        p_reservation_id => 1,
        p_stay_id        => lv_stay_id,
        p_folio_id       => lv_folio_id
    );

    DBMS_OUTPUT.PUT_LINE('Stay ID: ' || lv_stay_id);
    DBMS_OUTPUT.PUT_LINE('Folio ID: ' || lv_folio_id);

    COMMIT;

END;
/

SELECT *
FROM stay;

SELECT *
FROM guest_folio;

SELECT
    room_id,
    room_number,
    operational_status
FROM room
ORDER BY room_id;

SELECT reservation_id,
       reservation_status
FROM hotel_reservation;

BEGIN
    stay_folio_management_pkg.post_room_charges(1);
    COMMIT;
END;
/

SELECT *
FROM folio_charge;

SELECT stay_folio_management_pkg.get_folio_balance(1)
       AS outstanding_balance
FROM dual;

BEGIN
    stay_folio_management_pkg.checkout_reservation(1);
END;
/