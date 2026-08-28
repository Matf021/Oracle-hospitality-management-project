-- =====================================================
-- Overpayment test
-- Expected: ORA-20204
-- =====================================================

DECLARE
    lv_payment_id NUMBER;
BEGIN
    payment_management_pkg.process_payment(
        p_folio_id       => 1,
        p_amount         => 999999,
        p_payment_method => 'CREDIT_CARD',
        p_payment_id     => lv_payment_id
    );

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(
            'EXPECTED FAILURE: ' || SQLERRM
        );
END;
/

-- =====================================================
-- Invalid payment method
-- Expected: ORA-20205
-- =====================================================

DECLARE
    lv_payment_id NUMBER;
BEGIN
    payment_management_pkg.process_payment(
        p_folio_id       => 1,
        p_amount         => 10,
        p_payment_method => 'CRYPTO',
        p_payment_id     => lv_payment_id
    );

EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE(
            'EXPECTED FAILURE: ' || SQLERRM
        );
END;
/