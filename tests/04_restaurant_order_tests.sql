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


    -- Creates a checked-in guest with an OPEN folio.
    PROCEDURE create_test_folio (
        p_check_in_date  IN DATE,
        p_check_out_date IN DATE,
        p_reservation_id OUT NUMBER,
        p_stay_id        OUT NUMBER,
        p_folio_id       OUT NUMBER
    )
    IS
    BEGIN

        reservation_management_pkg.create_reservation(
            p_guest_id       => 1,
            p_check_in_date  => p_check_in_date,
            p_check_out_date => p_check_out_date,
            p_total_guests   => 2,
            p_reservation_id => p_reservation_id
        );

        reservation_management_pkg.add_room_to_reservation(
            p_reservation_id => p_reservation_id,
            p_room_id        => 1,
            p_nightly_rate   => 220,
            p_occupants      => 2
        );

        stay_folio_management_pkg.check_in_reservation(
            p_reservation_id => p_reservation_id,
            p_stay_id        => p_stay_id,
            p_folio_id       => p_folio_id
        );

    END create_test_folio;


BEGIN

    DBMS_OUTPUT.PUT_LINE(
        '=== RESTAURANT ORDER MANAGEMENT TESTS ==='
    );

    DBMS_OUTPUT.PUT_LINE('');


    -- =====================================================
    -- TEST 1
    -- Nonexistent restaurant
    -- Expected: -20301
    -- =====================================================

    DECLARE
        lv_order_id NUMBER;
    BEGIN

        restaurant_order_management_pkg.create_order(
            p_restaurant_id       => 999999,
            p_table_id            => NULL,
            p_restaurant_reservation_id   => NULL,
            p_folio_id            => NULL,
            p_payment_destination => 'DIRECT',
            p_order_id            => lv_order_id
        );

        print_result(
            'Reject nonexistent restaurant',
            FALSE,
            'No exception was raised.'
        );

    EXCEPTION
        WHEN OTHERS THEN

            print_result(
                'Reject nonexistent restaurant',
                SQLCODE = -20301,
                'Expected -20301, received '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;
    END;


    -- =====================================================
    -- TEST 2
    -- Table belongs to another restaurant
    --
    -- Table 1 belongs to restaurant 1.
    -- Restaurant 3 = Skyline Bar.
    --
    -- Expected: -20302
    -- =====================================================

    DECLARE
        lv_order_id NUMBER;
    BEGIN

        restaurant_order_management_pkg.create_order(
            p_restaurant_id       => 3,
            p_table_id            => 1,
            p_restaurant_reservation_id   => NULL,
            p_folio_id            => NULL,
            p_payment_destination => 'DIRECT',
            p_order_id            => lv_order_id
        );

        print_result(
            'Reject table from another restaurant',
            FALSE,
            'No exception was raised.'
        );

    EXCEPTION
        WHEN OTHERS THEN

            print_result(
                'Reject table from another restaurant',
                SQLCODE = -20302,
                'Expected -20302, received '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;
    END;


    -- =====================================================
    -- TEST 3
    -- Invalid payment destination
    -- Expected: -20303
    -- =====================================================

    DECLARE
        lv_order_id NUMBER;
    BEGIN

        restaurant_order_management_pkg.create_order(
            p_restaurant_id       => 3,
            p_table_id            => 9,
            p_restaurant_reservation_id   => NULL,
            p_folio_id            => NULL,
            p_payment_destination => 'BITCOIN',
            p_order_id            => lv_order_id
        );

        print_result(
            'Reject invalid payment destination',
            FALSE,
            'No exception was raised.'
        );

    EXCEPTION
        WHEN OTHERS THEN

            print_result(
                'Reject invalid payment destination',
                SQLCODE = -20303,
                'Expected -20303, received '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;
    END;


    -- =====================================================
    -- TEST 4
    -- ROOM_CHARGE requires a folio
    -- Expected: -20304
    -- =====================================================

    DECLARE
        lv_order_id NUMBER;
    BEGIN

        restaurant_order_management_pkg.create_order(
            p_restaurant_id       => 3,
            p_table_id            => 9,
            p_restaurant_reservation_id   => NULL,
            p_folio_id            => NULL,
            p_payment_destination => 'ROOM_CHARGE',
            p_order_id            => lv_order_id
        );

        print_result(
            'Reject room charge without folio',
            FALSE,
            'No exception was raised.'
        );

    EXCEPTION
        WHEN OTHERS THEN

            print_result(
                'Reject room charge without folio',
                SQLCODE = -20304,
                'Expected -20304, received '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;
    END;


    -- =====================================================
    -- TEST 5
    -- DIRECT payment must not reference a folio
    -- Expected: -20306
    -- =====================================================

    DECLARE
        lv_reservation_id NUMBER;
        lv_stay_id        NUMBER;
        lv_folio_id       NUMBER;
        lv_order_id       NUMBER;
    BEGIN

        create_test_folio(
            DATE '2028-09-01',
            DATE '2028-09-03',
            lv_reservation_id,
            lv_stay_id,
            lv_folio_id
        );

        restaurant_order_management_pkg.create_order(
            p_restaurant_id       => 3,
            p_table_id            => 9,
            p_restaurant_reservation_id   => NULL,
            p_folio_id            => lv_folio_id,
            p_payment_destination => 'DIRECT',
            p_order_id            => lv_order_id
        );

        print_result(
            'Reject direct payment with folio',
            FALSE,
            'No exception was raised.'
        );

    EXCEPTION
        WHEN OTHERS THEN

            print_result(
                'Reject direct payment with folio',
                SQLCODE = -20306,
                'Expected -20306, received '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;
    END;


    -- =====================================================
    -- TEST 6
    -- Quantity must be positive
    -- Expected: -20309
    -- =====================================================

    DECLARE
        lv_order_id NUMBER;
    BEGIN

        restaurant_order_management_pkg.create_order(
            p_restaurant_id       => 3,
            p_table_id            => 9,
            p_restaurant_reservation_id   => NULL,
            p_folio_id            => NULL,
            p_payment_destination => 'DIRECT',
            p_order_id            => lv_order_id
        );

        restaurant_order_management_pkg.add_order_item(
            p_order_id     => lv_order_id,
            p_menu_item_id => 7,
            p_quantity     => 0,
            p_notes        => NULL
        );

        print_result(
            'Reject zero item quantity',
            FALSE,
            'No exception was raised.'
        );

    EXCEPTION
        WHEN OTHERS THEN

            print_result(
                'Reject zero item quantity',
                SQLCODE = -20309,
                'Expected -20309, received '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;
    END;


    -- =====================================================
    -- TEST 7
    -- Menu item belongs to another restaurant
    --
    -- Order = Skyline Bar (restaurant 3)
    -- Menu item 1 = Atrium
    --
    -- Expected: -20310
    -- =====================================================

    DECLARE
        lv_order_id NUMBER;
    BEGIN

        restaurant_order_management_pkg.create_order(
            p_restaurant_id       => 3,
            p_table_id            => 9,
            p_restaurant_reservation_id   => NULL,
            p_folio_id            => NULL,
            p_payment_destination => 'DIRECT',
            p_order_id            => lv_order_id
        );

        restaurant_order_management_pkg.add_order_item(
            p_order_id     => lv_order_id,
            p_menu_item_id => 1,
            p_quantity     => 1,
            p_notes        => NULL
        );

        print_result(
            'Reject menu item from another restaurant',
            FALSE,
            'No exception was raised.'
        );

    EXCEPTION
        WHEN OTHERS THEN

            print_result(
                'Reject menu item from another restaurant',
                SQLCODE = -20310,
                'Expected -20310, received '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;
    END;


    -- =====================================================
    -- TEST 8
    -- Unavailable menu item
    -- Expected: -20311
    -- =====================================================

    DECLARE
        lv_order_id NUMBER;
    BEGIN

        UPDATE menu_item
        SET is_available = 'N'
        WHERE menu_item_id = 7;

        restaurant_order_management_pkg.create_order(
            p_restaurant_id       => 3,
            p_table_id            => 9,
            p_restaurant_reservation_id   => NULL,
            p_folio_id            => NULL,
            p_payment_destination => 'DIRECT',
            p_order_id            => lv_order_id
        );

        restaurant_order_management_pkg.add_order_item(
            p_order_id     => lv_order_id,
            p_menu_item_id => 7,
            p_quantity     => 1,
            p_notes        => NULL
        );

        print_result(
            'Reject unavailable menu item',
            FALSE,
            'No exception was raised.'
        );

    EXCEPTION
        WHEN OTHERS THEN

            print_result(
                'Reject unavailable menu item',
                SQLCODE = -20311,
                'Expected -20311, received '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;
    END;


    -- =====================================================
    -- TEST 9
    -- Cannot close an empty order
    -- Expected: -20314
    -- =====================================================

    DECLARE
        lv_order_id NUMBER;
    BEGIN

        restaurant_order_management_pkg.create_order(
            p_restaurant_id       => 3,
            p_table_id            => 9,
            p_restaurant_reservation_id   => NULL,
            p_folio_id            => NULL,
            p_payment_destination => 'DIRECT',
            p_order_id            => lv_order_id
        );

        restaurant_order_management_pkg.close_order(
            lv_order_id
        );

        print_result(
            'Reject closing empty order',
            FALSE,
            'No exception was raised.'
        );

    EXCEPTION
        WHEN OTHERS THEN

            print_result(
                'Reject closing empty order',
                SQLCODE = -20314,
                'Expected -20314, received '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;
    END;


    -- =====================================================
    -- TEST 10
    -- Successful ROOM_CHARGE posting
    --
    -- 2 Old Fashioned = 2 x $20 = $40
    -- 1 Cheese Selection = $24
    -- Expected total = $64
    -- =====================================================

    DECLARE
        lv_reservation_id NUMBER;
        lv_stay_id        NUMBER;
        lv_folio_id       NUMBER;
        lv_order_id       NUMBER;
        lv_charge_amount  NUMBER;
    BEGIN

        create_test_folio(
            DATE '2028-10-01',
            DATE '2028-10-03',
            lv_reservation_id,
            lv_stay_id,
            lv_folio_id
        );

        restaurant_order_management_pkg.create_order(
            p_restaurant_id       => 3,
            p_table_id            => 9,
            p_restaurant_reservation_id   => NULL,
            p_folio_id            => lv_folio_id,
            p_payment_destination => 'ROOM_CHARGE',
            p_order_id            => lv_order_id
        );

        restaurant_order_management_pkg.add_order_item(
            p_order_id     => lv_order_id,
            p_menu_item_id => 7,
            p_quantity     => 2,
            p_notes        => NULL
        );

        restaurant_order_management_pkg.add_order_item(
            p_order_id     => lv_order_id,
            p_menu_item_id => 9,
            p_quantity     => 1,
            p_notes        => NULL
        );

        restaurant_order_management_pkg.post_order_to_folio(
            lv_order_id
        );

        SELECT amount
        INTO lv_charge_amount
        FROM folio_charge
        WHERE folio_id = lv_folio_id
          AND charge_type = 'RESTAURANT'
          AND reference_id = lv_order_id;

        IF lv_charge_amount = 64 THEN

            print_result(
                'Post restaurant order to folio',
                TRUE
            );

        ELSE

            print_result(
                'Post restaurant order to folio',
                FALSE,
                'Expected $64, received $'
                || TO_CHAR(lv_charge_amount)
            );

        END IF;

        ROLLBACK;

    EXCEPTION
        WHEN OTHERS THEN

            print_result(
                'Post restaurant order to folio',
                FALSE,
                'Unexpected error '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;
    END;


    -- =====================================================
    -- TEST 11
    -- Duplicate restaurant charge
    -- Expected: -20319
    -- =====================================================

    DECLARE
        lv_reservation_id NUMBER;
        lv_stay_id        NUMBER;
        lv_folio_id       NUMBER;
        lv_order_id       NUMBER;
    BEGIN

        create_test_folio(
            DATE '2028-11-01',
            DATE '2028-11-03',
            lv_reservation_id,
            lv_stay_id,
            lv_folio_id
        );

        restaurant_order_management_pkg.create_order(
            p_restaurant_id       => 3,
            p_table_id            => 9,
            p_restaurant_reservation_id   => NULL,
            p_folio_id            => lv_folio_id,
            p_payment_destination => 'ROOM_CHARGE',
            p_order_id            => lv_order_id
        );

        restaurant_order_management_pkg.add_order_item(
            p_order_id     => lv_order_id,
            p_menu_item_id => 7,
            p_quantity     => 1,
            p_notes        => NULL
        );

        restaurant_order_management_pkg.post_order_to_folio(
            lv_order_id
        );

        restaurant_order_management_pkg.post_order_to_folio(
            lv_order_id
        );

        print_result(
            'Reject duplicate restaurant charge',
            FALSE,
            'No exception was raised.'
        );

    EXCEPTION
        WHEN OTHERS THEN

            print_result(
                'Reject duplicate restaurant charge',
                SQLCODE = -20319,
                'Expected -20319, received '
                || SQLCODE || ': ' || SQLERRM
            );

            ROLLBACK;
    END;


    -- =====================================================
    -- TEST 12
    -- VOID orders must never be posted to a folio.
    --
    -- This is intentionally testing a suspected bug.
    --
    -- We will use -20321 as the desired business error.
    -- The current package may NOT raise it yet.
    -- =====================================================

    DECLARE
        lv_reservation_id NUMBER;
        lv_stay_id        NUMBER;
        lv_folio_id       NUMBER;
        lv_order_id       NUMBER;
    BEGIN

        create_test_folio(
            DATE '2028-12-01',
            DATE '2028-12-03',
            lv_reservation_id,
            lv_stay_id,
            lv_folio_id
        );

        restaurant_order_management_pkg.create_order(
            p_restaurant_id       => 3,
            p_table_id            => 9,
            p_restaurant_reservation_id   => NULL,
            p_folio_id            => lv_folio_id,
            p_payment_destination => 'ROOM_CHARGE',
            p_order_id            => lv_order_id
        );

        restaurant_order_management_pkg.add_order_item(
            p_order_id     => lv_order_id,
            p_menu_item_id => 7,
            p_quantity     => 1,
            p_notes        => NULL
        );

        -- Simulate a voided order.
        UPDATE restaurant_order
        SET order_status = 'VOID'
        WHERE order_id = lv_order_id;

        restaurant_order_management_pkg.post_order_to_folio(
            lv_order_id
        );

        print_result(
            'Reject posting void order',
            FALSE,
            'VOID order was posted to the folio.'
        );

        ROLLBACK;

    EXCEPTION
        WHEN OTHERS THEN

            print_result(
                'Reject posting void order',
                SQLCODE = -20321,
                'Expected -20321, received '
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