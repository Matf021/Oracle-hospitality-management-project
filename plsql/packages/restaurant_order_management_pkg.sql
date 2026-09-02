CREATE OR REPLACE PACKAGE restaurant_order_management_pkg AS

    PROCEDURE create_order (
        p_restaurant_id              IN NUMBER,
        p_table_id                   IN NUMBER,
        p_restaurant_reservation_id  IN NUMBER DEFAULT NULL,
        p_payment_destination        IN VARCHAR2 DEFAULT 'DIRECT',
        p_folio_id                   IN NUMBER DEFAULT NULL,
        p_order_id                   OUT NUMBER
    );


    PROCEDURE add_order_item (
        p_order_id      IN NUMBER,
        p_menu_item_id  IN NUMBER,
        p_quantity      IN NUMBER,
        p_notes         IN VARCHAR2 DEFAULT NULL
    );


    FUNCTION calculate_order_total (
        p_order_id IN NUMBER
    ) RETURN NUMBER;


    PROCEDURE close_order (
        p_order_id IN NUMBER
    );


    PROCEDURE post_order_to_folio (
        p_order_id IN NUMBER
    );

END restaurant_order_management_pkg;
/

CREATE OR REPLACE PACKAGE BODY restaurant_order_management_pkg AS


    -- =====================================================
    -- PROCEDURE: create_order
    -- =====================================================

    PROCEDURE create_order (
        p_restaurant_id              IN NUMBER,
        p_table_id                   IN NUMBER,
        p_restaurant_reservation_id  IN NUMBER DEFAULT NULL,
        p_payment_destination        IN VARCHAR2 DEFAULT 'DIRECT',
        p_folio_id                   IN NUMBER DEFAULT NULL,
        p_order_id                   OUT NUMBER
    )
    IS
        lv_restaurant_count NUMBER;
        lv_table_count      NUMBER;
        lv_folio_status     guest_folio.folio_status%TYPE;
    BEGIN

        SELECT COUNT(*)
        INTO lv_restaurant_count
        FROM restaurant
        WHERE restaurant_id = p_restaurant_id;


        IF lv_restaurant_count = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20301,
                'Restaurant could not be found.'
            );
        END IF;


        IF p_table_id IS NOT NULL THEN

            SELECT COUNT(*)
            INTO lv_table_count
            FROM restaurant_table
            WHERE table_id = p_table_id
              AND restaurant_id = p_restaurant_id;


            IF lv_table_count = 0 THEN
                RAISE_APPLICATION_ERROR(
                    -20302,
                    'Table does not belong to the selected restaurant.'
                );
            END IF;

        END IF;


        IF UPPER(p_payment_destination)
            NOT IN ('DIRECT', 'ROOM_CHARGE')
        THEN
            RAISE_APPLICATION_ERROR(
                -20303,
                'Invalid payment destination.'
            );
        END IF;


        IF UPPER(p_payment_destination) = 'ROOM_CHARGE' THEN

            IF p_folio_id IS NULL THEN
                RAISE_APPLICATION_ERROR(
                    -20304,
                    'Room charge orders require a folio.'
                );
            END IF;


            SELECT folio_status
            INTO lv_folio_status
            FROM guest_folio
            WHERE folio_id = p_folio_id;


            IF lv_folio_status != 'OPEN' THEN
                RAISE_APPLICATION_ERROR(
                    -20305,
                    'Restaurant charges can only be posted to an open folio.'
                );
            END IF;

        ELSE

            IF p_folio_id IS NOT NULL THEN
                RAISE_APPLICATION_ERROR(
                    -20306,
                    'Direct-payment orders cannot be linked to a hotel folio.'
                );
            END IF;

        END IF;


        INSERT INTO restaurant_order (
            restaurant_id,
            table_id,
            restaurant_reservation_id,
            folio_id,
            payment_destination
        )
        VALUES (
            p_restaurant_id,
            p_table_id,
            p_restaurant_reservation_id,
            p_folio_id,
            UPPER(p_payment_destination)
        )
        RETURNING order_id
        INTO p_order_id;


    EXCEPTION

        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20307,
                'Hotel folio could not be found.'
            );

    END create_order;



    -- =====================================================
    -- PROCEDURE: add_order_item
    -- =====================================================

    PROCEDURE add_order_item (
        p_order_id      IN NUMBER,
        p_menu_item_id  IN NUMBER,
        p_quantity      IN NUMBER,
        p_notes         IN VARCHAR2 DEFAULT NULL
    )
    IS
        lv_order_status       restaurant_order.order_status%TYPE;
        lv_order_restaurant   NUMBER;
        lv_menu_restaurant    NUMBER;
        lv_menu_price         NUMBER(10,2);
        lv_available          CHAR(1);
    BEGIN

        SELECT restaurant_id,
               order_status
        INTO lv_order_restaurant,
             lv_order_status
        FROM restaurant_order
        WHERE order_id = p_order_id;


        IF lv_order_status != 'OPEN' THEN
            RAISE_APPLICATION_ERROR(
                -20308,
                'Items can only be added to an open order.'
            );
        END IF;


        IF p_quantity <= 0 THEN
            RAISE_APPLICATION_ERROR(
                -20309,
                'Quantity must be greater than zero.'
            );
        END IF;


        SELECT restaurant_id,
               price,
               is_available
        INTO lv_menu_restaurant,
             lv_menu_price,
             lv_available
        FROM menu_item
        WHERE menu_item_id = p_menu_item_id;


        IF lv_menu_restaurant != lv_order_restaurant THEN
            RAISE_APPLICATION_ERROR(
                -20310,
                'Menu item does not belong to this restaurant.'
            );
        END IF;


        IF lv_available != 'Y' THEN
            RAISE_APPLICATION_ERROR(
                -20311,
                'Menu item is currently unavailable.'
            );
        END IF;


        INSERT INTO order_item (
            order_id,
            menu_item_id,
            quantity,
            unit_price,
            notes
        )
        VALUES (
            p_order_id,
            p_menu_item_id,
            p_quantity,
            lv_menu_price,
            p_notes
        );


    EXCEPTION

        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20312,
                'Order or menu item could not be found.'
            );

    END add_order_item;



    -- =====================================================
    -- FUNCTION: calculate_order_total
    -- =====================================================

    FUNCTION calculate_order_total (
        p_order_id IN NUMBER
    ) RETURN NUMBER
    IS
        lv_total NUMBER(10,2);
    BEGIN

        SELECT NVL(
                   SUM(quantity * unit_price),
                   0
               )
        INTO lv_total
        FROM order_item
        WHERE order_id = p_order_id;

        RETURN lv_total;

    END calculate_order_total;



    -- =====================================================
    -- PROCEDURE: close_order
    -- =====================================================

    PROCEDURE close_order (
        p_order_id IN NUMBER
    )
    IS
        lv_status NUMBER;
    BEGIN

        SELECT COUNT(*)
        INTO lv_status
        FROM restaurant_order
        WHERE order_id = p_order_id
          AND order_status = 'OPEN';


        IF lv_status = 0 THEN
            RAISE_APPLICATION_ERROR(
                -20313,
                'Order does not exist or is not open.'
            );
        END IF;


        IF calculate_order_total(p_order_id) <= 0 THEN
            RAISE_APPLICATION_ERROR(
                -20314,
                'Cannot close an empty order.'
            );
        END IF;


        UPDATE restaurant_order
        SET order_status = 'CLOSED',
            closed_at = SYSTIMESTAMP
        WHERE order_id = p_order_id;

    END close_order;



    -- =====================================================
    -- PROCEDURE: post_order_to_folio
    -- =====================================================

    PROCEDURE post_order_to_folio (
        p_order_id IN NUMBER
    )
    IS
        lv_folio_id             NUMBER;
        lv_payment_destination  restaurant_order.payment_destination%TYPE;
        lv_order_status         restaurant_order.order_status%TYPE;
        lv_folio_status         guest_folio.folio_status%TYPE;
        lv_total                NUMBER(10,2);
        lv_existing_charge      NUMBER;
    BEGIN

        SELECT folio_id,
               payment_destination,
               order_status
        INTO lv_folio_id,
             lv_payment_destination,
             lv_order_status
        FROM restaurant_order
        WHERE order_id = p_order_id
        FOR UPDATE;

        IF lv_order_status = 'VOID' THEN
        RAISE_APPLICATION_ERROR(
            -20321,
            'Void restaurant orders cannot be posted to a folio.'
        );
        END IF;


        IF lv_payment_destination != 'ROOM_CHARGE' THEN
            RAISE_APPLICATION_ERROR(
                -20315,
                'Order is not configured as a room charge.'
            );
        END IF;


        IF lv_folio_id IS NULL THEN
            RAISE_APPLICATION_ERROR(
                -20316,
                'Order does not have an associated folio.'
            );
        END IF;


        SELECT folio_status
        INTO lv_folio_status
        FROM guest_folio
        WHERE folio_id = lv_folio_id;


        IF lv_folio_status != 'OPEN' THEN
            RAISE_APPLICATION_ERROR(
                -20317,
                'Restaurant charge cannot be posted to a closed folio.'
            );
        END IF;


        lv_total :=
            calculate_order_total(p_order_id);


        IF lv_total <= 0 THEN
            RAISE_APPLICATION_ERROR(
                -20318,
                'Order has no billable items.'
            );
        END IF;


        SELECT COUNT(*)
        INTO lv_existing_charge
        FROM folio_charge
        WHERE folio_id = lv_folio_id
          AND charge_type = 'RESTAURANT'
          AND reference_id = p_order_id;


        IF lv_existing_charge > 0 THEN
            RAISE_APPLICATION_ERROR(
                -20319,
                'Restaurant order has already been posted to the folio.'
            );
        END IF;


        IF lv_order_status = 'OPEN' THEN

            UPDATE restaurant_order
            SET order_status = 'CLOSED',
                closed_at = SYSTIMESTAMP
            WHERE order_id = p_order_id;

        END IF;


        INSERT INTO folio_charge (
            folio_id,
            charge_type,
            description,
            amount,
            reference_id
        )
        VALUES (
            lv_folio_id,
            'RESTAURANT',
            'Restaurant order #' || p_order_id,
            lv_total,
            p_order_id
        );


    EXCEPTION

        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(
                -20320,
                'Order or folio could not be found.'
            );

    END post_order_to_folio;


END restaurant_order_management_pkg;
/

-- ===================
--      TEST
-- ===================

SELECT
    hr.reservation_id,
    g.first_name,
    g.last_name,
    s.stay_id,
    gf.folio_id,
    gf.folio_status
FROM hotel_reservation hr
JOIN guest g
    ON g.guest_id = hr.guest_id
JOIN stay s
    ON s.reservation_id = hr.reservation_id
JOIN guest_folio gf
    ON gf.stay_id = s.stay_id
WHERE gf.folio_status = 'OPEN';

SET SERVEROUTPUT ON;

DECLARE
    lv_order_id NUMBER;
BEGIN

    restaurant_order_management_pkg.create_order(
        p_restaurant_id       => 3,
        p_table_id            => 9,
        p_payment_destination => 'ROOM_CHARGE',
        p_folio_id            => 21, 
        p_order_id            => lv_order_id
    );

    DBMS_OUTPUT.PUT_LINE(
        'Order ID: ' || lv_order_id
    );

    COMMIT;

END;
/

BEGIN

    restaurant_order_management_pkg.add_order_item(
        p_order_id     => 1,
        p_menu_item_id => 7,
        p_quantity     => 2
    );

    restaurant_order_management_pkg.add_order_item(
        p_order_id     => 1,
        p_menu_item_id => 9,
        p_quantity     => 1
    );

    COMMIT;

END;
/

SELECT
    restaurant_order_management_pkg.calculate_order_total(1)
        AS order_total
FROM dual;

BEGIN
    restaurant_order_management_pkg.post_order_to_folio(1);
    COMMIT;
END;
/

SELECT
    charge_id,
    charge_type,
    description,
    amount,
    reference_id
FROM folio_charge
ORDER BY charge_id;

SELECT
    stay_folio_management_pkg.get_folio_balance(21)
        AS outstanding_balance
FROM dual;