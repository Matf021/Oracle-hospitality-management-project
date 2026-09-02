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

    DBMS_OUTPUT.PUT_LINE('=== PAYMENT MANAGEMENT TESTS ===');
    DBMS_OUTPUT.PUT_LINE('');


    -- =====================================================
    -- TEST 1
    -- Nonexistent folio
    -- Expected: -20206
    -- =====================================================

    DECLARE
        lv_payment_id NUMBER;
    BEGIN

        payment_management_pkg.process_payment(
            p_folio_id       => 999999,
            p_amount         => 100,
            p_payment_method => 'CREDIT_CARD',
            p_payment_id     => lv_payment_id
        );

        print_result(
            'Reject nonexistent folio',
            FALSE,
            'No exception was raised.'
        );

    EXCEPTION
        WHEN OTHERS THEN
            print_result(
                'Reject nonexistent folio',
                SQLCODE = -20206,
                'Expected -20206, received '
                || SQLCODE || ': ' || SQLERRM
            );
    END;


    -- =====================================================
    -- TEST 2
    -- Invalid payment amount
    -- Expected: -20202
    -- =====================================================

    DECLARE
        lv_reservation_id NUMBER;
        lv_stay_id        NUMBER;
        lv_folio_id       NUMBER;
        lv_payment_id     NUMBER;
    BEGIN

        reservation_management_pkg.create_reservation(
            p_guest_id       => 1,
            p_check_in_date  => DATE '2028-02-01',
            p_check_out_date => DATE '2028-02-03',
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

        payment_management_pkg.process_payment(
            p_folio_id       => lv_folio_id,
            p_amount         => 0,
            p_payment_method => 'CREDIT_CARD',
            p_payment_id     => lv_payment_id
        );

        print_result(
            'Reject zero payment',
            FALSE,
            'No exception was raised.'
        );

    EXCEPTION
        WHEN OTHERS THEN
            print_result(
                'Reject zero payment',
                SQLCODE = -20202,
                'Expected -20202, received '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;
    END;


    -- =====================================================
    -- TEST 3
    -- Overpayment
    -- Expected: -20204
    -- =====================================================

    DECLARE
        lv_reservation_id NUMBER;
        lv_stay_id        NUMBER;
        lv_folio_id       NUMBER;
        lv_payment_id     NUMBER;
        lv_balance        NUMBER;
    BEGIN

        reservation_management_pkg.create_reservation(
            p_guest_id       => 1,
            p_check_in_date  => DATE '2028-03-01',
            p_check_out_date => DATE '2028-03-03',
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
            payment_management_pkg.get_remaining_balance(
                lv_folio_id
            );

        payment_management_pkg.process_payment(
            p_folio_id       => lv_folio_id,
            p_amount         => lv_balance + 1,
            p_payment_method => 'CREDIT_CARD',
            p_payment_id     => lv_payment_id
        );

        print_result(
            'Reject overpayment',
            FALSE,
            'No exception was raised.'
        );

    EXCEPTION
        WHEN OTHERS THEN
            print_result(
                'Reject overpayment',
                SQLCODE = -20204,
                'Expected -20204, received '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;
    END;


    -- =====================================================
    -- TEST 4
    -- Invalid payment method
    -- Expected: -20205
    -- =====================================================

    DECLARE
        lv_reservation_id NUMBER;
        lv_stay_id        NUMBER;
        lv_folio_id       NUMBER;
        lv_payment_id     NUMBER;
    BEGIN

        reservation_management_pkg.create_reservation(
            p_guest_id       => 1,
            p_check_in_date  => DATE '2028-04-01',
            p_check_out_date => DATE '2028-04-03',
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

        payment_management_pkg.process_payment(
            p_folio_id       => lv_folio_id,
            p_amount         => 100,
            p_payment_method => 'CRYPTO',
            p_payment_id     => lv_payment_id
        );

        print_result(
            'Reject invalid payment method',
            FALSE,
            'No exception was raised.'
        );

    EXCEPTION
        WHEN OTHERS THEN
            print_result(
                'Reject invalid payment method',
                SQLCODE = -20205,
                'Expected -20205, received '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;
    END;


    -- =====================================================
    -- TEST 5
    -- Successful payment
    -- Expected: success
    -- =====================================================

    DECLARE
        lv_reservation_id NUMBER;
        lv_stay_id        NUMBER;
        lv_folio_id       NUMBER;
        lv_payment_id     NUMBER;
        lv_balance_before NUMBER;
        lv_balance_after  NUMBER;
    BEGIN

        reservation_management_pkg.create_reservation(
            p_guest_id       => 1,
            p_check_in_date  => DATE '2028-05-01',
            p_check_out_date => DATE '2028-05-03',
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

        lv_balance_before :=
            payment_management_pkg.get_remaining_balance(
                lv_folio_id
            );

        payment_management_pkg.process_payment(
            p_folio_id       => lv_folio_id,
            p_amount         => lv_balance_before,
            p_payment_method => 'DEBIT_CARD',
            p_payment_id     => lv_payment_id
        );

        lv_balance_after :=
            payment_management_pkg.get_remaining_balance(
                lv_folio_id
            );

        IF lv_payment_id IS NOT NULL
           AND lv_balance_after = 0
        THEN
            print_result(
                'Process valid payment',
                TRUE
            );
        ELSE
            print_result(
                'Process valid payment',
                FALSE,
                'Payment ID or final balance is incorrect.'
            );
        END IF;

        ROLLBACK;

    EXCEPTION
        WHEN OTHERS THEN
            print_result(
                'Process valid payment',
                FALSE,
                'Unexpected error '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;
    END;


    -- =====================================================
    -- TEST 6
    -- Payment when balance is already zero
    -- Expected: -20203
    -- =====================================================

    DECLARE
        lv_reservation_id NUMBER;
        lv_stay_id        NUMBER;
        lv_folio_id       NUMBER;
        lv_payment_id     NUMBER;
        lv_payment_2      NUMBER;
        lv_balance        NUMBER;
    BEGIN

        reservation_management_pkg.create_reservation(
            p_guest_id       => 1,
            p_check_in_date  => DATE '2028-06-01',
            p_check_out_date => DATE '2028-06-03',
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
            payment_management_pkg.get_remaining_balance(
                lv_folio_id
            );

        payment_management_pkg.process_payment(
            p_folio_id       => lv_folio_id,
            p_amount         => lv_balance,
            p_payment_method => 'CREDIT_CARD',
            p_payment_id     => lv_payment_id
        );

        payment_management_pkg.process_payment(
            p_folio_id       => lv_folio_id,
            p_amount         => 1,
            p_payment_method => 'CREDIT_CARD',
            p_payment_id     => lv_payment_2
        );

        print_result(
            'Reject payment with zero balance',
            FALSE,
            'No exception was raised.'
        );

    EXCEPTION
        WHEN OTHERS THEN
            print_result(
                'Reject payment with zero balance',
                SQLCODE = -20203,
                'Expected -20203, received '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;
    END;


    -- =====================================================
    -- TEST 7
    -- Partial refund
    -- Expected: -20210
    -- =====================================================

    DECLARE
        lv_reservation_id NUMBER;
        lv_stay_id        NUMBER;
        lv_folio_id       NUMBER;
        lv_payment_id     NUMBER;
    BEGIN

        reservation_management_pkg.create_reservation(
            p_guest_id       => 1,
            p_check_in_date  => DATE '2028-07-01',
            p_check_out_date => DATE '2028-07-03',
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

        payment_management_pkg.process_payment(
            p_folio_id       => lv_folio_id,
            p_amount         => 440,
            p_payment_method => 'CREDIT_CARD',
            p_payment_id     => lv_payment_id
        );

        payment_management_pkg.refund_payment(
            p_payment_id => lv_payment_id,
            p_amount     => 100
        );

        print_result(
            'Reject partial refund',
            FALSE,
            'No exception was raised.'
        );

    EXCEPTION
        WHEN OTHERS THEN
            print_result(
                'Reject partial refund',
                SQLCODE = -20210,
                'Expected -20210, received '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;
    END;


    -- =====================================================
    -- TEST 8
    -- Successful full refund
    -- Expected: success
    -- =====================================================

    DECLARE
        lv_reservation_id NUMBER;
        lv_stay_id        NUMBER;
        lv_folio_id       NUMBER;
        lv_payment_id     NUMBER;

        lv_status         payment.payment_status%TYPE;
        lv_balance        NUMBER;
    BEGIN

        reservation_management_pkg.create_reservation(
            p_guest_id       => 1,
            p_check_in_date  => DATE '2028-08-01',
            p_check_out_date => DATE '2028-08-03',
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

        payment_management_pkg.process_payment(
            p_folio_id       => lv_folio_id,
            p_amount         => 440,
            p_payment_method => 'CREDIT_CARD',
            p_payment_id     => lv_payment_id
        );

        payment_management_pkg.refund_payment(
            p_payment_id => lv_payment_id,
            p_amount     => 440
        );

        SELECT payment_status
        INTO lv_status
        FROM payment
        WHERE payment_id = lv_payment_id;

        lv_balance :=
            payment_management_pkg.get_remaining_balance(
                lv_folio_id
            );

        IF lv_status = 'REFUNDED'
           AND lv_balance = 440
        THEN
            print_result(
                'Process full refund',
                TRUE
            );
        ELSE
            print_result(
                'Process full refund',
                FALSE,
                'Refund state or restored balance is incorrect.'
            );
        END IF;

        ROLLBACK;

    EXCEPTION
        WHEN OTHERS THEN
            print_result(
                'Process full refund',
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