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

            DBMS_OUTPUT.PUT_LINE(
                '[PASS] ' || p_test_name
            );

        ELSE

            lv_failed := lv_failed + 1;

            DBMS_OUTPUT.PUT_LINE(
                '[FAIL] ' || p_test_name
                || CASE
                       WHEN p_message IS NOT NULL
                       THEN ' - ' || p_message
                   END
            );

        END IF;

    END print_result;


    lv_reservation_id NUMBER;

BEGIN

    DBMS_OUTPUT.PUT_LINE(
        '=== RESERVATION MANAGEMENT TESTS ==='
    );

    DBMS_OUTPUT.PUT_LINE('');


    -- =====================================================
    -- TEST 1
    -- Guest does not exist
    -- Expected: -20001
    -- =====================================================

    BEGIN

        reservation_management_pkg.create_reservation(
            p_guest_id       => 999999,
            p_check_in_date  => DATE '2027-01-10',
            p_check_out_date => DATE '2027-01-12',
            p_total_guests   => 1,
            p_reservation_id => lv_reservation_id
        );

        print_result(
            'Reject nonexistent guest',
            FALSE,
            'No exception was raised.'
        );


    EXCEPTION

        WHEN OTHERS THEN

            print_result(
                'Reject nonexistent guest',
                SQLCODE = -20001,
                'Expected -20001, received '
                || SQLCODE || ': ' || SQLERRM
            );

    END;



    -- =====================================================
    -- TEST 2
    -- Invalid date range
    -- Expected: -20004
    -- =====================================================

    BEGIN

        reservation_management_pkg.create_reservation(
            p_guest_id       => 1,
            p_check_in_date  => DATE '2027-01-15',
            p_check_out_date => DATE '2027-01-10',
            p_total_guests   => 1,
            p_reservation_id => lv_reservation_id
        );


        print_result(
            'Reject invalid date range',
            FALSE,
            'No exception was raised.'
        );


    EXCEPTION

        WHEN OTHERS THEN

            print_result(
                'Reject invalid date range',
                SQLCODE = -20004,
                'Expected -20004, received '
                || SQLCODE || ': ' || SQLERRM
            );

    END;



    -- =====================================================
    -- TEST 3
    -- Zero guests
    -- Expected: -20005
    -- =====================================================

    BEGIN

        reservation_management_pkg.create_reservation(
            p_guest_id       => 1,
            p_check_in_date  => DATE '2027-01-10',
            p_check_out_date => DATE '2027-01-12',
            p_total_guests   => 0,
            p_reservation_id => lv_reservation_id
        );


        print_result(
            'Reject zero guests',
            FALSE,
            'No exception was raised.'
        );


    EXCEPTION

        WHEN OTHERS THEN

            print_result(
                'Reject zero guests',
                SQLCODE = -20005,
                'Expected -20005, received '
                || SQLCODE || ': ' || SQLERRM
            );

    END;



    -- =====================================================
    -- TEST 4
    -- Reservation does not exist
    -- Expected: -20006
    -- =====================================================

    BEGIN

        reservation_management_pkg.add_room_to_reservation(
            p_reservation_id => 999999,
            p_room_id        => 1,
            p_nightly_rate   => 220,
            p_occupants      => 1
        );


        print_result(
            'Reject nonexistent reservation',
            FALSE,
            'No exception was raised.'
        );


    EXCEPTION

        WHEN OTHERS THEN

            print_result(
                'Reject nonexistent reservation',
                SQLCODE = -20006,
                'Expected -20006, received '
                || SQLCODE || ': ' || SQLERRM
            );

    END;



    -- =====================================================
    -- TEST 5
    -- Room does not exist
    -- Expected: -20008
    -- =====================================================

    BEGIN

        reservation_management_pkg.create_reservation(
            p_guest_id       => 1,
            p_check_in_date  => DATE '2027-02-01',
            p_check_out_date => DATE '2027-02-03',
            p_total_guests   => 1,
            p_reservation_id => lv_reservation_id
        );


        reservation_management_pkg.add_room_to_reservation(
            p_reservation_id => lv_reservation_id,
            p_room_id        => 999999,
            p_nightly_rate   => 220,
            p_occupants      => 1
        );


        print_result(
            'Reject nonexistent room',
            FALSE,
            'No exception was raised.'
        );


    EXCEPTION

        WHEN OTHERS THEN

            print_result(
                'Reject nonexistent room',
                SQLCODE = -20008,
                'Expected -20008, received '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;

    END;



    -- =====================================================
    -- TEST 6
    -- Too many occupants
    -- Standard King max occupancy = 2
    -- Expected: -20011
    -- =====================================================

    BEGIN

        reservation_management_pkg.create_reservation(
            p_guest_id       => 1,
            p_check_in_date  => DATE '2027-03-01',
            p_check_out_date => DATE '2027-03-03',
            p_total_guests   => 3,
            p_reservation_id => lv_reservation_id
        );


        reservation_management_pkg.add_room_to_reservation(
            p_reservation_id => lv_reservation_id,
            p_room_id        => 1,
            p_nightly_rate   => 220,
            p_occupants      => 3
        );


        print_result(
            'Reject excessive room occupancy',
            FALSE,
            'No exception was raised.'
        );


    EXCEPTION

        WHEN OTHERS THEN

            print_result(
                'Reject excessive room occupancy',
                SQLCODE = -20011,
                'Expected -20011, received '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;

    END;



    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(
        '=============================='
    );

    DBMS_OUTPUT.PUT_LINE(
        'PASSED: ' || lv_passed
    );

    DBMS_OUTPUT.PUT_LINE(
        'FAILED: ' || lv_failed
    );

    DBMS_OUTPUT.PUT_LINE(
        '=============================='
    );


    ROLLBACK;

END;
/