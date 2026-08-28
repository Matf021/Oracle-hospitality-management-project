CREATE OR REPLACE PACKAGE payment_management_pkg AS

    FUNCTION get_remaining_balance (
        p_folio_id IN NUMBER
    ) RETURN NUMBER;


    PROCEDURE process_payment (
        p_folio_id       IN NUMBER,
        p_amount         IN NUMBER,
        p_payment_method IN VARCHAR2,
        p_payment_id     OUT NUMBER
    );


    PROCEDURE refund_payment (
        p_payment_id IN NUMBER,
        p_amount     IN NUMBER
    );

END payment_management_pkg;
/

CREATE OR REPLACE PACKAGE BODY payment_management_pkg AS


    -- =====================================================
    -- FUNCTION: get_remaining_balance
    -- =====================================================

    FUNCTION get_remaining_balance (
        p_folio_id IN NUMBER
    ) RETURN NUMBER
    IS
    BEGIN
        RETURN stay_folio_management_pkg.get_folio_balance(
            p_folio_id
        );
    END get_remaining_balance;



    -- =====================================================
    -- PROCEDURE: process_payment
    -- =====================================================

    PROCEDURE process_payment (
        p_folio_id       IN NUMBER,
        p_amount         IN NUMBER,
        p_payment_method IN VARCHAR2,
        p_payment_id     OUT NUMBER
    )
    IS
        lv_balance       NUMBER(10,2);
        lv_folio_status  guest_folio.folio_status%TYPE;
    BEGIN

        SELECT folio_status
        INTO lv_folio_status
        FROM guest_folio
        WHERE folio_id = p_folio_id
        FOR UPDATE;


        IF lv_folio_status != 'OPEN' THEN
            RAISE_APPLICATION_ERROR(
                -20201,
                'Payments can only be posted to an open folio.'
            );
        END IF;


        IF p_amount <= 0 THEN
            RAISE_APPLICATION_ERROR(
                -20202,
                'Payment amount must be greater than zero.'
            );
        END IF;


        lv_balance :=
            get_remaining_balance(p_folio_id);


        IF lv_balance <= 0 THEN
            RAISE_APPLICATION_ERROR(
                -20203,
                'Folio has no outstanding balance.'
            );
        END IF;


        IF p_amount > lv_balance THEN
            RAISE_APPLICATION_ERROR(
                -20204,
                'Payment exceeds outstanding balance of $'
                || TO_CHAR(lv_balance, 'FM9999990.00')
            );
        END IF;


        IF UPPER(p_payment_method) NOT IN (
            'CREDIT_CARD',
            'DEBIT_CARD',
            'CASH',
            'MOBILE',
            'OTHER'
        ) THEN
            RAISE_APPLICATION_ERROR(
                -20205,
                'Invalid payment method.'
            );
        END IF;


        INSERT INTO payment (
            folio_id,
            amount,
            payment_method,
            payment_status
        )
        VALUES (
            p_folio_id,
            p_amount,
            UPPER(p_payment_method),
            'COMPLETED'
        )
        RETURNING payment_id
        INTO p_payment_id;


    EXCEPTION

        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20206,
                'Folio could not be found.'
            );

    END process_payment;



    -- =====================================================
    -- PROCEDURE: refund_payment
    -- =====================================================

    PROCEDURE refund_payment (
        p_payment_id IN NUMBER,
        p_amount     IN NUMBER
    )
    IS
        lv_original_amount NUMBER(10,2);
        lv_status          payment.payment_status%TYPE;
    BEGIN

        SELECT amount,
               payment_status
        INTO lv_original_amount,
             lv_status
        FROM payment
        WHERE payment_id = p_payment_id
        FOR UPDATE;


        IF lv_status != 'COMPLETED' THEN
            RAISE_APPLICATION_ERROR(
                -20207,
                'Only completed payments can be refunded.'
            );
        END IF;


        IF p_amount <= 0 THEN
            RAISE_APPLICATION_ERROR(
                -20208,
                'Refund amount must be greater than zero.'
            );
        END IF;


        IF p_amount > lv_original_amount THEN
            RAISE_APPLICATION_ERROR(
                -20209,
                'Refund cannot exceed original payment.'
            );
        END IF;


        -- Version 1 only supports full refunds
        IF p_amount != lv_original_amount THEN
            RAISE_APPLICATION_ERROR(
                -20210,
                'Partial refunds are not supported in Version 1.'
            );
        END IF;


        UPDATE payment
        SET payment_status = 'REFUNDED'
        WHERE payment_id = p_payment_id;


    EXCEPTION

        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20211,
                'Payment could not be found.'
            );

    END refund_payment;


END payment_management_pkg;
/

SELECT
    gf.folio_id,
    s.reservation_id,
    gf.folio_status
FROM guest_folio gf
JOIN stay s
    ON s.stay_id = gf.stay_id;

SELECT
    stay_folio_management_pkg.get_folio_balance(1)
        AS outstanding_balance
FROM dual;

SET SERVEROUTPUT ON;

DECLARE
    lv_payment_id NUMBER;
BEGIN

    payment_management_pkg.process_payment(
        p_folio_id       => 1,
        p_amount         => 1590,
        p_payment_method => 'CREDIT_CARD',
        p_payment_id     => lv_payment_id
    );

    DBMS_OUTPUT.PUT_LINE(
        'Payment ID: ' || lv_payment_id
    );

    COMMIT;

END;
/

SELECT *
FROM payment;

SELECT
    payment_management_pkg.get_remaining_balance(1)
        AS remaining_balance
FROM dual;

BEGIN
    stay_folio_management_pkg.checkout_reservation(1);
    COMMIT;
END;
/

SELECT
    reservation_id,
    reservation_status
FROM hotel_reservation;

SELECT
    stay_id,
    stay_status,
    actual_check_in,
    actual_check_out
FROM stay;

SELECT
    folio_id,
    folio_status,
    opened_at,
    closed_at
FROM guest_folio;