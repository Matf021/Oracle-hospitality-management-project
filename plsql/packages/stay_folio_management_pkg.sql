create or replace package stay_folio_management_pkg as
   function calculate_room_charges (
      p_reservation_id in number
   ) return number;


   function get_folio_balance (
      p_folio_id in number
   ) return number;


   procedure check_in_reservation (
      p_reservation_id in number,
      p_stay_id        out number,
      p_folio_id       out number
   );


   procedure post_room_charges (
      p_reservation_id in number
   );


   procedure checkout_reservation (
      p_reservation_id in number
   );

end stay_folio_management_pkg;
/

create or replace package body stay_folio_management_pkg as


    -- =====================================================
    -- FUNCTION: calculate_room_charges
    -- =====================================================

   function calculate_room_charges (
      p_reservation_id in number
   ) return number is
      lv_total number(
         10,
         2
      );
   begin
      select nvl(
         sum(rr.nightly_rate *(hr.check_out_date - hr.check_in_date)),
         0
      )
        into lv_total
        from hotel_reservation hr
        join reservation_room rr
      on rr.reservation_id = hr.reservation_id
       where hr.reservation_id = p_reservation_id;

      return lv_total;
   end calculate_room_charges;



    -- =====================================================
    -- FUNCTION: get_folio_balance
    -- =====================================================

   function get_folio_balance (
      p_folio_id in number
   ) return number is
      lv_charges  number(
         10,
         2
      );
      lv_payments number(
         10,
         2
      );
   begin
      select nvl(
         sum(amount),
         0
      )
        into lv_charges
        from folio_charge
       where folio_id = p_folio_id;


      select nvl(
         sum(amount),
         0
      )
        into lv_payments
        from payment
       where folio_id = p_folio_id
         and payment_status = 'COMPLETED';


      return lv_charges - lv_payments;
   end get_folio_balance;



    -- =====================================================
    -- PROCEDURE: check_in_reservation
    -- =====================================================

   procedure check_in_reservation (
      p_reservation_id in number,
      p_stay_id        out number,
      p_folio_id       out number
   ) is
      lv_res_status    hotel_reservation.reservation_status%type;
      lv_room_count    number;
      lv_existing_stay number;
   begin

    -- Validate reservation exists and lock it
      begin
         select reservation_status
           into lv_res_status
           from hotel_reservation
          where reservation_id = p_reservation_id
         for update;

      exception
         when no_data_found then
            raise_application_error(
               -20104,
               'Reservation could not be found.'
            );
      end;


    -- Check whether this reservation already has a stay
      select count(*)
        into lv_existing_stay
        from stay
       where reservation_id = p_reservation_id;


      if lv_existing_stay > 0 then
         raise_application_error(
            -20103,
            'Reservation has already been checked in.'
         );
      end if;


    -- Reservation must still be BOOKED
      if lv_res_status != 'BOOKED' then
         raise_application_error(
            -20101,
            'Only booked reservations can be checked in.'
         );
      end if;


    -- Must have at least one room
      select count(*)
        into lv_room_count
        from reservation_room
       where reservation_id = p_reservation_id;


      if lv_room_count = 0 then
         raise_application_error(
            -20102,
            'Reservation must have at least one assigned room.'
         );
      end if;


    -- Validate total occupants
      reservation_management_pkg.validate_guest_count(p_reservation_id);


    -- Create stay
      insert into stay (
         reservation_id,
         actual_check_in,
         stay_status
      ) values
         ( p_reservation_id,
           systimestamp,
           'CHECKED_IN' )
      returning stay_id into p_stay_id;


    -- Open folio
      insert into guest_folio (
         stay_id,
         folio_status,
         opened_at
      ) values
         ( p_stay_id,
           'OPEN',
           systimestamp )
      returning folio_id into p_folio_id;


    -- Update reservation
      update hotel_reservation
         set
         reservation_status = 'CHECKED_IN'
       where reservation_id = p_reservation_id;


    -- Mark assigned rooms occupied
      update room
         set
         operational_status = 'OCCUPIED'
       where room_id in (
         select room_id
           from reservation_room
          where reservation_id = p_reservation_id
      );

   end check_in_reservation;



    -- =====================================================
    -- PROCEDURE: post_room_charges
    -- =====================================================

   procedure post_room_charges (
      p_reservation_id in number
   ) is
      lv_folio_id     number;
      lv_room_charges number(
         10,
         2
      );
      lv_charge_count number;
   begin

        -- Find active folio
      select gf.folio_id
        into lv_folio_id
        from guest_folio gf
        join stay s
      on s.stay_id = gf.stay_id
       where s.reservation_id = p_reservation_id
         and gf.folio_status = 'OPEN';


        -- Prevent room charges being posted twice
      select count(*)
        into lv_charge_count
        from folio_charge
       where folio_id = lv_folio_id
         and charge_type = 'ROOM'
         and reference_id = p_reservation_id;


      if lv_charge_count > 0 then
         raise_application_error(
            -20105,
            'Room charges have already been posted.'
         );
      end if;
      lv_room_charges := calculate_room_charges(p_reservation_id);
      if lv_room_charges <= 0 then
         raise_application_error(
            -20106,
            'No room charges were calculated.'
         );
      end if;
      insert into folio_charge (
         folio_id,
         charge_type,
         description,
         amount,
         reference_id
      ) values
         ( lv_folio_id,
           'ROOM',
           'Accommodation charges',
           lv_room_charges,
           p_reservation_id );


   exception
      when no_data_found then
         raise_application_error(
            -20107,
            'Open folio could not be found.'
         );
   end post_room_charges;



    -- =====================================================
    -- PROCEDURE: checkout_reservation
    -- =====================================================

   procedure checkout_reservation (
      p_reservation_id in number
   ) is
      lv_stay_id      number;
      lv_folio_id     number;
      lv_status       hotel_reservation.reservation_status%type;
      lv_balance      number(
         10,
         2
      );
      lv_charge_count number;
   begin
      select s.stay_id,
             gf.folio_id,
             hr.reservation_status
        into
         lv_stay_id,
         lv_folio_id,
         lv_status
        from hotel_reservation hr
        join stay s
      on s.reservation_id = hr.reservation_id
        join guest_folio gf
      on gf.stay_id = s.stay_id
       where hr.reservation_id = p_reservation_id
         and s.stay_status = 'CHECKED_IN'
         and gf.folio_status = 'OPEN'
      for update;


      if lv_status != 'CHECKED_IN' then
         raise_application_error(
            -20108,
            'Reservation is not currently checked in.'
         );
      end if;


        -- Check whether room charge already exists
      select count(*)
        into lv_charge_count
        from folio_charge
       where folio_id = lv_folio_id
         and charge_type = 'ROOM'
         and reference_id = p_reservation_id;


        -- Automatically post it if necessary
      if lv_charge_count = 0 then
         post_room_charges(p_reservation_id);
      end if;


        -- Calculate outstanding balance
      lv_balance := get_folio_balance(lv_folio_id);
      if lv_balance > 0 then
         raise_application_error(
            -20109,
            'Outstanding folio balance: $' || to_char(
               lv_balance,
               'FM9999990.00'
            )
         );
      end if;


        -- Close stay
      update stay
         set actual_check_out = systimestamp,
             stay_status = 'CHECKED_OUT'
       where stay_id = lv_stay_id;


        -- Close folio
      update guest_folio
         set folio_status = 'CLOSED',
             closed_at = systimestamp
       where folio_id = lv_folio_id;


        -- Complete reservation
      update hotel_reservation
         set
         reservation_status = 'COMPLETED'
       where reservation_id = p_reservation_id;


        -- Rooms now require housekeeping
      update room
         set
         operational_status = 'CLEANING'
       where room_id in (
         select room_id
           from reservation_room
          where reservation_id = p_reservation_id
      );


   exception
      when no_data_found then
         raise_application_error(
            -20110,
            'Active stay or folio could not be found.'
         );
   end checkout_reservation;


end stay_folio_management_pkg;
/

declare
   lv_stay_id  number;
   lv_folio_id number;
begin
   stay_folio_management_pkg.check_in_reservation(
      p_reservation_id => 1,
      p_stay_id        => lv_stay_id,
      p_folio_id       => lv_folio_id
   );

   dbms_output.put_line('Stay ID: ' || lv_stay_id);
   dbms_output.put_line('Folio ID: ' || lv_folio_id);
   commit;
end;
/

select *
  from stay;

select *
  from guest_folio;

select room_id,
       room_number,
       operational_status
  from room
 order by room_id;

select reservation_id,
       reservation_status
  from hotel_reservation;

begin
   stay_folio_management_pkg.post_room_charges(1);
   commit;
end;
/

select *
  from folio_charge;

select stay_folio_management_pkg.get_folio_balance(1) as outstanding_balance
  from dual;

begin
   stay_folio_management_pkg.checkout_reservation(1);
end;
/