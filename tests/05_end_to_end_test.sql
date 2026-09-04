SET SERVEROUTPUT ON;

DECLARE
    lv_reservation_id NUMBER;
    lv_stay_id        NUMBER;
    lv_folio_id       NUMBER;
    lv_order_id       NUMBER;
    lv_payment_id     NUMBER;
    lv_balance        NUMBER(10,2);

    lv_test_guest_id          NUMBER;
    lv_test_room_id           NUMBER;
    lv_skyline_restaurant_id  NUMBER;
    lv_skyline_table_id       NUMBER;
    lv_old_fashioned_id       NUMBER;
    lv_cheese_selection_id    NUMBER;

    lv_res_status     hotel_reservation.reservation_status%TYPE;
    lv_stay_status    stay.stay_status%TYPE;
    lv_folio_status   guest_folio.folio_status%TYPE;

BEGIN

    SELECT guest_id
    INTO lv_test_guest_id
    FROM guest
    WHERE email = 'daniel.carter@example.com';

    SELECT room_id
    INTO lv_test_room_id
    FROM room
    WHERE room_number = '201';

    SELECT restaurant_id
    INTO lv_skyline_restaurant_id
    FROM restaurant
    WHERE restaurant_name = 'Skyline Bar';

    SELECT table_id
    INTO lv_skyline_table_id
    FROM restaurant_table rt
    JOIN restaurant r
        ON r.restaurant_id = rt.restaurant_id
    WHERE r.restaurant_name = 'Skyline Bar'
      AND rt.table_number = 'S1';

    SELECT menu_item_id
    INTO lv_old_fashioned_id
    FROM menu_item mi
    JOIN restaurant r
        ON r.restaurant_id = mi.restaurant_id
    WHERE r.restaurant_name = 'Skyline Bar'
      AND mi.item_name = 'Old Fashioned';

    SELECT menu_item_id
    INTO lv_cheese_selection_id
    FROM menu_item mi
    JOIN restaurant r
        ON r.restaurant_id = mi.restaurant_id
    WHERE r.restaurant_name = 'Skyline Bar'
      AND mi.item_name = 'Cheese Selection';

    DBMS_OUTPUT.PUT_LINE('=== END-TO-END TEST START ===');


    -- =====================================================
    -- 1. CREATE RESERVATION
    -- =====================================================

    reservation_management_pkg.create_reservation(
        p_guest_id       => lv_test_guest_id,
        p_check_in_date  => DATE '2030-10-10',
        p_check_out_date => DATE '2030-10-13',
        p_total_guests   => 2,
        p_reservation_id => lv_reservation_id
    );

    DBMS_OUTPUT.PUT_LINE(
        'Reservation created: ' || lv_reservation_id
    );


    -- =====================================================
    -- 2. ADD ROOM
    -- =====================================================

    reservation_management_pkg.add_room_to_reservation(
        p_reservation_id => lv_reservation_id,
        p_room_id        => lv_test_room_id,
        p_nightly_rate   => 220,
        p_occupants      => 2
    );


    reservation_management_pkg.validate_guest_count(
        lv_reservation_id
    );

    DBMS_OUTPUT.PUT_LINE('Room assigned successfully');


    -- =====================================================
    -- 3. CHECK IN
    -- =====================================================

    stay_folio_management_pkg.check_in_reservation(
        p_reservation_id => lv_reservation_id,
        p_stay_id        => lv_stay_id,
        p_folio_id       => lv_folio_id
    );

    DBMS_OUTPUT.PUT_LINE(
        'Stay created: ' || lv_stay_id
    );

    DBMS_OUTPUT.PUT_LINE(
        'Folio opened: ' || lv_folio_id
    );


    -- =====================================================
    -- 4. POST ROOM CHARGES
    -- =====================================================

    stay_folio_management_pkg.post_room_charges(
        lv_reservation_id
    );

    DBMS_OUTPUT.PUT_LINE(
        'Room charges posted'
    );


    -- =====================================================
    -- 5. CREATE RESTAURANT ORDER
    -- =====================================================

    restaurant_order_management_pkg.create_order(
        p_restaurant_id       => lv_skyline_restaurant_id,
        p_table_id            => lv_skyline_table_id,
        p_payment_destination => 'ROOM_CHARGE',
        p_folio_id            => lv_folio_id,
        p_order_id            => lv_order_id
    );

    DBMS_OUTPUT.PUT_LINE(
        'Restaurant order created: ' || lv_order_id
    );


    -- =====================================================
    -- 6. ADD RESTAURANT ITEMS
    -- =====================================================

    restaurant_order_management_pkg.add_order_item(
        p_order_id     => lv_order_id,
        p_menu_item_id => lv_old_fashioned_id,
        p_quantity     => 2
    );

    restaurant_order_management_pkg.add_order_item(
        p_order_id     => lv_order_id,
        p_menu_item_id => lv_cheese_selection_id,
        p_quantity     => 1
    );


    -- =====================================================
    -- 7. POST RESTAURANT ORDER TO FOLIO
    -- =====================================================

    restaurant_order_management_pkg.post_order_to_folio(
        lv_order_id
    );

    DBMS_OUTPUT.PUT_LINE(
        'Restaurant order posted to folio'
    );


    -- =====================================================
    -- 8. CALCULATE TOTAL BALANCE
    -- =====================================================

    lv_balance :=
        payment_management_pkg.get_remaining_balance(
            lv_folio_id
        );

    DBMS_OUTPUT.PUT_LINE(
        'Outstanding balance: $'
        || TO_CHAR(lv_balance, 'FM9999990.00')
    );


    -- =====================================================
    -- 9. PAY EXACT BALANCE
    -- =====================================================

    payment_management_pkg.process_payment(
        p_folio_id       => lv_folio_id,
        p_amount         => lv_balance,
        p_payment_method => 'CREDIT_CARD',
        p_payment_id     => lv_payment_id
    );

    DBMS_OUTPUT.PUT_LINE(
        'Payment created: ' || lv_payment_id
    );


    -- =====================================================
    -- 10. CHECKOUT
    -- =====================================================

    stay_folio_management_pkg.checkout_reservation(
        lv_reservation_id
    );

    DBMS_OUTPUT.PUT_LINE(
        'Checkout completed'
    );


    -- =====================================================
    -- 11. VERIFY FINAL STATE
    -- =====================================================

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


    lv_balance :=
        payment_management_pkg.get_remaining_balance(
            lv_folio_id
        );


    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('=== FINAL STATE ===');

    DBMS_OUTPUT.PUT_LINE(
        'Reservation: ' || lv_res_status
    );

    DBMS_OUTPUT.PUT_LINE(
        'Stay: ' || lv_stay_status
    );

    DBMS_OUTPUT.PUT_LINE(
        'Folio: ' || lv_folio_status
    );

    DBMS_OUTPUT.PUT_LINE(
        'Balance: $'
        || TO_CHAR(lv_balance, 'FM9999990.00')
    );


    -- =====================================================
    -- ASSERTIONS
    -- =====================================================

    IF lv_res_status != 'COMPLETED' THEN
        RAISE_APPLICATION_ERROR(
            -20901,
            'TEST FAILED: Reservation was not completed.'
        );
    END IF;


    IF lv_stay_status != 'CHECKED_OUT' THEN
        RAISE_APPLICATION_ERROR(
            -20902,
            'TEST FAILED: Stay was not checked out.'
        );
    END IF;


    IF lv_folio_status != 'CLOSED' THEN
        RAISE_APPLICATION_ERROR(
            -20903,
            'TEST FAILED: Folio was not closed.'
        );
    END IF;


    IF lv_balance != 0 THEN
        RAISE_APPLICATION_ERROR(
            -20904,
            'TEST FAILED: Final balance is not zero.'
        );
    END IF;


    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE(
        '=== END-TO-END TEST PASSED ==='
    );


    ROLLBACK;


EXCEPTION

    WHEN OTHERS THEN

        DBMS_OUTPUT.PUT_LINE('');
        DBMS_OUTPUT.PUT_LINE(
            '=== END-TO-END TEST FAILED ==='
        );

        DBMS_OUTPUT.PUT_LINE(SQLERRM);

        ROLLBACK;

        RAISE;

END;
/