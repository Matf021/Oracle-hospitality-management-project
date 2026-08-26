-- =========================================================
-- Hospitality Management System
-- schema/02_indexes.sql
-- =========================================================


-- =========================================================
-- HOTEL / GUEST INDEXES
-- =========================================================

CREATE INDEX idx_reservation_guest
    ON hotel_reservation (guest_id);

CREATE INDEX idx_reservation_dates
    ON hotel_reservation (check_in_date, check_out_date);

CREATE INDEX idx_reservation_status
    ON hotel_reservation (reservation_status);


-- =========================================================
-- ROOM / RESERVATION ROOM INDEXES
-- =========================================================

CREATE INDEX idx_room_room_type
    ON room (room_type_id);

CREATE INDEX idx_reservation_room_reservation
    ON reservation_room (reservation_id);

CREATE INDEX idx_reservation_room_room
    ON reservation_room (room_id);


-- =========================================================
-- STAY / FOLIO INDEXES
-- =========================================================

CREATE INDEX idx_stay_reservation
    ON stay (reservation_id);

CREATE INDEX idx_folio_stay
    ON guest_folio (stay_id);

CREATE INDEX idx_folio_charge_folio
    ON folio_charge (folio_id);

CREATE INDEX idx_folio_charge_type
    ON folio_charge (charge_type);

CREATE INDEX idx_payment_folio
    ON payment (folio_id);


-- =========================================================
-- RESTAURANT INDEXES
-- =========================================================

CREATE INDEX idx_restaurant_table_restaurant
    ON restaurant_table (restaurant_id);

CREATE INDEX idx_rest_res_restaurant
    ON restaurant_reservation (restaurant_id);

CREATE INDEX idx_rest_res_guest
    ON restaurant_reservation (guest_id);

CREATE INDEX idx_rest_res_table
    ON restaurant_reservation (table_id);

CREATE INDEX idx_rest_res_time
    ON restaurant_reservation (reservation_time);


-- =========================================================
-- MENU / ORDER INDEXES
-- =========================================================

CREATE INDEX idx_menu_item_restaurant
    ON menu_item (restaurant_id);

CREATE INDEX idx_order_restaurant
    ON restaurant_order (restaurant_id);

CREATE INDEX idx_order_table
    ON restaurant_order (table_id);

CREATE INDEX idx_order_reservation
    ON restaurant_order (restaurant_reservation_id);

CREATE INDEX idx_order_folio
    ON restaurant_order (folio_id);

CREATE INDEX idx_order_item_order
    ON order_item (order_id);

CREATE INDEX idx_order_item_menu
    ON order_item (menu_item_id);