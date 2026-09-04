   SET SERVEROUTPUT ON;

declare
   lv_passed         number := 0;
   lv_failed         number := 0;

   lv_test_guest_id number;
   lv_test_room_id number;

   lv_reservation_id number;

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

begin

    -- Resolve test data using stable business identifiers.
    SELECT guest_id
    INTO lv_test_guest_id
    FROM guest
    WHERE email = 'daniel.carter@example.com';


    SELECT room_id
    INTO lv_test_room_id
    FROM room
    WHERE room_number = '201';

   dbms_output.put_line('=== RESERVATION MANAGEMENT TESTS ===');
   dbms_output.put_line('');


    -- =====================================================
    -- TEST 1
    -- Guest does not exist
    -- Expected: -20001
    -- =====================================================

   begin
      reservation_management_pkg.create_reservation(
         p_guest_id       => 999999,
         p_check_in_date  => date '2027-01-10',
         p_check_out_date => date '2027-01-12',
         p_total_guests   => 1,
         p_reservation_id => lv_reservation_id
      );

      print_result(
         'Reject nonexistent guest',
         false,
         'No exception was raised.'
      );
   exception
      when others then
         print_result(
            'Reject nonexistent guest',
            sqlcode = -20001,
            'Expected -20001, received '
            || sqlcode
            || ': '
            || sqlerrm
         );
   end;



    -- =====================================================
    -- TEST 2
    -- Invalid date range
    -- Expected: -20004
    -- =====================================================

   begin
      reservation_management_pkg.create_reservation(
         p_guest_id       => lv_test_guest_id,
         p_check_in_date  => date '2027-01-15',
         p_check_out_date => date '2027-01-10',
         p_total_guests   => 1,
         p_reservation_id => lv_reservation_id
      );


      print_result(
         'Reject invalid date range',
         false,
         'No exception was raised.'
      );
   exception
      when others then
         print_result(
            'Reject invalid date range',
            sqlcode = -20004,
            'Expected -20004, received '
            || sqlcode
            || ': '
            || sqlerrm
         );
   end;



    -- =====================================================
    -- TEST 3
    -- Zero guests
    -- Expected: -20005
    -- =====================================================

   begin
      reservation_management_pkg.create_reservation(
         p_guest_id       => lv_test_guest_id,
         p_check_in_date  => date '2027-01-10',
         p_check_out_date => date '2027-01-12',
         p_total_guests   => 0,
         p_reservation_id => lv_reservation_id
      );


      print_result(
         'Reject zero guests',
         false,
         'No exception was raised.'
      );
   exception
      when others then
         print_result(
            'Reject zero guests',
            sqlcode = -20005,
            'Expected -20005, received '
            || sqlcode
            || ': '
            || sqlerrm
         );
   end;



    -- =====================================================
    -- TEST 4
    -- Reservation does not exist
    -- Expected: -20006
    -- =====================================================

   begin
      reservation_management_pkg.add_room_to_reservation(
         p_reservation_id => 999999,
         p_room_id        => lv_test_room_id,
         p_nightly_rate   => 220,
         p_occupants      => 1
      );


      print_result(
         'Reject nonexistent reservation',
         false,
         'No exception was raised.'
      );
   exception
      when others then
         print_result(
            'Reject nonexistent reservation',
            sqlcode = -20006,
            'Expected -20006, received '
            || sqlcode
            || ': '
            || sqlerrm
         );
   end;



    -- =====================================================
    -- TEST 5
    -- Room does not exist
    -- Expected: -20008
    -- =====================================================

   begin
      reservation_management_pkg.create_reservation(
         p_guest_id       => lv_test_guest_id,
         p_check_in_date  => date '2027-02-01',
         p_check_out_date => date '2027-02-03',
         p_total_guests   => 1,
         p_reservation_id => lv_reservation_id
      );


      reservation_management_pkg.add_room_to_reservation(
         p_reservation_id => lv_reservation_id,
         p_room_id        => 999999,
         p_nightly_rate   => 220,
         p_occupants      => 1
      );


      print_result(
         'Reject nonexistent room',
         false,
         'No exception was raised.'
      );
   exception
      when others then
         print_result(
            'Reject nonexistent room',
            sqlcode = -20008,
            'Expected -20008, received '
            || sqlcode
            || ': '
            || sqlerrm
         );

         rollback;
   end;



    -- =====================================================
    -- TEST 6
    -- Too many occupants
    -- Standard King max occupancy = 2
    -- Expected: -20011
    -- =====================================================

   begin
      reservation_management_pkg.create_reservation(
         p_guest_id       => lv_test_guest_id,
         p_check_in_date  => date '2027-03-01',
         p_check_out_date => date '2027-03-03',
         p_total_guests   => 3,
         p_reservation_id => lv_reservation_id
      );


      reservation_management_pkg.add_room_to_reservation(
         p_reservation_id => lv_reservation_id,
         p_room_id        => lv_test_room_id,
         p_nightly_rate   => 220,
         p_occupants      => 3
      );


      print_result(
         'Reject excessive room occupancy',
         false,
         'No exception was raised.'
      );
   exception
      when others then
         print_result(
            'Reject excessive room occupancy',
            sqlcode = -20011,
            'Expected -20011, received '
            || sqlcode
            || ': '
            || sqlerrm
         );

         rollback;
   end;

    -- =====================================================
-- TEST 7
-- Duplicate room assignment
-- Expected: -20013
-- =====================================================

   begin
      reservation_management_pkg.create_reservation(
         p_guest_id       => lv_test_guest_id,
         p_check_in_date  => date '2027-04-01',
         p_check_out_date => date '2027-04-03',
         p_total_guests   => 2,
         p_reservation_id => lv_reservation_id
      );

      reservation_management_pkg.add_room_to_reservation(
         p_reservation_id => lv_reservation_id,
         p_room_id        => lv_test_room_id,
         p_nightly_rate   => 220,
         p_occupants      => 2
      );

      reservation_management_pkg.add_room_to_reservation(
         p_reservation_id => lv_reservation_id,
         p_room_id        => lv_test_room_id,
         p_nightly_rate   => 220,
         p_occupants      => 2
      );

      print_result(
         'Reject duplicate room assignment',
         false,
         'No exception was raised.'
      );
   exception
      when others then
         print_result(
            'Reject duplicate room assignment',
            sqlcode = -20013,
            'Expected -20013, received '
            || sqlcode
            || ': '
            || sqlerrm
         );

         rollback;
   end;

-- =====================================================
-- TEST 8
-- Double-book same room for overlapping dates
-- Expected: -20014
-- =====================================================

   declare
      lv_reservation_1 number;
      lv_reservation_2 number;
   begin

    -- First reservation
      reservation_management_pkg.create_reservation(
         p_guest_id       => lv_test_guest_id,
         p_check_in_date  => date '2027-05-10',
         p_check_out_date => date '2027-05-15',
         p_total_guests   => 2,
         p_reservation_id => lv_reservation_1
      );

      reservation_management_pkg.add_room_to_reservation(
         p_reservation_id => lv_reservation_1,
         p_room_id        => lv_test_room_id,
         p_nightly_rate   => 220,
         p_occupants      => 2
      );


    -- Overlapping reservation
      reservation_management_pkg.create_reservation(
         p_guest_id       => lv_test_guest_id,
         p_check_in_date  => date '2027-05-12',
         p_check_out_date => date '2027-05-14',
         p_total_guests   => 1,
         p_reservation_id => lv_reservation_2
      );

      reservation_management_pkg.add_room_to_reservation(
         p_reservation_id => lv_reservation_2,
         p_room_id        => lv_test_room_id,
         p_nightly_rate   => 220,
         p_occupants      => 1
      );


      print_result(
         'Reject overlapping room reservation',
         false,
         'No exception was raised.'
      );
   exception
      when others then
         print_result(
            'Reject overlapping room reservation',
            sqlcode = -20014,
            'Expected -20014, received '
            || sqlcode
            || ': '
            || sqlerrm
         );

         rollback;
   end;

-- =====================================================
-- TEST 9
-- Assigned occupants do not match reservation total
-- Expected: -20016
-- =====================================================

   begin
      reservation_management_pkg.create_reservation(
         p_guest_id       => lv_test_guest_id,
         p_check_in_date  => date '2027-06-01',
         p_check_out_date => date '2027-06-03',
         p_total_guests   => 3,
         p_reservation_id => lv_reservation_id
      );

      reservation_management_pkg.add_room_to_reservation(
         p_reservation_id => lv_reservation_id,
         p_room_id        => lv_test_room_id,
         p_nightly_rate   => 220,
         p_occupants      => 2
      );


      reservation_management_pkg.validate_guest_count(lv_reservation_id);
      print_result(
         'Reject guest-count mismatch',
         false,
         'No exception was raised.'
      );
   exception
      when others then
         print_result(
            'Reject guest-count mismatch',
            sqlcode = -20016,
            'Expected -20016, received '
            || sqlcode
            || ': '
            || sqlerrm
         );

         rollback;
   end;

-- =====================================================
-- TEST 10
-- Maintenance room cannot be assigned
-- Expected: -20009
-- =====================================================

   begin
      update room
         set
         operational_status = 'MAINTENANCE'
       where room_id = lv_test_room_id;


      reservation_management_pkg.create_reservation(
         p_guest_id       => lv_test_guest_id,
         p_check_in_date  => date '2027-07-01',
         p_check_out_date => date '2027-07-03',
         p_total_guests   => 1,
         p_reservation_id => lv_reservation_id
      );


      reservation_management_pkg.add_room_to_reservation(
         p_reservation_id => lv_reservation_id,
         p_room_id        => lv_test_room_id,
         p_nightly_rate   => 220,
         p_occupants      => 1
      );


      print_result(
         'Reject maintenance room',
         false,
         'No exception was raised.'
      );
   exception
      when others then
         print_result(
            'Reject maintenance room',
            sqlcode = -20009,
            'Expected -20009, received '
            || sqlcode
            || ': '
            || sqlerrm
         );

         rollback;
   end;

-- =====================================================
-- TEST 11
-- Valid reservation and room assignment
-- Expected: success
-- =====================================================

   declare
      lv_test_reservation number;
   begin
      reservation_management_pkg.create_reservation(
         p_guest_id       => lv_test_guest_id,
         p_check_in_date  => date '2027-08-01',
         p_check_out_date => date '2027-08-03',
         p_total_guests   => 2,
         p_reservation_id => lv_test_reservation
      );


      reservation_management_pkg.add_room_to_reservation(
         p_reservation_id => lv_test_reservation,
         p_room_id        => lv_test_room_id,
         p_nightly_rate   => 220,
         p_occupants      => 2
      );


      reservation_management_pkg.validate_guest_count(lv_test_reservation);
      print_result(
         'Create valid reservation',
         true
      );
      rollback;
   exception
      when others then
         print_result(
            'Create valid reservation',
            false,
            'Unexpected error '
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