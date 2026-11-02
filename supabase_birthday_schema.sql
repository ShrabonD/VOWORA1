-- ============================================================================
-- VOWORA — Birthday Module Database Schema
-- Run this script in your Supabase Dashboard SQL Editor
-- ============================================================================

-- 1. BIRTHDAY SERVICES CATALOG TABLE
CREATE TABLE IF NOT EXISTS public.birthday_services (
    id TEXT PRIMARY KEY,
    category TEXT NOT NULL CHECK (category IN ('catering', 'photography', 'decoration')),
    title TEXT NOT NULL,
    short_description TEXT NOT NULL,
    description TEXT NOT NULL,
    image_url TEXT NOT NULL,
    base_price NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    price_unit TEXT NOT NULL DEFAULT 'package', -- 'package', 'per_person', 'per_hour'
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.birthday_services ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Birthday services viewable by everyone" ON public.birthday_services;
CREATE POLICY "Birthday services viewable by everyone"
    ON public.birthday_services FOR SELECT USING (true);

-- 2. BIRTHDAY SERVICE PACKAGES TABLE
CREATE TABLE IF NOT EXISTS public.birthday_service_packages (
    id TEXT PRIMARY KEY,
    service_id TEXT NOT NULL REFERENCES public.birthday_services(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    tier TEXT NOT NULL CHECK (tier IN ('silver', 'gold', 'royal')),
    price NUMERIC(12,2) NOT NULL,
    description TEXT NOT NULL,
    image_url TEXT,
    inclusions JSONB NOT NULL DEFAULT '[]'::jsonb,
    available_addons JSONB NOT NULL DEFAULT '[]'::jsonb,
    is_active BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.birthday_service_packages ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Birthday packages viewable by everyone" ON public.birthday_service_packages;
CREATE POLICY "Birthday packages viewable by everyone"
    ON public.birthday_service_packages FOR SELECT USING (true);

-- 3. BIRTHDAY BOOKINGS TABLE
CREATE TABLE IF NOT EXISTS public.birthday_bookings (
    id TEXT PRIMARY KEY, -- e.g. BDAY-2026-XXXX
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    event_id TEXT,
    contact_name TEXT NOT NULL,
    contact_phone TEXT NOT NULL,
    contact_email TEXT,
    event_date DATE NOT NULL,
    time_slot TEXT NOT NULL CHECK (time_slot IN ('morning', 'afternoon', 'evening')),
    guest_count INT NOT NULL DEFAULT 25,
    venue_address TEXT,
    special_notes TEXT,
    subtotal_amount NUMERIC(12,2) NOT NULL,
    service_fee NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    discount_amount NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    total_amount NUMERIC(12,2) NOT NULL,
    amount_paid NUMERIC(12,2) NOT NULL DEFAULT 0.00,
    balance_due_at DATE,
    booking_status TEXT NOT NULL DEFAULT 'pending' 
        CHECK (booking_status IN ('pending', 'confirmed', 'completed', 'cancelled')),
    payment_status TEXT NOT NULL DEFAULT 'pending' 
        CHECK (payment_status IN ('pending', 'successful', 'partially_paid', 'fully_paid', 'failed', 'cancelled', 'refunded')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.birthday_bookings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own birthday bookings" ON public.birthday_bookings;
DROP POLICY IF EXISTS "Users can insert their own birthday bookings" ON public.birthday_bookings;
DROP POLICY IF EXISTS "Users can update their own birthday bookings" ON public.birthday_bookings;

CREATE POLICY "Users can view their own birthday bookings"
    ON public.birthday_bookings FOR SELECT TO authenticated USING (user_id = auth.uid());

REVOKE INSERT, UPDATE, DELETE ON public.birthday_bookings FROM anon, authenticated;
GRANT SELECT ON public.birthday_bookings TO authenticated;

-- 4. BIRTHDAY BOOKING ITEMS TABLE (Selected Services)
CREATE TABLE IF NOT EXISTS public.birthday_booking_items (
    id TEXT PRIMARY KEY,
    booking_id TEXT NOT NULL REFERENCES public.birthday_bookings(id) ON DELETE CASCADE,
    service_id TEXT REFERENCES public.birthday_services(id) ON DELETE SET NULL,
    package_id TEXT REFERENCES public.birthday_service_packages(id) ON DELETE SET NULL,
    service_category TEXT NOT NULL,
    package_name TEXT NOT NULL,
    unit_price NUMERIC(12,2) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    selected_addons JSONB DEFAULT '[]'::jsonb,
    item_total NUMERIC(12,2) NOT NULL,
    custom_instructions TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.birthday_booking_items ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Booking items are viewable by all" ON public.birthday_booking_items;
CREATE POLICY "Booking items are viewable by all"
    ON public.birthday_booking_items FOR ALL USING (true);

-- 5. BIRTHDAY BOOKING SLOTS (Availability & Conflict Prevention)
CREATE TABLE IF NOT EXISTS public.birthday_booking_slots (
    id TEXT PRIMARY KEY,
    slot_date DATE NOT NULL,
    time_slot TEXT NOT NULL CHECK (time_slot IN ('morning', 'afternoon', 'evening')),
    status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'reserved', 'booked')),
    reserved_by_user UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    reservation_token TEXT,
    reserved_until TIMESTAMP WITH TIME ZONE,
    booking_id TEXT REFERENCES public.birthday_bookings(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    CONSTRAINT unique_slot_per_date UNIQUE (slot_date, time_slot)
);

ALTER TABLE public.birthday_booking_slots ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Slots are viewable by everyone" ON public.birthday_booking_slots;
CREATE POLICY "Slots are viewable by everyone"
    ON public.birthday_booking_slots FOR ALL USING (true);

-- 6. BIRTHDAY PAYMENTS TABLE (bKash, Cards, Bank)
CREATE TABLE IF NOT EXISTS public.birthday_payments (
    id TEXT PRIMARY KEY,
    booking_id TEXT NOT NULL REFERENCES public.birthday_bookings(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    amount NUMERIC(12,2) NOT NULL,
    payment_method TEXT NOT NULL CHECK (payment_method IN ('bkash', 'nagad', 'visa', 'mastercard', 'card', 'bank_transfer')),
    transaction_id TEXT NOT NULL,
    idempotency_key TEXT,
    sender_phone_or_account TEXT,
    gateway_reference TEXT,
    payment_status TEXT NOT NULL DEFAULT 'pending' 
        CHECK (payment_status IN ('pending', 'successful', 'failed', 'cancelled', 'refunded')),
    verified_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.birthday_payments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Payments are viewable by all authorized" ON public.birthday_payments;
DROP POLICY IF EXISTS "Users can view their own birthday payments" ON public.birthday_payments;
CREATE POLICY "Users can view their own birthday payments"
    ON public.birthday_payments FOR SELECT TO authenticated USING (user_id = auth.uid());

REVOKE INSERT, UPDATE, DELETE ON public.birthday_payments FROM anon, authenticated;
GRANT SELECT ON public.birthday_payments TO authenticated;
CREATE UNIQUE INDEX IF NOT EXISTS birthday_payments_idempotency_key_unique
    ON public.birthday_payments (idempotency_key)
    WHERE idempotency_key IS NOT NULL;

-- 7. BIRTHDAY EVENT PARTICIPANTS TABLE
CREATE TABLE IF NOT EXISTS public.birthday_event_participants (
    id TEXT PRIMARY KEY,
    event_id TEXT NOT NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    display_name TEXT NOT NULL,
    role TEXT NOT NULL DEFAULT 'guest' CHECK (role IN ('host', 'guest', 'photographer', 'admin')),
    access_code TEXT NOT NULL,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.birthday_event_participants ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Event participants access" ON public.birthday_event_participants;
CREATE POLICY "Event participants access"
    ON public.birthday_event_participants FOR ALL USING (true);

-- 8. BIRTHDAY SHARED EVENT PHOTOS TABLE
CREATE TABLE IF NOT EXISTS public.birthday_shared_photos (
    id TEXT PRIMARY KEY,
    event_id TEXT NOT NULL,
    uploader_id TEXT,
    uploader_name TEXT NOT NULL,
    uploader_role TEXT NOT NULL DEFAULT 'guest',
    image_url TEXT NOT NULL,
    storage_path TEXT,
    caption TEXT,
    likes_count INT NOT NULL DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.birthday_shared_photos ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Shared photos viewable by event participants" ON public.birthday_shared_photos;
CREATE POLICY "Shared photos viewable by event participants"
    ON public.birthday_shared_photos FOR ALL USING (true);

-- 9. BIRTHDAY REVIEWS TABLE
CREATE TABLE IF NOT EXISTS public.birthday_reviews (
    id TEXT PRIMARY KEY,
    booking_id TEXT REFERENCES public.birthday_bookings(id) ON DELETE SET NULL,
    service_id TEXT REFERENCES public.birthday_services(id) ON DELETE SET NULL,
    user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    user_name TEXT NOT NULL,
    rating INT NOT NULL CHECK (rating >= 1 AND rating <= 5),
    comment TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

ALTER TABLE public.birthday_reviews ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Reviews viewable by everyone" ON public.birthday_reviews;
CREATE POLICY "Reviews viewable by everyone"
    ON public.birthday_reviews FOR ALL USING (true);

-- 10. PRE-POPULATED LUXURY BIRTHDAY SERVICES & PACKAGES
INSERT INTO public.birthday_services (id, category, title, short_description, description, image_url, base_price, price_unit)
VALUES
('svc_catering', 'catering', 'Gourmet Feast & Birthday Catering', 'Royal Biryani, artisanal sliders, mocktail bars & dessert tables.', 'Comprehensive celebration catering crafted with fresh ingredients, live food stations, bespoke birthday cakes, and dessert bars tailored to your guest headcount.', 'https://images.unsplash.com/photo-1555244162-803834f70033', 650.00, 'per_person'),
('svc_photo', 'photography', 'Cinematic Photography & 4K Highlights', 'Candid portraits, family moments, cake cutting & 4K highlight reels.', 'Professional high-fashion and cinematic event photographers capturing every laughter, milestone toast, and precious birthday memory in ultra-high resolution.', 'https://images.unsplash.com/photo-1537633552985-df8429e8048b', 18000.00, 'package'),
('svc_decor', 'decoration', 'Blush Floral & Luxury Balloon Styling', 'Bespoke floral arches, golden backdrops, fairy lights & centerpieces.', 'Sophisticated blush pink, ivory and champagne gold styling with grand welcome entrance, custom neon signages, table floral runners, and organic balloon clouds.', 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3', 25000.00, 'package')
ON CONFLICT (id) DO NOTHING;

-- Packages for Catering
INSERT INTO public.birthday_service_packages (id, service_id, name, tier, price, description, image_url, inclusions, available_addons)
VALUES
('pkg_cat_silver', 'svc_catering', 'Classic Celebration Feast', 'silver', 650.00, 'Delightful family buffet with biryani, chicken roast, fresh salads, and dessert cups.', 'https://images.unsplash.com/photo-1555244162-803834f70033', 
'["Basmati Chicken Roast / Polao", "Fresh Green Garden Salad", "Gulab Jamun or Firni Cups", "Chilled Soft Drinks & Mineral Water", "Standard Buffet Setup & Chafing Dishes"]'::jsonb,
'[{"id": "add_cake", "name": "1kg Custom Theme Cake", "price": 1800}, {"id": "add_mocktails", "name": "Live Mocktail Station", "price": 4000}]'::jsonb),

('pkg_cat_gold', 'svc_catering', 'Royal Moghul Shahi Banquet', 'gold', 1100.00, 'Sumptuous feast with Mutton Kacchi Biryani, Jali Kebab, Borhani, and live dessert counter.', 'https://images.unsplash.com/photo-1544025162-d76694265947',
'["Special Mutton Kacchi Biryani", "Chicken Roast with Saffron Glaze", "Beef Jali Kebab & Chutney", "Traditional Dhaka Borhani", "Shahi Tukra & Faluda Jars", "Dedicated Catering Waitstaff & Crockery"]'::jsonb,
'[{"id": "add_pasta", "name": "Live Italian Pasta Station", "price": 6000}, {"id": "add_chocolate_fountain", "name": "Belgian Chocolate Fountain", "price": 8000}]'::jsonb),

('pkg_cat_royal', 'svc_catering', 'Imperial Gourmet Extravaganza', 'royal', 1800.00, 'Grand multi-course culinary journey with live grill, artisanal sliders, seafood bites, and luxury dessert table.', 'https://images.unsplash.com/photo-1504674900247-0877df9cc836',
'["Live BBQ & Tandoori Station", "Grand Mutton Kacchi & Polao Dual Entree", "Prawn Tempura & Finger Food Platters", "Artisanal Cheese & Fruit Display", "Imported Ice Cream & Patisserie Bar", "White Glove Butler & Dining Setup"]'::jsonb,
'[{"id": "add_barista", "name": "Specialty Espresso Barista", "price": 7500}]'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- Packages for Photography
INSERT INTO public.birthday_service_packages (id, service_id, name, tier, price, description, image_url, inclusions, available_addons)
VALUES
('pkg_pho_silver', 'svc_photo', 'Memories Starter Session', 'silver', 18000.00, '3 hours of candid coverage focusing on guest arrivals, cake cutting, and family portraits.', 'https://images.unsplash.com/photo-1537633552985-df8429e8048b',
'["1 Senior Candid Photographer", "3 Hours Event Coverage", "Unlimited Raw High-Res Photos", "50 Master Retouched Photographs", "Private Online Delivery Link Within 4 Days"]'::jsonb,
'[{"id": "add_album", "name": "Hardcover Keepsake Photobook", "price": 6500}, {"id": "add_extra_hour", "name": "Additional Coverage Hour", "price": 3000}]'::jsonb),

('pkg_pho_gold', 'svc_photo', 'Cinematic Story & Reel Package', 'gold', 32000.00, 'Full event photo and video coverage with 4K Instagram Reels and cinematic highlight video.', 'https://images.unsplash.com/photo-1606800052052-a08af7148866',
'["1 Senior Photographer + 1 Cinematographer", "5 Hours Event Coverage", "100 Color-Graded Retouched Portraits", "2-3 Minute 4K Cinematic Highlight Film", "2 Vertical Instagram Reels/TikToks", "Delivered on Custom Wooden USB + Cloud"]'::jsonb,
'[{"id": "add_drone", "name": "Drone Aerial Shots", "price": 8000}]'::jsonb),

('pkg_pho_royal', 'svc_photo', 'Royal Masterpiece Production', 'royal', 55000.00, 'Top-tier production crew with pre-birthday mini session, drone footage, luxury album, and instant live photo sharing.', 'https://images.unsplash.com/photo-1511285560929-80b456fea0bc',
'["2 Master Photographers + 2 Senior Cinematographers", "Unlimited Event Day Coverage", "Pre-Birthday Golden Hour Mini Portrait Session", "Full 4K Documentary Cut + Teaser Film", "Live On-Site Digital Photo Booth", "Premium Leather-Bound Flush Mount Album (40 Pages)"]'::jsonb,
'[]'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- Packages for Decoration
INSERT INTO public.birthday_service_packages (id, service_id, name, tier, price, description, image_url, inclusions, available_addons)
VALUES
('pkg_dec_silver', 'svc_decor', 'Elegance Blush & Pastel Backdrop', 'silver', 25000.00, 'Chic 8ft circular arch with blush floral sprays, custom acrylic nameplate, and mood spotlighting.', 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3',
'["8ft Circular Metal Arch with Blush Flowers", "Custom Birthday Person Name Acrylic Board", "Organic Pastel Balloon Garland (Dual Tone)", "Cake Table Plinth with Floral Accent", "Warm LED Ambience Spotlights"]'::jsonb,
'[{"id": "add_neon", "name": "Happy Birthday Neon Sign", "price": 3500}, {"id": "add_entry", "name": "Welcome Easel Board with Flowers", "price": 4000}]'::jsonb),

('pkg_dec_gold', 'svc_decor', 'Champagne Gold Glamour Stage', 'gold', 45000.00, '12ft multi-layered stage with luxury silk floral arrangements, shimmer sequin backdrop, and entrance tunnel.', 'https://images.unsplash.com/photo-1464366400600-7168b8af9bc3',
'["12ft Curved Stage Backdrop with Champagne Gold Trim", "Hydrangea & Rose Silk Floral Runners", "Fairy Light Tunnel / Grand Entrance Arch", "3 Luxury Cylinder Pedestals for Cake & Desserts", "Custom Neon Signboard & Number Lighted Props", "Ambient Floor Up-Lighting (6 Units)"]'::jsonb,
'[{"id": "add_table_centerpieces", "name": "10 Guest Table Flower Centerpieces", "price": 8000}, {"id": "add_fog", "name": "Low Fog Dry-Ice for Cake Cutting", "price": 5000}]'::jsonb),

('pkg_dec_royal', 'svc_decor', 'Imperial Palace Theme Wonderland', 'royal', 80000.00, 'Complete ballroom transformation with fresh imported botanical blossoms, crystal chandeliers, and customized theme elements.', 'https://images.unsplash.com/photo-1530103862676-de8c9debad1d',
'["Complete Venue Theme Styling (Stage, Entrance, Seating)", "100% Fresh Imported Floral Installations", "Custom Fabricated Castle/Arch Architectural Backdrop", "Crystal Chandeliers & Overhead Ceiling Drapes", "All Guest Tables Decorated with Silk Linen & Floral Candelabras", "Dedicated Decor Styling Coordinator On-Site"]'::jsonb,
'[]'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- 11. SUPABASE STORAGE BUCKET FOR SHARED PHOTOS
INSERT INTO storage.buckets (id, name, public)
VALUES ('birthday-photos', 'birthday-photos', true)
ON CONFLICT (id) DO NOTHING;

DROP POLICY IF EXISTS "Public can view birthday photos" ON storage.objects;
DROP POLICY IF EXISTS "Authenticated users can upload birthday photos" ON storage.objects;

CREATE POLICY "Public can view birthday photos"
    ON storage.objects FOR SELECT USING (bucket_id = 'birthday-photos');

CREATE POLICY "Authenticated users can upload birthday photos"
    ON storage.objects FOR INSERT WITH CHECK (bucket_id = 'birthday-photos');
