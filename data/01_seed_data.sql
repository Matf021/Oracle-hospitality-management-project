-- =========================================================
-- Hospitality Management System
-- data/01_seed_data.sql
-- =========================================================


-- =========================================================
-- ROOM TYPES
-- =========================================================

INSERT INTO room_type (
    type_name,
    description,
    base_rate,
    max_occupancy
)
VALUES (
    'Standard King',
    'Standard guest room with one king bed.',
    220.00,
    2
);

INSERT INTO room_type (
    type_name,
    description,
    base_rate,
    max_occupancy
)
VALUES (
    'Standard Double',
    'Standard guest room with two double beds.',
    240.00,
    4
);

INSERT INTO room_type (
    type_name,
    description,
    base_rate,
    max_occupancy
)
VALUES (
    'Deluxe King',
    'Spacious guest room with king bed and upgraded amenities.',
    310.00,
    2
);

INSERT INTO room_type (
    type_name,
    description,
    base_rate,
    max_occupancy
)
VALUES (
    'Junior Suite',
    'Large suite with separate sitting area.',
    425.00,
    3
);

INSERT INTO room_type (
    type_name,
    description,
    base_rate,
    max_occupancy
)
VALUES (
    'Executive Suite',
    'Premium suite with separate bedroom and living area.',
    650.00,
    4
);

-- =========================================================
-- ROOMS
-- =========================================================

INSERT INTO room (room_number, room_type_id, floor_number)
VALUES ('201', 1, 2);

INSERT INTO room (room_number, room_type_id, floor_number)
VALUES ('202', 1, 2);

INSERT INTO room (room_number, room_type_id, floor_number)
VALUES ('203', 2, 2);

INSERT INTO room (room_number, room_type_id, floor_number)
VALUES ('204', 2, 2);

INSERT INTO room (room_number, room_type_id, floor_number)
VALUES ('301', 3, 3);

INSERT INTO room (room_number, room_type_id, floor_number)
VALUES ('302', 3, 3);

INSERT INTO room (room_number, room_type_id, floor_number)
VALUES ('303', 3, 3);

INSERT INTO room (room_number, room_type_id, floor_number)
VALUES ('401', 4, 4);

INSERT INTO room (room_number, room_type_id, floor_number)
VALUES ('402', 4, 4);

INSERT INTO room (room_number, room_type_id, floor_number)
VALUES ('501', 5, 5);

-- =========================================================
-- AMENITIES
-- =========================================================

INSERT INTO amenity (amenity_name, description)
VALUES ('Wi-Fi', 'Complimentary high-speed wireless internet.');

INSERT INTO amenity (amenity_name, description)
VALUES ('Smart TV', 'Smart television with streaming support.');

INSERT INTO amenity (amenity_name, description)
VALUES ('Mini Bar', 'In-room refrigerated mini bar.');

INSERT INTO amenity (amenity_name, description)
VALUES ('Coffee Machine', 'In-room espresso and coffee machine.');

INSERT INTO amenity (amenity_name, description)
VALUES ('Bathrobe', 'Complimentary bathrobe for use during the stay.');

INSERT INTO amenity (amenity_name, description)
VALUES ('Soaking Tub', 'Deep soaking bathtub.');

INSERT INTO amenity (amenity_name, description)
VALUES ('Living Area', 'Separate furnished living area.');

-- Standard King 201
INSERT INTO room_amenity VALUES (1, 1);
INSERT INTO room_amenity VALUES (1, 2);
INSERT INTO room_amenity VALUES (1, 4);

-- Standard King 202
INSERT INTO room_amenity VALUES (2, 1);
INSERT INTO room_amenity VALUES (2, 2);
INSERT INTO room_amenity VALUES (2, 4);

-- Deluxe King 301
INSERT INTO room_amenity VALUES (5, 1);
INSERT INTO room_amenity VALUES (5, 2);
INSERT INTO room_amenity VALUES (5, 3);
INSERT INTO room_amenity VALUES (5, 4);
INSERT INTO room_amenity VALUES (5, 5);

-- Junior Suite 401
INSERT INTO room_amenity VALUES (8, 1);
INSERT INTO room_amenity VALUES (8, 2);
INSERT INTO room_amenity VALUES (8, 3);
INSERT INTO room_amenity VALUES (8, 4);
INSERT INTO room_amenity VALUES (8, 5);
INSERT INTO room_amenity VALUES (8, 6);

-- Executive Suite 501
INSERT INTO room_amenity VALUES (10, 1);
INSERT INTO room_amenity VALUES (10, 2);
INSERT INTO room_amenity VALUES (10, 3);
INSERT INTO room_amenity VALUES (10, 4);
INSERT INTO room_amenity VALUES (10, 5);
INSERT INTO room_amenity VALUES (10, 6);
INSERT INTO room_amenity VALUES (10, 7);

-- =========================================================
-- GUESTS
-- =========================================================

INSERT INTO guest (
    first_name,
    last_name,
    email,
    phone_number,
    date_of_birth,
    address_line,
    city,
    country
)
VALUES (
    'Daniel',
    'Carter',
    'daniel.carter@example.com',
    '+1-416-555-0101',
    DATE '1988-04-14',
    '120 King Street',
    'Toronto',
    'Canada'
);

INSERT INTO guest (
    first_name,
    last_name,
    email,
    phone_number,
    date_of_birth,
    city,
    country
)
VALUES (
    'Sofia',
    'Martinez',
    'sofia.martinez@example.com',
    '+1-647-555-0122',
    DATE '1992-11-03',
    'Montreal',
    'Canada'
);

INSERT INTO guest (
    first_name,
    last_name,
    email,
    phone_number,
    date_of_birth,
    city,
    country
)
VALUES (
    'Oliver',
    'Bennett',
    'oliver.bennett@example.com',
    '+44-20-5555-0133',
    DATE '1981-07-21',
    'London',
    'United Kingdom'
);

INSERT INTO guest (
    first_name,
    last_name,
    email,
    phone_number,
    city,
    country
)
VALUES (
    'Maya',
    'Thompson',
    'maya.thompson@example.com',
    '+1-212-555-0144',
    'New York',
    'United States'
);

INSERT INTO guest (
    first_name,
    last_name,
    email,
    phone_number,
    city,
    country
)
VALUES (
    'Lucas',
    'Moreau',
    'lucas.moreau@example.com',
    '+33-1-55-55-0155',
    'Paris',
    'France'
);

-- =========================================================
-- RESTAURANTS
-- =========================================================

INSERT INTO restaurant (
    restaurant_name,
    location,
    opening_time,
    closing_time
)
VALUES (
    'The Atrium',
    'Ground Floor',
    '07:00',
    '22:00'
);

INSERT INTO restaurant (
    restaurant_name,
    location,
    opening_time,
    closing_time
)
VALUES (
    'Ember',
    'Second Floor',
    '17:00',
    '23:00'
);

INSERT INTO restaurant (
    restaurant_name,
    location,
    opening_time,
    closing_time
)
VALUES (
    'Skyline Bar',
    'Rooftop',
    '16:00',
    '01:00'
);

-- =========================================================
-- RESTAURANT TABLES
-- =========================================================

-- The Atrium
INSERT INTO restaurant_table (restaurant_id, table_number, capacity)
VALUES (1, 'A1', 2);

INSERT INTO restaurant_table (restaurant_id, table_number, capacity)
VALUES (1, 'A2', 2);

INSERT INTO restaurant_table (restaurant_id, table_number, capacity)
VALUES (1, 'A3', 4);

INSERT INTO restaurant_table (restaurant_id, table_number, capacity)
VALUES (1, 'A4', 6);


-- Ember
INSERT INTO restaurant_table (restaurant_id, table_number, capacity)
VALUES (2, 'E1', 2);

INSERT INTO restaurant_table (restaurant_id, table_number, capacity)
VALUES (2, 'E2', 2);

INSERT INTO restaurant_table (restaurant_id, table_number, capacity)
VALUES (2, 'E3', 4);

INSERT INTO restaurant_table (restaurant_id, table_number, capacity)
VALUES (2, 'E4', 6);


-- Skyline Bar
INSERT INTO restaurant_table (restaurant_id, table_number, capacity)
VALUES (3, 'S1', 2);

INSERT INTO restaurant_table (restaurant_id, table_number, capacity)
VALUES (3, 'S2', 4);

INSERT INTO restaurant_table (restaurant_id, table_number, capacity)
VALUES (3, 'S3', 6);

-- =========================================================
-- MENU ITEMS
-- =========================================================

-- The Atrium

INSERT INTO menu_item (
    restaurant_id,
    item_name,
    item_category,
    description,
    price
)
VALUES (
    1,
    'Buttermilk Pancakes',
    'BREAKFAST',
    'Buttermilk pancakes with maple syrup and seasonal fruit.',
    18.00
);

INSERT INTO menu_item (
    restaurant_id,
    item_name,
    item_category,
    description,
    price
)
VALUES (
    1,
    'Eggs Benedict',
    'BREAKFAST',
    'Poached eggs, English muffin, ham and hollandaise.',
    22.00
);

INSERT INTO menu_item (
    restaurant_id,
    item_name,
    item_category,
    description,
    price
)
VALUES (
    1,
    'Caesar Salad',
    'FOOD',
    'Romaine lettuce, parmesan, croutons and Caesar dressing.',
    19.00
);


-- Ember

INSERT INTO menu_item (
    restaurant_id,
    item_name,
    item_category,
    description,
    price
)
VALUES (
    2,
    'Seared Scallops',
    'FOOD',
    'Seared scallops with cauliflower puree and brown butter.',
    34.00
);

INSERT INTO menu_item (
    restaurant_id,
    item_name,
    item_category,
    description,
    price
)
VALUES (
    2,
    'Braised Short Rib',
    'FOOD',
    'Slow-braised beef short rib with seasonal vegetables.',
    42.00
);

INSERT INTO menu_item (
    restaurant_id,
    item_name,
    item_category,
    description,
    price
)
VALUES (
    2,
    'Chocolate Souffle',
    'DESSERT',
    'Warm dark chocolate souffle.',
    16.00
);


-- Skyline Bar

INSERT INTO menu_item (
    restaurant_id,
    item_name,
    item_category,
    description,
    price
)
VALUES (
    3,
    'Old Fashioned',
    'COCKTAIL',
    'Bourbon, bitters and sugar.',
    20.00
);

INSERT INTO menu_item (
    restaurant_id,
    item_name,
    item_category,
    description,
    price
)
VALUES (
    3,
    'Martini',
    'COCKTAIL',
    'Gin and dry vermouth.',
    21.00
);

INSERT INTO menu_item (
    restaurant_id,
    item_name,
    item_category,
    description,
    price
)
VALUES (
    3,
    'Cheese Selection',
    'FOOD',
    'Selection of cheeses with seasonal accompaniments.',
    24.00
);