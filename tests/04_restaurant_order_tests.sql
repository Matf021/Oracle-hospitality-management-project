-- =====================================================
-- Room charge without folio
-- Expected: ORA-20304
-- =====================================================

DECLARE
    lv_order_id NUMBER;
BEGIN
    restaurant_order_management_pkg.create_order(
        p_restaurant_id       => 3,
        p_table_id            => 9,
        p_payment_destination => 'ROOM_CHARGE',
        p_folio_id            => NULL,
        p_order_id            => lv_order_id
    );

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(
            'EXPECTED FAILURE: ' || SQLERRM
        );
END;
/

-- =====================================================
-- Add item from wrong restaurant
-- Expected: ORA-20310
-- =====================================================

BEGIN
    restaurant_order_management_pkg.add_order_item(
        p_order_id     => 1,
        p_menu_item_id => 1,
        p_quantity     => 1
    );

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(
            'EXPECTED FAILURE: ' || SQLERRM
        );
END;
/

