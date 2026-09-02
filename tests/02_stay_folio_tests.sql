SET SERVEROUTPUT ON;

DECLARE
    lv_passed NUMBER := 0;
    lv_failed NUMBER := 0;

    PROCEDURE print_result (
        p_test_name IN VARCHAR2,
        p_passed    IN BOOLEAN,
        p_message   IN VARCHAR2 DEFAULT NULL
    )
    IS
    BEGIN
        IF p_passed THEN
            lv_passed := lv_passed + 1;
            DBMS_OUTPUT.PUT_LINE('[PASS] ' || p_test_name);
        ELSE
            lv_failed := lv_failed + 1;
            DBMS_OUTPUT.PUT_LINE(
                '[FAIL] ' || p_test_name ||
                CASE
                    WHEN p_message IS NOT NULL
                    THEN ' - ' || p_message
                END
            );
        END IF;
    END print_result;

BEGIN

    DBMS_OUTPUT.PUT_LINE('=== STAY / FOLIO MANAGEMENT TESTS ===');
    DBMS_OUTPUT.PUT_LINE('');


    -- =====================================================
    -- TEST 1
    -- Check-in without assigned rooms
    -- Expected: -20102
    -- =====================================================

    DECLARE
        lv_reservation_id NUMBER;
        lv_stay_id        NUMBER;
        lv_folio_id       NUMBER;
    BEGIN

        reservation_management_pkg.create_reservation(
            p_guest_id       => 1,
            p_check_in_date  => DATE '2027-09-01',
            p_check_out_date => DATE '2027-09-03',
            p_total_guests   => 1,
            p_reservation_id => lv_reservation_id
        );

        stay_folio_management_pkg.check_in_reservation(
            p_reservation_id => lv_reservation_id,
            p_stay_id        => lv_stay_id,
            p_folio_id       => lv_folio_id
        );

        print_result(
            'Reject check-in without rooms',
            FALSE,
            'No exception was raised.'
        );

    EXCEPTION
        WHEN OTHERS THEN
            print_result(
                'Reject check-in without rooms',
                SQLCODE = -20102,
                'Expected -20102, received '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;
    END;


    -- =====================================================
    -- TEST 2
    -- Duplicate check-in
    -- Expected: -20103
    -- =====================================================

    DECLARE
        lv_reservation_id NUMBER;
        lv_stay_id        NUMBER;
        lv_folio_id       NUMBER;

        lv_second_stay    NUMBER;
        lv_second_folio   NUMBER;
    BEGIN

        reservation_management_pkg.create_reservation(
            p_guest_id       => 1,
            p_check_in_date  => DATE '2027-10-01',
            p_check_out_date => DATE '2027-10-03',
            p_total_guests   => 2,
            p_reservation_id => lv_reservation_id
        );

        reservation_management_pkg.add_room_to_reservation(
            p_reservation_id => lv_reservation_id,
            p_room_id        => 1,
            p_nightly_rate   => 220,
            p_occupants      => 2
        );

        stay_folio_management_pkg.check_in_reservation(
            p_reservation_id => lv_reservation_id,
            p_stay_id        => lv_stay_id,
            p_folio_id       => lv_folio_id
        );

        stay_folio_management_pkg.check_in_reservation(
            p_reservation_id => lv_reservation_id,
            p_stay_id        => lv_second_stay,
            p_folio_id       => lv_second_folio
        );

        print_result(
            'Reject duplicate check-in',
            FALSE,
            'No exception was raised.'
        );

    EXCEPTION
        WHEN OTHERS THEN
            print_result(
                'Reject duplicate check-in',
                SQLCODE = -20103,
                'Expected -20103, received '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;
    END;


    -- =====================================================
    -- TEST 3
    -- Duplicate room charge
    -- Expected: -20105
    -- =====================================================

    DECLARE
        lv_reservation_id NUMBER;
        lv_stay_id        NUMBER;
        lv_folio_id       NUMBER;
    BEGIN

        reservation_management_pkg.create_reservation(
            p_guest_id       => 1,
            p_check_in_date  => DATE '2027-11-01',
            p_check_out_date => DATE '2027-11-03',
            p_total_guests   => 2,
            p_reservation_id => lv_reservation_id
        );

        reservation_management_pkg.add_room_to_reservation(
            p_reservation_id => lv_reservation_id,
            p_room_id        => 1,
            p_nightly_rate   => 220,
            p_occupants      => 2
        );

        stay_folio_management_pkg.check_in_reservation(
            p_reservation_id => lv_reservation_id,
            p_stay_id        => lv_stay_id,
            p_folio_id       => lv_folio_id
        );

        stay_folio_management_pkg.post_room_charges(
            lv_reservation_id
        );

        stay_folio_management_pkg.post_room_charges(
            lv_reservation_id
        );

        print_result(
            'Reject duplicate room charge',
            FALSE,
            'No exception was raised.'
        );

    EXCEPTION
        WHEN OTHERS THEN
            print_result(
                'Reject duplicate room charge',
                SQLCODE = -20105,
                'Expected -20105, received '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;
    END;


    -- =====================================================
    -- TEST 4
    -- Checkout with unpaid balance
    -- Expected: -20109
    -- =====================================================

    DECLARE
        lv_reservation_id NUMBER;
        lv_stay_id        NUMBER;
        lv_folio_id       NUMBER;
    BEGIN

        reservation_management_pkg.create_reservation(
            p_guest_id       => 1,
            p_check_in_date  => DATE '2027-12-01',
            p_check_out_date => DATE '2027-12-03',
            p_total_guests   => 2,
            p_reservation_id => lv_reservation_id
        );

        reservation_management_pkg.add_room_to_reservation(
            p_reservation_id => lv_reservation_id,
            p_room_id        => 1,
            p_nightly_rate   => 220,
            p_occupants      => 2
        );

        stay_folio_management_pkg.check_in_reservation(
            p_reservation_id => lv_reservation_id,
            p_stay_id        => lv_stay_id,
            p_folio_id       => lv_folio_id
        );

        stay_folio_management_pkg.post_room_charges(
            lv_reservation_id
        );

        stay_folio_management_pkg.checkout_reservation(
            lv_reservation_id
        );

        print_result(
            'Reject checkout with unpaid balance',
            FALSE,
            'No exception was raised.'
        );

    EXCEPTION
        WHEN OTHERS THEN
            print_result(
                'Reject checkout with unpaid balance',
                SQLCODE = -20109,
                'Expected -20109, received '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;
    END;


    -- =====================================================
    -- TEST 5
    -- Successful paid checkout
    -- Expected: success
    -- =====================================================

    DECLARE
        lv_reservation_id NUMBER;
        lv_stay_id        NUMBER;
        lv_folio_id       NUMBER;
        lv_payment_id     NUMBER;
        lv_balance        NUMBER;

        lv_res_status     hotel_reservation.reservation_status%TYPE;
        lv_stay_status    stay.stay_status%TYPE;
        lv_folio_status   guest_folio.folio_status%TYPE;
    BEGIN

        reservation_management_pkg.create_reservation(
            p_guest_id       => 1,
            p_check_in_date  => DATE '2028-01-01',
            p_check_out_date => DATE '2028-01-03',
            p_total_guests   => 2,
            p_reservation_id => lv_reservation_id
        );

        reservation_management_pkg.add_room_to_reservation(
            p_reservation_id => lv_reservation_id,
            p_room_id        => 1,
            p_nightly_rate   => 220,
            p_occupants      => 2
        );

        stay_folio_management_pkg.check_in_reservation(
            p_reservation_id => lv_reservation_id,
            p_stay_id        => lv_stay_id,
            p_folio_id       => lv_folio_id
        );

        stay_folio_management_pkg.post_room_charges(
            lv_reservation_id
        );

        lv_balance :=
            stay_folio_management_pkg.get_folio_balance(
                lv_folio_id
            );

        payment_management_pkg.process_payment(
            p_folio_id       => lv_folio_id,
            p_amount         => lv_balance,
            p_payment_method => 'CREDIT_CARD',
            p_payment_id     => lv_payment_id
        );

        stay_folio_management_pkg.checkout_reservation(
            lv_reservation_id
        );

        SELECT reservation_status
        INTO lv_res_status
        FROM hotel_reservation
        WHERE reservation_id = lv_reservation_id;

        SELECT stay_status
        INTO lv_stay_status
        FROM stay
        WHERE stay_id = lv_stay_id;

        SELECT folio_status
        INTO lv_folio_status
        FROM guest_folio
        WHERE folio_id = lv_folio_id;

        IF lv_res_status = 'COMPLETED'
           AND lv_stay_status = 'CHECKED_OUT'
           AND lv_folio_status = 'CLOSED'
        THEN
            print_result(
                'Complete paid checkout',
                TRUE
            );
        ELSE
            print_result(
                'Complete paid checkout',
                FALSE,
                'Final state is incorrect.'
            );
        END IF;

        ROLLBACK;

    EXCEPTION
        WHEN OTHERS THEN
            print_result(
                'Complete paid checkout',
                FALSE,
                'Unexpected error '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;
    END;


    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('==============================');
    DBMS_OUTPUT.PUT_LINE('PASSED: ' || lv_passed);
    DBMS_OUTPUT.PUT_LINE('FAILED: ' || lv_failed);
    DBMS_OUTPUT.PUT_LINE('==============================');

    ROLLBACK;

END;
/