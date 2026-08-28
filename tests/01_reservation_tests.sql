SET SERVEROUTPUT ON;

-- =====================================================
-- TEST 1: Invalid date range
-- Expected: ORA-20002
-- =====================================================

DECLARE
    lv_reservation_id NUMBER;
BEGIN
    reservation_management_pkg.create_reservation(
        p_guest_id       => 1,
        p_check_in_date  => DATE '2026-09-15',
        p_check_out_date => DATE '2026-09-10',
        p_total_guests   => 2,
        p_reservation_id => lv_reservation_id
    );

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(
            'TEST 1 PASSED: ' || SQLERRM
        );
END;
/

-- =====================================================
-- TEST 2: Invalid guest count
-- Expected: ORA-20003
-- =====================================================

DECLARE
    lv_reservation_id NUMBER;
BEGIN
    reservation_management_pkg.create_reservation(
        p_guest_id       => 1,
        p_check_in_date  => DATE '2026-09-10',
        p_check_out_date => DATE '2026-09-13',
        p_total_guests   => 0,
        p_reservation_id => lv_reservation_id
    );

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(
            'TEST 2 PASSED: ' || SQLERRM
        );
END;
/

-- =====================================================
-- TEST 3: Double-book same room
-- Expected: ORA-20008
-- =====================================================

DECLARE
    lv_reservation_id NUMBER;
BEGIN
    reservation_management_pkg.create_reservation(
        p_guest_id       => 2,
        p_check_in_date  => DATE '2026-09-11',
        p_check_out_date => DATE '2026-09-12',
        p_total_guests   => 1,
        p_reservation_id => lv_reservation_id
    );

    reservation_management_pkg.add_room_to_reservation(
        p_reservation_id => lv_reservation_id,
        p_room_id        => 1,
        p_nightly_rate   => 220,
        p_occupants      => 1
    );

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(
            'TEST 3 RESULT: ' || SQLERRM
        );

        ROLLBACK;
END;
/