   SET SERVEROUTPUT ON;

declare
   lv_passed                number := 0;
   lv_failed                number := 0;
   lv_test_guest_id         number;
   lv_test_room_id          number;
   lv_skyline_restaurant_id number;
   lv_atrium_table_id       number;
   lv_skyline_table_id      number;
   lv_old_fashioned_id      number;
   lv_cheese_selection_id   number;
   lv_atrium_menu_item_id   number;


   procedure print_result (
      p_test_name in varchar2,
      p_passed    in boolean,
      p_message   in varchar2 default null
   ) is
   begin
      if p_passed then
         lv_passed := lv_passed + 1;
         dbms_output.put_line('[PASS] ' || p_test_name);
      else
         lv_failed := lv_failed + 1;
         dbms_output.put_line('[FAIL] '
                              || p_test_name ||
            case
               when p_message is not null then
                  ' - ' || p_message
            end
         );
      end if;
   end print_result;


    -- Creates a checked-in guest with an OPEN folio.
   procedure create_test_folio (
      p_check_in_date  in date,
      p_check_out_date in date,
      p_reservation_id out number,
      p_stay_id        out number,
      p_folio_id       out number
   ) is
   begin
      reservation_management_pkg.create_reservation(
         p_guest_id       => lv_test_guest_id,
         p_check_in_date  => p_check_in_date,
         p_check_out_date => p_check_out_date,
         p_total_guests   => 2,
         p_reservation_id => p_reservation_id
      );

      reservation_management_pkg.add_room_to_reservation(
         p_reservation_id => p_reservation_id,
         p_room_id        => lv_test_room_id,
         p_nightly_rate   => 220,
         p_occupants      => 2
      );

      stay_folio_management_pkg.check_in_reservation(
         p_reservation_id => p_reservation_id,
         p_stay_id        => p_stay_id,
         p_folio_id       => p_folio_id
      );

   end create_test_folio;


begin

    -- Resolve test data using stable business identifiers.
   select guest_id
     into lv_test_guest_id
     from guest
    where email = 'daniel.carter@example.com';

   select room_id
     into lv_test_room_id
     from room
    where room_number = '201';

   select restaurant_id
     into lv_skyline_restaurant_id
     from restaurant
    where restaurant_name = 'Skyline Bar';

   select table_id
     into lv_atrium_table_id
     from restaurant_table rt
     join restaurant r
   on r.restaurant_id = rt.restaurant_id
    where r.restaurant_name = 'The Atrium'
      and rt.table_number = 'A1';

   select table_id
     into lv_skyline_table_id
     from restaurant_table rt
     join restaurant r
   on r.restaurant_id = rt.restaurant_id
    where r.restaurant_name = 'Skyline Bar'
      and rt.table_number = 'S1';

   select menu_item_id
     into lv_old_fashioned_id
     from menu_item mi
     join restaurant r
   on r.restaurant_id = mi.restaurant_id
    where r.restaurant_name = 'Skyline Bar'
      and mi.item_name = 'Old Fashioned';

   select menu_item_id
     into lv_cheese_selection_id
     from menu_item mi
     join restaurant r
   on r.restaurant_id = mi.restaurant_id
    where r.restaurant_name = 'Skyline Bar'
      and mi.item_name = 'Cheese Selection';

   select menu_item_id
     into lv_atrium_menu_item_id
     from menu_item mi
     join restaurant r
   on r.restaurant_id = mi.restaurant_id
    where r.restaurant_name = 'The Atrium'
      and mi.item_name = 'Buttermilk Pancakes';

   dbms_output.put_line('=== RESTAURANT ORDER MANAGEMENT TESTS ===');
   dbms_output.put_line('');

    -- =====================================================
    -- TEST 1
    -- Nonexistent restaurant
    -- Expected: -20301
    -- =====================================================

   declare
      lv_order_id number;
   begin
      restaurant_order_management_pkg.create_order(
         p_restaurant_id             => 999999,
         p_table_id                  => null,
         p_restaurant_reservation_id => null,
         p_folio_id                  => null,
         p_payment_destination       => 'DIRECT',
         p_order_id                  => lv_order_id
      );

      print_result(
         'Reject nonexistent restaurant',
         false,
         'No exception was raised.'
      );
   exception
      when others then
         print_result(
            'Reject nonexistent restaurant',
            sqlcode = -20301,
            'Expected -20301, received '
            || sqlcode
            || ': '
            || sqlerrm
         );

         rollback;
   end;


    -- =====================================================
    -- TEST 2
    -- Table belongs to another restaurant
    --
    -- Atrium table cannot be used for a Skyline Bar order.
    --
    -- Expected: -20302
    -- =====================================================

   declare
      lv_order_id number;
   begin
      restaurant_order_management_pkg.create_order(
         p_restaurant_id             => lv_skyline_restaurant_id,
         p_table_id                  => lv_atrium_table_id,
         p_restaurant_reservation_id => null,
         p_folio_id                  => null,
         p_payment_destination       => 'DIRECT',
         p_order_id                  => lv_order_id
      );

      print_result(
         'Reject table from another restaurant',
         false,
         'No exception was raised.'
      );
   exception
      when others then
         print_result(
            'Reject table from another restaurant',
            sqlcode = -20302,
            'Expected -20302, received '
            || sqlcode
            || ': '
            || sqlerrm
         );

         rollback;
   end;


    -- =====================================================
    -- TEST 3
    -- Invalid payment destination
    -- Expected: -20303
    -- =====================================================

   declare
      lv_order_id number;
   begin
      restaurant_order_management_pkg.create_order(
         p_restaurant_id             => lv_skyline_restaurant_id,
         p_table_id                  => lv_skyline_table_id,
         p_restaurant_reservation_id => null,
         p_folio_id                  => null,
         p_payment_destination       => 'BITCOIN',
         p_order_id                  => lv_order_id
      );

      print_result(
         'Reject invalid payment destination',
         false,
         'No exception was raised.'
      );
   exception
      when others then
         print_result(
            'Reject invalid payment destination',
            sqlcode = -20303,
            'Expected -20303, received '
            || sqlcode
            || ': '
            || sqlerrm
         );

         rollback;
   end;


    -- =====================================================
    -- TEST 4
    -- ROOM_CHARGE requires a folio
    -- Expected: -20304
    -- =====================================================

   declare
      lv_order_id number;
   begin
      restaurant_order_management_pkg.create_order(
         p_restaurant_id             => lv_skyline_restaurant_id,
         p_table_id                  => lv_skyline_table_id,
         p_restaurant_reservation_id => null,
         p_folio_id                  => null,
         p_payment_destination       => 'ROOM_CHARGE',
         p_order_id                  => lv_order_id
      );

      print_result(
         'Reject room charge without folio',
         false,
         'No exception was raised.'
      );
   exception
      when others then
         print_result(
            'Reject room charge without folio',
            sqlcode = -20304,
            'Expected -20304, received '
            || sqlcode
            || ': '
            || sqlerrm
         );

         rollback;
   end;


    -- =====================================================
    -- TEST 5
    -- DIRECT payment must not reference a folio
    -- Expected: -20306
    -- =====================================================

   declare
      lv_reservation_id number;
      lv_stay_id        number;
      lv_folio_id       number;
      lv_order_id       number;
   begin
      create_test_folio(
         date '2028-09-01',
         date '2028-09-03',
         lv_reservation_id,
         lv_stay_id,
         lv_folio_id
      );
      restaurant_order_management_pkg.create_order(
         p_restaurant_id             => lv_skyline_restaurant_id,
         p_table_id                  => lv_skyline_table_id,
         p_restaurant_reservation_id => null,
         p_folio_id                  => lv_folio_id,
         p_payment_destination       => 'DIRECT',
         p_order_id                  => lv_order_id
      );

      print_result(
         'Reject direct payment with folio',
         false,
         'No exception was raised.'
      );
   exception
      when others then
         print_result(
            'Reject direct payment with folio',
            sqlcode = -20306,
            'Expected -20306, received '
            || sqlcode
            || ': '
            || sqlerrm
         );

         rollback;
   end;


    -- =====================================================
    -- TEST 6
    -- Quantity must be positive
    -- Expected: -20309
    -- =====================================================

   declare
      lv_order_id number;
   begin
      restaurant_order_management_pkg.create_order(
         p_restaurant_id             => lv_skyline_restaurant_id,
         p_table_id                  => lv_skyline_table_id,
         p_restaurant_reservation_id => null,
         p_folio_id                  => null,
         p_payment_destination       => 'DIRECT',
         p_order_id                  => lv_order_id
      );

      restaurant_order_management_pkg.add_order_item(
         p_order_id     => lv_order_id,
         p_menu_item_id => lv_old_fashioned_id,
         p_quantity     => 0,
         p_notes        => null
      );

      print_result(
         'Reject zero item quantity',
         false,
         'No exception was raised.'
      );
   exception
      when others then
         print_result(
            'Reject zero item quantity',
            sqlcode = -20309,
            'Expected -20309, received '
            || sqlcode
            || ': '
            || sqlerrm
         );

         rollback;
   end;


    -- =====================================================
    -- TEST 7
    -- Menu item belongs to another restaurant
    --
    -- Atrium menu item cannot be added to a Skyline Bar order.
    --
    -- Expected: -20310
    -- =====================================================

   declare
      lv_order_id number;
   begin
      restaurant_order_management_pkg.create_order(
         p_restaurant_id             => lv_skyline_restaurant_id,
         p_table_id                  => lv_skyline_table_id,
         p_restaurant_reservation_id => null,
         p_folio_id                  => null,
         p_payment_destination       => 'DIRECT',
         p_order_id                  => lv_order_id
      );

      restaurant_order_management_pkg.add_order_item(
         p_order_id     => lv_order_id,
         p_menu_item_id => lv_atrium_menu_item_id,
         p_quantity     => 1,
         p_notes        => null
      );

      print_result(
         'Reject menu item from another restaurant',
         false,
         'No exception was raised.'
      );
   exception
      when others then
         print_result(
            'Reject menu item from another restaurant',
            sqlcode = -20310,
            'Expected -20310, received '
            || sqlcode
            || ': '
            || sqlerrm
         );

         rollback;
   end;


    -- =====================================================
    -- TEST 8
    -- Unavailable menu item
    -- Expected: -20311
    -- =====================================================

   declare
      lv_order_id number;
   begin
      update menu_item
         set
         is_available = 'N'
       where menu_item_id = lv_old_fashioned_id;

      restaurant_order_management_pkg.create_order(
         p_restaurant_id             => lv_skyline_restaurant_id,
         p_table_id                  => lv_skyline_table_id,
         p_restaurant_reservation_id => null,
         p_folio_id                  => null,
         p_payment_destination       => 'DIRECT',
         p_order_id                  => lv_order_id
      );

      restaurant_order_management_pkg.add_order_item(
         p_order_id     => lv_order_id,
         p_menu_item_id => lv_old_fashioned_id,
         p_quantity     => 1,
         p_notes        => null
      );

      print_result(
         'Reject unavailable menu item',
         false,
         'No exception was raised.'
      );
   exception
      when others then
         print_result(
            'Reject unavailable menu item',
            sqlcode = -20311,
            'Expected -20311, received '
            || sqlcode
            || ': '
            || sqlerrm
         );

         rollback;
   end;


    -- =====================================================
    -- TEST 9
    -- Cannot close an empty order
    -- Expected: -20314
    -- =====================================================

   declare
      lv_order_id number;
   begin
      restaurant_order_management_pkg.create_order(
         p_restaurant_id             => lv_skyline_restaurant_id,
         p_table_id                  => lv_skyline_table_id,
         p_restaurant_reservation_id => null,
         p_folio_id                  => null,
         p_payment_destination       => 'DIRECT',
         p_order_id                  => lv_order_id
      );

      restaurant_order_management_pkg.close_order(lv_order_id);
      print_result(
         'Reject closing empty order',
         false,
         'No exception was raised.'
      );
   exception
      when others then
         print_result(
            'Reject closing empty order',
            sqlcode = -20314,
            'Expected -20314, received '
            || sqlcode
            || ': '
            || sqlerrm
         );

         rollback;
   end;


    -- =====================================================
    -- TEST 10
    -- Successful ROOM_CHARGE posting
    --
    -- 2 Old Fashioned = 2 x $20 = $40
    -- 1 Cheese Selection = $24
    -- Expected total = $64
    -- =====================================================

   declare
      lv_reservation_id number;
      lv_stay_id        number;
      lv_folio_id       number;
      lv_order_id       number;
      lv_charge_amount  number;
   begin
      create_test_folio(
         date '2028-10-01',
         date '2028-10-03',
         lv_reservation_id,
         lv_stay_id,
         lv_folio_id
      );
      restaurant_order_management_pkg.create_order(
         p_restaurant_id             => lv_skyline_restaurant_id,
         p_table_id                  => lv_skyline_table_id,
         p_restaurant_reservation_id => null,
         p_folio_id                  => lv_folio_id,
         p_payment_destination       => 'ROOM_CHARGE',
         p_order_id                  => lv_order_id
      );

      restaurant_order_management_pkg.add_order_item(
         p_order_id     => lv_order_id,
         p_menu_item_id => lv_old_fashioned_id,
         p_quantity     => 2,
         p_notes        => null
      );

      restaurant_order_management_pkg.add_order_item(
         p_order_id     => lv_order_id,
         p_menu_item_id => lv_cheese_selection_id,
         p_quantity     => 1,
         p_notes        => null
      );

      restaurant_order_management_pkg.post_order_to_folio(lv_order_id);
      select amount
        into lv_charge_amount
        from folio_charge
       where folio_id = lv_folio_id
         and charge_type = 'RESTAURANT'
         and reference_id = lv_order_id;

      if lv_charge_amount = 64 then
         print_result(
            'Post restaurant order to folio',
            true
         );
      else
         print_result(
            'Post restaurant order to folio',
            false,
            'Expected $64, received $' || to_char(lv_charge_amount)
         );
      end if;

      rollback;
   exception
      when others then
         print_result(
            'Post restaurant order to folio',
            false,
            'Unexpected error '
            || sqlcode
            || ': '
            || sqlerrm
         );
         rollback;
   end;


    -- =====================================================
    -- TEST 11
    -- Duplicate restaurant charge
    -- Expected: -20319
    -- =====================================================

   declare
      lv_reservation_id number;
      lv_stay_id        number;
      lv_folio_id       number;
      lv_order_id       number;
   begin
      create_test_folio(
         date '2028-11-01',
         date '2028-11-03',
         lv_reservation_id,
         lv_stay_id,
         lv_folio_id
      );
      restaurant_order_management_pkg.create_order(
         p_restaurant_id             => lv_skyline_restaurant_id,
         p_table_id                  => lv_skyline_table_id,
         p_restaurant_reservation_id => null,
         p_folio_id                  => lv_folio_id,
         p_payment_destination       => 'ROOM_CHARGE',
         p_order_id                  => lv_order_id
      );

      restaurant_order_management_pkg.add_order_item(
         p_order_id     => lv_order_id,
         p_menu_item_id => lv_old_fashioned_id,
         p_quantity     => 1,
         p_notes        => null
      );

      restaurant_order_management_pkg.post_order_to_folio(lv_order_id);
      restaurant_order_management_pkg.post_order_to_folio(lv_order_id);
      print_result(
         'Reject duplicate restaurant charge',
         false,
         'No exception was raised.'
      );
   exception
      when others then
         print_result(
            'Reject duplicate restaurant charge',
            sqlcode = -20319,
            'Expected -20319, received '
            || sqlcode
            || ': '
            || sqlerrm
         );

         rollback;
   end;


    -- =====================================================
    -- TEST 12
    -- VOID orders must never be posted to a folio.
    --
    -- This is intentionally testing a suspected bug.
    --
    -- We will use -20321 as the desired business error.
    -- The current package may NOT raise it yet.
    -- =====================================================

   declare
      lv_reservation_id number;
      lv_stay_id        number;
      lv_folio_id       number;
      lv_order_id       number;
   begin
      create_test_folio(
         date '2028-12-01',
         date '2028-12-03',
         lv_reservation_id,
         lv_stay_id,
         lv_folio_id
      );
      restaurant_order_management_pkg.create_order(
         p_restaurant_id             => lv_skyline_restaurant_id,
         p_table_id                  => lv_skyline_table_id,
         p_restaurant_reservation_id => null,
         p_folio_id                  => lv_folio_id,
         p_payment_destination       => 'ROOM_CHARGE',
         p_order_id                  => lv_order_id
      );

      restaurant_order_management_pkg.add_order_item(
         p_order_id     => lv_order_id,
         p_menu_item_id => lv_old_fashioned_id,
         p_quantity     => 1,
         p_notes        => null
      );

        -- Simulate a voided order.
      update restaurant_order
         set
         order_status = 'VOID'
       where order_id = lv_order_id;

      restaurant_order_management_pkg.post_order_to_folio(lv_order_id);
      print_result(
         'Reject posting void order',
         false,
         'VOID order was posted to the folio.'
      );
      rollback;
   exception
      when others then
         print_result(
            'Reject posting void order',
            sqlcode = -20321,
            'Expected -20321, received '
            || sqlcode
            || ': '
            || sqlerrm
         );

         rollback;
   end;


   dbms_output.put_line('');
   dbms_output.put_line('==============================');
   dbms_output.put_line('PASSED: ' || lv_passed);
   dbms_output.put_line('FAILED: ' || lv_failed);
   dbms_output.put_line('==============================');
   rollback;
end;
/