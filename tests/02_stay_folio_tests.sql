-- =====================================================
-- Invalid checkout with unpaid balance
-- Expected: ORA-20109
-- =====================================================

BEGIN
    stay_folio_management_pkg.checkout_reservation(1);

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(
            'EXPECTED FAILURE: ' || SQLERRM
        );
END;
/